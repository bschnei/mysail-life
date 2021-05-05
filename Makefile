GCP_PROJECT_ID=mysail-life
GCP_ZONE=us-central1-a
GCP_INSTANCE_NAME=web-server

run-local:
	docker-compose -f docker-compose.local.yml up --build

###

create-tf-backend-bucket:
	gsutil mb -p $(GCP_PROJECT_ID) gs://$(GCP_PROJECT_ID)-terraform

###

define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(GCP_PROJECT_ID))
endef

define get-ipv4
$(shell curl -s http://whatismyip.akamai.com/)
endef

terraform-init:
	cd terraform && \
		terraform init

TF_ACTION?=plan
terraform-action:
	@cd terraform && \
		terraform $(TF_ACTION) \
		-var="atlas_private_key=$(call get-secret,atlas_private_key)" \
		-var="atlas_user_password=$(call get-secret,atlas_user_password)" \
		-var="gcp_project_id=$(GCP_PROJECT_ID)" \
		-var="gcp_instance_name=$(GCP_INSTANCE_NAME)" \
		-var="namecheap_username=$(call get-secret,namecheap_username)" \
		-var="namecheap_token=$(call get-secret,namecheap_token)" \
		-var="namecheap_ip=$(call get-ipv4)"

###

SSH_STRING=ben@$(GCP_INSTANCE_NAME)

sleep:
	gcloud compute instances stop $(GCP_INSTANCE_NAME) \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE)

ssh:
	gcloud compute ssh $(SSH_STRING) \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE)

ssh-cmd:
	@gcloud compute ssh $(SSH_STRING) \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE) \
		--command="$(CMD)"

wake:
	gcloud compute instances start $(GCP_INSTANCE_NAME) \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE)

OAUTH_CLIENT_ID=1001255306684-j6fe3u0ppm5kebff6s34a3jmn5vv2i25.apps.googleusercontent.com

GITHUB_SHA?=latest
LOCAL_APP_TAG=$(GCP_PROJECT_ID):$(GITHUB_SHA)
REMOTE_APP_TAG=gcr.io/$(GCP_PROJECT_ID)/app:$(GITHUB_SHA)

LOCAL_SWAG_TAG=swag:latest
REMOTE_SWAG_TAG=gcr.io/$(GCP_PROJECT_ID)/$(LOCAL_SWAG_TAG)

CONTAINER_NAME=mysail-life-api
DB_NAME=mysail-life

build:
	docker build -t $(LOCAL_APP_TAG) ./app
	docker build -t $(LOCAL_SWAG_TAG) ./swag

push:
	docker tag $(LOCAL_APP_TAG) $(REMOTE_APP_TAG)
	docker push $(REMOTE_APP_TAG)
	docker tag $(LOCAL_SWAG_TAG) $(REMOTE_SWAG_TAG)
	docker push $(REMOTE_SWAG_TAG)

test:
	gcloud compute scp docker-compose.yml $(GCP_INSTANCE_NAME):~ \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE)
	$(MAKE) ssh-cmd CMD='docker-credential-gcloud configure-docker'
	$(MAKE) ssh-cmd CMD='GCS=$(call get-secret,google_oauth_client_secret) MURI=mongodb+srv://mysail-life-user:$(call get-secret,atlas_user_password)@mysail-life.54zcx.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority docker-compose pull'

deploy:
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_APP_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
	  		-e PORT=3000 \
	  		-e \"MONGO_URI=mongodb+srv://mysail-life-user:$(call get-secret,atlas_user_password)@mysail-life.54zcx.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority\" \
	  		-e GOOGLE_CLIENT_ID=$(OAUTH_CLIENT_ID) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,google_oauth_client_secret) \
			$(REMOTE_APP_TAG) \
			'
