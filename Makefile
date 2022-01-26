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
validate: setup-terraform
	$(info $(M) Validating modules)
	${TSNODE} $(TSNODE_SCRIPTS)/validate.ts

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
