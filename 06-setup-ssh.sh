#!/bin/bash
set -euo pipefail

## === MODULE: SSH Key & Configuration Setup ===

echo "🔐 Setting up SSH keys and configuration..."

# Function to run commands as the target user
run_as_user() {
    if [[ $EUID -eq 0 ]]; then
        if [[ -n "${SETUP_USERNAME:-}" ]]; then
            sudo -u "$SETUP_USERNAME" "$@"
        else
            echo "❌ SETUP_USERNAME not set and running as root"
            exit 1
        fi
    else
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

USER_HOME=$(get_user_home)
SSH_DIR="$USER_HOME/.ssh"

# Create SSH directory with proper permissions
echo "📁 Setting up SSH directory..."
run_as_user mkdir -p "$SSH_DIR"
run_as_user chmod 700 "$SSH_DIR"

# Setup authorized_keys for server access
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
echo ""
echo "🔑 SSH Server Setup (for remote access to this server):"
echo "This allows you to SSH into this server using your public key."
echo ""

if [[ -f "$AUTHORIZED_KEYS" ]]; then
    echo "✅ authorized_keys file already exists"
    echo "Current authorized keys:"
    run_as_user cat "$AUTHORIZED_KEYS" | while read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            KEY_COMMENT=$(echo "$line" | cut -d' ' -f3- 2>/dev/null || echo "unnamed key")
            echo "   $KEY_COMMENT"
        fi
    done
    echo ""
    if [[ -t 0 ]]; then
        read -rp "Do you want to add another SSH public key? [y/N]: " ADD_KEY
    else
        ADD_KEY="n"
        echo "Do you want to add another SSH public key? [y/N]: $ADD_KEY (auto)"
    fi
else
    echo "No authorized_keys file found."
    if [[ -t 0 ]]; then
        read -rp "Do you want to add an SSH public key for remote access? [Y/n]: " ADD_KEY
        ADD_KEY=${ADD_KEY:-y}
    else
        ADD_KEY="n"
        echo "Do you want to add an SSH public key for remote access? [Y/n]: $ADD_KEY (auto)"
    fi
fi

if [[ "$ADD_KEY" =~ ^[Yy]$ ]]; then
    echo ""
    if [[ -t 0 ]]; then
        echo "📝 Please paste your SSH public key (the content of your id_rsa.pub file):"
        echo "   It should start with 'ssh-rsa', 'ssh-ed25519', etc."
        echo "   Press Enter when done, or Ctrl+C to skip:"
        echo ""
        
        read -r PUBLIC_KEY
    else
        PUBLIC_KEY=""
        echo "📝 SSH public key input skipped in automatic mode"
    fi
    
    if [[ -n "$PUBLIC_KEY" ]]; then
        # Validate the public key format
        if [[ "$PUBLIC_KEY" =~ ^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-) ]]; then
            echo "✅ Valid SSH public key format detected"
            
            # Add to authorized_keys
            run_as_user touch "$AUTHORIZED_KEYS"
            echo "$PUBLIC_KEY" | run_as_user tee -a "$AUTHORIZED_KEYS" > /dev/null
            run_as_user chmod 600 "$AUTHORIZED_KEYS"
            
            echo "✅ SSH public key added to authorized_keys"
        else
            echo "❌ Invalid SSH public key format. Skipping..."
        fi
    else
        echo "ℹ️  No key provided, skipping authorized_keys setup"
    fi
fi

# Setup client SSH keys (for outgoing connections)
echo ""
echo "🔐 SSH Client Setup (for connecting to other servers/GitHub):"

CLIENT_PRIVATE_KEY="$SSH_DIR/id_rsa"
CLIENT_PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

if [[ -f "$CLIENT_PRIVATE_KEY" ]]; then
    echo "✅ SSH client key already exists: $CLIENT_PRIVATE_KEY"
    if [[ -t 0 ]]; then
        read -rp "Do you want to replace it with a new key? [y/N]: " REPLACE_KEY
    else
        REPLACE_KEY="n"
        echo "Do you want to replace it with a new key? [y/N]: $REPLACE_KEY (auto)"
    fi
else
    echo "No SSH client key found."
    if [[ -t 0 ]]; then
        read -rp "Do you want to generate a new SSH key pair for this user? [Y/n]: " REPLACE_KEY
        REPLACE_KEY=${REPLACE_KEY:-y}
    else
        REPLACE_KEY="y"
        echo "Do you want to generate a new SSH key pair for this user? [Y/n]: $REPLACE_KEY (auto)"
    fi
fi

