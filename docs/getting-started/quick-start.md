# Quick Start Guide

Get Simple SNMP Daemon up and running in minutes.

## Prerequisites

- Simple SNMP Daemon installed (see [Installation Guide](installation.md))
- Basic knowledge of SNMP concepts
- Network access to the target system

## Basic Setup

### 1. Start the Daemon

```bash
# Start with default configuration
sudo simple-snmpd

# Or start with custom config
sudo simple-snmpd -c /path/to/your/config.conf
```

### 2. Test SNMP Queries

From another machine, test basic SNMP queries:

```bash
# Test with snmpwalk (if available)
snmpwalk -v2c -c public localhost

# Test with snmpget (if available)
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0
```

### 3. Verify Service Status

```bash
# Check if daemon is running
ps aux | grep simple-snmpd

# Check listening ports
netstat -ulnp | grep 161
```

## Basic Configuration

Edit `/etc/simple-snmpd/simple-snmpd.conf`:

```ini
# Basic configuration
port=161
community=public
log_level=info
max_connections=100
timeout_seconds=30
```

## Common SNMP Queries

### System Information

```bash
# System description
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# System uptime
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.3.0

# System name
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.5.0
```

### Network Interfaces

```bash
# Interface table
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2.2.1.2

# Interface statistics
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2.2.1.10
```

## Troubleshooting

### Common Issues

1. **Permission denied**: Run with `sudo` or check file permissions
2. **Port already in use**: Check if another SNMP daemon is running
3. **Connection refused**: Verify firewall settings and port configuration

### Debug Mode

```bash
# Run with verbose logging
sudo simple-snmpd -v -c /etc/simple-snmpd/simple-snmpd.conf
```

### Check Logs

```bash
# System logs (Linux)
sudo journalctl -u simple-snmpd -f

# Log files (if configured)
tail -f /var/log/simple-snmpd/simple-snmpd.log
```

## Next Steps

- [Configuration Guide](../configuration/README.md) - Advanced configuration
- [User Guide](../user-guide/README.md) - Complete usage guide
- [Troubleshooting Guide](../troubleshooting/README.md) - Common issues and solutions
