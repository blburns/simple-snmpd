# Configuration Guide

This guide provides comprehensive documentation for configuring Simple SNMP Daemon. The daemon uses a simple INI-style configuration file format that's easy to read and modify.

## Configuration File Location

### Default Locations
- **Linux/macOS**: `/etc/simple-snmpd/simple-snmpd.conf`
- **Windows**: `%ProgramData%\Simple-SNMPd\simple-snmpd.conf`

### Custom Location
You can specify a custom configuration file using the `-c` or `--config` option:
```bash
simple-snmpd -c /path/to/custom.conf
```

## Configuration File Format

The configuration file uses an INI-style format with key-value pairs:
```ini
# This is a comment
section_name = value
another_setting = "quoted value with spaces"
```

## Configuration Sections

### Network Configuration

#### Basic Network Settings
```ini
# Network interface to bind to (0.0.0.0 for all interfaces)
listen_address = 0.0.0.0

# SNMP agent port (default: 161)
listen_port = 161

# Enable IPv6 support
enable_ipv6 = true

# Maximum number of concurrent connections
max_connections = 1000

# Connection timeout in seconds
connection_timeout = 30

# Specific network interfaces to bind to (comma-separated)
bind_interfaces = eth0,eth1
```

#### Advanced Network Settings
```ini
# Enable TCP support (non-standard, for testing)
enable_tcp = false
tcp_port = 161

# Socket buffer sizes
receive_buffer_size = 65536
send_buffer_size = 65536

# Enable SO_REUSEADDR
reuse_address = true
```

### SNMP Configuration

#### SNMP Version Settings
```ini
# SNMP version (1, 2c, 3, or all)
snmp_version = 2c

# Default community string for v1/v2c
community_string = public

# Read-only community string
read_community = public

# Read-write community string
write_community = private

# Enable SNMPv3 support
enable_v3 = false
```

#### SNMPv3 Configuration
```ini
# SNMPv3 engine ID (auto-generated if empty)
v3_engine_id =

# SNMPv3 user database file
v3_user_database = %CONFIG_DIR%/v3-users.conf

# Default security level (noAuthNoPriv, authNoPriv, authPriv)
v3_default_security_level = noAuthNoPriv

# Default authentication protocol (MD5, SHA, SHA224, SHA256, SHA384, SHA512)
v3_default_auth_protocol = MD5

# Default privacy protocol (DES, AES, AES192, AES256)
v3_default_priv_protocol = DES
```

### Security Configuration

#### Access Control
```ini
# Enable authentication
enable_authentication = false

# Authentication protocol (MD5, SHA, SHA224, SHA256, SHA384, SHA512)
authentication_protocol = MD5

# Privacy protocol (DES, AES, AES192, AES256)
privacy_protocol = DES

# User database file
user_database = %CONFIG_DIR%/users.conf

# Access control file
access_control = %CONFIG_DIR%/access.conf

# Allowed networks (CIDR notation, comma-separated)
allowed_networks = 192.168.1.0/24,10.0.0.0/8

# Denied networks (CIDR notation, comma-separated)
denied_networks = 0.0.0.0/0

# Enable rate limiting
enable_rate_limiting = false
rate_limit_requests = 100
rate_limit_window = 60
rate_limit_burst = 10
```

#### Community String Security
```ini
# Require community strings for all requests
require_community = true

# Community string validation
validate_community = true

# Case-sensitive community strings
case_sensitive_community = false
```

### MIB Configuration

#### MIB Management
```ini
# MIB directory path
mib_directory = %MIB_DIR%

# Enable MIB loading
enable_mib_loading = true

# MIB cache size
mib_cache_size = 1000

# MIB cache timeout in seconds
mib_cache_timeout = 300

# Custom MIB files (comma-separated)
custom_mibs = CUSTOM-MIB.txt,ENTERPRISE-MIB.txt

# Enable MIB validation
validate_mibs = true
```

