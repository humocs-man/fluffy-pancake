#!/usr/bin/env bash
set -e

USER="$1"

sudo -u "$USER" NONINTERACTIVE=1 \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
