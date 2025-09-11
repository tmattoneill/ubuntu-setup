# 🚀 Ubuntu Server Setup Scripts

**Complete automated setup for fresh Ubuntu servers and droplets**

A comprehensive collection of bash scripts designed to transform a fresh Ubuntu installation into a fully-configured development and production server environment. Perfect for new VPS deployments, local development servers, or setting up consistent environments across multiple machines.

## ✨ Features

### 🔧 Core System Setup
- **System Updates**: Automated security updates, essential packages, and system configuration
- **User Management**: Creates non-root user with sudo access and proper permissions
- **SSH Configuration**: Secure SSH setup with key-based authentication and authorized_keys management
- **Firewall**: UFW firewall configuration with sensible defaults

### 🛠️ Development Environment
- **Git**: Complete Git configuration with global settings and useful aliases
- **Python**: Python 3.11, pyenv, pip, and virtual environment tools
- **Node.js**: NVM, latest Node.js LTS, and npm package manager
- **Shell**: Zsh with Oh My Zsh, Powerlevel10k theme, and productivity plugins
- **Fonts**: Nerd Fonts installation for enhanced terminal experience

### 🌐 Web Services
- **Nginx**: Web server with basic configuration and security headers
- **Docker**: Docker Engine and Docker Compose with user permissions
- **SSL/TLS**: Certificate management with Certbot integration

### ⚙️ Management Interfaces
- **Cockpit**: Modern web-based server management (port 9090)
- **Webmin**: Traditional web-based system administration (port 10000)

## 🚀 Quick Start

### One-Command Installation

For a complete automated setup:

```bash
# Download and run the main script
curl -fsSL https://raw.githubusercontent.com/your-repo/ubuntu-setup/main/ubuntu-setup.sh | bash
```

Or clone the repository first:

```bash
git clone https://github.com/your-repo/ubuntu-setup.git
cd ubuntu-setup
chmod +x ubuntu-setup.sh
sudo ./ubuntu-setup.sh
```

### Installation Options

#### Interactive Mode (Recommended)
```bash
sudo ./ubuntu-setup.sh
```
- Prompts for component selection
- Guides through configuration options
- Allows customization of installation

#### Automated Mode
```bash
sudo ./ubuntu-setup.sh --auto
```
- Installs all core and development components
- Uses sensible defaults
- Perfect for scripted deployments

#### Help and Options
```bash
./ubuntu-setup.sh --help
```

## 📋 Installation Order

The scripts are executed in this precise order for optimal dependency management:

1. **`00-system-update.sh`** - System updates and basic security
2. **`01-setup-user.sh`** - User account creation (if run as root)
3. **`setup-ssh.sh`** - SSH configuration and key management
4. **`02-setup-git.sh`** - Git configuration
5. **`setup-python.sh`** - Python development environment
6. **`setup-node.sh`** - Node.js development environment
7. **`setup-shell.sh`** - Zsh shell environment
8. **`05-setup-fonts.sh`** - Terminal fonts
9. **`03-setup-nginx.sh`** - Nginx web server
10. **`04-setup-docker.sh`** - Docker containerization
11. **`setup-cockpit.sh`** - Cockpit web interface
12. **`setup-webmin.sh`** - Webmin administration

## 🔧 Individual Script Usage

Each script can be run independently for specific setups:

### Core System Scripts
```bash
sudo ./00-system-update.sh      # Update system and install essentials
sudo ./01-setup-user.sh         # Create main user account
./setup-ssh.sh                  # Configure SSH keys and access
./02-setup-git.sh               # Set up Git configuration
```

### Development Environment
```bash
./setup-python.sh               # Install Python development tools
./setup-node.sh                 # Install Node.js and npm
./setup-shell.sh                # Set up Zsh with Oh My Zsh
./05-setup-fonts.sh             # Install terminal fonts
```

### Web Services
```bash
sudo ./03-setup-nginx.sh        # Install and configure Nginx
sudo ./04-setup-docker.sh       # Install Docker and Docker Compose
```