#### Standard MIBs
```ini
# Enable standard MIB tables
enable_if_table = true
enable_ip_table = false
enable_tcp_table = false
enable_udp_table = false
enable_route_table = false

# Interface table configuration
if_table_poll_interval = 30
if_table_cache_timeout = 300
```

### Logging Configuration

#### Basic Logging
```ini
# Log level (debug, info, warn, error, fatal)
log_level = info

# Log file path
log_file = %LOG_DIR%/simple-snmpd.log

# Error log file path
error_log_file = %LOG_DIR%/simple-snmpd.error.log

# Enable console logging (for debugging)
enable_console_logging = false

# Enable syslog integration
enable_syslog = false
syslog_facility = daemon
```

#### Advanced Logging
```ini
# Log rotation
log_rotation = true
max_log_size = 10MB
max_log_files = 5
log_rotation_time = daily

# Log format
log_format = "[%Y-%m-%d %H:%M:%S] [%L] [%T] %M"

# Enable packet logging (for debugging)
enable_packet_logging = false
packet_log_file = %LOG_DIR%/packets.log

# Log SNMP requests
log_requests = true
log_responses = false
```

### Performance Configuration

#### Threading and Concurrency
```ini
# Number of worker threads
worker_threads = 4

# Maximum packet size
max_packet_size = 65507

# Enable statistics collection
enable_statistics = true

# Statistics collection interval in seconds
stats_interval = 60

# Cache timeout in seconds
cache_timeout = 300

# Memory limit (0 = unlimited)
memory_limit = 0

# CPU limit (0 = unlimited)
cpu_limit = 0
```

#### Optimization Settings
```ini
# Enable connection pooling
enable_connection_pooling = true
connection_pool_size = 100

# Enable response caching
enable_response_cache = true
response_cache_size = 1000
response_cache_timeout = 60

# Enable bulk operations
enable_bulk_operations = true
max_bulk_size = 10
```

### SNMP Agent Configuration

#### System Information
```ini
# System name
system_name = Simple SNMP Daemon

# System description
system_description = Simple SNMP Daemon - Lightweight SNMP Agent

# System contact
system_contact = admin@example.com

# System location
system_location = Data Center

# System uptime tracking
system_uptime = true

# System Object ID
system_oid = 1.3.6.1.4.1.99999.1
```

#### Agent Behavior
```ini
# Enable agent statistics
enable_agent_stats = true

# Agent statistics interval
agent_stats_interval = 60

# Enable SNMP error reporting
enable_error_reporting = true

# SNMP error log file
error_log_file = %LOG_DIR%/snmp-errors.log
```

### Trap Configuration

#### Basic Trap Settings
```ini
# Enable SNMP traps
enable_traps = true

# Trap port
trap_port = 162

# Trap community string
trap_community = public

# Trap destinations (comma-separated)
trap_destinations = 192.168.1.100,192.168.1.101

# Trap retry count
trap_retry_count = 3

# Trap timeout in seconds
trap_timeout = 5
```

#### Advanced Trap Settings
```ini
# Enable trap authentication
trap_authentication = false

# Trap authentication protocol
trap_auth_protocol = MD5

# Trap privacy protocol
trap_priv_protocol = DES

# Trap user database
trap_user_database = %CONFIG_DIR%/trap-users.conf

# Enable trap logging
enable_trap_logging = true
trap_log_file = %LOG_DIR%/traps.log
```

### Monitoring Configuration

#### System Monitoring
```ini
# Enable system monitoring
enable_system_monitoring = true

# System monitoring interval in seconds
monitoring_interval = 60

# Data collection interval in seconds
collect_interval = 30

# Enable CPU monitoring
enable_cpu_monitoring = true

# Enable memory monitoring
enable_memory_monitoring = true

# Enable disk monitoring
enable_disk_monitoring = true

# Enable network interface monitoring
enable_network_interface_monitoring = true
```

