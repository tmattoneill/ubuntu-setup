#!/bin/bash
set -euo pipefail

echo "🐍 Installing Python 3.11, pip, pyenv, and development tools..."

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

## === SYSTEM DEPS ===
echo "📦 Installing system packages and build dependencies..."
sudo apt update
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
run_as_user bash -c 'curl --max-time 30 --retry 3 --retry-delay 2 -sS https://bootstrap.pypa.io/get-pip.py | python3.11'

# Get user's home directory and zshrc
USER_HOME=$(get_user_home)
ZSHRC="$USER_HOME/.zshrc"
if ! grep -q '.local/bin' "$ZSHRC" 2>/dev/null; then
  echo '🔧 Adding ~/.local/bin to PATH in ~/.zshrc'
  run_as_user bash -c 'echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> '"$ZSHRC"
fi

# Symlink python to python3.11 for compatibility (optional)
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

echo "✅ Python version: $(python --version)"
echo "✅ pip version: $(run_as_user pip --version)"

## === PYENV INSTALL ===
if [ ! -d "$USER_HOME/.pyenv" ]; then
  echo "📥 Installing pyenv..."
  run_as_user bash -c 'curl --max-time 60 --retry 3 --retry-delay 2 https://pyenv.run | bash'
else
  echo "✅ pyenv already installed."
fi

# Add pyenv to shell startup if missing
if ! grep -q 'pyenv init' "$ZSHRC" 2>/dev/null; then
  echo '🔧 Adding pyenv config to ~/.zshrc...'
  run_as_user bash -c 'cat <<'\''EOF'\'' >> '"$ZSHRC"'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOF
fi

# Install Python via pyenv
PYENV_PYTHON="3.11.9"
if ! run_as_user bash -c 'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; pyenv versions' | grep -q "$PYENV_PYTHON"; then
  echo "🐍 Installing Python $PYENV_PYTHON via pyenv..."
  run_as_user bash -c 'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; pyenv install '"$PYENV_PYTHON"
else
  echo "✅ Python $PYENV_PYTHON already installed via pyenv"
fi

run_as_user bash -c 'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; pyenv global '"$PYENV_PYTHON"
echo "✅ pyenv version: $(run_as_user bash -c 'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; pyenv --version')"

## === OPTIONAL: Virtualenv + pipx ===
echo "📦 Installing virtualenv and pipx..."
run_as_user pip install --user virtualenv pipx
run_as_user pipx ensurepath

echo "✅ Python dev environment is ready."
echo "💡 Restart your shell or run 'exec zsh' to activate pyenv."
