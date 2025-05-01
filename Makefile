#############################
# VARIABLES
#############################
M 									= $(shell printf "\033[34;1m▶\033[0m")
sed 								= $(shell printf "sed")
UNAME 							= $(shell uname -s)
SHELL 							:= /bin/bash -o pipefail
SHELL_SCRIPTS 			:= _build/scripts
TSNODE 							:= node_modules/.bin/ts-node
TSNODE_SCRIPTS			:= _build/run
LOG_LEVEL						?= info
TERRATEST_LOG_PARSER_VERSION ?= v0.40.24
ARCHITECTURE                 ?= linux_amd64

# Set false to leave resources in place after testing (speed up feedback loops)
CLEANUP_AFTER_TESTS ?= true

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

define InstallTerratestLogParser
	curl --location --silent --fail --show-error -o terratest_log_parser https://github.com/gruntwork-io/terratest/releases/download/${TERRATEST_LOG_PARSER_VERSION}/terratest_log_parser_${ARCHITECTURE}
	chmod +x terratest_log_parser
	mv terratest_log_parser /usr/local/bin
endef

.PHONY: install
install: node-setup
	$(info $(M) INSTALLING NODE MODULES...)
	$(SHELL) $(SHELL_SCRIPTS)/install.sh

.PHONY: clean
clean:
	$(call header,CLEANING...)
	echo 'Creating a temporary commit... use [git reflog] to get your work back!'
	git add -A && ((HUSKY_SKIP_HOOKS=1 git commit -m 'WIPE CLEAN' && git reset HEAD^ --hard) || true)
	git clean -dfx

.PHONY: node-setup
node-setup:
	$(info $(M) NODE SETUP...)
	$(SHELL) $(SHELL_SCRIPTS)/node-setup.sh

.PHONY: setup-terraform
setup-terraform:
	$(info $(M) Setting up terraform)
	asdf plugin add terraform https://github.com/Banno/asdf-hashicorp.git || true
	asdf plugin add terraform-docs https://github.com/looztra/asdf-terraform-docs || true
	asdf install terraform
	asdf install terraform-docs

.PHONY: validate
validate: setup-terraform
	$(info $(M) Validating modules)
	${TSNODE} $(TSNODE_SCRIPTS)/validate.ts --directory=$(VALIDATE_DIR)

.PHONY: setup-go
setup-go:
	$(info $(M) Setting up golang...)
	asdf plugin add golang https://github.com/kennyp/asdf-golang.git || true
	asdf install golang

.PHONY: local-az-login
local-az-login: ## Login to the subscription required for this project
	az login --tenant 09e95bcb-540c-433b-8597-3e94ab4119e5
	az account set --subscription 68bb123f-6027-4e99-8ab0-a01fb16cdd79

.PHONY: test
test: setup-go setup-terraform
	$(info $(M) Running tests for $(TERRATEST_DIR)...)
ifeq ($(UNAME),Darwin)
	(cd _tests/src/$(TERRATEST_DIR) && go test -timeout 60m)
else 
	$(call InstallTerratestLogParser)
	(cd _tests/src/$(TERRATEST_DIR) && go test -timeout 60m | tee test_output.log) && (terratest_log_parser -testlog _tests/src/$(TERRATEST_DIR)/test_output.log -outputdir _tests/src/$(TERRATEST_DIR))
endif

.PHONY: format-all
format-all:
	$(info $(M) Formatting...)
	terraform fmt -recursive

.PHONY: generate-docs
generate-docs: setup-terraform
	$(info $(M) Generating docs...)
	$(TSNODE) $(TSNODE_SCRIPTS)/readmes.ts -l=$(LOG_LEVEL)

.PHONY: bump-version
bump-version: install 
	$(info $(M) Bumping version...)
	$(TSNODE) $(TSNODE_SCRIPTS)/version.ts --log=${LOG_LEVEL} --version=${NEW_VERSION_CODE} --force=${FORCE_BUMP_VERSION}
	make changelog

.PHONY: changelog
changelog:
	$(info $(M) Generating changelog...)
	npx standard-version

.PHONY: send-slack
send-slack: install
	$(info $(M) Sending slack message...)
	$(TSNODE) $(TSNODE_SCRIPTS)/slack.ts --log=${LOG_LEVEL} -t=${TEST_NAME}
