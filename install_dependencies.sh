#!/bin/bash

# Install required dependencies on a Debian-based Linux system.

echo "[TERRAUTILS] Updating package list..."
sudo apt-get update
echo "[TERRAUTILS] ... done!"

echo "[TERRAUTILS] Installing base dependencies..."
sudo apt-get install -y \
  rbenv \
  tfswitch \
  tgswitch \
  tflint \
  tfsec \
  terraform-docs \
  pre-commit
echo "[TERRAUTILS] ... done!"
