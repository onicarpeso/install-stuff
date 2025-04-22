create a github README file for this script

# Ubuntu DevOps Toolkit Installer

A comprehensive, production-ready script for Ubuntu 24.04 that automatically sets up essential development and networking tools with proper error handling.

## Features

This script automatically:

- ✅ Checks for sufficient disk space before installation
- ✅ Installs and configures Git, Docker, Tailscale, and Cloudflared
- ✅ Enables SSH password authentication
- ✅ Configures tools to run without sudo privileges
- ✅ Clones a specified repository
- ✅ Provides detailed logging throughout the process

## Prerequisites

- Ubuntu 24.04 LTS
- Sudo privileges
- Internet connection

## Installation

1. Clone this repository or download the script:

```bash
wget https://raw.githubusercontent.com/yourusername/ubuntu-devops-toolkit/main/setup.sh
```

2. Make the script executable:

```bash
chmod +x setup.sh
```

3. Run the script:

```bash
./setup.sh
```

## What the Script Does

### 1. Disk Space Check
Verifies that you have at least 5GB of free disk space to ensure smooth installation.

### 2. Git Installation
- Installs Git if not already present
- Configures basic user information

### 3. Docker Installation
- Installs Docker Engine and CLI tools
- Adds your user to the Docker group so you can run Docker without sudo

### 4. Tailscale Installation
- Installs Tailscale VPN client
- Configures user permissions for Tailscale operation

### 5. Cloudflared Installation
- Installs Cloudflare Tunnel client
- Sets up user-specific configuration directory

### 6. SSH Password Authentication
- Installs OpenSSH server if not present
- Enables password-based authentication
- Configures keyboard-interactive authentication
- Creates backups of any modified configuration files

### 7. Repository Cloning
- Clones the specified GitHub repository (https://github.com/onicarpeso/cftunnel.git)
- Places it in your home directory

## Error Handling

The script includes robust error handling:
- Exits immediately if any command fails
- Provides clear error messages
- Creates backups before modifying system files

## Security Considerations

While this script enables password authentication for SSH, please be aware of the security implications:

- Password authentication is generally less secure than key-based authentication
- Consider implementing additional security measures:
  - Strong passwords
  - Fail2ban to prevent brute force attacks
  - IP-based access restrictions

## After Installation

After running the script:

1. **For Docker**: You may need to log out and log back in for the Docker group membership to take effect.

2. **For SSH**: Password authentication will be immediately available.

3. **For Tailscale**: You'll need to authenticate with `tailscale up` to connect to your Tailscale network.

4. **For Cloudflared**: Additional configuration may be required to set up specific tunnels.

## Troubleshooting

If you encounter any issues:

1. Check the script output for specific error messages
2. Verify your internet connection
3. Ensure you have sudo privileges
4. For SSH configuration issues, check the backup files created in `/etc/ssh/`

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

