#!/bin/bash
set -euo pipefail

## === MODULE 04: Node.js + NVM + npm (Zsh-safe, idempotent) ===

echo "📦 Installing NVM and latest Node.js LTS..."

# Function to run commands as the target user
run_as_user() {
    if [[ $EUID -eq 0 ]]; then
        # Running as root, need to determine target user
        if [[ -n "${SETUP_USERNAME:-}" ]]; then
            sudo -u "$SETUP_USERNAME" "$@"
        else
            echo "❌ SETUP_USERNAME not set and running as root"
            exit 1
        fi
    else
        # Running as user
        "$@"
    fi
}

get_user_home() {
    if [[ $EUID -eq 0 ]]; then
        if [[ -n "${SETUP_USERNAME:-}" ]]; then
            echo "/home/$SETUP_USERNAME"
        else
            echo "/root"
        fi
    else
        echo "${HOME:-/tmp}"
    fi
}

# Vars
USER_HOME=$(get_user_home)
export NVM_DIR="$USER_HOME/.nvm"
ZSHRC="$USER_HOME/.zshrc"

# Install NVM if missing
if [ ! -d "$NVM_DIR" ]; then
  echo "⬇️  Cloning NVM..."
  run_as_user bash -c 'curl --max-time 30 --retry 3 --retry-delay 2 -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
else
  echo "✅ NVM already installed at $NVM_DIR"
fi

# Ensure NVM loads in future zsh sessions
if ! run_as_user grep -q 'nvm.sh' "$ZSHRC" 2>/dev/null; then
  echo "🔧 Adding NVM init to $ZSHRC..."
  run_as_user bash -c 'cat >> '"$ZSHRC"' << '\''EOF'\''

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF'
fi

# Load NVM and install Node as target user
if ! run_as_user command -v node &>/dev/null; then
  echo "📦 Installing Node.js LTS..."
  run_as_user bash -c '
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default "lts/*" || true
  '
else
  echo "✅ Node.js already installed: $(run_as_user node -v 2>/dev/null || echo 'version check failed')"
fi

# Confirm installation
echo "✅ Node version: $(run_as_user bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; node -v' 2>/dev/null || echo 'not available')"
echo "✅ npm version: $(run_as_user bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; npm -v' 2>/dev/null || echo 'not available')"
