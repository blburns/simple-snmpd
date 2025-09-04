# Command Line Interface Reference

This document provides comprehensive documentation for the Simple SNMP Daemon command line interface.

## Overview

Simple SNMP Daemon provides a command line interface for configuration, testing, and management. The CLI supports various options for different use cases and environments.

## Basic Usage

```bash
simple-snmpd [OPTIONS]
```

## Command Line Options

### General Options

#### `-h, --help`
Display help information and exit.

```bash
simple-snmpd --help
```

#### `-v, --version`
Display version information and exit.

```bash
simple-snmpd --version
```

#### `-c, --config FILE`
Specify configuration file path.

```bash
simple-snmpd --config /etc/simple-snmpd/simple-snmpd.conf
```

#### `-d, --daemon`
Run as daemon (background process).

```bash
simple-snmpd --daemon
```

#### `-f, --foreground`
Run in foreground (default for testing).

```bash
simple-snmpd --foreground
```

### Configuration Options

#### `--config-test`
Test configuration file syntax and exit.

```bash
simple-snmpd --config-test
simple-snmpd --config-test --config /path/to/config.conf
```

#### `--config-summary`
Display configuration summary and exit.

```bash
simple-snmpd --config-summary
```

#### `--config-validate`
Validate configuration file and dependencies.

```bash
simple-snmpd --config-validate
```

### Service Options

#### `--service`
Run as system service (Windows only).

```bash
simple-snmpd --service
```

#### `--console`
Run in console mode (Windows only).

```bash
simple-snmpd --console
```

### Logging Options

#### `-l, --log-level LEVEL`
Set log level (debug, info, warn, error, fatal).

```bash
simple-snmpd --log-level debug
simple-snmpd --log-level info
```

#### `--log-file FILE`
Specify log file path.

```bash
simple-snmpd --log-file /var/log/simple-snmpd/simple-snmpd.log
```

#### `--enable-console-logging`
Enable console logging.

```bash
simple-snmpd --enable-console-logging
```

#### `--disable-console-logging`
Disable console logging.

```bash
simple-snmpd --disable-console-logging
```

### Network Options

#### `--listen-address ADDRESS`
Set listen address.

```bash
simple-snmpd --listen-address 0.0.0.0
simple-snmpd --listen-address 127.0.0.1
```

#### `--listen-port PORT`
Set listen port.

```bash
simple-snmpd --listen-port 161
```

#### `--enable-ipv6`
Enable IPv6 support.

```bash
simple-snmpd --enable-ipv6
```

#### `--disable-ipv6`
Disable IPv6 support.

```bash
simple-snmpd --disable-ipv6
```

### SNMP Options

#### `--snmp-version VERSION`
Set SNMP version (1, 2c, 3).

```bash
simple-snmpd --snmp-version 2c
```

#### `--community-string STRING`
Set community string.

```bash
simple-snmpd --community-string public
```

#### `--read-community STRING`
Set read-only community string.

```bash
simple-snmpd --read-community readonly
```

#### `--write-community STRING`
Set read-write community string.

```bash
simple-snmpd --write-community write
```

### Performance Options

#### `--worker-threads COUNT`
Set number of worker threads.

```bash
simple-snmpd --worker-threads 4
```

#### `--max-connections COUNT`
Set maximum number of connections.

```bash
simple-snmpd --max-connections 1000
```

#### `--enable-statistics`
Enable statistics collection.

```bash
simple-snmpd --enable-statistics
```

#### `--disable-statistics`
Disable statistics collection.

```bash
simple-snmpd --disable-statistics
```

### Debug Options

#### `--debug`
Enable debug mode.

```bash
simple-snmpd --debug
```

#### `--verbose`
Enable verbose output.

```bash
simple-snmpd --verbose
```

