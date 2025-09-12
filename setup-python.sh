#!/bin/bash
set -euo pipefail

echo "🐍 Installing Python 3.11, pip, pyenv, and development tools..."

## === SYSTEM DEPS ===
echo "📦 Installing system packages and build dependencies..."

# Check for problematic repositories and handle gracefully
echo "🔍 Checking for repository issues..."
if sudo apt update 2>&1 | grep -q "webmin"; then
    echo "⚠️  Detected Webmin repository issue. Temporarily disabling..."
    sudo mv /etc/apt/sources.list.d/webmin.list /etc/apt/sources.list.d/webmin.list.disabled 2>/dev/null || true
    sudo apt update
else
    echo "✅ Repository update successful"
fi
sudo apt install -y \
  software-properties-common curl build-essential \
  zlib1g-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
  llvm libncurses-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
  libffi-dev liblzma-dev git

## === PYTHON 3.11 via apt ===
echo "🐍 Installing Python 3.11 via apt..."
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-distutils

# Install pip for Python 3.11
echo "📦 Installing pip for Python 3.11..."
curl --max-time 30 --retry 3 --retry-delay 2 -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Ensure ~/.local/bin is in PATH
ZSHRC="${HOME:-/tmp}/.zshrc"
if ! grep -q '.local/bin' "$ZSHRC"; then
  echo '🔧 Adding ~/.local/bin to PATH in ~/.zshrc'
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
  export PATH="${HOME:-/tmp}/.local/bin:$PATH"
fi

# Symlink python to python3.11 for compatibility (optional)
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

echo "✅ Python version: $(python --version)"
echo "✅ pip version: $(pip --version)"

## === PYENV INSTALL ===
if [ ! -d "${HOME:-/tmp}/.pyenv" ]; then
  echo "📥 Installing pyenv..."
  curl --max-time 60 --retry 3 --retry-delay 2 https://pyenv.run | bash
else
  echo "✅ pyenv already installed."
fi

# Add pyenv to shell startup if missing
if ! grep -q 'pyenv init' "$ZSHRC"; then
  echo '🔧 Adding pyenv config to ~/.zshrc...'
  cat <<'EOF' >> "$ZSHRC"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOF
fi

# Load pyenv immediately (disable strict mode temporarily for pyenv)
export PYENV_ROOT="${HOME:-/tmp}/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
set +u  # Temporarily disable unbound variable checking for pyenv
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
set -u  # Re-enable unbound variable checking

# Install Python via pyenv
PYENV_PYTHON="3.11.9"
if ! pyenv versions | grep -q "$PYENV_PYTHON"; then
  echo "🐍 Installing Python $PYENV_PYTHON via pyenv..."
  pyenv install "$PYENV_PYTHON"
else
  echo "✅ Python $PYENV_PYTHON already installed via pyenv"
fi

pyenv global "$PYENV_PYTHON"
echo "✅ pyenv version: $(pyenv --version)"
echo "✅ current Python: $(python --version)"

## === OPTIONAL: Virtualenv + pipx ===
echo "📦 Installing virtualenv and pipx..."
pip install --user virtualenv pipx
pipx ensurepath

echo "✅ Python dev environment is ready."
echo "💡 Restart your shell or run 'exec zsh' to activate pyenv."
