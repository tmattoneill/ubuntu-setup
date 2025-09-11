#!/bin/bash
set -euo pipefail

## === MODULE 04: Node.js + NVM + npm (Zsh-safe, idempotent) ===

echo "📦 Installing NVM and latest Node.js LTS..."

# Vars
export NVM_DIR="${HOME:-/tmp}/.nvm"
ZSHRC="${HOME:-/tmp}/.zshrc"

# Install NVM if missing
if [ ! -d "$NVM_DIR" ]; then
  echo "⬇️  Cloning NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  echo "✅ NVM already installed at $NVM_DIR"
fi

# Ensure NVM loads in future zsh sessions
if ! grep -q 'nvm.sh' "$ZSHRC"; then
  echo "🔧 Adding NVM init to $ZSHRC..."
  {
    echo ''
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
  } >> "$ZSHRC"
fi

# Load NVM into current session (disable strict mode temporarily for NVM)
# shellcheck disable=SC1090
set +u  # Temporarily disable unbound variable checking for NVM
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
set -u  # Re-enable unbound variable checking

# Install + use latest LTS Node
if ! command -v node &>/dev/null; then
  echo "📦 Installing Node.js LTS..."
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*' || true
else
  echo "✅ Node.js already installed: $(node -v)"
fi

# Confirm
echo "✅ Node version: $(node -v)"
echo "✅ npm version: $(npm -v)"
