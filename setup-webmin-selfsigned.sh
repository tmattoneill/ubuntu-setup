#!/bin/bash

set -e

echo "[+] Generating self-signed cert for Webmin (CN: 192.168.68.4)..."

sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/webmin/miniserv.key \
  -out /etc/webmin/miniserv.cert \
  -subj "/CN=192.168.68.4"

echo "[+] Restarting Webmin to apply cert..."

sudo systemctl restart webmin

echo "[✓] Done. Access Webmin at: https://192.168.68.4:10000"
echo "    Browser will still warn, but it's your signed cert now."
