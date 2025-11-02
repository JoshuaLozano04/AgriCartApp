# How to Run Redis Server in Bash

## Option 1: Using WSL (Windows Subsystem for Linux)

### 0. Install WSL (if not already installed)

If you don't have WSL installed, follow these steps:

1. **Check if WSL is installed and configured:**
   ```powershell
   wsl --status
   ```
   
   **If you see errors about WSL not being supported:**
   - If it says "Please enable the 'Virtual Machine Platform' optional component", run:
     ```powershell
     wsl.exe --install --no-distribution
     ```
   - This will enable the Virtual Machine Platform and Windows Subsystem for Linux
   - You may need to restart your computer after this step
   - Ensure virtualization is enabled in your BIOS if required
   
   **If WSL is configured but has no distributions:**
   - Proceed to step 2 to install a Linux distribution

2. **List available distributions:**
   ```powershell
   wsl.exe --list --online
   ```

3. **Install WSL with a Linux distribution (Recommended: Ubuntu):**
   ```powershell
   # Install Ubuntu (default/latest version)
   wsl.exe --install Ubuntu
   
   # OR install a specific Ubuntu version
   wsl.exe --install Ubuntu-24.04
   # OR
   wsl.exe --install Ubuntu-22.04
   ```

4. **Set up your Linux distribution:**
   - After installation, you'll be prompted to create a username and password
   - This username will be used for sudo commands later

5. **Verify WSL installation:**
   ```powershell
   wsl --list --verbose
   # Should show your installed distribution
   ```

6. **Set default distribution (if you have multiple):**
   ```powershell
   wsl --set-default Ubuntu
   ```

### 1. Open WSL Terminal
Open WSL from Start Menu or run `wsl` in PowerShell/Command Prompt.

### 2. Install Redis (if not already installed)
```bash
sudo apt-get update
sudo apt-get install redis-server
```

### 3. Start Redis Server
```bash
# Start Redis server in foreground (for testing)
redis-server

# OR start as a service (recommended)
sudo service redis-server start

# OR start with systemd (Ubuntu 20.04+)
sudo systemctl start redis-server
```

### 4. Verify Redis is Running
Open a new terminal and run:
```bash
redis-cli ping
# Should return: PONG
```

### 5. Run Redis in Background (Persistent)
To run Redis as a service that starts automatically:
```bash
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

## Option 2: Using Git Bash (Limited Support)

Git Bash on Windows has limited Redis support. You'll need to:

1. Install Redis for Windows:
   - Download from: https://github.com/microsoftarchive/redis/releases
   - Extract and add to PATH
   - Or use WSL (recommended)

2. Run in Git Bash:
```bash
redis-server
```

## Option 3: Using Docker (Cross-platform)

If you have Docker installed:

```bash
# Pull Redis image
docker pull redis

# Run Redis container
docker run -d -p 6379:6379 --name redis-server redis

# Verify it's running
docker ps

# Stop Redis
docker stop redis-server

# Start Redis
docker start redis-server
```

## Option 4: Windows Native Installation

1. Download Redis for Windows:
   - https://github.com/microsoftarchive/redis/releases
   - Or: https://github.com/tporadowski/redis/releases

2. Extract and run:
   ```bash
   # Navigate to Redis directory
   cd C:\path\to\redis

   # Run server
   redis-server.exe

   # Or run as Windows service (see installation instructions)
   ```

## Quick Start Commands

### Start Redis (One-time)
```bash
redis-server
```

### Start Redis as Service (Linux/WSL)
```bash
sudo systemctl start redis-server
```

### Check if Redis is Running
```bash
redis-cli ping
# Expected output: PONG
```

### Stop Redis
```bash
# If running in foreground: Press Ctrl+C

# If running as service:
sudo systemctl stop redis-server
```

### Check Redis Status
```bash
sudo systemctl status redis-server
```

## Redis Configuration

Default Redis runs on:
- **Host**: localhost
- **Port**: 6379

You can verify this matches your `.env` configuration:
```env
REDIS_URL=redis://localhost:6379/0
```

## Troubleshooting

### WSL Setup Issues

**Error: "WSL2 is not supported with your current machine configuration"**

This means the Virtual Machine Platform needs to be enabled:

1. **Enable Virtual Machine Platform:**
   ```powershell
   wsl.exe --install --no-distribution
   ```
   - Run this command as Administrator (right-click PowerShell → Run as Administrator)
   - Restart your computer when prompted

2. **Enable Virtualization in BIOS (if needed):**
   - Restart your computer and enter BIOS/UEFI settings
   - Look for "Virtualization Technology" or "Intel VT-x" / "AMD-V"
   - Enable it and save settings
   - Restart again

3. **Enable Windows features manually (alternative):**
   ```powershell
   # Run PowerShell as Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
   ```
   - Restart your computer after running these commands

4. **Verify WSL is ready:**
   ```powershell
   wsl --status
   # Should show: Default Version: 2
   ```

**Error: "WSL has no installed distributions"**
- This is normal if you haven't installed a Linux distribution yet
- Proceed to install Ubuntu (see step 3 in WSL installation section)

### Redis won't start
```bash
# Check if Redis is already running
redis-cli ping

# Check Redis logs
sudo tail -f /var/log/redis/redis-server.log

# Check if port 6379 is in use
netstat -an | grep 6379  # Linux/WSL
netstat -an | findstr 6379  # Windows CMD
```

### Permission Denied
```bash
# Run with sudo (Linux/WSL)
sudo redis-server

# Or start as service
sudo systemctl start redis-server
```

### Redis Connection Error in Django
1. Verify Redis is running: `redis-cli ping`
2. Check REDIS_URL in `.env` matches: `redis://localhost:6379/0`
3. Ensure Redis is accessible from your Django app

## Recommended Setup for Development

**WSL (Recommended for Windows):**
```bash
# Install
sudo apt-get update && sudo apt-get install redis-server -y

# Start service
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify
redis-cli ping
```

This way Redis will start automatically when WSL starts.


