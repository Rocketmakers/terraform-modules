#############################
# VARIABLES
#############################
M 									= $(shell printf "\033[34;1m▶\033[0m")
sed 								= $(shell printf "sed")
SHELL 							:= /bin/bash
SHELL_SCRIPTS 			:= _build/scripts
TSNODE 							:= node_modules/.bin/ts-node
TSNODE_SCRIPTS			:= _build/run
LOG_LEVEL						?= info

# To allow terraform init to work without having to hardcode an AWS region into a provider block
AWS_DEFAULT_REGION	?= eu-west-1

# Detect OS
ifeq ($(OS),Windows_NT) 
  detected_OS := Windows
else
  detected_OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
endif

# Setup environment depending on OS
ifeq ($(detected_OS),Darwin)
	sed = $(shell printf "gsed")
endif

# Due to https://github.com/hashicorp/terraform-provider-azurerm/issues/7359#issuecomment-648711339 we need to setup
# an azure providers record in order for terraform-providers to pass.
# However, according to https://www.terraform.io/docs/language/modules/develop/providers.html we should not be defining
# provider blocks in reusable modules.
define Validate
	for d in $(1)/* ; do \
		if [ "$(1)" = "azure" ]; then \
			(cd $${d} && (rm -f providers.tf) && echo 'provider "azurerm" {' > providers.tf && echo 'features {}' >> providers.tf && echo '}' >> providers.tf); \
		fi; \
		if [ "$(1)" = "aws" ]; then \
			(cd $${d} && (rm -f providers.tf) && echo 'provider "aws" {' > providers.tf && echo 'region = "${AWS_DEFAULT_REGION}"' >> providers.tf && echo '}' >> providers.tf); \
		fi; \
    (cd $${d} && echo "Validating" $${d} && terraform init && terraform validate) || exit; \
	done
endef

.PHONY: node-setup
node-setup:
	$(info $(M) NODE SETUP...)
	$(SHELL) $(SHELL_SCRIPTS)/node-setup.sh

.PHONY: install-node-modules
install-node-modules: node-setup
	$(info $(M) INSTALLING NODE MODULES...)
	npm i

.PHONY: setup-terraform
setup-terraform:
	$(info $(M) Setting up terraform)
	asdf install terraform
	asdf install terraform-docs

.PHONY: validate
validate: setup-terraform validate-aws validate-azure validate-gcp validate-shared
	$(info $(M) Finished)

.PHONY: validate-aws
validate-aws:
	$(info $(M) Validating aws...)
	$(call Validate,aws)

.PHONY: validate-azure
validate-azure:
	$(info $(M) Validating azure...)
	$(call Validate,azure)

.PHONY: validate-gcp
validate-gcp:
	$(info $(M) Validating gcp...)
	$(call Validate,gcp)

.PHONY: validate-shared
validate-shared:
	$(info $(M) Validating shared...)
	$(call Validate,shared)

.PHONY: format-all
format-all:
	$(info $(M) Formatting...)
	terraform fmt -recursive

.PHONY: generate-docs
generate-docs:
	$(info $(M) Generating docs...)
	$(TSNODE) $(TSNODE_SCRIPTS)/readmes.ts -l=$(LOG_LEVEL)

changelog:
	$(info $(M) Generating changelog...)
	npx standard-version
