#!/bin/bash
set -euo pipefail

## === MODULE 01: Prerequisites ===
echo "🔧 Updating system and installing base tools..."
apt update && apt upgrade -y
apt install -y build-essential curl git unzip software-properties-common zsh sudo gnupg lsb-release ca-certificates ufw fail2ban

## === MODULE 02: User Creation ===
echo "👤 Creating users: ubuntu, moneill, matt..."
for user in ubuntu moneill matt; do
    if ! id "$user" &>/dev/null; then
        adduser --disabled-password --gecos "" "$user"
        usermod -aG sudo "$user"
        mkdir -p /home/$user/.ssh
        cp ~/.ssh/authorized_keys /home/$user/.ssh/authorized_keys
        chown -R $user:$user /home/$user/.ssh
        chmod 700 /home/$user/.ssh
        chmod 600 /home/$user/.ssh/authorized_keys
        echo "✅ Created user: $user"
    else
        echo "⚠️ User $user already exists."
    fi
done
