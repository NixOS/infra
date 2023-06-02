.PHONY: plan apply

arch=x86_64
version=23.05

tfvarsFile=$(version).$(arch).current.tfvars

$(tfvarsFile) .current-workspace:
	./pull-latest $(version) $(arch)

copy.tf.json: regions.jq regions.json
	@jq -f regions.jq regions.json > copy.tf.json

plan: copy.tf.json $(tfvarsFile) .current-workspace
	@terraform workspace select -or-create $(shell cat .current-workspace)
	@terraform plan -var-file=$(tfvarsFile)

apply: copy.tf.json $(tfvarsFile)
	@terraform workspace select -or-create $(shell cat .current-workspace)
	@terraform apply -var-file=$(tfvarsFile)
