#!/bin/bash

# Install required dependencies on a Debian-based Linux system.
if [[ "$(which apt)" == "apt not found" ]]; then
  echo "[TERRAUTILS] Please install the following dependencies for your platform:"
  echo "               * rbenv (https://github.com/rbenv/rbenv#installation)"
  echo "               * tenv  (https://github.com/tofuutils/tenv?tab=readme-ov-file#automatic-installation)"
else
  echo "[TERRAUTILS] Updating package list & installing base dependencies..."
  sudo apt-get update && sudo apt-get install -y rbenv tenv
  echo "[TERRAUTILS] ... done!"
fi
echo ""

# Check 1Password requirements
if [[ "$(which op)" == "op not found" ]]; then
  echo "[TERRAUTILS] If you wish to fetch secrets using 1Password, please install 1password-cli and its dependencies:"
  echo "               https://developer.1password.com/docs/cli/get-started/#step-1-install-1password-cli"
fi
