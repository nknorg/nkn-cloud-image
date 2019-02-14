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