#### `--dry-run`
Perform a dry run (don't start the daemon).

```bash
simple-snmpd --dry-run
```

#### `--test-mode`
Run in test mode.

```bash
simple-snmpd --test-mode
```

## Environment Variables

Simple SNMP Daemon can be configured using environment variables:

### Network Configuration
```bash
export SNMP_LISTEN_ADDRESS=0.0.0.0
export SNMP_LISTEN_PORT=161
export SNMP_ENABLE_IPV6=true
```

### SNMP Configuration
```bash
export SNMP_VERSION=2c
export SNMP_COMMUNITY=public
export SNMP_READ_COMMUNITY=readonly
export SNMP_WRITE_COMMUNITY=write
```

### Logging Configuration
```bash
export SNMP_LOG_LEVEL=info
export SNMP_LOG_FILE=/var/log/simple-snmpd/simple-snmpd.log
export SNMP_ENABLE_CONSOLE_LOGGING=false
```

### System Configuration
```bash
export SNMP_SYSTEM_NAME="My Server"
export SNMP_SYSTEM_DESCRIPTION="Simple SNMP Daemon"
export SNMP_SYSTEM_CONTACT="admin@example.com"
export SNMP_SYSTEM_LOCATION="Data Center"
```

### Performance Configuration
```bash
export SNMP_WORKER_THREADS=4
export SNMP_MAX_CONNECTIONS=1000
export SNMP_ENABLE_STATISTICS=true
```

## Configuration File Override

Command line options override configuration file settings:

```bash
# Configuration file sets community to "public"
# Command line overrides to "secure"
simple-snmpd --config /etc/simple-snmpd/simple-snmpd.conf --community-string secure
```

## Common Usage Patterns

### Development and Testing
```bash
# Run in foreground with debug logging
simple-snmpd --foreground --log-level debug --enable-console-logging

# Test configuration
simple-snmpd --config-test --config /path/to/config.conf

# Dry run to check configuration
simple-snmpd --dry-run --config /path/to/config.conf
```

### Production Deployment
```bash
# Run as daemon with production configuration
simple-snmpd --daemon --config /etc/simple-snmpd/simple-snmpd.conf

# Run with specific log file
simple-snmpd --daemon --log-file /var/log/simple-snmpd/simple-snmpd.log --log-level info
```

### Service Management
```bash
# Windows service mode
simple-snmpd --service

# Windows console mode
simple-snmpd --console
```

### Custom Network Configuration
```bash
# Listen on specific interface
simple-snmpd --listen-address 192.168.1.100 --listen-port 161

# Enable IPv6
simple-snmpd --enable-ipv6 --listen-address ::1
```

### Performance Tuning
```bash
# High-performance configuration
simple-snmpd --worker-threads 8 --max-connections 10000 --enable-statistics

# Memory-optimized configuration
simple-snmpd --worker-threads 2 --max-connections 100
```

## Exit Codes

Simple SNMP Daemon returns the following exit codes:

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Network error |
| 4 | Permission error |
| 5 | Resource error |
| 6 | Service error |

## Signal Handling

Simple SNMP Daemon handles the following signals:

### SIGTERM
Graceful shutdown request.

```bash
kill -TERM <pid>
```

### SIGINT
Interrupt signal (Ctrl+C).

```bash
kill -INT <pid>
```

### SIGHUP
Reload configuration.

```bash
kill -HUP <pid>
```

### SIGUSR1
Rotate log files.

```bash
kill -USR1 <pid>
```

### SIGUSR2
Dump statistics.

```bash
kill -USR2 <pid>
```

## Examples

### Basic Examples

#### Start with default configuration
```bash
simple-snmpd
```

#### Start with custom configuration
```bash
simple-snmpd --config /etc/simple-snmpd/simple-snmpd.conf
```

#### Start as daemon
```bash
simple-snmpd --daemon --config /etc/simple-snmpd/simple-snmpd.conf
```

### Configuration Examples

#### Test configuration file
```bash
simple-snmpd --config-test --config /etc/simple-snmpd/simple-snmpd.conf
```

#### Show configuration summary
```bash
simple-snmpd --config-summary --config /etc/simple-snmpd/simple-snmpd.conf
```

#### Validate configuration
```bash
simple-snmpd --config-validate --config /etc/simple-snmpd/simple-snmpd.conf
```

### Network Examples

#### Listen on all interfaces
```bash
simple-snmpd --listen-address 0.0.0.0 --listen-port 161
```

#### Listen on specific interface
```bash
simple-snmpd --listen-address 192.168.1.100 --listen-port 161
```

#### Enable IPv6
```bash
simple-snmpd --enable-ipv6 --listen-address ::1
```

### SNMP Examples

#### Set community string
```bash
simple-snmpd --community-string secure_community
```

#### Set different read/write communities
```bash
simple-snmpd --read-community readonly --write-community write
```

#### Use SNMPv3
```bash
simple-snmpd --snmp-version 3
```

### Logging Examples

#### Debug logging
```bash
simple-snmpd --log-level debug --enable-console-logging
```

#### Log to file
```bash
simple-snmpd --log-file /var/log/simple-snmpd/simple-snmpd.log --log-level info
```

#### Verbose output
```bash
simple-snmpd --verbose --log-level debug
```

### Performance Examples

#### High-performance setup
```bash
simple-snmpd --worker-threads 8 --max-connections 10000 --enable-statistics
```

#### Memory-optimized setup
```bash
simple-snmpd --worker-threads 2 --max-connections 100
```

### Debug Examples

#### Debug mode
```bash
simple-snmpd --debug --log-level debug --enable-console-logging
```

#### Dry run
```bash
simple-snmpd --dry-run --config /etc/simple-snmpd/simple-snmpd.conf
```

#### Test mode
```bash
simple-snmpd --test-mode --log-level debug
```

## Troubleshooting

### Common Issues

#### Configuration file not found
```bash
# Check if file exists
ls -la /etc/simple-snmpd/simple-snmpd.conf

# Use absolute path
simple-snmpd --config /absolute/path/to/config.conf
```

#### Permission denied
```bash
# Check file permissions
ls -la /etc/simple-snmpd/simple-snmpd.conf

# Fix permissions
sudo chown snmp:snmp /etc/simple-snmpd/simple-snmpd.conf
sudo chmod 644 /etc/simple-snmpd/simple-snmpd.conf
```

#### Port already in use
```bash
# Check port usage
netstat -tulpn | grep :161
ss -tulpn | grep :161

# Use different port
simple-snmpd --listen-port 1161
```

#### Invalid configuration
```bash
# Test configuration
simple-snmpd --config-test --config /path/to/config.conf

# Check syntax
simple-snmpd --config-validate --config /path/to/config.conf
```

### Debug Commands

#### Enable debug logging
```bash
simple-snmpd --debug --log-level debug --enable-console-logging
```

#### Verbose output
```bash
simple-snmpd --verbose --log-level debug
```

#### Dry run
```bash
simple-snmpd --dry-run --config /path/to/config.conf
```

## Best Practices

### Command Line Best Practices

1. **Use Configuration Files**: Prefer configuration files over command line options for complex setups
2. **Test Configuration**: Always test configuration before deploying
3. **Use Appropriate Log Levels**: Use debug for development, info for production
4. **Set Proper Permissions**: Ensure configuration files have proper permissions
5. **Use Absolute Paths**: Use absolute paths for configuration files

### Security Best Practices

1. **Avoid Default Community Strings**: Never use default community strings in production
2. **Use SNMPv3**: Use SNMPv3 for secure environments
3. **Restrict Network Access**: Use appropriate listen addresses
4. **Regular Updates**: Keep the daemon updated
5. **Monitor Access**: Enable request logging

### Performance Best Practices

1. **Optimize Thread Count**: Set worker threads based on CPU cores
2. **Monitor Memory**: Set appropriate memory limits
3. **Enable Statistics**: Enable statistics for monitoring
4. **Use Caching**: Enable response caching for frequently accessed data
5. **Log Rotation**: Enable log rotation to prevent disk space issues

## Integration with System Services

### systemd Integration
```bash
# Start with systemd
sudo systemctl start simple-snmpd

# Enable auto-start
sudo systemctl enable simple-snmpd

# Check status
sudo systemctl status simple-snmpd
```

### init.d Integration
```bash
# Start with init.d
sudo service simple-snmpd start

# Check status
sudo service simple-snmpd status
```

### Windows Service Integration
```cmd
# Start Windows service
net start SimpleSnmpd

# Check status
sc query SimpleSnmpd
```

## Next Steps

- **Configuration Guide**: See the [Configuration Guide](../configuration/README.md)
- **Examples**: Check out [Configuration Examples](../examples/README.md)
- **Troubleshooting**: See the [Troubleshooting Guide](../troubleshooting/README.md)
- **Support**: Get help from the [Support Guide](../support/README.md)
