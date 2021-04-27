PROJECT_ID=mysail-life
ZONE=us-central1-a

run-local:
	docker-compose up

###

create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform

###

check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

# This cannot be indented or else make will include spaces in front of secret
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

terraform-create-workspace: check-env
	cd terraform && \
		terraform workspace new $(ENV)

terraform-init: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

TF_ACTION?=plan
terraform-action: check-env
	@cd terraform && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars" \
		-var="atlas_private_key=$(call get-secret,atlas_private_key)" \
		-var="atlas_user_password=$(call get-secret,atlas_user_password_$(ENV))" \
		-var="cloudflare_api_token=$(call get-secret,cloudflare_api_token)"

###

SSH_STRING=ben@mysail-life-vm-$(ENV)
OAUTH_CLIENT_ID=1001255306684-j6fe3u0ppm5kebff6s34a3jmn5vv2i25.apps.googleusercontent.com

GITHUB_SHA?=latest
LOCAL_TAG=$(PROJECT_ID):$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)

CONTAINER_NAME=mysail-life-api
DB_NAME=mysail-life

sleep: check-env
	gcloud compute instances stop mysail-life-vm-$(ENV) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh: check-env
	gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh-cmd: check-env
	@gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE) \
		--command="$(CMD)"

wake: check-env
	gcloud compute instances start mysail-life-vm-$(ENV) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

build:
	docker build -t $(LOCAL_TAG) .

push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

deploy: check-env
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
	  		-e PORT=3000 \
	  		-e \"MONGO_URI=mongodb+srv://mysail-life-user-$(ENV):$(call get-secret,atlas_user_password_$(ENV))@mysail-life-$(ENV).54zcx.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority\" \
	  		-e GOOGLE_CLIENT_ID=$(OAUTH_CLIENT_ID) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,google_oauth_client_secret) \
			$(REMOTE_TAG) \
			'
