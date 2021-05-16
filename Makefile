GCP_PROJECT_ID=mysail-life
GCP_ZONE=us-central1-a
GCP_INSTANCE_NAME=web-server
OAUTH_CLIENT_ID=1001255306684-j6fe3u0ppm5kebff6s34a3jmn5vv2i25.apps.googleusercontent.com

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

LOCAL_APP_TAG=app:latest
REMOTE_APP_TAG=gcr.io/$(GCP_PROJECT_ID)/$(LOCAL_APP_TAG)

LOCAL_SWAG_TAG=swag:latest
REMOTE_SWAG_TAG=gcr.io/$(GCP_PROJECT_ID)/$(LOCAL_SWAG_TAG)

DB_USER=mysail-life-user
DB_NAME=mysail-life

build:
	docker build -t $(LOCAL_APP_TAG) ./app
	docker build -t $(LOCAL_SWAG_TAG) ./swag

push:
	docker tag $(LOCAL_APP_TAG) $(REMOTE_APP_TAG)
	docker push $(REMOTE_APP_TAG)
	docker tag $(LOCAL_SWAG_TAG) $(REMOTE_SWAG_TAG)
	docker push $(REMOTE_SWAG_TAG)

deploy:
	gcloud compute scp docker-compose.yml $(GCP_INSTANCE_NAME):~ \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE)
	$(MAKE) ssh-cmd CMD='gcloud --quiet auth configure-docker'
	$(MAKE) ssh-cmd CMD='docker-compose pull'
	@$(MAKE) ssh-cmd CMD='\
		GOOGLE_CLIENT_ID=$(OAUTH_CLIENT_ID) \
		GOOGLE_CLIENT_SECRET=$(call get-secret,google_oauth_client_secret) \
		MONGO_URI=mongodb+srv://$(DB_USER):$(call get-secret,atlas_user_password)@mysail-life.54zcx.mongodb.net/$(DB_NAME)?retryWrites=true\&w=majority \
		docker-compose up -d'
	$(MAKE) ssh-cmd CMD='docker system prune -a -f'
