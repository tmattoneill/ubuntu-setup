#!/bin/bash
set -euo pipefail

## === MODULE 03: Zsh + Oh My Zsh ===

echo "🐚 Installing Zsh and Oh My Zsh..."

# Install Zsh if needed
if ! command -v zsh &>/dev/null; then
  sudo apt install -y zsh
fi

# Set Zsh as default shell for current user
sudo usermod -s /usr/bin/zsh "$USER"

# Install Oh My Zsh
export RUNZSH=no
export CHSH=no
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "📦 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ Oh My Zsh already installed."
fi

# Install plugins
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Patch .zshrc
sed -i 's/plugins=(git)/plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo "✅ Zs
