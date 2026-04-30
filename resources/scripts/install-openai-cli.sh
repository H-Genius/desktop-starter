#!/usr/bin/env bash

set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  brew install --cask codex
else
  npm install -g @openai/codex
fi

echo
codex --version
echo
read -r -p "Press Enter to close this window..."
