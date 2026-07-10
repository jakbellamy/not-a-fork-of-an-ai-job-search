#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

info() {
  printf '\n[setup] %s\n' "$*"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists brew; then
  info 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$('/opt/homebrew/bin/brew' shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$('/usr/local/bin/brew' shellenv)"
  fi
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
info 'Updating Homebrew...'
brew update

info 'Installing core tools...'
brew install git python@3.12 node@20
brew link --overwrite node@20 || true

if ! command_exists bun; then
  info 'Installing Bun...'
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

info 'Installing LaTeX and PDF tooling...'
brew install --cask basictex poppler
export PATH="/Library/TeX/texbin:$PATH"
if command_exists tlmgr; then
  tlmgr init-usertree
  tlmgr --verify-repo=none install moderncv fontawesome5 fontawesome6 academicons import luatexbase pgf titlesec textpos xltxtra xunicode cite realscripts
fi

info 'Installing Claude Code and Python packages...'
npm install -g @anthropic-ai/claude-code
python3 -m pip install --user --upgrade pip pytest

info 'Installing job-portal CLI dependencies...'
for tool in jobbank-search jobdanmark-search jobindex-search jobnet-search linkedin-search freehire-search; do
  cli_dir="$SCRIPT_DIR/.agents/skills/$tool/cli"
  if [ -d "$cli_dir" ]; then
    info "Installing $tool dependencies..."
    (
      cd "$cli_dir"
      bun install
    )
  fi
done

info 'Setup complete.'
info 'Open a new terminal and run: claude'
info 'Then inside Claude Code, run: /setup'
