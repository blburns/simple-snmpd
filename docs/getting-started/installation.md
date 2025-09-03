# Installation Guide

This guide covers installing Simple SNMP Daemon on various platforms.

## System Requirements

- **Operating Systems**: Linux, macOS, Windows
- **Architecture**: x86_64, ARM64, ARMv7
- **Memory**: Minimum 64MB RAM
- **Disk Space**: 10MB for installation
- **Network**: UDP port 161 (SNMP) and optionally 162 (SNMP traps)

## Installation Methods

### From Source

#### Prerequisites

- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)
- CMake 3.16 or later
- Git

#### Build Steps

```bash
# Clone the repository
git clone https://github.com/simpledaemons/simple-snmpd.git
cd simple-snmpd

# Build the project
make

# Install (requires sudo on Unix systems)
make install
```

### Package Installation

#### Linux (Ubuntu/Debian)

```bash
# Download and install .deb package
wget https://github.com/simpledaemons/simple-snmpd/releases/latest/download/simple-snmpd_0.1.0_amd64.deb
sudo dpkg -i simple-snmpd_0.1.0_amd64.deb
```

#### Linux (CentOS/RHEL)

```bash
# Download and install .rpm package
wget https://github.com/simpledaemons/simple-snmpd/releases/latest/download/simple-snmpd-0.1.0-1.x86_64.rpm
sudo rpm -i simple-snmpd-0.1.0-1.x86_64.rpm
```

#### macOS

```bash
# Download and install .pkg package
curl -L -O https://github.com/simpledaemons/simple-snmpd/releases/latest/download/simple-snmpd-0.1.0-macOS-x86_64.pkg
sudo installer -pkg simple-snmpd-0.1.0-macOS-x86_64.pkg -target /
```

#### Windows

1. Download the MSI installer from the releases page
2. Run the installer as Administrator
3. Follow the installation wizard

### Docker Installation

```bash
# Pull the Docker image
docker pull simpledaemons/simple-snmpd:latest

# Run the container
docker run -d --name simple-snmpd \
  -p 161:161/udp \
  -v /path/to/config:/etc/simple-snmpd \
  simpledaemons/simple-snmpd:latest
```

## Post-Installation

### Verify Installation

```bash
# Check if the daemon is installed
simple-snmpd --version

# Test configuration
simple-snmpd --test-config -c /etc/simple-snmpd/simple-snmpd.conf
```

### Service Setup

#### Linux (systemd)

```bash
# Enable and start the service
sudo systemctl enable simple-snmpd
sudo systemctl start simple-snmpd

# Check status
sudo systemctl status simple-snmpd
```

#### macOS (launchd)

```bash
# Copy the plist file
sudo cp deployment/launchd/com.simpledaemons.simple-snmpd.plist /Library/LaunchDaemons/

# Load and start the service
sudo launchctl load /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
sudo launchctl start com.simpledaemons.simple-snmpd
```

#### Windows

```cmd
# Install as Windows service
sc create "Simple SNMP Daemon" binPath="C:\Program Files\simple-snmpd\simple-snmpd.exe" start=auto

# Start the service
sc start "Simple SNMP Daemon"
```

## Configuration

After installation, configure the daemon by editing the configuration file:

- **Linux/macOS**: `/etc/simple-snmpd/simple-snmpd.conf`
- **Windows**: `C:\Program Files\simple-snmpd\simple-snmpd.conf`

See the [Configuration Guide](../configuration/README.md) for detailed configuration options.

## Next Steps

- [Quick Start Guide](quick-start.md) - Get started quickly
- [Configuration Guide](../configuration/README.md) - Configure the daemon
- [User Guide](../user-guide/README.md) - Complete usage guide
