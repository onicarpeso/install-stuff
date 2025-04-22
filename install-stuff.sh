#!/bin/bash

# Script to check and install Git, Docker, Tailscale, and Cloudflared
# Enable SSH password authentication
# Then clone the specified repository
# For Ubuntu 24.04

# Error handling
set -e  # Exit immediately if a command exits with a non-zero status
trap 'echo "An error occurred. Exiting..."; exit 1' ERR

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check disk space (minimum 5GB free)
check_disk_space() {
    log "Checking available disk space..."
    FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$FREE_SPACE" -lt 5 ]; then
        log "ERROR: Not enough disk space. At least 5GB required, but only ${FREE_SPACE}GB available."
        exit 1
    else
        log "Sufficient disk space available: ${FREE_SPACE}GB"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install Git if not installed
install_git() {
    if ! command_exists git; then
        log "Git not found. Installing Git..."
        sudo apt update
        sudo apt install -y git
        
        # Configure Git to run without sudo
        log "Configuring Git for current user..."
        git config --global user.name "$(whoami)"
        git config --global user.email "$(whoami)@$(hostname)"
        
        log "Git installed successfully."
    else
        log "Git is already installed."
    fi
}

# Install Docker if not installed
install_docker() {
    if ! command_exists docker; then
        log "Docker not found. Installing Docker..."
        
        # Install dependencies
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        
        # Add current user to docker group to run without sudo
        log "Adding user to docker group to run without sudo..."
        sudo groupadd -f docker
        sudo usermod -aG docker "$USER"
        
        log "Docker installed successfully. You may need to log out and back in for group changes to take effect."
    else
        log "Docker is already installed."
    fi
}

# Install Tailscale if not installed
install_tailscale() {
    if ! command_exists tailscale; then
        log "Tailscale not found. Installing Tailscale..."
        
        # Install dependencies
        sudo apt update
        sudo apt install -y curl lsb-release
        
        # Add Tailscale GPG key and repository
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
        
        # Install Tailscale
        sudo apt update
        sudo apt install -y tailscale
        
        # Configure Tailscale to run without sudo
        log "Configuring Tailscale to run without sudo..."
        sudo tailscale set --operator="$USER"
        
        log "Tailscale installed successfully."
    else
        log "Tailscale is already installed."
    fi
}

# Install Cloudflared if not installed
install_cloudflared() {
    if ! command_exists cloudflared; then
        log "Cloudflared not found. Installing Cloudflared..."
        
        # Download and install Cloudflared
        cd /tmp
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared-linux-amd64.deb
        sudo apt-get install -f -y
        
        # Create directory for cloudflared config
        mkdir -p "$HOME/.cloudflared"
        
        log "Cloudflared installed successfully."
    else
        log "Cloudflared is already installed."
    fi
}

# Enable SSH password authentication
enable_ssh_password_auth() {
    log "Enabling SSH password authentication..."
    
    # Check if SSH server is installed
    if ! command_exists sshd; then
        log "SSH server not found. Installing OpenSSH server..."
        sudo apt update
        sudo apt install -y openssh-server
    fi
    
    # Create a backup of the original configuration
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    
    # Check for configuration in the main sshd_config file
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        sudo cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.backup.$TIMESTAMP"
        sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        log "Updated PasswordAuthentication setting in /etc/ssh/sshd_config"
    fi
    
    # Check for configuration in the sshd_config.d directory
    if [ -d /etc/ssh/sshd_config.d ]; then
        # Find all files containing PasswordAuthentication directive
        CONFIG_FILES=$(grep -l "^PasswordAuthentication no" /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true)
        
        if [ -n "$CONFIG_FILES" ]; then
            for file in $CONFIG_FILES; do
                sudo cp "$file" "$file.backup.$TIMESTAMP"
                sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$file"
                log "Updated PasswordAuthentication setting in $file"
            done
        else
            # If no existing configuration found, create a new one
            log "No existing PasswordAuthentication setting found in config.d directory, creating new one..."
            echo "PasswordAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/99-enable-password-auth.conf > /dev/null
        fi
    else
        # If the directory doesn't exist, update the main config file
        if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
            sudo cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.backup.$TIMESTAMP"
            echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
            log "Added PasswordAuthentication setting to /etc/ssh/sshd_config"
        fi
    fi
    
    # Also ensure KbdInteractiveAuthentication is enabled (needed for Ubuntu 22.04+)
    if grep -q "^KbdInteractiveAuthentication no" /etc/ssh/sshd_config; then
        sudo sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
        log "Updated KbdInteractiveAuthentication setting in /etc/ssh/sshd_config"
    elif ! grep -q "^KbdInteractiveAuthentication" /etc/ssh/sshd_config; then
        echo "KbdInteractiveAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        log "Added KbdInteractiveAuthentication setting to /etc/ssh/sshd_config"
    fi
    
    # Restart SSH service to apply changes
    log "Restarting SSH service to apply changes..."
    sudo systemctl restart ssh
    
    # Verify the changes
    if ssh -o BatchMode=yes -o PasswordAuthentication=yes -o PubkeyAuthentication=no localhost exit 2>/dev/null; then
        log "SSH password authentication has been successfully enabled."
    else
        log "WARNING: SSH password authentication may not be properly configured. Manual verification recommended."
    fi
}

# Clone the repository
clone_repository() {
    REPO_URL="https://github.com/onicarpeso/cftunnel.git"
    TARGET_DIR="$HOME/cftunnel"
    
    log "Cloning repository: $REPO_URL"
    
    if [ -d "$TARGET_DIR" ]; then
        log "Directory $TARGET_DIR already exists. Removing it before cloning..."
        rm -rf "$TARGET_DIR"
    fi
    
    git clone "$REPO_URL" "$TARGET_DIR"
    
    if [ $? -eq 0 ]; then
        log "Repository cloned successfully to $TARGET_DIR"
    else
        log "ERROR: Failed to clone repository."
        exit 1
    fi
}

# Main function
main() {
    log "Starting installation and setup process..."
    
    # Check disk space
    check_disk_space
    
    # Install required packages
    install_git
    install_docker
    install_tailscale
    install_cloudflared
    
    # Enable SSH password authentication
    enable_ssh_password_auth
    
    # Clone the repository
    clone_repository
    
    log "All tasks completed successfully!"
    log "Note: For Docker to work without sudo, you may need to log out and log back in."
    log "SSH password authentication has been enabled. You can now connect using passwords."
}

# Run the main function
main
