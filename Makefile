STACK ?= terraform/github
STATE_BUCKET := mazino2d-as-se1-eac-tfstate
# Stack variables: gs://<bucket>/secrets/<stack path under terraform/>.tfvars.json
SECRETS := gs://$(STATE_BUCKET)/secrets/$(patsubst terraform/%,%,$(STACK)).tfvars.json
TFVARS := $(STACK)/ci.auto.tfvars.json

.PHONY: init plan apply fmt validate secrets secrets-edit

# Needs Application Default Credentials: gcloud auth application-default login
init:
	terraform -chdir=$(STACK) init

# Copies the stack's variables to $(TFVARS) (git-ignored), if it has any.
secrets:
	@if gcloud storage objects describe $(SECRETS) >/dev/null 2>&1; then \
	  gcloud storage cp --no-user-output-enabled $(SECRETS) $(TFVARS) && echo "Loaded $(SECRETS)"; \
	else echo "No variables at $(SECRETS)"; fi

# Edits the stack's variables in $$EDITOR through $(TFVARS), then uploads them.
secrets-edit: secrets
	@[ -f $(TFVARS) ] || echo '{}' > $(TFVARS)
	$${EDITOR:-vi} $(TFVARS)
	python3 -m json.tool $(TFVARS) >/dev/null
	gcloud storage cp --no-user-output-enabled $(TFVARS) $(SECRETS) && echo "Uploaded $(SECRETS)"

# Waits up to 10 minutes for the state lock (a CI apply or plan may hold it).
plan: secrets
	terraform -chdir=$(STACK) plan -lock-timeout=10m

apply: secrets
	terraform -chdir=$(STACK) apply -lock-timeout=10m -auto-approve

fmt:
	terraform fmt -recursive terraform/

validate:
	terraform -chdir=$(STACK) validate

# Usage:
#   make plan STACK=terraform/github
#   make apply STACK=terraform/gcp/mazino2d-as-se1-dev
#   make secrets-edit STACK=terraform/cloudflare
#   make fmt
