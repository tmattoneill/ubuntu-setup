#!/bin/bash

set -e

echo "=== Cockpit One-Shot Installer ==="
echo "Target IP: 192.168.68.4 (adjust manually if needed)"
echo ""

# Step 1: Install Cockpit
echo "[+] Installing Cockpit and required packages..."
sudo apt update
sudo apt install -y cockpit openssl ufw

# Step 2: Enable Cockpit service
echo "[+] Enabling and starting Cockpit service..."
sudo systemctl enable --now cockpit.socket || { echo "❌ Failed to enable cockpit.socket"; exit 1; }

# Step 3: Open firewall
echo "[+] Allowing Cockpit port (9090) via UFW..."
sudo ufw allow 9090/tcp

# Step 4: Prompt for self-signed cert
read -rp "Do you want to install a self-signed certificate for Cockpit? [y/N]: " INSTALL_CERT

if [[ "$INSTALL_CERT" =~ ^[Yy]$ ]]; then
    echo "[+] Generating self-signed certificate for 192.168.68.4..."

    sudo openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout /etc/ssl/private/cockpit-selfsigned.key \
      -out /etc/ssl/certs/cockpit-selfsigned.crt \
      -subj "/CN=192.168.68.4"

    echo "[+] Installing self-signed certificate into Cockpit..."
    sudo mkdir -p /etc/cockpit/ws-certs.d/
    sudo cp /etc/ssl/certs/cockpit-selfsigned.crt /etc/cockpit/ws-certs.d/0-selfsigned.cert
    sudo cp /etc/ssl/private/cockpit-selfsigned.key /etc/cockpit/ws-certs.d/0-selfsigned.key
else
    echo "[i] Skipping self-signed cert setup. Make sure to use Certbot or your own cert later."
fi

# Step 5: Prompt to install cockpit-pcp
read -rp "Do you want to install 'cockpit-pcp' for advanced metrics? [y/N]: " INSTALL_PCP

if [[ "$INSTALL_PCP" =~ ^[Yy]$ ]]; then
    echo "[+] Installing Performance Co-Pilot (PCP)..."
    sudo apt install -y cockpit-pcp pcp
    sudo systemctl enable --now pmcd || echo "⚠️ Failed to enable pmcd, continuing without performance metrics"
fi

# Step 6: Prompt for Certbot setup (production domains only)
read -rp "Do you want to install Certbot (Let's Encrypt)? [y/N]: " INSTALL_CERTBOT

if [[ "$INSTALL_CERTBOT" =~ ^[Yy]$ ]]; then
    echo "[+] Installing Certbot (standalone mode)..."
    sudo apt install -y certbot

    echo ""
    echo "⚠️  IMPORTANT: You need a real domain name pointing to this server's IP."
    read -rp "Enter your domain name (e.g. cockpit.example.com): " DOMAIN

    echo "[+] Attempting standalone cert issuance..."
    sudo systemctl stop cockpit.socket
    sudo certbot certonly --standalone -d "$DOMAIN"
    sudo systemctl start cockpit.socket

    echo "[i] Certbot is done. You’ll need to manually point Cockpit to:"
    echo "    /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "    /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo ""
    echo "Edit: /etc/cockpit/ws-certs.d/0-letsencrypt.cert and .key"
    echo "Then: sudo systemctl restart cockpit || echo "⚠️ Failed to restart cockpit, may need manual restart""
fi

# Final restart
echo "[+] Restarting Cockpit service..."
sudo systemctl restart cockpit || echo "⚠️ Failed to restart cockpit, may need manual restart"

# Done
echo ""
echo "✅ Cockpit setup complete!"
echo "Visit: https://192.168.68.4:9090"
echo "Login using your system use
#!/bin/bash

set -e

echo "=== Cockpit One-Shot Installer ==="
echo "Target IP: 192.168.68.4 (adjust manually if needed)"
echo ""

# Step 1: Install Cockpit
echo "[+] Installing Cockpit and required packages..."
sudo apt update
sudo apt install -y cockpit openssl ufw

# Step 2: Enable Cockpit service
echo "[+] Enabling and starting Cockpit service..."
sudo systemctl enable --now cockpit.socket || { echo "❌ Failed to enable cockpit.socket"; exit 1; }

# Step 3: Open firewall
echo "[+] Allowing Cockpit port (9090) via UFW..."
sudo ufw allow 9090/tcp

# Step 4: Prompt for self-signed cert
read -rp "Do you want to install a self-signed certificate for Cockpit? [y/N]: " INSTALL_CERT

if [[ "$INSTALL_CERT" =~ ^[Yy]$ ]]; then
    echo "[+] Generating self-signed certificate for 192.168.68.4..."

    sudo openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout /etc/ssl/private/cockpit-selfsigned.key \
      -out /etc/ssl/certs/cockpit-selfsigned.crt \
      -subj "/CN=192.168.68.4"

    echo "[+] Installing self-signed certificate into Cockpit..."
    sudo mkdir -p /etc/cockpit/ws-certs.d/
    sudo cp /etc/ssl/certs/cockpit-selfsigned.crt /etc/cockpit/ws-certs.d/0-selfsigned.cert
    sudo cp /etc/ssl/private/cockpit-selfsigned.key /etc/cockpit/ws-certs.d/0-selfsigned.key
else
    echo "[i] Skipping self-signed cert setup. Make sure to use Certbot or your own cert later."
fi

# Step 5: Prompt to install cockpit-pcp
read -rp "Do you want to install 'cockpit-pcp' for advanced metrics? [y/N]: " INSTALL_PCP

if [[ "$INSTALL_PCP" =~ ^[Yy]$ ]]; then
    echo "[+] Installing Performance Co-Pilot (PCP)..."
    sudo apt install -y cockpit-pcp pcp
    sudo systemctl enable --now pmcd || echo "⚠️ Failed to enable pmcd, continuing without performance metrics"
fi

# Step 6: Prompt for Certbot setup (production domains only)
read -rp "Do you want to install Certbot (Let's Encrypt)? [y/N]: " INSTALL_CERTBOT

if [[ "$INSTALL_CERTBOT" =~ ^[Yy]$ ]]; then
    echo "[+] Installing Certbot (standalone mode)..."
    sudo apt install -y certbot

    echo ""
    echo "⚠️  IMPORTANT: You need a real domain name pointing to this server's IP."
    read -rp "Enter your domain name (e.g. cockpit.example.com): " DOMAIN

    echo "[+] Attempting standalone cert issuance..."
    sudo systemctl stop cockpit.socket
    sudo certbot certonly --standalone -d "$DOMAIN"
    sudo systemctl start cockpit.socket

    echo "[i] Certbot is done. You’ll need to manually point Cockpit to:"
    echo "    /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "    /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo ""
    echo "Edit: /etc/cockpit/ws-certs.d/0-letsencrypt.cert and .key"
    echo "Then: sudo systemctl restart cockpit || echo "⚠️ Failed to restart cockpit, may need manual restart""
fi

# Final restart
echo "[+] Restarting Cockpit service..."
sudo systemctl restart cockpit || echo "⚠️ Failed to restart cockpit, may need manual restart"

# Done
echo ""
echo "✅ Cockpit setup complete!"
echo "Visit: https://192.168.68.4:9090"
echo "Login using your system use
