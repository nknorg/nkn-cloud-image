BUILD=packer build \
-var 'do_api_token=$(shell cat do_api_token)' \
-var 'gc_project_id=nkn-testnet' \
-var 'gc_zone=us-west1-a' \
-var 'gc_account_file=gc_account_nkn_testnet.json'

TEMPLATE=packer.json

.PHONY: do
do:
	$(BUILD) -only=digitalocean $(TEMPLATE)

.PHONY: gc
gc:
	$(BUILD) -only=googlecompute $(TEMPLATE)

.PHONY: all
all:
	$(BUILD) $(TEMPLATE)
