#!/bin/bash
set -euo pipefail

## === MODULE 02: Git Installation & Configuration ===

echo "🔧 Setting up Git..."

# Function to run commands as the target user
run_as_user() {
    if [[ $EUID -eq 0 ]]; then
        # Running as root, need to determine target user
        if [[ -n "${SETUP_USERNAME:-}" ]]; then
            sudo -u "$SETUP_USERNAME" "$@"
        else
            echo "❌ SETUP_USERNAME not set and running as root"
            exit 1
        fi
    else
        # Running as user
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

# Install git if not present
if ! command -v git &>/dev/null; then
    echo "📦 Installing Git..."
    
    # Check for required commands
    if ! command -v apt &>/dev/null; then
        echo "❌ apt command not found. This script requires Ubuntu/Debian."
        exit 1
    fi
    
    if [[ $EUID -eq 0 ]]; then
        apt update || { echo "❌ Failed to update package list"; exit 1; }
        apt install -y git || { echo "❌ Failed to install Git"; exit 1; }
    else
        sudo apt update || { echo "❌ Failed to update package list"; exit 1; }
        sudo apt install -y git || { echo "❌ Failed to install Git"; exit 1; }
    fi
    echo "✅ Git installed: $(git --version)"
else
    echo "✅ Git already installed: $(git --version)"
fi

# Get current user's home directory
USER_HOME=$(get_user_home)

# Check if git is already configured
CURRENT_USER=$(run_as_user git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(run_as_user git config --global user.email 2>/dev/null || echo "")

if [[ -n "$CURRENT_USER" && -n "$CURRENT_EMAIL" ]]; then
    echo "✅ Git already configured:"
    echo "   Name: $CURRENT_USER"
    echo "   Email: $CURRENT_EMAIL"
    
    if [[ -t 0 ]]; then
        read -rp "Do you want to reconfigure Git? [y/N]: " RECONFIGURE
    else
        RECONFIGURE="n"
        echo "Do you want to reconfigure Git? [y/N]: $RECONFIGURE (auto)"
    fi
    if [[ ! "$RECONFIGURE" =~ ^[Yy]$ ]]; then
        echo "✅ Keeping existing Git configuration"
        exit 0
    fi
fi

# Default values from existing minimal.sh
DEFAULT_NAME="Matt O'Neill"
DEFAULT_EMAIL="tmattoneill@gmail.com"

# Prompt for git configuration
echo "🔧 Git configuration setup:"

# Get name
if [[ -n "${GIT_USER_NAME:-}" ]]; then
    USER_NAME="$GIT_USER_NAME"
else
    if [[ -t 0 ]]; then
        read -rp "Enter your full name [$DEFAULT_NAME]: " USER_NAME
        USER_NAME=${USER_NAME:-$DEFAULT_NAME}
    else
        USER_NAME="$DEFAULT_NAME"
        echo "Enter your full name [$DEFAULT_NAME]: $USER_NAME (auto)"
    fi
fi

# Get email
if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    USER_EMAIL="$GIT_USER_EMAIL"
else
    if [[ -t 0 ]]; then
        read -rp "Enter your email [$DEFAULT_EMAIL]: " USER_EMAIL
        USER_EMAIL=${USER_EMAIL:-$DEFAULT_EMAIL}
    else
        USER_EMAIL="$DEFAULT_EMAIL"
        echo "Enter your email [$DEFAULT_EMAIL]: $USER_EMAIL (auto)"
    fi
    
    # Validate email format
    if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "❌ Invalid email format. Please enter a valid email address."
        exit 1
    fi
fi

# Configure git
echo "⚙️  Configuring Git..."
run_as_user git config --global user.name "$USER_NAME"
run_as_user git config --global user.email "$USER_EMAIL"

# Set up some sensible defaults
echo "🔧 Setting up Git defaults..."
run_as_user git config --global init.defaultBranch main
run_as_user git config --global pull.rebase true
run_as_user git config --global core.autocrlf input
run_as_user git config --global color.ui auto

# Set up a basic .gitignore_global
GITIGNORE_GLOBAL="$USER_HOME/.gitignore_global"
if [[ ! -f "$GITIGNORE_GLOBAL" ]]; then
    echo "📝 Creating global .gitignore..."
    run_as_user cat > "$GITIGNORE_GLOBAL" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs
*.log

# Temporary files
*.tmp
*.temp
EOF
    
    run_as_user git config --global core.excludesfile "$GITIGNORE_GLOBAL"
    echo "✅ Global .gitignore created and configured"
fi

# Verify configuration
echo ""
echo "✅ Git configuration complete!"
echo "📊 Git settings:"
echo "   Name: $(run_as_user git config --global user.name)"
echo "   Email: $(run_as_user git config --global user.email)"
echo "   Default branch: $(run_as_user git config --global init.defaultBranch)"
echo "   Global gitignore: $(run_as_user git config --global core.excludesfile)"
echo ""