### Management Interfaces
```bash
sudo ./setup-cockpit.sh         # Install Cockpit web console
sudo ./setup-webmin.sh          # Install Webmin administration
```

## 🔐 Security Features

### Automatic Security Hardening
- **Unattended Upgrades**: Automatic security updates
- **UFW Firewall**: Configured with essential ports only
- **SSH Security**: Key-based authentication, disabled password auth
- **User Privileges**: Non-root user with sudo access

### SSL/TLS Support
- **Self-signed Certificates**: For development and internal use
- **Let's Encrypt**: Production-ready certificates via Certbot
- **Security Headers**: Nginx configured with security best practices

## 🎯 Use Cases

### 🖥️ Development Workstation
Perfect for setting up a local development environment with all necessary tools and a modern shell experience.

### ☁️ VPS/Droplet Setup
One-command setup for new cloud servers (DigitalOcean, Linode, AWS EC2, etc.).

### 🏢 Team Environments
Consistent development environments across team members and deployment targets.

### 🧪 Testing & CI/CD
Reproducible environments for testing and continuous integration pipelines.

## 📁 Project Structure

```
ubuntu-setup/
├── ubuntu-setup.sh              # Main orchestrator script
├── 00-system-update.sh          # System updates and essentials
├── 01-setup-user.sh             # User account creation
├── 02-setup-git.sh              # Git configuration
├── 03-setup-nginx.sh            # Nginx web server
├── 04-setup-docker.sh           # Docker installation
├── 05-setup-fonts.sh            # Terminal fonts
├── setup-ssh.sh                 # SSH configuration
├── setup-shell.sh               # Zsh shell environment
├── setup-node.sh                # Node.js development
├── setup-python.sh              # Python development
├── setup-cockpit.sh             # Cockpit web interface
├── setup-webmin.sh              # Webmin administration
├── minimal.sh                   # Legacy all-in-one script
├── README.md                    # This documentation
└── CLAUDE.md                    # AI assistant guidance
```

## ⚙️ Configuration

### Environment Variables

Scripts respect these environment variables for automation:

```bash
export SETUP_USERNAME="myuser"        # Target username
export SETUP_FULLNAME="My User"       # User's full name
export GIT_USER_NAME="My Name"        # Git user name
export GIT_USER_EMAIL="my@email.com"  # Git email
```

### Customization

Each script is designed to be:
- **Idempotent**: Safe to run multiple times
- **Interactive**: Prompts for configuration when needed
- **Flexible**: Can be customized by editing variables at the top of each script

## 🔍 Troubleshooting

### Common Issues

**Permission Denied**
```bash
chmod +x *.sh
```

**Script Not Found**
```bash
# Ensure you're in the correct directory
cd ubuntu-setup
ls -la *.sh
```

**Network Issues**
```bash
# Check internet connectivity
curl -I https://google.com
```

**Package Installation Failures**
```bash
# Update package lists
sudo apt update
sudo apt upgrade
```

### Log Files

Scripts provide detailed output during execution. For debugging:
- Watch output in real-time
- Check system logs: `sudo journalctl -f`
- Review individual script execution

## 🤝 Contributing

### Adding New Scripts

1. Follow the naming convention: `##-descriptive-name.sh`
2. Include proper error handling: `set -euo pipefail`
3. Add idempotency checks
4. Include user/root privilege handling
5. Add to the main orchestrator script

### Script Template

```bash
#!/bin/bash
set -euo pipefail

## === MODULE: Description ===

echo "🔧 Setting up [component]..."

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

# Your installation logic here

echo "✅ [Component] setup complete!"
```

## 📜 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Amazing Zsh configuration framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Beautiful and fast Zsh theme
- [Nerd Fonts](https://www.nerdfonts.com/) - Icon-patched fonts for terminals
- Ubuntu and the open-source community

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/your-repo/ubuntu-setup/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-repo/ubuntu-setup/discussions)
- 📚 **Documentation**: This README and inline script comments

---

**Made with ❤️ for the Ubuntu community**
