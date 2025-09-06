#!/bin/bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "[+] Pasting private key into ~/.ssh/id_rsa..."
# Insert method to securely import here (e.g. from 1Password CLI, env var, or manual paste)
chmod 600 ~/.ssh/id_rsa

echo "[+] Pasting public key into ~/.ssh/id_rsa.pub..."
chmod 644 ~/.ssh/id_rsa.pub

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

echo "[✓] SSH key added and ready to use with GitHub."
