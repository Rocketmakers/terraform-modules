#!/bin/bash
set -e

asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git || true
asdf plugin add terraform-docs https://github.com/looztra/asdf-terraform-docs || true
asdf plugin add github-cli https://github.com/bartlomiejdanek/asdf-github-cli.git || true

# asdf install >= 0.16 returns non-zero error code if already installed
asdf install terraform || true
asdf install terraform-docs || true
asdf install github-cli || true
