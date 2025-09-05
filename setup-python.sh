#!/bin/bash
set -euo pipefail

echo "🐍 Installing Python 3.11+, pip, pyenv, and virtualenv tools..."

## === SYSTEM DEPS ===
echo "📦 Installing system packages and build dependencies..."
sudo apt update
sudo apt install -y \
    software-properties-common curl build-essential \
    zlib1g-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
    llvm libncurses-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev git

## === PYENV INSTALL ===
if ! command -v pyenv &>/dev/null; then
  echo "📥 Installing pyenv..."
  curl https://pyenv.run | bash
else
  echo "✅ pyenv already installed."
fi

# Add pyenv to shell startup (zsh assumed)
if ! grep -q 'pyenv init' ~/.zshrc; then
  echo '🔧 Adding pyenv config to ~/.zshrc...'
  cat <<'EOF' >> ~/.zshrc

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOF
fi

# Load pyenv immediately
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

## === PYTHON INSTALL ===
PYTHON_VERSION="3.11.9"

if ! pyenv versions | grep -q "${PYTHON_VERSION}"; then
  echo "🐍 Installing Python ${PYTHON_VERSION} via pyenv..."
  pyenv install "${PYTHON_VERSION}"
fi

echo "📎 Setting Python ${PYTHON_VERSION} as global default..."
pyenv global "${PYTHON_VERSION}"

## === PIP + VIRTUALENV / PIPX ===
echo "📦 Installing pip, virtualenv, and pipx..."
pip install --upgrade pip
pip install virtualenv pipx
pipx ensurepath

echo "✅ Python environment setup complete."
echo "💡 You may need to restart your terminal or run 'exec zsh' for pyenv to be active."
