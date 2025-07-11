#!/bin/bash

# Install required dependencies on a Debian-based Linux system.
if [[ "$(which apt)" == "apt not found" ]]; then
  echo "[TERRAUTILS] Please install the following dependencies for your platform:"
  echo "               * rbenv    (https://github.com/rbenv/rbenv#installation)"
  echo "               * tfswitch (https://github.com/warrensbox/terraform-switcher)"
  echo "               * tgswitch (https://github.com/warrensbox/tgswitch)"
else
  echo "[TERRAUTILS] Updating package list & installing base dependencies..."
  sudo apt-get update && sudo apt-get install -y rbenv tfswitch tgswitch
  echo "[TERRAUTILS] ... done!"
fi

echo ""

# Check 1Password requirements
if [[ "$(which op)" == "op not found" ]]; then
  echo "[TERRAUTILS] If you wish to fetch secrets using 1Password, please install 1password-cli and its dependencies:"
  echo "               https://developer.1password.com/docs/cli/get-started/#step-1-install-1password-cli"
  echo ""
fi

# Complete setup
echo "[TERRAUTILS] Please install reqired Ruby version via rbenv, install the required Ruby gems and run setup:"
echo '               $ cd /path/to/terra_utils'
echo '               $ rbenv install'
echo '               $ bundle install'
echo '               $ thor setup'
