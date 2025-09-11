#!/bin/bash
set -euo pipefail

## === Ubuntu Server Complete Setup Script ===
## One-shot installation for fresh Ubuntu servers
## Supports both root and user execution with proper privilege handling

# Script metadata
SCRIPT_VERSION="1.0.0"

# Determine script directory - handle both local execution and curl|bash
if [[ "${BASH_SOURCE[0]:-}" ]]; then
    # Script is being executed from a file
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ "$0" != "bash" ]]; then
    # Script is being executed directly
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    # Script is being piped into bash (curl | bash scenario)
    # In this case, we need to download the required scripts
    SCRIPT_DIR="/tmp/ubuntu-setup-$$"
    REMOTE_REPO="https://raw.githubusercontent.com/tmattoneill/ubuntu-setup/main"
    DOWNLOAD_MODE=true
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Download required scripts when running via curl|bash
download_scripts() {
    if [[ "${DOWNLOAD_MODE:-}" != "true" ]]; then
        return 0
    fi
    
    log "INFO" "Setting up temporary directory for script downloads..."
    mkdir -p "$SCRIPT_DIR"
    
    local required_scripts=(
        "00-system-update.sh"
        "01-setup-user.sh"
        "02-setup-git.sh"
        "03-setup-nginx.sh"
        "04-setup-docker.sh"
        "05-setup-fonts.sh"
        "06-setup-ssh.sh"
        "07-setup-shell.sh"
        "setup-node.sh"
        "setup-python.sh"
        "setup-cockpit.sh"
        "setup-webmin.sh"
    )
    
    log "INFO" "Downloading required scripts from GitHub..."
    local failed_downloads=()
    
    for script in "${required_scripts[@]}"; do
        local url="$REMOTE_REPO/$script"
        local dest="$SCRIPT_DIR/$script"
        
        echo -n "  Downloading $script... "
        if curl -fsSL "$url" -o "$dest"; then
            chmod +x "$dest"
            echo "✅"
        else
            echo "❌"
            failed_downloads+=("$script")
        fi
    done
    
    if [[ ${#failed_downloads[@]} -gt 0 ]]; then
        log "ERROR" "Failed to download required scripts:"
        for script in "${failed_downloads[@]}"; do
            log "ERROR" "  - $script"
        done
        log "ERROR" "Please check your internet connection and try again"
        exit 1
    fi
    
    log "INFO" "All scripts downloaded successfully ✅"
}

# Cleanup downloaded scripts
cleanup_downloads() {
    if [[ "${DOWNLOAD_MODE:-}" == "true" ]] && [[ -d "$SCRIPT_DIR" ]]; then
        log "INFO" "Cleaning up temporary files..."
        rm -rf "$SCRIPT_DIR"
    fi
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC}  $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${CYAN}[DEBUG]${NC} $message" ;;
        "STEP")  echo -e "${PURPLE}[STEP]${NC}  $message" ;;
        *)       echo "[$timestamp] $message" ;;
    esac
}

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          🚀 Ubuntu Server Setup v$SCRIPT_VERSION                          ║"
    echo "║                                                                                ║"
    echo "║  Complete automated setup for fresh Ubuntu servers                            ║"
    echo "║  • System updates & security                                                   ║"
    echo "║  • User management & SSH configuration                                         ║"
    echo "║  • Development environment (Git, Node.js, Python)                             ║"
    echo "║  • Shell environment (Zsh + Oh My Zsh + Powerlevel10k)                        ║"
    echo "║  • Web services (Nginx, Docker)                                               ║"
    echo "║  • Management interfaces (Cockpit, Webmin)                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check script dependencies
