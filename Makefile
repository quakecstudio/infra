ENV ?= global
DIR = environments/$(ENV)

.PHONY: init reconfigure fmt validate plan apply destroy

init:
	cd $(DIR) && terraform init -upgrade

reconfigure:
	cd $(DIR) && terraform init -reconfigure

fmt:
	terraform fmt -recursive

validate: fmt
	cd $(DIR) && terraform validate

plan: validate
	cd $(DIR) && terraform plan

apply:
	cd $(DIR) && terraform apply

destroy:
	cd $(DIR) && terraform destroy