#### Process and Service Monitoring
```ini
# Enable process monitoring
enable_process_monitoring = false

# Monitored processes (comma-separated)
monitored_processes = sshd,nginx,mysql

# Process check interval in seconds
process_check_interval = 60

# Enable service monitoring
enable_service_monitoring = false

# Monitored services (comma-separated)
monitored_services = ssh,nginx,mysql

# Service check interval in seconds
service_check_interval = 300
```

#### Network Monitoring
```ini
# Enable interface monitoring
enable_interface_monitoring = true

# Interface poll interval in seconds
interface_poll_interval = 30

# Enable route monitoring
enable_route_monitoring = false

# Enable ARP monitoring
enable_arp_monitoring = false

# Network statistics collection
enable_network_stats = true
network_stats_interval = 60
```

### Platform-Specific Configuration

#### Linux-Specific Settings
```ini
# Enable /proc filesystem monitoring
enable_proc_monitoring = true

# Enable /sys filesystem monitoring
enable_sys_monitoring = true

# Enable systemd integration
enable_systemd_integration = true

# Enable cgroups monitoring
enable_cgroups_monitoring = false
```

#### Windows-Specific Settings
```ini
# Enable WMI monitoring
enable_wmi_monitoring = true

# WMI namespace
wmi_namespace = root\cimv2

# Enable performance counters
enable_performance_counters = true

# Performance counter interval in seconds
performance_counter_interval = 30

# Enable event log monitoring
enable_event_log_monitoring = false

# Event log sources to monitor
event_log_sources = System,Application
```

#### macOS-Specific Settings
```ini
# Enable IOKit monitoring
enable_iokit_monitoring = true

# Enable launchd integration
enable_launchd_integration = true

# Enable system profiler integration
enable_system_profiler = false
```

### Custom OID Configuration

#### Custom OID Support
```ini
# Custom OID configuration file
custom_oid_file = %CONFIG_DIR%/custom-oids.conf

# Enable custom OID support
enable_custom_oids = true

# Custom OID cache size
custom_oid_cache_size = 100

# Custom OID cache timeout
custom_oid_cache_timeout = 300
```

#### Custom OID File Format
The custom OID file uses the following format:
```ini
# Custom OID definitions
# Format: OID = value_type:value:description

# Example custom OIDs
1.3.6.1.4.1.99999.1.1.1 = string:"Custom Value 1":"Custom OID 1"
1.3.6.1.4.1.99999.1.1.2 = integer:42:"Custom Integer Value"
1.3.6.1.4.1.99999.1.1.3 = counter:12345:"Custom Counter Value"
```

### Health Check Configuration

#### Health Monitoring
```ini
# Enable health checks
enable_health_check = true

# Health check interval in seconds
health_check_interval = 30

# Health check endpoint
health_check_endpoint = /health

# Health check timeout in seconds
health_check_timeout = 5

# Health check log file
health_check_log = %LOG_DIR%/health.log
```

### Metrics Configuration

#### Metrics Collection
```ini
# Enable metrics collection
enable_metrics = true

# Metrics endpoint
metrics_endpoint = /metrics

# Metrics port
metrics_port = 8080

# Metrics format (prometheus, json)
metrics_format = prometheus

# Metrics collection interval
metrics_interval = 60
```

### Backup and Update Configuration

#### Configuration Backup
```ini
# Enable configuration backup
enable_config_backup = true

# Backup interval in seconds
backup_interval = 86400

# Backup directory
backup_directory = %DATA_DIR%/backups

# Maximum number of backup files
max_backup_files = 7
```

#### Auto-Update Settings
```ini
# Enable automatic updates
enable_auto_update = false

# Update check interval in seconds
update_check_interval = 86400

# Update server URL
update_server =

# Update channel (stable, beta, alpha)
update_channel = stable
```

## Configuration Variables

