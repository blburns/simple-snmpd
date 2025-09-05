# First Steps with Simple SNMP Daemon

This guide will help you get started with Simple SNMP Daemon after installation. You'll learn the basics of configuration, starting the service, and performing your first SNMP queries.

## Prerequisites

Before following this guide, ensure you have:
- Simple SNMP Daemon installed (see [Installation Guide](installation.md))
- Basic understanding of SNMP concepts
- Access to a terminal/command prompt
- Administrator/root privileges for service management

## Quick Overview

Simple SNMP Daemon is a lightweight SNMP agent that provides:
- **SNMP v1/v2c/v3** support
- **Cross-platform compatibility** (Linux, macOS, Windows)
- **Easy configuration** with simple text files
- **Built-in monitoring** of system resources
- **Extensible MIB support** for custom monitoring

## Step 1: Verify Installation

First, let's verify that Simple SNMP Daemon is properly installed:

### Linux/macOS
```bash
# Check if the binary exists
which simple-snmpd
ls -la /usr/sbin/simple-snmpd

# Check version
simple-snmpd --version
```

### Windows
```cmd
# Check if the service is installed
sc query SimpleSnmpd

# Check version
simple-snmpd.exe --version
```

## Step 2: Initial Configuration

The daemon uses a simple configuration file format. Let's create a basic configuration:

### Configuration File Location
- **Linux/macOS**: `/etc/simple-snmpd/simple-snmpd.conf`
- **Windows**: `%ProgramData%\Simple-SNMPd\simple-snmpd.conf`

### Basic Configuration
Create a minimal configuration file:

```ini
# Basic SNMP Configuration
listen_address = 127.0.0.1
listen_port = 161
snmp_version = 2c
community_string = public
read_community = public
write_community = private

# Logging
log_level = info
log_file = /var/log/simple-snmpd/simple-snmpd.log

# System Information
system_name = My Server
system_description = Simple SNMP Daemon
system_contact = admin@example.com
system_location = Data Center
```

### Configuration Validation
Test your configuration:
```bash
# Linux/macOS
simple-snmpd --config-test

# Windows
simple-snmpd.exe --config-test
```

## Step 3: Start the Service

### Linux/macOS (systemd)
```bash
# Start the service
sudo systemctl start simple-snmpd

# Enable auto-start
sudo systemctl enable simple-snmpd

# Check status
sudo systemctl status simple-snmpd
```

### Linux/macOS (init.d)
```bash
# Start the service
sudo service simple-snmpd start

# Check status
sudo service simple-snmpd status
```

### Windows
```cmd
# Start the service
net start SimpleSnmpd

# Or using the management script
install-service.bat start
```

## Step 4: Verify Service is Running

### Check Process
```bash
# Linux/macOS
ps aux | grep simple-snmpd
netstat -tulpn | grep :161

# Windows
tasklist | findstr simple-snmpd
netstat -an | findstr :161
```

### Check Port Binding
```bash
# Linux/macOS
sudo netstat -tulpn | grep :161
sudo ss -tulpn | grep :161

# Windows
netstat -an | findstr :161
```

## Step 5: Test SNMP Connectivity

### Using snmpget (if available)
```bash
# Test basic connectivity
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test system description
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test system uptime
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.3.0
```

### Using snmpwalk (if available)
```bash
# Walk the system MIB
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.1

# Walk interface information
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2
```

### Using PowerShell (Windows)
```powershell
# Test port connectivity
Test-NetConnection -ComputerName localhost -Port 161

# Test with SNMP tools if available
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0
```

## Step 6: Basic SNMP Queries

### Common SNMP OIDs to Test

| OID | Description | Example |
|-----|-------------|---------|
| `1.3.6.1.2.1.1.1.0` | System Description | "Simple SNMP Daemon" |
| `1.3.6.1.2.1.1.2.0` | System Object ID | "1.3.6.1.4.1.99999.1" |
| `1.3.6.1.2.1.1.3.0` | System Uptime | "1234567" |
| `1.3.6.1.2.1.1.4.0` | System Contact | "admin@example.com" |
| `1.3.6.1.2.1.1.5.0` | System Name | "My Server" |
| `1.3.6.1.2.1.1.6.0` | System Location | "Data Center" |

### Test Commands
```bash
# System information
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.5.0

# System uptime
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.3.0

# Interface information
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2.2.1.2
```

## Step 7: Check Logs

### Linux/macOS
```bash
# Check service logs
sudo journalctl -u simple-snmpd -f

# Check log file
tail -f /var/log/simple-snmpd/simple-snmpd.log

# Check for errors
grep -i error /var/log/simple-snmpd/simple-snmpd.log
```

### Windows
```cmd
# Check Windows Event Log
eventvwr.msc

# Check service logs
type "%ProgramData%\Simple-SNMPd\logs\simple-snmpd.log"
```

## Step 8: Basic Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check configuration
simple-snmpd --config-test

# Check port availability
netstat -tulpn | grep :161

# Check permissions
ls -la /etc/simple-snmpd/
```

#### SNMP Queries Fail
```bash
# Check firewall
sudo ufw status
sudo iptables -L

# Check service status
systemctl status simple-snmpd

# Test local connectivity
snmpget -v2c -c public 127.0.0.1 1.3.6.1.2.1.1.1.0
```

#### Permission Issues
```bash
# Check file permissions
ls -la /var/log/simple-snmpd/
ls -la /etc/simple-snmpd/

# Fix permissions if needed
sudo chown -R snmp:snmp /var/log/simple-snmpd/
sudo chown -R snmp:snmp /etc/simple-snmpd/
```

## Step 9: Next Steps

Now that you have Simple SNMP Daemon running, you can:

1. **Configure Monitoring**: Set up monitoring for specific system resources
2. **Add Custom MIBs**: Extend functionality with custom MIB definitions
3. **Set Up SNMPv3**: Configure secure SNMPv3 authentication
4. **Configure Traps**: Set up SNMP trap notifications
5. **Integrate with Monitoring**: Connect to monitoring systems like Nagios, Zabbix, etc.

## Configuration Examples

### Minimal Configuration
```ini
# Minimal working configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = public
log_level = info
```

### Production Configuration
```ini
# Production-ready configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = secure_community
read_community = readonly_community
write_community = write_community

# Security
enable_authentication = true
allowed_networks = 192.168.1.0/24,10.0.0.0/8

# Logging
log_level = info
log_file = /var/log/simple-snmpd/simple-snmpd.log
log_rotation = true
max_log_size = 10MB

# System Information
system_name = Production Server
system_description = Simple SNMP Daemon - Production
system_contact = admin@company.com
system_location = Production Data Center
```

## Getting Help

If you encounter issues:

1. **Check Logs**: Always check the service logs first
2. **Verify Configuration**: Use `--config-test` to validate configuration
3. **Test Connectivity**: Use `snmpget` to test basic connectivity
4. **Check Documentation**: Refer to the [Configuration Guide](../configuration/README.md)
5. **Troubleshooting**: See the [Troubleshooting Guide](../troubleshooting/README.md)

## What's Next?

- **Configuration Guide**: Learn about all configuration options
- **Deployment Guide**: Set up production deployments
- **User Guide**: Master advanced features
- **Examples**: See real-world configuration examples

Congratulations! You now have Simple SNMP Daemon running and responding to SNMP queries. You're ready to explore more advanced features and configurations.