check_dependencies() {
    log "INFO" "Checking script dependencies..."
    
    # Check if we're on Ubuntu
    if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
        log "ERROR" "This script is designed for Ubuntu systems only"
        exit 1
    fi
    
    # Download scripts if running via curl|bash
    download_scripts
    
    # Check if required scripts exist
    local missing_scripts=()
    local required_scripts=(
        "00-system-update.sh"
        "01-setup-user.sh"
        "02-setup-git.sh"
        "03-setup-nginx.sh"
        "04-setup-docker.sh"
        "05-setup-fonts.sh"
        "06-setup-ssh.sh"
        "07-setup-shell.sh"
        "setup-node.sh"
        "setup-python.sh"
        "setup-cockpit.sh"
        "setup-webmin.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        log "ERROR" "Missing required scripts:"
        for script in "${missing_scripts[@]}"; do
            log "ERROR" "  - $script"
        done
        exit 1
    fi
    
    log "INFO" "All required scripts found ✅"
}

# Check privileges and handle user setup
handle_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log "INFO" "Running as root - setting up main user account"
        
        # Prompt for main user details
        echo ""
        log "STEP" "👤 Main User Account Setup"
        echo "This script will create a main non-root user account for daily use."
        echo ""
        
        read -rp "Enter username for the main user [webdev]: " MAIN_USERNAME
        MAIN_USERNAME=${MAIN_USERNAME:-webdev}
        
        read -rp "Enter full name for the user [Web Developer]: " MAIN_FULLNAME  
        MAIN_FULLNAME=${MAIN_FULLNAME:-Web Developer}
        
        # Export for use by other scripts
        export SETUP_USERNAME="$MAIN_USERNAME"
        export SETUP_FULLNAME="$MAIN_FULLNAME"
        
        log "INFO" "Main user will be: $MAIN_USERNAME ($MAIN_FULLNAME)"
        
    else
        # Running as regular user
        log "INFO" "Running as user: $USER"
        
        # Check if user has sudo access
        if ! sudo -n true 2>/dev/null; then
            log "ERROR" "This script requires sudo privileges. Please run with a user that has sudo access."
            exit 1
        fi
        
        export SETUP_USERNAME="$USER"
        log "INFO" "Using current user: $USER"
    fi
}

# Execute a script with error handling
execute_script() {
    local script_name="$1"
    local description="$2"
    local script_path="$SCRIPT_DIR/$script_name"
    
    log "STEP" "🔄 $description"
    echo "   Executing: $script_name"
    
    if [[ ! -f "$script_path" ]]; then
        log "ERROR" "Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log "INFO" "Making script executable: $script_name"
        chmod +x "$script_path"
    fi
    
    # Execute the script with proper environment
    if bash "$script_path"; then
        log "INFO" "✅ $description - Complete"
        return 0
    else
        local exit_code=$?
        log "ERROR" "❌ $description - Failed (exit code: $exit_code)"
        return $exit_code
    fi
}

# Prompt user for optional components
prompt_for_options() {
    echo ""
    log "STEP" "⚙️  Component Selection"
    echo "Choose which components to install:"
    echo ""
    
    # Core components (always installed)
    echo "Core components (automatically included):"
    echo "  ✅ System updates & security"
    echo "  ✅ User management"
    echo "  ✅ SSH configuration"
    echo "  ✅ Git configuration"
    echo ""
    
    # Development environment
    read -rp "Install development environment (Python, Node.js, Shell)? [Y/n]: " INSTALL_DEV
    INSTALL_DEV=${INSTALL_DEV:-y}
    
    # Web services
    read -rp "Install web services (Nginx, Docker)? [Y/n]: " INSTALL_WEB
    INSTALL_WEB=${INSTALL_WEB:-y}
    
    # Management interfaces
    read -rp "Install management interfaces (Cockpit, Webmin)? [y/N]: " INSTALL_MGMT
    INSTALL_MGMT=${INSTALL_MGMT:-n}
    
    # Fonts
    if [[ "$INSTALL_DEV" =~ ^[Yy]$ ]]; then
        read -rp "Install terminal fonts (for better shell experience)? [Y/n]: " INSTALL_FONTS
        INSTALL_FONTS=${INSTALL_FONTS:-y}
    else
        INSTALL_FONTS="n"
    fi
    
    echo ""
    log "INFO" "Installation plan:"
    echo "  Development Environment: $([ "$INSTALL_DEV" =~ ^[Yy]$ ] && echo "✅ Yes" || echo "❌ No")"
    echo "  Web Services: $([ "$INSTALL_WEB" =~ ^[Yy]$ ] && echo "✅ Yes" || echo "❌ No")"
    echo "  Management Interfaces: $([ "$INSTALL_MGMT" =~ ^[Yy]$ ] && echo "✅ Yes" || echo "❌ No")"
    echo "  Terminal Fonts: $([ "$INSTALL_FONTS" =~ ^[Yy]$ ] && echo "✅ Yes" || echo "❌ No")"
    echo ""
    
    read -rp "Continue with this configuration? [Y/n]: " CONTINUE_SETUP
    CONTINUE_SETUP=${CONTINUE_SETUP:-y}
    
    if [[ ! "$CONTINUE_SETUP" =~ ^[Yy]$ ]]; then
        log "INFO" "Setup cancelled by user"
        exit 0
    fi
}

