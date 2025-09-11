#!/bin/bash
set -euo pipefail

## === MODULE 00: System Update & Basic Packages ===

echo "🔄 Starting system update and basic package installation..."

# Check if we have required privileges
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
   echo "❌ This script requires root privileges. Please run with sudo or ensure passwordless sudo is configured."
   exit 1
fi

# Define command wrapper for privilege elevation
run_cmd() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Test if system is already updated recently (check if apt update was run in last 6 hours)
LAST_UPDATE=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s 2>/dev/null || echo "0")
SIX_HOURS=21600

if [[ $((CURRENT_TIME - LAST_UPDATE)) -lt $SIX_HOURS ]]; then
    echo "✅ System was updated recently (within 6 hours). Skipping update."
else
    # Check network connectivity first
    if ! curl -s --max-time 5 --head http://archive.ubuntu.com >/dev/null 2>&1; then
        echo "❌ Cannot reach Ubuntu repositories. Please check your internet connection."
        exit 1
    fi
    
    echo "📦 Updating package lists..."
    run_cmd apt update || { echo "❌ apt update failed"; exit 1; }

    echo "⬆️ Upgrading system packages..."
    run_cmd apt upgrade -y || { echo "❌ apt upgrade failed"; exit 1; }

    echo "🧹 Cleaning up package cache..."
    run_cmd apt autoremove -y || echo "⚠️ apt autoremove failed, continuing..."
    run_cmd apt autoclean || echo "⚠️ apt autoclean failed, continuing..."
fi

# Install essential packages if not already present
ESSENTIAL_PACKAGES="curl wget ca-certificates gnupg lsb-release software-properties-common apt-transport-https build-essential"

echo "📦 Installing essential packages..."
for package in $ESSENTIAL_PACKAGES; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "   Installing $package..."
        run_cmd apt install -y "$package" || { echo "❌ Failed to install $package"; exit 1; }
    else
        echo "   ✅ $package already installed"
    fi
done

# Configure timezone if not already set to a specific timezone
CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Etc/UTC")
if [[ "$CURRENT_TZ" == "Etc/UTC" ]]; then
    echo "🕐 Current timezone is UTC. Would you like to set a different timezone?"
    read -rp "Enter timezone (e.g., America/New_York) or press Enter to keep UTC: " NEW_TIMEZONE
    
    if [[ -n "$NEW_TIMEZONE" ]]; then
        # Validate timezone format
        if [[ ! "$NEW_TIMEZONE" =~ ^[A-Za-z_]+(/[A-Za-z_]+)*$ ]]; then
            echo "❌ Invalid timezone format. Use format like 'America/New_York' or 'Europe/London'"
            exit 1
        fi
        
        if run_cmd timedatectl set-timezone "$NEW_TIMEZONE" 2>/dev/null; then
            echo "✅ Timezone set to $NEW_TIMEZONE"
        else
            echo "⚠️  Invalid timezone '$NEW_TIMEZONE', keeping UTC"
        fi
    else
        echo "✅ Keeping UTC timezone"
    fi
else
    echo "✅ Timezone already configured: $CURRENT_TZ"
fi

# Enable unattended security updates
echo "🔒 Configuring automatic security updates..."
if ! dpkg -l | grep -q "^ii  unattended-upgrades "; then
    run_cmd apt install -y unattended-upgrades || { echo "❌ Failed to install unattended-upgrades"; exit 1; }
    echo 'Unattended-Upgrade::Automatic-Reboot "false";' | run_cmd tee /etc/apt/apt.conf.d/50unattended-upgrades-custom >/dev/null || { echo "❌ Failed to configure unattended-upgrades"; exit 1; }
    run_cmd dpkg-reconfigure -f noninteractive unattended-upgrades
    echo "✅ Automatic security updates enabled"
else
    echo "✅ Unattended upgrades already configured"
fi

# Configure firewall basics
echo "🔥 Configuring UFW firewall..."
if ! command -v ufw &>/dev/null; then
    run_cmd apt install -y ufw || { echo "❌ Failed to install ufw"; exit 1; }
fi

if run_cmd ufw status | grep -q "Status: inactive"; then
    # Allow SSH before enabling firewall
    run_cmd ufw allow ssh
    echo "y" | run_cmd ufw enable
    echo "✅ UFW firewall enabled with SSH access"
else
    echo "✅ UFW firewall already active"
fi

echo ""
echo "✅ System update and basic configuration complete!"
echo "📊 System info:"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   Kernel: $(uname -r)"
echo "   Timezone: $(timedatectl show --property=Timezone --value)"
echo "   UFW Status: $(ufw status | head -1)"
echo ""