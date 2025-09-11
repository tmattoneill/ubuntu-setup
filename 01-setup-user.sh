#!/bin/bash
set -euo pipefail

## === MODULE 01: User Creation & Configuration ===

echo "👤 Setting up main user account..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Default values
DEFAULT_USERNAME="webdev"
DEFAULT_FULLNAME="Web Developer"
DEFAULT_SHELL="/usr/bin/zsh"

# Prompt for username if not provided via environment variable
if [[ -z "${SETUP_USERNAME:-}" ]]; then
    echo "👤 User account setup:"
    read -rp "Enter username [$DEFAULT_USERNAME]: " SETUP_USERNAME
    SETUP_USERNAME=${SETUP_USERNAME:-$DEFAULT_USERNAME}
fi

# Prompt for full name
if [[ -z "${SETUP_FULLNAME:-}" ]]; then
    read -rp "Enter full name [$DEFAULT_FULLNAME]: " SETUP_FULLNAME
    SETUP_FULLNAME=${SETUP_FULLNAME:-$DEFAULT_FULLNAME}
fi

# Check if user already exists
if id "$SETUP_USERNAME" &>/dev/null; then
    echo "✅ User '$SETUP_USERNAME' already exists"
    
    # Check if user is in sudo group
    if groups "$SETUP_USERNAME" | grep -q sudo; then
        echo "✅ User '$SETUP_USERNAME' already has sudo access"
    else
        echo "🔑 Adding sudo access to existing user..."
        usermod -aG sudo "$SETUP_USERNAME"
        echo "✅ Sudo access granted to '$SETUP_USERNAME'"
    fi
    
    # Check current shell
    CURRENT_SHELL=$(getent passwd "$SETUP_USERNAME" 2>/dev/null | cut -d: -f7 || echo "/bin/bash")
    if [[ "$CURRENT_SHELL" == "$DEFAULT_SHELL" ]]; then
        echo "✅ User shell already set to zsh"
    else
        echo "🐚 Setting shell to zsh..."
        # Install zsh if not present
        if ! command -v zsh &>/dev/null; then
            apt update || { echo "❌ apt update failed"; exit 1; }
            apt install -y zsh || { echo "❌ Failed to install zsh"; exit 1; }
        fi
        chsh -s "$DEFAULT_SHELL" "$SETUP_USERNAME"
        echo "✅ Shell changed to zsh for '$SETUP_USERNAME'"
    fi
else
    echo "👤 Creating new user '$SETUP_USERNAME'..."
    
    # Install zsh if not present
    if ! command -v zsh &>/dev/null; then
        echo "🐚 Installing zsh..."
        apt update
        apt install -y zsh
    fi
    
    # Create user with home directory
    useradd -m -s "$DEFAULT_SHELL" -c "$SETUP_FULLNAME" "$SETUP_USERNAME"
    
    # Add to sudo and www-data groups
    usermod -aG sudo,www-data "$SETUP_USERNAME"
    
    echo "✅ User '$SETUP_USERNAME' created successfully"
    echo "🔑 User added to sudo and www-data groups"
fi

# Set up basic directory structure
USER_HOME="/home/$SETUP_USERNAME"

echo "📁 Setting up user directories..."
sudo -u "$SETUP_USERNAME" mkdir -p "$USER_HOME"/{bin,projects,backups,.local/bin}

# Ensure proper ownership
chown -R "$SETUP_USERNAME:$SETUP_USERNAME" "$USER_HOME"

# Set up sudo without password for initial setup (will be removed later)
SUDOERS_FILE="/etc/sudoers.d/setup-$SETUP_USERNAME"
if [[ ! -f "$SUDOERS_FILE" ]]; then
    echo "🔓 Temporarily enabling passwordless sudo for setup..."
    echo "$SETUP_USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo "⚠️  Note: Passwordless sudo is temporary and will be removed after setup"
fi

# Create basic .profile if it doesn't exist
PROFILE_FILE="$USER_HOME/.profile"
if [[ ! -f "$PROFILE_FILE" ]]; then
    sudo -u "$SETUP_USERNAME" cat > "$PROFILE_FILE" << 'EOF'
# ~/.profile: executed by the command interpreter for login shells.

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF
    echo "✅ Created basic .profile for $SETUP_USERNAME"
fi

# Display user information
echo ""
echo "✅ User setup complete!"
echo "📊 User details:"
echo "   Username: $SETUP_USERNAME"
echo "   Full name: $SETUP_FULLNAME"
echo "   Home: $USER_HOME"
echo "   Shell: $(getent passwd "$SETUP_USERNAME" 2>/dev/null | cut -d: -f7 || echo "unknown")"
echo "   Groups: $(groups "$SETUP_USERNAME" | cut -d: -f2)"
echo ""
echo "🔄 Remaining setup scripts will run as '$SETUP_USERNAME' with sudo privileges"
echo ""