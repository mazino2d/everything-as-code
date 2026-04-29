STACK ?= terraform/github

.PHONY: init plan apply fmt validate

init:
	terraform -chdir=$(STACK) init

plan:
	terraform -chdir=$(STACK) plan

apply:
	terraform -chdir=$(STACK) apply -auto-approve

fmt:
	terraform fmt -recursive terraform/

validate:
	terraform -chdir=$(STACK) validate

# Usage:
#   make plan STACK=terraform/github
#   make apply STACK=terraform/gcp/project-example
#   make fmt