# Main installation sequence
run_installation() {
    local start_time=$(date +%s)
    local failed_scripts=()
    
    log "STEP" "🚀 Starting Ubuntu Server Setup"
    echo ""
    
    # Core system setup (always run)
    execute_script "00-system-update.sh" "System Updates & Security" || failed_scripts+=("System Updates")
    
    if [[ $EUID -eq 0 ]]; then
        execute_script "01-setup-user.sh" "User Account Creation" || failed_scripts+=("User Setup")
    fi
    
    execute_script "06-setup-ssh.sh" "SSH Configuration" || failed_scripts+=("SSH Setup")
    execute_script "02-setup-git.sh" "Git Configuration" || failed_scripts+=("Git Setup")
    
    # Development environment
    if [[ "$INSTALL_DEV" =~ ^[Yy]$ ]]; then
        echo ""
        log "STEP" "🛠️  Installing Development Environment"
        execute_script "setup-python.sh" "Python Development Environment" || failed_scripts+=("Python")
        execute_script "setup-node.sh" "Node.js Development Environment" || failed_scripts+=("Node.js")
        execute_script "07-setup-shell.sh" "Zsh Shell Environment" || failed_scripts+=("Shell")
        
        if [[ "$INSTALL_FONTS" =~ ^[Yy]$ ]]; then
            execute_script "05-setup-fonts.sh" "Terminal Fonts" || failed_scripts+=("Fonts")
        fi
    fi
    
    # Web services
    if [[ "$INSTALL_WEB" =~ ^[Yy]$ ]]; then
        echo ""
        log "STEP" "🌐 Installing Web Services"
        execute_script "03-setup-nginx.sh" "Nginx Web Server" || failed_scripts+=("Nginx")
        execute_script "04-setup-docker.sh" "Docker & Docker Compose" || failed_scripts+=("Docker")
    fi
    
    # Management interfaces
    if [[ "$INSTALL_MGMT" =~ ^[Yy]$ ]]; then
        echo ""
        log "STEP" "⚙️  Installing Management Interfaces"
        execute_script "setup-cockpit.sh" "Cockpit Web Console" || failed_scripts+=("Cockpit")
        execute_script "setup-webmin.sh" "Webmin Administration" || failed_scripts+=("Webmin")
    fi
    
    # Calculate total time
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    local minutes=$((total_time / 60))
    local seconds=$((total_time % 60))
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                              🎉 Setup Complete!                                ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ ${#failed_scripts[@]} -eq 0 ]]; then
        log "INFO" "✅ All components installed successfully!"
    else
        log "WARN" "⚠️  Some components failed to install:"
        for script in "${failed_scripts[@]}"; do
            log "WARN" "   - $script"
        done
        echo ""
        log "INFO" "You can manually run the individual scripts to retry failed components"
    fi
    
    echo ""
    log "INFO" "📊 Setup Summary:"
    echo "   Total time: ${minutes}m ${seconds}s"
    echo "   Components attempted: $((${#failed_scripts[@]} > 0 ? $(echo "${#failed_scripts[@]}") : "All successful"))"
    echo ""
    
    # Post-installation instructions
    log "STEP" "📋 Next Steps:"
    echo ""
    
    if [[ $EUID -eq 0 ]]; then
        echo "1. 👤 Switch to the main user account:"
        echo "   su - $SETUP_USERNAME"
        echo ""
        echo "2. 🔐 Configure SSH keys if you haven't already"
        echo "   The SSH setup script guided you through this"
        echo ""
    fi
    
    if [[ "$INSTALL_DEV" =~ ^[Yy]$ ]]; then
        echo "3. 🐚 Activate your new shell environment:"
        echo "   exec zsh"
        echo "   p10k configure  # Customize your prompt"
        echo ""
    fi
    
    if [[ "$INSTALL_WEB" =~ ^[Yy]$ ]]; then
        echo "4. 🌐 Test your web server:"
        local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
        echo "   Visit: http://$server_ip"
        echo ""
    fi
    
    if [[ "$INSTALL_MGMT" =~ ^[Yy]$ ]]; then
        echo "5. ⚙️  Access management interfaces:"
        local server_ip=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
        echo "   Cockpit: https://$server_ip:9090"
        echo "   Webmin:  https://$server_ip:10000"
        echo ""
    fi
    
    echo "6. 🔒 Security recommendations:"
    echo "   - Change default passwords if any were created"
    echo "   - Review firewall settings: sudo ufw status"
    echo "   - Keep your system updated: sudo apt update && sudo apt upgrade"
    echo ""
    
    if [[ ${#failed_scripts[@]} -gt 0 ]]; then
        echo "7. 🔧 Retry failed components:"
        echo "   Check logs above and manually run failed scripts"
        echo ""
    fi
    
    log "INFO" "🎯 Ubuntu server setup complete! Enjoy your new environment!"
    
    # Clean up downloaded files if in download mode
    cleanup_downloads
}

# Cleanup function
cleanup() {
    local exit_code=$?
    cleanup_downloads
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        log "ERROR" "Setup interrupted (exit code: $exit_code)"
        log "INFO" "You can resume by running individual scripts manually"
    fi
    exit $exit_code
}

# Main function
main() {
    # Set up signal handlers
    trap cleanup EXIT INT TERM
    
    # Parse command line arguments
    local skip_prompts=false
    local help_requested=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes|--auto)
                skip_prompts=true
                shift
                ;;
            -h|--help)
                help_requested=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                help_requested=true
                break
                ;;
        esac
    done
    
    if [[ "$help_requested" = true ]]; then
        echo "Ubuntu Server Setup Script v$SCRIPT_VERSION"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -y, --yes, --auto    Skip prompts and use defaults"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "This script performs a complete Ubuntu server setup including:"
        echo "  • System updates and security configuration"
        echo "  • User account creation and SSH setup"
        echo "  • Development environment (Git, Python, Node.js, Zsh)"
        echo "  • Web services (Nginx, Docker)"
        echo "  • Management interfaces (Cockpit, Webmin)"
        echo ""
        echo "Run as root for initial server setup, or as a sudo user for existing systems."
        exit 0
    fi
    
    # Main execution flow
    print_banner
    check_dependencies
    handle_privileges
    
    if [[ "$skip_prompts" = false ]]; then
        prompt_for_options
    else
        # Auto mode - install everything
        INSTALL_DEV="y"
        INSTALL_WEB="y"
        INSTALL_MGMT="n"  # Management interfaces off by default in auto mode
        INSTALL_FONTS="y"
        log "INFO" "Auto mode: Installing all core and development components"
    fi
    
    run_installation
}

# Execute main function
main "$@"