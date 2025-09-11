#!/bin/bash
set -euo pipefail

## === MODULE: Zsh + Oh My Zsh + Powerlevel10k Setup ===

echo "🐚 Setting up Zsh shell environment..."

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

# Function to run commands with proper privileges
run_cmd() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

get_user_home() {
    if [[ $EUID -eq 0 ]]; then
        echo "/home/${SETUP_USERNAME:-}"
    else
        echo "$HOME"
    fi
}

get_target_user() {
    if [[ $EUID -eq 0 ]]; then
        echo "${SETUP_USERNAME:-}"
    else
        echo "$USER"
    fi
}

USER_HOME=$(get_user_home)
TARGET_USER=$(get_target_user)

# Install Zsh if needed
if ! command -v zsh &>/dev/null; then
    echo "📦 Installing Zsh..."
    run_cmd apt update
    run_cmd apt install -y zsh
    echo "✅ Zsh installed"
else
    echo "✅ Zsh already installed: $(zsh --version)"
fi

# Check current shell
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "/usr/bin/zsh" && "$CURRENT_SHELL" != "/bin/zsh" ]]; then
    echo "🔧 Setting Zsh as default shell for $TARGET_USER..."
    run_cmd chsh -s "$(which zsh)" "$TARGET_USER"
    echo "✅ Default shell changed to Zsh"
else
    echo "✅ Zsh already set as default shell for $TARGET_USER"
fi

# Install Oh My Zsh
export RUNZSH=no
export CHSH=no
OMZ_DIR="$USER_HOME/.oh-my-zsh"

if [[ ! -d "$OMZ_DIR" ]]; then
    echo "📦 Installing Oh My Zsh..."
    run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "✅ Oh My Zsh installed"
else
    echo "✅ Oh My Zsh already installed"
fi

# Install Powerlevel10k theme
P10K_DIR="$OMZ_DIR/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "🎨 Installing Powerlevel10k theme..."
    run_as_user git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    echo "✅ Powerlevel10k installed"
else
    echo "✅ Powerlevel10k already installed"
fi

# Install useful plugins
ZSH_CUSTOM="$OMZ_DIR/custom"
PLUGINS_DIR="$ZSH_CUSTOM/plugins"

echo "🔌 Installing Oh My Zsh plugins..."

# zsh-autosuggestions
if [[ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]]; then
    echo "   Installing zsh-autosuggestions..."
    run_as_user git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions"
else
    echo "   ✅ zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [[ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
    echo "   Installing zsh-syntax-highlighting..."
    run_as_user git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGINS_DIR/zsh-syntax-highlighting"
else
    echo "   ✅ zsh-syntax-highlighting already installed"
fi

# zsh-completions
if [[ ! -d "$PLUGINS_DIR/zsh-completions" ]]; then
    echo "   Installing zsh-completions..."
    run_as_user git clone https://github.com/zsh-users/zsh-completions "$PLUGINS_DIR/zsh-completions"
else
    echo "   ✅ zsh-completions already installed"
fi

# Configure .zshrc
ZSHRC_FILE="$USER_HOME/.zshrc"
if [[ -f "$ZSHRC_FILE" ]]; then
    echo "⚙️  Configuring .zshrc..."
    
    # Set Powerlevel10k theme
    if ! run_as_user grep -q "powerlevel10k/powerlevel10k" "$ZSHRC_FILE"; then
        run_as_user sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC_FILE"
        echo "   ✅ Powerlevel10k theme configured"
    else
        echo "   ✅ Powerlevel10k theme already configured"
    fi
    
    # Configure plugins
    DESIRED_PLUGINS="git sudo zsh-autosuggestions zsh-syntax-highlighting zsh-completions"
    if ! run_as_user grep -q "zsh-autosuggestions" "$ZSHRC_FILE"; then
        run_as_user sed -i "s|^plugins=(.*|plugins=($DESIRED_PLUGINS)|" "$ZSHRC_FILE"
        echo "   ✅ Plugins configured: $DESIRED_PLUGINS"
    else
        echo "   ✅ Plugins already configured"
    fi
    
    # Add zsh-completions to fpath if not already there
    if ! run_as_user grep -q "zsh-completions" "$ZSHRC_FILE" | grep -q "fpath"; then
        run_as_user sed -i '/^source \$ZSH\/oh-my-zsh.sh/i fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src' "$ZSHRC_FILE"
        echo "   ✅ zsh-completions fpath added"
    fi
    
    # Add some useful aliases if not present
    if ! run_as_user grep -q "# Custom aliases" "$ZSHRC_FILE"; then
        run_as_user cat >> "$ZSHRC_FILE" << 'EOF'

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Docker aliases (if Docker is installed)
if command -v docker &> /dev/null; then
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias drm='docker rm'
    alias drmi='docker rmi'
    alias dstop='docker stop'
    alias dstart='docker start'
fi
EOF
        echo "   ✅ Useful aliases added"
    else
        echo "   ✅ Custom aliases already present"
    fi
else
    echo "⚠️  .zshrc file not found, Oh My Zsh installation may have failed"
fi

# Create a simple p10k config if it doesn't exist
P10K_CONFIG="$USER_HOME/.p10k.zsh"
if [[ ! -f "$P10K_CONFIG" ]]; then
    echo "🎨 Creating basic Powerlevel10k configuration..."
    run_as_user cat > "$P10K_CONFIG" << 'EOF'
# Powerlevel10k configuration - basic setup
# Run 'p10k configure' to customize further

# Instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Basic configuration
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir                     # current directory
  vcs                     # git status
  prompt_char             # prompt symbol
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # exit code of the last command
  command_execution_time  # duration of the last command
  background_jobs         # presence of background jobs
  time                    # current time
)

# Prompt character configuration
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=green
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=red

# Directory configuration
typeset -g POWERLEVEL9K_DIR_FOREGROUND=blue
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=

# Git configuration
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=green
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=yellow
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=cyan

# Time format
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
EOF
    
    # Add p10k source to .zshrc if not already there
    if [[ -f "$ZSHRC_FILE" ]] && ! run_as_user grep -q "p10k.zsh" "$ZSHRC_FILE"; then
        echo "" | run_as_user tee -a "$ZSHRC_FILE" > /dev/null
        echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." | run_as_user tee -a "$ZSHRC_FILE" > /dev/null
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" | run_as_user tee -a "$ZSHRC_FILE" > /dev/null
    fi
    
    echo "✅ Basic Powerlevel10k configuration created"
else
    echo "✅ Powerlevel10k configuration already exists"
fi

# Set proper permissions
run_as_user chmod 644 "$ZSHRC_FILE" 2>/dev/null || true
run_as_user chmod 644 "$P10K_CONFIG" 2>/dev/null || true

echo ""
echo "✅ Zsh shell environment setup complete!"
echo "📊 Configuration summary:"
echo "   Shell: $(which zsh)"
echo "   Default shell for $TARGET_USER: $(getent passwd "$TARGET_USER" | cut -d: -f7)"
echo "   Oh My Zsh: ✅ Installed"
echo "   Powerlevel10k: ✅ Installed"
echo "   Plugins: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions"
echo "   Configuration: $ZSHRC_FILE"
echo ""
echo "💡 Next steps:"
echo "   1. Log out and back in (or run 'exec zsh') to activate Zsh"
echo "   2. Run 'p10k configure' to customize your prompt"
echo "   3. Install recommended fonts (MesloLGS NF) for best experience"
echo ""
