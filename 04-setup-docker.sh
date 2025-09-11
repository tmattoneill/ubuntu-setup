#!/bin/bash
set -euo pipefail

## === MODULE 04: Docker & Docker Compose Installation ===

echo "🐳 Setting up Docker and Docker Compose..."

# Check if running with sudo privileges
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo privileges"
    exit 1
fi

# Function to run commands with proper privileges
run_cmd() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

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

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    echo "✅ Docker already installed: $(docker --version)"
    
    # Check if Docker service is running
    if systemctl is-active --quiet docker; then
        echo "✅ Docker service is running"
    else
        echo "🔄 Starting Docker service..."
        run_cmd systemctl start docker
        run_cmd systemctl enable docker
        echo "✅ Docker service started and enabled"
    fi
else
    echo "📦 Installing Docker..."
    
    # Install prerequisites
    run_cmd apt update
    run_cmd apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    run_cmd mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_cmd gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | run_cmd tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    run_cmd apt update
    run_cmd apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    # Start and enable Docker
    run_cmd systemctl start docker
    run_cmd systemctl enable docker
    
    echo "✅ Docker installed and started"
fi

# Add user to docker group
TARGET_USER=""
if [[ -n "${SETUP_USERNAME:-}" ]]; then
    TARGET_USER="$SETUP_USERNAME"
elif [[ $EUID -ne 0 ]]; then
    TARGET_USER="$USER"
fi

if [[ -n "$TARGET_USER" ]]; then
    if id "$TARGET_USER" &>/dev/null; then
        if ! groups "$TARGET_USER" | grep -q docker; then
            echo "👥 Adding user '$TARGET_USER' to docker group..."
            run_cmd usermod -aG docker "$TARGET_USER"
            echo "✅ User '$TARGET_USER' added to docker group"
            echo "⚠️  Note: You may need to log out and back in for group changes to take effect"
        else
            echo "✅ User '$TARGET_USER' already in docker group"
        fi
    fi
fi

# Check if Docker Compose is already installed
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
    echo "✅ Docker Compose already available: $(docker compose version)"
else
    echo "📦 Installing Docker Compose..."
    
    # Docker Compose is now included as a plugin with Docker CE
    # If it's not available, install the standalone version
    if ! docker compose version &>/dev/null 2>&1; then
        # Get latest version from GitHub API
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        
        if [[ -z "$COMPOSE_VERSION" ]]; then
            COMPOSE_VERSION="v2.21.0"  # Fallback version
            echo "⚠️  Could not fetch latest version, using fallback: $COMPOSE_VERSION"
        fi
        
        echo "📥 Downloading Docker Compose $COMPOSE_VERSION..."
        run_cmd curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        run_cmd chmod +x /usr/local/bin/docker-compose
        
        # Create symlink for compatibility
        run_cmd ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        echo "✅ Docker Compose installed"
    else
        echo "✅ Docker Compose plugin already available"
    fi
fi

# Test Docker installation
echo "🧪 Testing Docker installation..."
if run_cmd docker run --rm hello-world &>/dev/null; then
    echo "✅ Docker test successful"
else
    echo "❌ Docker test failed"
    exit 1
fi

# Create useful directories for Docker projects
if [[ -n "$TARGET_USER" ]]; then
    USER_HOME="/home/$TARGET_USER"
    echo "📁 Creating Docker project directories..."
    run_as_user mkdir -p "$USER_HOME/docker-projects"
    run_as_user mkdir -p "$USER_HOME/docker-data"
    
    # Create a sample docker-compose.yml template
    COMPOSE_TEMPLATE="$USER_HOME/docker-projects/docker-compose.template.yml"
    if [[ ! -f "$COMPOSE_TEMPLATE" ]]; then
        run_as_user cat > "$COMPOSE_TEMPLATE" << 'EOF'
# Docker Compose Template
# Copy this file to your project directory and modify as needed

version: '3.8'

services:
  # Example web service
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped
    
  # Example database service
  # db:
  #   image: postgres:15
  #   environment:
  #     POSTGRES_DB: myapp
  #     POSTGRES_USER: user
  #     POSTGRES_PASSWORD: password
  #   volumes:
  #     - db_data:/var/lib/postgresql/data
  #   restart: unless-stopped

# volumes:
#   db_data:

# networks:
#   default:
#     driver: bridge
EOF
        echo "✅ Docker Compose template created at $COMPOSE_TEMPLATE"
    fi
fi

# Create Docker daemon configuration for better defaults
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
if [[ ! -f "$DOCKER_DAEMON_CONFIG" ]]; then
    echo "⚙️  Creating Docker daemon configuration..."
    run_cmd cat > "$DOCKER_DAEMON_CONFIG" << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    
    echo "🔄 Restarting Docker to apply configuration..."
    run_cmd systemctl restart docker
    echo "✅ Docker daemon configuration applied"
fi

echo ""
echo "✅ Docker setup complete!"
echo "📊 Installation details:"
echo "   Docker: $(docker --version)"
if command -v docker-compose &>/dev/null; then
    echo "   Docker Compose: $(docker-compose --version)"
elif docker compose version &>/dev/null; then
    echo "   Docker Compose: $(docker compose version)"
fi
echo "   Service status: $(systemctl is-active docker)"

if [[ -n "$TARGET_USER" ]]; then
    echo "   User '$TARGET_USER' added to docker group"
    echo "   Project directory: /home/$TARGET_USER/docker-projects"
fi

echo ""
echo "💡 Quick start commands:"
echo "   docker run hello-world              # Test Docker"
echo "   docker ps                          # List running containers"
echo "   docker images                      # List images"
echo "   docker-compose up -d               # Start services from compose file"
echo ""
echo "⚠️  Note: If you added a user to the docker group, they need to log out and back in"
echo ""