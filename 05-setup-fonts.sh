#!/bin/bash
set -euo pipefail

## === MODULE 05: Font Installation for Terminal Themes ===

echo "🔤 Installing fonts for terminal themes (Powerline, Nerd Fonts)..."

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
FONTS_DIR="$USER_HOME/.local/share/fonts"

# Create fonts directory
echo "📁 Creating fonts directory..."
run_as_user mkdir -p "$FONTS_DIR"

# Install fontconfig if not present
if ! command -v fc-cache &>/dev/null; then
    echo "📦 Installing fontconfig..."
    run_cmd apt update
    run_cmd apt install -y fontconfig
fi

# Function to download and install a font
install_nerd_font() {
    local font_name="$1"
    local font_url="$2"
    local font_file="$3"
    
    if [[ -f "$FONTS_DIR/$font_file" ]]; then
        echo "✅ $font_name already installed"
        return 0
    fi
    
    echo "📥 Downloading $font_name..."
    if run_as_user curl --max-time 30 --retry 3 --retry-delay 2 -fLo "$FONTS_DIR/$font_file" "$font_url"; then
        echo "✅ $font_name installed"
    else
        echo "❌ Failed to download $font_name"
        return 1
    fi
}

# Install popular Nerd Fonts
echo "🔤 Installing Nerd Fonts..."

# MesloLGS NF (recommended for Powerlevel10k)
install_nerd_font "MesloLGS NF Regular" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" \
    "MesloLGS_NF_Regular.ttf"

install_nerd_font "MesloLGS NF Bold" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf" \
    "MesloLGS_NF_Bold.ttf"

install_nerd_font "MesloLGS NF Italic" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf" \
    "MesloLGS_NF_Italic.ttf"

install_nerd_font "MesloLGS NF Bold Italic" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf" \
    "MesloLGS_NF_Bold_Italic.ttf"

# Fira Code Nerd Font (popular for coding)
FIRA_VERSION="3.1.1"
install_nerd_font "FiraCode Nerd Font Regular" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v$FIRA_VERSION/FiraCode.zip" \
    "FiraCode.zip"

# Extract FiraCode if downloaded
if [[ -f "$FONTS_DIR/FiraCode.zip" ]]; then
    echo "📦 Extracting FiraCode Nerd Font..."
    cd "$FONTS_DIR"
    run_as_user unzip -o FiraCode.zip "*.ttf" 2>/dev/null || true
    run_as_user rm -f FiraCode.zip
    echo "✅ FiraCode Nerd Font extracted"
fi

# Install JetBrains Mono Nerd Font
install_nerd_font "JetBrainsMono Nerd Font" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v$FIRA_VERSION/JetBrainsMono.zip" \
    "JetBrainsMono.zip"

# Extract JetBrains Mono if downloaded
if [[ -f "$FONTS_DIR/JetBrainsMono.zip" ]]; then
    echo "📦 Extracting JetBrainsMono Nerd Font..."
    cd "$FONTS_DIR"
    run_as_user unzip -o JetBrainsMono.zip "*.ttf" 2>/dev/null || true
    run_as_user rm -f JetBrainsMono.zip
    echo "✅ JetBrainsMono Nerd Font extracted"
fi

