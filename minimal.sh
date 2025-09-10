#!/bin/bash
set -euo pipefail

# --- VARIABLES ---
USERNAME="webdev"
FULLNAME="Matt O'Neill"
EMAIL="tmattoneill@gmail.com"

# --- CREATE USER ---
if ! id -u "$USERNAME" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$USERNAME"
  usermod -aG sudo,www-data "$USERNAME"
  chsh -s /usr/bin/zsh "$USERNAME"
fi

# --- BASIC PACKAGES ---
apt update && apt upgrade -y
apt install -y \
  zsh git curl wget build-essential \
  net-tools python3 python3-pip python3-venv \
  nginx unzip

# --- GIT CONFIG ---
sudo -u "$USERNAME" git config --global user.name "$FULLNAME"
sudo -u "$USERNAME" git config --global user.email "$EMAIL"

# --- OH MY ZSH + POWERLEVEL10K ---
sudo -u "$USERNAME" sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k
sudo -u "$USERNAME" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "/home/$USERNAME/.oh-my-zsh/custom/themes/powerlevel10k"
sudo -u "$USERNAME" sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "/home/$USERNAME/.zshrc"

# --- NVM + NODE + NPM ---
sudo -u "$USERNAME" bash <<'EOF'
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
EOF

# --- PYENV ---
sudo -u "$USERNAME" bash <<'EOF'
curl https://pyenv.run | bash
cat <<'EOT' >> ~/.zshrc

# Pyenv
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOT
EOF

# --- FINISHED ---
echo "Setup complete! Now 'su - $USERNAME' or SSH in as $USERNAME."
