# User Guide

This comprehensive user guide covers all aspects of using Simple SNMP Daemon, from basic setup to advanced configuration and troubleshooting.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Service Management](#service-management)
5. [SNMP Operations](#snmp-operations)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Security](#security)
8. [Performance Tuning](#performance-tuning)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Features](#advanced-features)

## Getting Started

### What is Simple SNMP Daemon?

Simple SNMP Daemon is a lightweight, cross-platform SNMP agent that provides essential SNMP monitoring capabilities. It's designed for simplicity, security, and ease of use while maintaining enterprise-grade features.

### Key Features

- **SNMP v1/v2c/v3 Support**: Full support for all major SNMP versions
- **Cross-Platform**: Runs on Linux, macOS, and Windows
- **Easy Configuration**: Simple INI-style configuration files
- **Built-in Monitoring**: System resource monitoring out of the box
- **Extensible**: Support for custom MIBs and OIDs
- **Docker Ready**: Containerized deployment support
- **Service Integration**: Native systemd, launchd, and Windows service support

### Quick Start

1. **Install** the daemon
2. **Configure** basic settings
3. **Start** the service
4. **Test** SNMP connectivity

```bash
# Install (example for Linux)
sudo apt-get install simple-snmpd

# Configure
sudo cp /etc/simple-snmpd/simple-snmpd.conf.example /etc/simple-snmpd/simple-snmpd.conf

# Start
sudo systemctl start simple-snmpd

# Test
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0
```

## Installation

### System Requirements

#### Minimum Requirements
- **CPU**: 1 core
- **Memory**: 128 MB RAM
- **Disk**: 50 MB free space
- **Network**: UDP port 161 available

#### Recommended Requirements
- **CPU**: 2+ cores
- **Memory**: 512 MB RAM
- **Disk**: 1 GB free space
- **Network**: UDP ports 161 and 162 available

### Supported Platforms

#### Linux
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 9, 10, 11, 12
- **RHEL/CentOS**: 7, 8, 9
- **Fedora**: 35, 36, 37, 38
- **SUSE**: openSUSE Leap, SLES
- **Arch Linux**: All versions

#### macOS
- **macOS**: 10.15, 11, 12, 13, 14

#### Windows
- **Windows**: 7, 8, 10, 11
- **Windows Server**: 2008 R2, 2012, 2016, 2019, 2022

### Installation Methods

#### Package Installation

##### Debian/Ubuntu
```bash
# Add repository (if available)
wget -qO - https://packages.simpledaemons.org/key.gpg | sudo apt-key add -
echo "deb https://packages.simpledaemons.org/debian stable main" | sudo tee /etc/apt/sources.list.d/simpledaemons.list

# Install
sudo apt-get update
sudo apt-get install simple-snmpd
```

##### RHEL/CentOS/Fedora
```bash
# Add repository (if available)
sudo dnf config-manager --add-repo https://packages.simpledaemons.org/rpm/simpledaemons.repo

# Install
sudo dnf install simple-snmpd
```

##### macOS
```bash
# Using Homebrew
brew install simple-snmpd

# Using MacPorts
sudo port install simple-snmpd
```

##### Windows
```cmd
# Download and run installer
simple-snmpd-setup.exe

# Or use Chocolatey
choco install simple-snmpd
```

#### Source Installation

##### Prerequisites
```bash
# Linux
sudo apt-get install build-essential cmake pkg-config libssl-dev libjsoncpp-dev libsnmp-dev

# macOS
brew install cmake pkg-config openssl jsoncpp net-snmp

# Windows
# Install Visual Studio with C++ tools
```

##### Build and Install
```bash
# Clone repository
git clone https://github.com/simpledaemons/simple-snmpd.git
cd simple-snmpd

# Build
mkdir build && cd build
cmake ..
make -j$(nproc)

# Install
sudo make install
```

#### Docker Installation
```bash
# Pull image
docker pull simpledaemons/simple-snmpd:latest

# Run container
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  simpledaemons/simple-snmpd:latest
```

## Configuration

### Configuration File Location

| Platform | Default Location |
|----------|------------------|
| Linux | `/etc/simple-snmpd/simple-snmpd.conf` |
| macOS | `/usr/local/etc/simple-snmpd/simple-snmpd.conf` |
| Windows | `%ProgramData%\Simple-SNMPd\simple-snmpd.conf` |

### Basic Configuration

#### Minimal Configuration
```ini
# Minimal working configuration
listen_address = 127.0.0.1
listen_port = 161
snmp_version = 2c
community_string = public
log_level = info
```

#### Development Configuration
```ini
# Development configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = dev_community
log_level = debug
enable_console_logging = true
enable_packet_logging = true
```

#### Production Configuration
```ini
# Production configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = secure_production_community
read_community = readonly_production
write_community = write_production

# Security
enable_authentication = true
allowed_networks = 192.168.1.0/24,10.0.0.0/8
enable_rate_limiting = true

# Logging
log_level = info
log_rotation = true
max_log_size = 100MB
max_log_files = 10

# Performance
worker_threads = 8
enable_statistics = true
enable_response_cache = true
```

### Configuration Validation

#### Test Configuration
```bash
# Test configuration file
simple-snmpd --config-test

# Test with specific file
simple-snmpd --config-test --config /path/to/config.conf
```

#### Configuration Summary
```bash
# Show configuration summary
simple-snmpd --config-summary
```

## Service Management

### Linux (systemd)

#### Start Service
```bash
sudo systemctl start simple-snmpd
```

#### Stop Service
```bash
sudo systemctl stop simple-snmpd
```

#### Restart Service
```bash
sudo systemctl restart simple-snmpd
```

#### Enable Auto-Start
```bash
sudo systemctl enable simple-snmpd
```

#### Check Status
```bash
sudo systemctl status simple-snmpd
```

#### View Logs
```bash
sudo journalctl -u simple-snmpd -f
```

### Linux (init.d)

#### Start Service
```bash
sudo service simple-snmpd start
```

#### Stop Service
```bash
sudo service simple-snmpd stop
```

#### Restart Service
```bash
sudo service simple-snmpd restart
```

#### Check Status
```bash
sudo service simple-snmpd status
```

### macOS (launchd)

#### Start Service
```bash
sudo launchctl start com.simpledaemons.simple-snmpd
```

#### Stop Service
```bash
sudo launchctl stop com.simpledaemons.simple-snmpd
```

#### Load Service
```bash
sudo launchctl load /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
```

#### Unload Service
```bash
sudo launchctl unload /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
```

### Windows

#### Start Service
```cmd
net start SimpleSnmpd
```

#### Stop Service
```cmd
net stop SimpleSnmpd
```

#### Check Status
```cmd
sc query SimpleSnmpd
```

#### Using Management Scripts
```cmd
# Batch script
install-service.bat start
install-service.bat stop
install-service.bat status

# PowerShell script
.\install-service.ps1 start
.\install-service.ps1 stop
.\install-service.ps1 status
```

## SNMP Operations

### SNMP Versions

#### SNMPv1
```ini
snmp_version = 1
community_string = public
```

#### SNMPv2c
```ini
snmp_version = 2c
community_string = public
read_community = public
write_community = private
```

#### SNMPv3
```ini
snmp_version = 3
enable_v3 = true
v3_user_database = /etc/simple-snmpd/v3-users.conf
```

### Common SNMP Operations

#### GET Request
```bash
# Get system description
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Get system uptime
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.3.0

# Get system name
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.5.0
```

#### WALK Request
```bash
# Walk system MIB
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.1

# Walk interface MIB
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2
```

#### SET Request
```bash
# Set system name (requires write community)
snmpset -v2c -c private localhost 1.3.6.1.2.1.1.5.0 s "New Server Name"
```

### Standard MIB Objects

#### System Information
| OID | Description | Example |
|-----|-------------|---------|
| 1.3.6.1.2.1.1.1.0 | System Description | "Simple SNMP Daemon" |
| 1.3.6.1.2.1.1.2.0 | System Object ID | "1.3.6.1.4.1.99999.1" |
| 1.3.6.1.2.1.1.3.0 | System Uptime | "1234567" |
| 1.3.6.1.2.1.1.4.0 | System Contact | "admin@example.com" |
| 1.3.6.1.2.1.1.5.0 | System Name | "My Server" |
| 1.3.6.1.2.1.1.6.0 | System Location | "Data Center" |

#### Interface Information
| OID | Description | Example |
|-----|-------------|---------|
| 1.3.6.1.2.1.2.2.1.2 | Interface Description | "eth0" |
| 1.3.6.1.2.1.2.2.1.3 | Interface Type | "6" (ethernet) |
| 1.3.6.1.2.1.2.2.1.5 | Interface Speed | "1000000000" |
| 1.3.6.1.2.1.2.2.1.8 | Interface Status | "1" (up) |

## Monitoring and Logging

### Log Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| debug | Detailed debugging information | Development |
| info | General information messages | Production |
| warn | Warning messages | Production |
| error | Error messages | Production |
| fatal | Fatal error messages | Production |

### Log Configuration

#### Basic Logging
```ini
log_level = info
log_file = /var/log/simple-snmpd/simple-snmpd.log
error_log_file = /var/log/simple-snmpd/simple-snmpd.error.log
```

#### Advanced Logging
```ini
log_level = info
log_file = /var/log/simple-snmpd/simple-snmpd.log
error_log_file = /var/log/simple-snmpd/simple-snmpd.error.log
log_rotation = true
max_log_size = 100MB
max_log_files = 10
log_format = "[%Y-%m-%d %H:%M:%S] [%L] [%T] %M"
```

#### Debug Logging
```ini
log_level = debug
log_file = /var/log/simple-snmpd/debug.log
enable_console_logging = true
enable_packet_logging = true
packet_log_file = /var/log/simple-snmpd/packets.log
```

### Log Rotation

#### Automatic Log Rotation
```ini
log_rotation = true
max_log_size = 100MB
max_log_files = 10
log_rotation_time = daily
```

#### Manual Log Rotation
```bash
# Rotate logs manually
sudo kill -USR1 $(pidof simple-snmpd)
```

### Statistics

#### Enable Statistics
```ini
enable_statistics = true
stats_interval = 60
```

#### View Statistics
```bash
# Dump statistics
sudo kill -USR2 $(pidof simple-snmpd)

# View statistics file
cat /var/lib/simple-snmpd/statistics.json
```

## Security

### Community String Security

#### Strong Community Strings
```ini
# Use strong, non-default community strings
community_string = $(openssl rand -hex 16)
read_community = $(openssl rand -hex 16)
write_community = $(openssl rand -hex 16)
```

#### Community String Validation
```ini
require_community = true
validate_community = true
case_sensitive_community = true
```

### Network Security

#### Access Control
```ini
# Restrict access to specific networks
allowed_networks = 192.168.1.0/24,10.0.0.0/8
denied_networks = 0.0.0.0/0
```

#### Rate Limiting
```ini
enable_rate_limiting = true
rate_limit_requests = 1000
rate_limit_window = 60
rate_limit_burst = 10
```

### SNMPv3 Security

#### User Configuration
```ini
# SNMPv3 configuration
enable_v3 = true
v3_user_database = /etc/simple-snmpd/v3-users.conf
v3_default_security_level = authPriv
v3_default_auth_protocol = SHA256
v3_default_priv_protocol = AES256
```

#### User Database
```ini
# /etc/simple-snmpd/v3-users.conf
# Format: username:auth_protocol:auth_password:priv_protocol:priv_password
admin:SHA256:adminpass:AES256:privpass
readonly:SHA256:readpass::
```

### Firewall Configuration

#### Linux (iptables)
```bash
# Allow SNMP from specific networks
sudo iptables -A INPUT -p udp --dport 161 -s 192.168.1.0/24 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 161 -s 10.0.0.0/8 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 161 -j DROP
```

#### Linux (ufw)
```bash
# Allow SNMP from specific networks
sudo ufw allow from 192.168.1.0/24 to any port 161
sudo ufw allow from 10.0.0.0/8 to any port 161
```

#### Windows
```cmd
# Configure Windows Firewall
configure-firewall.bat add
```

## Performance Tuning

### Thread Configuration

#### CPU-Based Threading
```ini
# Set worker threads based on CPU cores
worker_threads = 4  # For 4-core system
```

#### Memory-Based Threading
```ini
# Conservative threading for memory-constrained systems
worker_threads = 2
max_connections = 100
```

### Connection Management

#### High-Performance Configuration
```ini
max_connections = 10000
connection_timeout = 30
enable_connection_pooling = true
connection_pool_size = 1000
```

#### Memory-Optimized Configuration
```ini
max_connections = 1000
connection_timeout = 60
enable_connection_pooling = true
connection_pool_size = 100
```

### Caching

#### Response Caching
```ini
enable_response_cache = true
response_cache_size = 10000
response_cache_timeout = 300
```

#### MIB Caching
```ini
enable_mib_loading = true
mib_cache_size = 1000
mib_cache_timeout = 300
```

### System Optimization

#### Kernel Parameters (Linux)
```bash
# /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.ipv4.udp_mem = 102400 873800 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
```

#### Apply Changes
```bash
sudo sysctl -p
```

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
sudo systemctl status simple-snmpd

# Check logs
sudo journalctl -u simple-snmpd -f

# Check configuration
simple-snmpd --config-test
```

#### SNMP Queries Fail
```bash
# Check port binding
netstat -tulpn | grep :161

# Test local connectivity
snmpget -v2c -c public 127.0.0.1 1.3.6.1.2.1.1.1.0

# Check firewall
sudo ufw status
sudo iptables -L
```

#### Permission Issues
```bash
# Check file permissions
ls -la /etc/simple-snmpd/
ls -la /var/log/simple-snmpd/

# Fix permissions
sudo chown -R snmp:snmp /etc/simple-snmpd/
sudo chown -R snmp:snmp /var/log/simple-snmpd/
```

### Debug Mode

#### Enable Debug Logging
```bash
# Run with debug logging
simple-snmpd --foreground --log-level debug --enable-console-logging
```

#### Packet Logging
```bash
# Enable packet logging
simple-snmpd --enable-packet-logging --packet-log-file /tmp/packets.log
```

### Health Checks

#### HTTP Health Check
```bash
# Configure health check endpoint
curl http://localhost:8080/health
```

#### SNMP Health Check
```bash
# SNMP-based health check
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.3.0
```

## Advanced Features

### Custom MIBs

#### Load Custom MIBs
```ini
enable_mib_loading = true
mib_directory = /usr/share/snmp/mibs
custom_mibs = CUSTOM-MIB.txt,ENTERPRISE-MIB.txt
```

#### Custom OID Support
```ini
enable_custom_oids = true
custom_oid_file = /etc/simple-snmpd/custom-oids.conf
```

### Trap Configuration

#### Basic Trap Setup
```ini
enable_traps = true
trap_port = 162
trap_community = public
trap_destinations = 192.168.1.100,192.168.1.101
```

#### Advanced Trap Configuration
```ini
enable_traps = true
trap_port = 162
trap_community = trap_community
trap_destinations = 192.168.1.100:162,192.168.1.101:162
trap_retry_count = 5
trap_timeout = 10
enable_trap_authentication = true
```

### Monitoring Integration

#### Prometheus Integration
```ini
enable_metrics = true
metrics_endpoint = /metrics
metrics_port = 8080
metrics_format = prometheus
```

#### Grafana Integration
```ini
enable_metrics = true
metrics_endpoint = /metrics
metrics_port = 8080
enable_health_check = true
health_check_endpoint = /health
```

### Backup and Recovery

#### Configuration Backup
```ini
enable_config_backup = true
backup_interval = 86400
backup_directory = /var/backups/simple-snmpd
max_backup_files = 7
```

#### Manual Backup
```bash
# Backup configuration
tar -czf simple-snmpd-config-$(date +%Y%m%d).tar.gz /etc/simple-snmpd/

# Restore configuration
tar -xzf simple-snmpd-config-20240101.tar.gz -C /
```

## Best Practices

### General Best Practices

1. **Use Configuration Files**: Prefer configuration files over command line options
2. **Test Configuration**: Always test configuration before deploying
3. **Monitor Logs**: Regularly check logs for errors and warnings
4. **Keep Updated**: Keep the daemon and dependencies updated
5. **Document Changes**: Document all configuration changes

### Security Best Practices

1. **Use Strong Community Strings**: Avoid default community strings
2. **Enable Access Control**: Use `allowed_networks` to restrict access
3. **Use SNMPv3**: Use SNMPv3 for secure environments
4. **Enable Rate Limiting**: Prevent abuse with rate limiting
5. **Regular Security Audits**: Regularly audit security configurations

### Performance Best Practices

1. **Optimize Thread Count**: Set worker threads based on CPU cores
2. **Enable Caching**: Use response caching for frequently accessed data
3. **Monitor Memory**: Set appropriate memory limits
4. **Log Rotation**: Enable log rotation to prevent disk space issues
5. **Regular Monitoring**: Monitor performance metrics regularly

### Operational Best Practices

1. **Configuration Backup**: Enable automatic configuration backup
2. **Health Monitoring**: Enable health checks for monitoring systems
3. **Comprehensive Logging**: Use appropriate log levels
4. **Documentation**: Document all custom configurations
5. **Testing**: Test changes in development before production

## Getting Help

### Documentation
- **Configuration Guide**: [Configuration Guide](../configuration/README.md)
- **CLI Reference**: [CLI Reference](cli.md)
- **Examples**: [Configuration Examples](../examples/README.md)
- **Troubleshooting**: [Troubleshooting Guide](../troubleshooting/README.md)

### Support
- **GitHub Issues**: [GitHub Issues](https://github.com/simpledaemons/simple-snmpd/issues)
- **Documentation**: [Documentation](https://docs.simpledaemons.org)
- **Community**: [Community Forum](https://community.simpledaemons.org)

### Professional Support
- **Enterprise Support**: [Enterprise Support](https://simpledaemons.org/support)
- **Consulting**: [Professional Services](https://simpledaemons.org/services)
- **Training**: [Training Programs](https://simpledaemons.org/training)

## License

Simple SNMP Daemon is licensed under the Apache License, Version 2.0. See the LICENSE file for details.