# Install system-wide fonts as well (requires sudo)
SYSTEM_FONTS_DIR="/usr/share/fonts/truetype/nerd-fonts"
if [[ ! -d "$SYSTEM_FONTS_DIR" ]]; then
    echo "📁 Creating system fonts directory..."
    run_cmd mkdir -p "$SYSTEM_FONTS_DIR"
    
    # Copy user fonts to system directory
    if [[ -n "$(ls -A "$FONTS_DIR"/*.ttf 2>/dev/null)" ]]; then
        echo "📋 Copying fonts to system directory..."
        run_cmd cp "$FONTS_DIR"/*.ttf "$SYSTEM_FONTS_DIR/" 2>/dev/null || true
    fi
fi

# Update font cache
echo "🔄 Updating font cache..."
run_as_user fc-cache -fv "$FONTS_DIR" &>/dev/null
run_cmd fc-cache -fv &>/dev/null

# Verify installation
echo "🔍 Verifying font installation..."
INSTALLED_FONTS=$(run_as_user fc-list 2>/dev/null | grep -i "nerd\|meslo\|fira\|jetbrains" | wc -l 2>/dev/null || echo "0")

if [[ $INSTALLED_FONTS -gt 0 ]]; then
    echo "✅ Found $INSTALLED_FONTS Nerd Font variants installed"
else
    echo "⚠️  No Nerd Fonts detected in font cache"
fi

# Create a font test script
FONT_TEST_SCRIPT="$USER_HOME/bin/test-fonts.sh"
echo "📝 Creating font test script..."
run_as_user mkdir -p "$USER_HOME/bin"
run_as_user cat > "$FONT_TEST_SCRIPT" << 'EOF'
#!/bin/bash
# Font test script - displays various Unicode characters and symbols

echo "🔤 Font Test - Unicode and Powerline Symbols"
echo "=============================================="
echo
echo "📐 Basic Unicode symbols:"
echo "   ✓ ✗ ⚠ ⚡ 🔥 🚀 📁 🔒 🌐 ⭐"
echo
echo "🔗 Powerline symbols:"
echo "   ❯ ➜     "
echo
echo "🔢 Programming ligatures (if supported):"
echo "   != == >= <= => -> <-"
echo "   |> <| || && ?? :: ... ::"
echo
echo "📊 Box drawing characters:"
echo "   ┌─┬─┐ ├─┼─┤ └─┴─┘"
echo "   │ │ │ ╭─╮ ╰─╯"
echo
echo "🎯 Nerd Font icons (if MesloLGS or other Nerd Font is active):"
echo "                              "
echo
echo "💡 To use these fonts:"
echo "   1. In Terminal: Set font to 'MesloLGS NF' or similar"
echo "   2. In VS Code: Set 'editor.fontFamily' to 'MesloLGS NF'"
echo "   3. In SSH clients: Configure terminal font settings"
EOF

run_as_user chmod +x "$FONT_TEST_SCRIPT"

# Create font configuration for better rendering
FONTCONFIG_DIR="$USER_HOME/.config/fontconfig"
run_as_user mkdir -p "$FONTCONFIG_DIR"

FONTCONFIG_FILE="$FONTCONFIG_DIR/fonts.conf"
if [[ ! -f "$FONTCONFIG_FILE" ]]; then
    echo "⚙️  Creating fontconfig configuration..."
    run_as_user cat > "$FONTCONFIG_FILE" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Improve font rendering -->
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
  </match>
  
  <match target="font">
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
  </match>
  
  <match target="font">
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
  </match>
  
  <match target="font">
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
  </match>
  
  <!-- Prefer Nerd Fonts for monospace -->
  <alias>
    <family>monospace</family>
    <prefer>
      <family>MesloLGS NF</family>
      <family>FiraCode Nerd Font</family>
      <family>JetBrainsMono Nerd Font</family>
    </prefer>
  </alias>
</fontconfig>
EOF
    echo "✅ Fontconfig configuration created"
fi

echo ""
echo "✅ Font installation complete!"
echo "📊 Installation summary:"
echo "   User fonts directory: $FONTS_DIR"
echo "   System fonts directory: $SYSTEM_FONTS_DIR"
echo "   Font cache updated: ✅"
echo "   Installed Nerd Font variants: $INSTALLED_FONTS"
echo ""
echo "🎯 Recommended fonts for terminals:"
echo "   • MesloLGS NF (best for Powerlevel10k)"
echo "   • FiraCode Nerd Font (great for coding)"
echo "   • JetBrainsMono Nerd Font (clean and modern)"
echo ""
echo "🧪 Test your fonts:"
echo "   Run: $FONT_TEST_SCRIPT"
echo ""
echo "💡 Terminal configuration:"
echo "   1. Set your terminal font to 'MesloLGS NF' or similar"
echo "   2. Size 12-14 usually works well"
echo "   3. Enable font ligatures if available"
echo ""