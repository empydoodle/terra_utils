#!/bin/bash

# Install required dependencies on a Debian-based Linux system.
if [[ "$(which mise)" == "mise not found" ]]; then
  echo "[TERRAUTILS] Installing mise for package management..."
  # install from https://github.com/mise/mise
  curl -sSL https://mise.run | sh
  export PATH="~/.local/bin:$PATH"
  eval "$(mise activate bash)"
  echo "[TERRAUTILS] ... done!"

  echo "[TERRAUTILS] Activating mise..."
  # Bash
  cat <<EOF >> ${HOME}/.bashrc

# Added by terra_utils at $(date)
eval "$(~/.local/bin/mise activate bash)"
EOF
  # Zsh
  cat <<EOF >> ${HOME}/.zshrc

# Added by terra_utils at $(date)
eval "$(~/.local/bin/mise activate zsh)"
EOF
  # Fish
  cat <<EOF >> ${HOME}/.config/fish/config.fish

# Added by terra_utils at $(date)
eval "$(~/.local/bin/mise activate fish)"
EOF
  echo "[TERRAUTILS] ... done!"
fi

echo ""
echo "[TERRAUTILS] Installing packages with mise..."
~/.local/bin/mise install
echo "[TERRAUTILS] ... done!"

echo ""
echo "[TERRAUTILS] Checking 1Password requirements..."

# Complete setup
echo "[TERRAUTILS] Please install reqired Ruby version via rbenv, install the required Ruby gems and run setup:"
echo '               $ cd /path/to/terra_utils'
echo '               $ rbenv install'
echo '               $ bundle install'
echo '               $ thor setup'
