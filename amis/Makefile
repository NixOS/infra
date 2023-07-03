.PHONY: plan apply

arch=x86_64
version=23.05
build-nr=

tfvarsFile=$(version).$(arch).current.tfvars

$(tfvarsFile) .current-workspace:
	./pull-latest $(version) $(arch) $(build-nr)

copy.tf.json: regions.jq regions.json
	@jq -f regions.jq regions.json > copy.tf.json

plan: copy.tf.json $(tfvarsFile) .current-workspace
	@terraform workspace select -or-create $(shell cat .current-workspace)
	@terraform plan -var-file=$(tfvarsFile)

apply: copy.tf.json $(tfvarsFile)
	@terraform workspace select -or-create $(shell cat .current-workspace)
	@terraform apply -var-file=$(tfvarsFile)

destroy: copy.tf.json $(tfvarsFile)
	@terraform workspace select $(shell cat .current-workspace)
	@terraform destroy -var-file=$(tfvarsFile)