The configuration file supports several built-in variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `%CONFIG_DIR%` | Configuration directory | `/etc/simple-snmpd` |
| `%LOG_DIR%` | Log directory | `/var/log/simple-snmpd` |
| `%DATA_DIR%` | Data directory | `/var/lib/simple-snmpd` |
| `%MIB_DIR%` | MIB directory | `/usr/share/snmp/mibs` |
| `%TEMP_DIR%` | Temporary directory | `/tmp` |

## Configuration Validation

### Command Line Validation
```bash
# Test configuration file
simple-snmpd --config-test

# Test with specific config file
simple-snmpd -c /path/to/config.conf --config-test

# Show configuration summary
simple-snmpd --config-summary
```

### Configuration Testing
```bash
# Dry run mode
simple-snmpd --dry-run

# Verbose configuration loading
simple-snmpd --verbose-config
```

## Best Practices

### Security Best Practices
1. **Use Strong Community Strings**: Avoid default community strings in production
2. **Enable Access Control**: Use `allowed_networks` to restrict access
3. **Enable SNMPv3**: Use SNMPv3 for secure environments
4. **Regular Updates**: Keep the daemon updated
5. **Monitor Access**: Enable request logging

### Performance Best Practices
1. **Optimize Thread Count**: Set `worker_threads` based on CPU cores
2. **Enable Caching**: Use response caching for frequently accessed data
3. **Monitor Memory**: Set appropriate memory limits
4. **Log Rotation**: Enable log rotation to prevent disk space issues

### Operational Best Practices
1. **Configuration Backup**: Enable automatic configuration backup
2. **Health Monitoring**: Enable health checks for monitoring systems
3. **Comprehensive Logging**: Use appropriate log levels
4. **Documentation**: Document custom configurations

## Configuration Examples

### Minimal Configuration
```ini
# Minimal working configuration
listen_address = 127.0.0.1
listen_port = 161
snmp_version = 2c
community_string = public
log_level = info
```

### Development Configuration
```ini
# Development configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = public
log_level = debug
enable_console_logging = true
enable_packet_logging = true
```

### Production Configuration
```ini
# Production configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = secure_community_2024
read_community = readonly_community
write_community = write_community

# Security
enable_authentication = true
allowed_networks = 192.168.1.0/24,10.0.0.0/8
enable_rate_limiting = true
rate_limit_requests = 1000
rate_limit_window = 60

# Logging
log_level = info
log_file = /var/log/simple-snmpd/simple-snmpd.log
log_rotation = true
max_log_size = 50MB
max_log_files = 10

# Performance
worker_threads = 8
enable_statistics = true
enable_response_cache = true
response_cache_size = 5000

# Monitoring
enable_system_monitoring = true
monitoring_interval = 30
enable_health_check = true
```

## Troubleshooting Configuration

### Common Configuration Issues

#### Syntax Errors
```bash
# Check for syntax errors
simple-snmpd --config-test

# Common syntax issues:
# - Missing quotes around values with spaces
# - Invalid boolean values (use true/false, not 1/0)
# - Invalid numeric values
```

#### Permission Issues
```bash
# Check file permissions
ls -la /etc/simple-snmpd/simple-snmpd.conf

# Fix permissions if needed
sudo chown snmp:snmp /etc/simple-snmpd/simple-snmpd.conf
sudo chmod 644 /etc/simple-snmpd/simple-snmpd.conf
```

#### Path Issues
```bash
# Check if paths exist
ls -la /var/log/simple-snmpd/
ls -la /var/lib/simple-snmpd/

# Create directories if needed
sudo mkdir -p /var/log/simple-snmpd
sudo mkdir -p /var/lib/simple-snmpd
sudo chown snmp:snmp /var/log/simple-snmpd
sudo chown snmp:snmp /var/lib/simple-snmpd
```

## Next Steps

- **Examples**: See [Configuration Examples](../examples/README.md) for real-world configurations
- **Deployment**: Learn about [Production Deployment](../deployment/production.md)
- **Troubleshooting**: Check the [Troubleshooting Guide](../troubleshooting/README.md) for common issues