if [[ "$REPLACE_KEY" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔧 SSH Key Generation Options:"
    echo "1. Generate new key pair automatically"
    echo "2. Paste existing private key"
    echo "3. Skip client key setup"
    echo ""
    if [[ -t 0 ]]; then
        read -rp "Choose option [1-3]: " KEY_OPTION
    else
        KEY_OPTION="1"
        echo "Choose option [1-3]: $KEY_OPTION (auto - generate)"
    fi
    
    case $KEY_OPTION in
        1)
            # Generate new key pair
            if [[ -t 0 ]]; then
                read -rp "Enter email for key comment [$(run_as_user git config --global user.email 2>/dev/null || echo "user@$(hostname)")]: " KEY_EMAIL
            else
                KEY_EMAIL=$(run_as_user git config --global user.email 2>/dev/null || echo "user@$(hostname)")
                echo "Enter email for key comment: $KEY_EMAIL (auto)"
            fi
            KEY_EMAIL=${KEY_EMAIL:-$(run_as_user git config --global user.email 2>/dev/null || echo "user@$(hostname)")}
            
            echo "🔑 Generating new SSH key pair..."
            run_as_user ssh-keygen -t rsa -b 4096 -C "$KEY_EMAIL" -f "$CLIENT_PRIVATE_KEY" -N ""
            echo "✅ New SSH key pair generated"
            
            echo ""
            echo "📋 Your new public key (add this to GitHub/GitLab):"
            echo "================================================================"
            run_as_user cat "$CLIENT_PUBLIC_KEY"
            echo "================================================================"
            ;;
        2)
            # Import existing private key
            echo ""
            echo "📝 Paste your private SSH key (including -----BEGIN OPENSSH PRIVATE KEY----- header):"
            echo "Press Enter on empty line when done, or Ctrl+C to skip:"
            echo ""
            
            PRIVATE_KEY_CONTENT=""
            while IFS= read -r line; do
                if [[ -z "$line" ]]; then
                    break
                fi
                PRIVATE_KEY_CONTENT+="$line"$'\n'
            done
            
            if [[ -n "$PRIVATE_KEY_CONTENT" ]]; then
                echo "$PRIVATE_KEY_CONTENT" | run_as_user tee "$CLIENT_PRIVATE_KEY" > /dev/null
                run_as_user chmod 600 "$CLIENT_PRIVATE_KEY"
                
                # Generate public key from private key
                if run_as_user ssh-keygen -y -f "$CLIENT_PRIVATE_KEY" > /tmp/temp_pubkey 2>/dev/null; then
                    run_as_user mv /tmp/temp_pubkey "$CLIENT_PUBLIC_KEY"
                    run_as_user chmod 644 "$CLIENT_PUBLIC_KEY"
                    echo "✅ SSH private key imported and public key generated"
                else
                    echo "❌ Invalid private key format"
                    run_as_user rm -f "$CLIENT_PRIVATE_KEY"
                fi
            else
                echo "ℹ️  No key provided, skipping client key setup"
            fi
            ;;
        3)
            echo "ℹ️  Skipping client key setup"
            ;;
        *)
            echo "ℹ️  Invalid option, skipping client key setup"
            ;;
    esac
fi

# Create SSH config file with useful defaults
SSH_CONFIG="$SSH_DIR/config"
if [[ ! -f "$SSH_CONFIG" ]]; then
    echo "⚙️  Creating SSH config with useful defaults..."
    run_as_user cat > "$SSH_CONFIG" << 'EOF'
# SSH Client Configuration

# Default settings for all hosts
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
    
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    
# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_rsa

# Example server entry (uncomment and modify as needed)
# Host myserver
#     HostName your-server.com
#     User your-username
#     Port 22
#     IdentityFile ~/.ssh/id_rsa
EOF
    
    run_as_user chmod 600 "$SSH_CONFIG"
    echo "✅ SSH config created with useful defaults"
else
    echo "✅ SSH config already exists"
fi

# Test SSH client key if it exists
if [[ -f "$CLIENT_PRIVATE_KEY" ]]; then
    echo ""
    echo "🧪 Testing SSH key..."
    
    # Test GitHub connection
    if run_as_user ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ GitHub SSH connection successful"
    else
        echo "ℹ️  GitHub SSH test inconclusive (key may not be added to GitHub yet)"
    fi
fi

# Ensure SSH service is running and configured
if command -v systemctl &>/dev/null; then
    echo "🔧 Checking SSH service configuration..."
    
    # Check if SSH service is running
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        echo "✅ SSH service is running"
    else
        echo "⚠️  SSH service is not running"
        if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
            if [[ -t 0 ]]; then
                read -rp "Do you want to start the SSH service? [Y/n]: " START_SSH
            else
                START_SSH="y"
                echo "Do you want to start the SSH service? [Y/n]: $START_SSH (auto)"
            fi
            START_SSH=${START_SSH:-y}
            if [[ "$START_SSH" =~ ^[Yy]$ ]]; then
                if [[ $EUID -eq 0 ]]; then
                    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null
                    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null
                else
                    sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null
                    sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null
                fi
                
                # Verify SSH service is running
                sleep 2
                if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
                    echo "✅ SSH service started and enabled"
                else
                    echo "⚠️ SSH service may not be running properly"
                fi
            fi
        fi
    fi
fi

echo ""
echo "✅ SSH setup complete!"
echo "📊 Configuration summary:"
echo "   SSH directory: $SSH_DIR"
if [[ -f "$AUTHORIZED_KEYS" ]]; then
    KEY_COUNT=$(run_as_user wc -l < "$AUTHORIZED_KEYS" 2>/dev/null || echo "0")
    echo "   Authorized keys: $KEY_COUNT"
fi
if [[ -f "$CLIENT_PRIVATE_KEY" ]]; then
    echo "   Client key: ✅ Present"
    echo "   Public key: $CLIENT_PUBLIC_KEY"
else
    echo "   Client key: ❌ Not configured"
fi
echo "   SSH config: $([ -f "$SSH_CONFIG" ] && echo "✅ Present" || echo "❌ Not found")"
echo ""
echo "💡 Next steps:"
echo "   1. Add your public key to GitHub/GitLab if you haven't already"
echo "   2. Test SSH connection: ssh -T git@github.com"
echo "   3. Configure additional hosts in $SSH_CONFIG as needed"
echo ""
