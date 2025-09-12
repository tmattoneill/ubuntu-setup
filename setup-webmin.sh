#!/bin/bash

set -e

echo "=== Webmin One-Shot Installer ==="
echo "Target IP: 192.168.68.4 (adjust manually if needed)"
echo ""

# Step 1: Add Webmin repo + key
echo "[+] Adding Webmin repository and key..."
sudo apt update
sudo apt install -y software-properties-common apt-transport-https curl gnupg2

# Remove any existing webmin repository and keys first
sudo rm -f /etc/apt/sources.list.d/webmin.list
sudo rm -f /usr/share/keyrings/webmin.gpg

# Use the modern keyring method
echo "[+] Adding Webmin GPG key to keyring..."
curl -fsSL https://download.webmin.com/jcameron-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/webmin.gpg
echo "deb [signed-by=/usr/share/keyrings/webmin.gpg] https://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list

# Step 2: Install Webmin
echo "[+] Installing Webmin..."
sudo apt update
sudo apt install -y webmin

# Step 3: Open firewall
echo "[+] Allowing Webmin port (10000) via UFW..."
sudo ufw allow 10000/tcp

# Step 4: Prompt for self-signed cert
read -rp "Do you want to install a self-signed certificate for Webmin? [y/N]: " INSTALL_CERT

if [[ "$INSTALL_CERT" =~ ^[Yy]$ ]]; then
    echo "[+] Generating self-signed certificate for 192.168.68.4..."

    sudo openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout /etc/webmin/miniserv.key \
      -out /etc/webmin/miniserv.cert \
      -subj "/CN=192.168.68.4"

    echo "[+] Self-signed certificate installed."
else
    echo "[i] Skipping self-signed cert setup. Webmin will use its default self-signed cert (also untrusted)."
fi

# Step 5: Prompt for Certbot setup
read -rp "Do you want to install Certbot (Let's Encrypt)? [y/N]: " INSTALL_CERTBOT

if [[ "$INSTALL_CERTBOT" =~ ^[Yy]$ ]]; then
    echo "[+] Installing Certbot (standalone mode)..."
    sudo apt install -y certbot

    echo ""
    echo "⚠️  IMPORTANT: You need a real domain name pointing to this server's IP."
    read -rp "Enter your domain name (e.g. webmin.example.com): " DOMAIN

    echo "[+] Attempting standalone cert issuance..."
    sudo systemctl stop webmin
    sudo certbot certonly --standalone -d "$DOMAIN"
    sudo systemctl start webmin

    echo "[i] Certbot complete. To use the new cert:"
    echo "    Edit: /etc/webmin/miniserv.conf"
    echo "    Replace certfile= and keyfile= with:"
    echo "      /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "      /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo "    Then run: sudo systemctl restart webmin"
fi

# Step 6: Restart Webmin
echo "[+] Restarting Webmin service..."
sudo systemctl restart webmin

# Done
echo ""
echo "✅ Webmin setup complete!"
echo "Visit: https://192.168.68.4:10000"
echo "Login using your system user (e.g. 'ubuntu')."

if [[ "$INSTALL_CERT" =~ ^[Yy]$ ]]; then
    echo "⚠️  Self-signed cert installed — browser will warn. Click 'Advanced' → 'Accept Risk'."
elif [[ "$INSTALL_CERTBOT" =~ ^[Yy]$ ]]; then
    echo "✅ Let's Encrypt cert acquired — configure it in miniserv.conf to apply."
else
    echo "ℹ️  Webmin is using default TLS cert — not trusted."
fi
