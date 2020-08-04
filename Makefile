BUILD=packer build
TEMPLATE=packer.json
GC_LICENSE=/projects/nkn-public/global/licenses/nkn-full-node

.PHONY: do
do:
	$(BUILD) -only=digitalocean \
	-var 'do_api_token=$(shell cat digitalocean/api_token)' \
	$(TEMPLATE)

.PHONY: gc-dev
gc-dev:
	$(BUILD) -only=googlecompute \
	-var 'gc_project_id=nkn-dev' \
	-var 'gc_license=$(GC_LICENSE)' \
	-var 'gc_account_file=googlecloud/nkn-dev.json' \
	-var 'gc_zone=us-west1-a' \
	$(TEMPLATE)

.PHONY: gc-public
gc-public:
	$(BUILD) -only=googlecompute \
	-var 'gc_project_id=nkn-public' \
	-var 'gc_license=$(GC_LICENSE)' \
	-var 'gc_account_file=googlecloud/nkn-public.json' \
	-var 'gc_zone=us-west1-a' \
	$(TEMPLATE)

.PHONY: gc-package
gc-package:
	rm -rf googlecloud/package
	docker run --rm --workdir /mounted \
	--mount type=bind,source="$(shell pwd)",target=/mounted \
	--user $(shell id -u):$(shell id -g) gcr.io/cloud-marketplace-tools/dm/autogen \
	--input_type YAML --single_input googlecloud/solution.yaml \
	--output_type PACKAGE --output googlecloud/package
	cd googlecloud/package && zip --exclude "*.DS_Store*" --exclude "*__MACOSX*" -r package.zip *

.PHONY: aws
aws:
	$(BUILD) -only=amazon-ebs \
	-var 'aws_access_key=$(shell cat aws/access_key)' \
	-var 'aws_secret_access_key=$(shell cat aws/secret_access_key)' \
	-var 'aws_region=us-east-1' \
	$(TEMPLATE)

.PHONY: aws-marketplace
aws-marketplace:
	$(BUILD) -only=amazon-ebs \
	-var 'aws_access_key=$(shell cat aws/marketplace_access_key)' \
	-var 'aws_secret_access_key=$(shell cat aws/marketplace_secret_access_key)' \
	-var 'aws_region=us-east-1' \
	$(TEMPLATE)

.PHONY: azure
azure:
	$(BUILD) -only=azure-arm \
	-var 'azure_client_secret=$(shell cat azure/client_secret)' \
	-var 'azure_client_id=ef478b29-3eea-43fb-a976-d440eb4616d4' \
	-var 'azure_subscription_id=c2c2a793-38b2-43a6-ad76-b0f36b868494' \
	-var 'azure_tenant_id=fca45903-25c1-4b28-8e6c-3164d0d79b30' \
	-var 'azure_resource_group_name=yilunpacker' \
	-var 'azure_storage_account=yilunpacker' \
	$(TEMPLATE)

.PHONY: docker
docker:
	$(BUILD) -only=docker \
	-var 'docker_repository=gcr.io/nkn-public/nkn-mainnet' \
	$(TEMPLATE)

all-public: do gc-public aws-marketplace
