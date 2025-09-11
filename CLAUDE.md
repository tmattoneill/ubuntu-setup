# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A comprehensive collection of bash scripts for automated Ubuntu server setup, designed to transform fresh installations into fully-configured development and production environments. The system supports both interactive and automated deployment scenarios with proper privilege handling and security configurations.

## New Architecture (v1.0.0)

### META Orchestrator
- **`ubuntu-setup.sh`** - Main orchestrator script with component selection, privilege handling, and progress tracking

### Numbered Core Scripts (Execution Order)
- **`00-system-update.sh`** - System updates, security configuration, firewall, and essential packages
- **`01-setup-user.sh`** - User account creation with sudo access and directory structure
- **`02-setup-git.sh`** - Git configuration with global settings and .gitignore
- **`03-setup-nginx.sh`** - Nginx web server with security headers and SSL support
- **`04-setup-docker.sh`** - Docker Engine, Docker Compose, and user permissions
- **`05-setup-fonts.sh`** - Nerd Fonts installation for terminal themes

### Named Component Scripts
- **`setup-ssh.sh`** - SSH configuration, key management, and authorized_keys setup
- **`setup-shell.sh`** - Zsh + Oh My Zsh + Powerlevel10k + plugins + aliases
- **`setup-node.sh`** - NVM + Node.js LTS + npm with proper shell integration
- **`setup-python.sh`** - Python 3.11 + pyenv + pip + development tools
- **`setup-cockpit.sh`** - Cockpit web console (port 9090)
- **`setup-webmin.sh`** - Webmin administration interface (port 10000)

### Legacy Scripts
- **`minimal.sh`** - Original all-in-one setup (maintained for compatibility)

## Key Features

### Privilege Handling
All scripts support both root and user execution:
```bash
# Root execution (creates user account)
sudo ./ubuntu-setup.sh

# User execution (works with existing account)
./ubuntu-setup.sh
```

### Environment Variables
Scripts use these variables for automation:
```bash
export SETUP_USERNAME="username"     # Target user account
export SETUP_FULLNAME="Full Name"    # User's display name
export GIT_USER_NAME="Git Name"      # Git configuration
export GIT_USER_EMAIL="git@email"    # Git email
```

### User/Root Functions
All scripts include standardized functions:
```bash
run_as_user() { ... }    # Execute as target user
run_cmd() { ... }        # Execute with proper privileges
get_user_home() { ... }  # Get user's home directory
```

## Installation Patterns

### Complete Setup
```bash
# Interactive mode
sudo ./ubuntu-setup.sh

# Automated mode
sudo ./ubuntu-setup.sh --auto

# Help and options
./ubuntu-setup.sh --help
```

### Individual Components
```bash
# Core system (requires root/sudo)
sudo ./00-system-update.sh
sudo ./01-setup-user.sh

# Development environment
./setup-ssh.sh
./02-setup-git.sh
./setup-python.sh
./setup-node.sh
./setup-shell.sh
./05-setup-fonts.sh

# Web services (requires sudo)
sudo ./03-setup-nginx.sh
sudo ./04-setup-docker.sh

# Management interfaces (requires sudo)
sudo ./setup-cockpit.sh
sudo ./setup-webmin.sh
```

## Script Conventions

### Error Handling
All scripts use strict error handling:
```bash
#!/bin/bash
set -euo pipefail
```

### Idempotency
Every operation checks for existing state:
```bash
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "📦 Installing Oh My Zsh..."
    # Installation logic
else
    echo "✅ Oh My Zsh already installed"
fi
```

### User Prompts
Scripts prompt for configuration when needed:
```bash
read -rp "Enter username [webdev]: " USERNAME
USERNAME=${USERNAME:-webdev}
```

### Progress Reporting
Consistent logging format:
```bash
echo "🔧 Setting up component..."
echo "✅ Component setup complete!"
```

## Security Features

### Automatic Hardening
- UFW firewall with minimal open ports
- Unattended security updates
- SSH key-based authentication
- Non-root user with sudo access

### SSL/TLS Support
- Self-signed certificates for development
- Let's Encrypt integration for production
- Security headers in Nginx configuration

### SSH Configuration
- Authorized keys management with validation
- Client key generation and import
- SSH config file with useful defaults
- GitHub/GitLab integration testing

## Testing and Development

### Manual Testing
Scripts should be tested on:
- Fresh Ubuntu 20.04 LTS
- Fresh Ubuntu 22.04 LTS
- Clean VM environments

### Development Workflow
1. Test individual scripts first
2. Test complete orchestrator workflow
3. Verify idempotency (run twice)
4. Test both root and user execution
5. Verify component interaction

## Common Operations

### Running Full Setup
```bash
# Clone repository
git clone <repository>
cd ubuntu-setup

# Run complete setup
sudo ./ubuntu-setup.sh
```

### Debugging Scripts
```bash
# Test individual script
bash -x ./setup-shell.sh

# Check environment
env | grep SETUP_

# Verify permissions
ls -la *.sh
```

### Customization
Modify variables at the top of scripts:
```bash
# In setup-git.sh
DEFAULT_NAME="Your Name"
DEFAULT_EMAIL="your@email.com"

# In setup-webmin.sh
TARGET_IP="your.server.ip"
```

## File Structure

```
ubuntu-setup/
├── ubuntu-setup.sh          # Main orchestrator
├── 00-system-update.sh      # System updates
├── 01-setup-user.sh         # User creation
├── 02-setup-git.sh          # Git configuration
├── 03-setup-nginx.sh        # Nginx web server
├── 04-setup-docker.sh       # Docker installation
├── 05-setup-fonts.sh        # Terminal fonts
├── setup-ssh.sh             # SSH configuration
├── setup-shell.sh           # Zsh environment
├── setup-node.sh            # Node.js development
├── setup-python.sh          # Python development
├── setup-cockpit.sh         # Cockpit interface
├── setup-webmin.sh          # Webmin interface
├── minimal.sh               # Legacy all-in-one
├── README.md                # User documentation
└── CLAUDE.md                # This file
```

## Development Notes

When modifying scripts:
- Maintain strict error handling and idempotency
- Support both root and user execution contexts
- Include comprehensive progress reporting
- Test interactive prompts and default values
- Verify proper file permissions and ownership
- Ensure scripts work when run multiple times
- Update the main orchestrator script when adding new components