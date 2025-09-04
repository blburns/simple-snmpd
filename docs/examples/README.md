# Configuration Examples

This directory contains real-world configuration examples for Simple SNMP Daemon in various environments and use cases.

## Example Categories

### Basic Examples
- **[Simple Configuration](simple/)** - Minimal working configurations
- **[Development Setup](development/)** - Development and testing configurations
- **[Local Network](local-network/)** - Small office/home office setups

### Production Examples
- **[Enterprise](enterprise/)** - Large enterprise deployments
- **[Cloud](cloud/)** - Cloud platform configurations
- **[High Availability](high-availability/)** - Clustered and load-balanced setups

### Specialized Examples
- **[Security](security/)** - High-security configurations
- **[Performance](performance/)** - High-performance optimizations
- **[Monitoring](monitoring/)** - Monitoring and alerting setups

## Quick Start Examples

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
# Development configuration with debugging
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = dev_community
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

## Environment-Specific Examples

### Docker Environment
```ini
# Docker-optimized configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = docker_community
log_level = info
system_name = Docker Container
system_description = Simple SNMP Daemon in Docker
enable_statistics = true
worker_threads = 2
```

### Kubernetes Environment
```ini
# Kubernetes-optimized configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = k8s_community
log_level = info
system_name = Kubernetes Pod
system_description = Simple SNMP Daemon in Kubernetes
enable_health_check = true
health_check_endpoint = /health
enable_metrics = true
metrics_endpoint = /metrics
metrics_port = 8080
```

### Cloud Environment
```ini
# Cloud-optimized configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = cloud_community
log_level = info
system_name = Cloud Instance
system_description = Simple SNMP Daemon in Cloud
enable_cloud_monitoring = true
cloud_provider = aws
enable_auto_scaling = true
```

## Security Examples

### SNMPv3 Configuration
```ini
# SNMPv3 secure configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 3
enable_v3 = true
v3_user_database = /etc/simple-snmpd/v3-users.conf
v3_default_security_level = authPriv
v3_default_auth_protocol = SHA256
v3_default_priv_protocol = AES256
```

### Network Security
```ini
# Network security configuration
listen_address = 192.168.1.100
listen_port = 161
snmp_version = 2c
community_string = secure_community
allowed_networks = 192.168.1.0/24,10.0.0.0/8
denied_networks = 0.0.0.0/0
enable_rate_limiting = true
rate_limit_requests = 1000
rate_limit_window = 60
```

## Performance Examples

### High-Performance Configuration
```ini
# High-performance configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = perf_community
worker_threads = 16
max_connections = 10000
enable_response_cache = true
response_cache_size = 10000
response_cache_timeout = 300
enable_connection_pooling = true
connection_pool_size = 1000
```

### Memory-Optimized Configuration
```ini
# Memory-optimized configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = mem_community
worker_threads = 4
max_connections = 1000
memory_limit = 512MB
enable_response_cache = true
response_cache_size = 1000
response_cache_timeout = 60
```

## Monitoring Examples

### Comprehensive Monitoring
```ini
# Comprehensive monitoring configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = monitor_community

# System monitoring
enable_system_monitoring = true
enable_cpu_monitoring = true
enable_memory_monitoring = true
enable_disk_monitoring = true
enable_network_interface_monitoring = true
monitoring_interval = 30

# Process monitoring
enable_process_monitoring = true
monitored_processes = sshd,nginx,mysql,postgresql
process_check_interval = 60

# Service monitoring
enable_service_monitoring = true
monitored_services = ssh,nginx,mysql,postgresql
service_check_interval = 300

# Network monitoring
enable_interface_monitoring = true
enable_route_monitoring = true
interface_poll_interval = 30
```

### Metrics and Health Checks
```ini
# Metrics and health checks configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = metrics_community

# Health checks
enable_health_check = true
health_check_interval = 30
health_check_endpoint = /health
health_check_timeout = 5

# Metrics
enable_metrics = true
metrics_endpoint = /metrics
metrics_port = 8080
metrics_format = prometheus
metrics_interval = 60

# Statistics
enable_statistics = true
stats_interval = 60
```

## Platform-Specific Examples

### Linux Configuration
```ini
# Linux-specific configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = linux_community

# Linux-specific monitoring
enable_proc_monitoring = true
enable_sys_monitoring = true
enable_systemd_integration = true
enable_cgroups_monitoring = false

# System information
system_name = Linux Server
system_description = Simple SNMP Daemon on Linux
system_contact = admin@linux-server.com
system_location = Linux Data Center
```

### Windows Configuration
```ini
# Windows-specific configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = windows_community

# Windows-specific monitoring
enable_wmi_monitoring = true
wmi_namespace = root\cimv2
enable_performance_counters = true
performance_counter_interval = 30
enable_event_log_monitoring = false

# System information
system_name = Windows Server
system_description = Simple SNMP Daemon on Windows
system_contact = admin@windows-server.com
system_location = Windows Data Center
```

### macOS Configuration
```ini
# macOS-specific configuration
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = macos_community

# macOS-specific monitoring
enable_iokit_monitoring = true
enable_launchd_integration = true
enable_system_profiler = false

# System information
system_name = macOS Server
system_description = Simple SNMP Daemon on macOS
system_contact = admin@macos-server.com
system_location = macOS Data Center
```

## Custom OID Examples

### Custom System Information
```ini
# Custom OID configuration
enable_custom_oids = true
custom_oid_file = /etc/simple-snmpd/custom-oids.conf
custom_oid_cache_size = 100
custom_oid_cache_timeout = 300
```

### Custom OID File Example
```ini
# Custom OID definitions
# Format: OID = value_type:value:description

# Custom system information
1.3.6.1.4.1.99999.1.1.1 = string:"Custom Server":"Custom Server Name"
1.3.6.1.4.1.99999.1.1.2 = string:"Production":"Environment Type"
1.3.6.1.4.1.99999.1.1.3 = string:"v1.0.0":"Application Version"

# Custom metrics
1.3.6.1.4.1.99999.1.2.1 = counter:12345:"Custom Counter 1"
1.3.6.1.4.1.99999.1.2.2 = gauge:42:"Custom Gauge 1"
1.3.6.1.4.1.99999.1.2.3 = integer:100:"Custom Integer 1"

# Custom status information
1.3.6.1.4.1.99999.1.3.1 = string:"Online":"Service Status"
1.3.6.1.4.1.99999.1.3.2 = string:"Healthy":"Health Status"
1.3.6.1.4.1.99999.1.3.3 = string:"Normal":"Load Status"
```

## Trap Configuration Examples

### Basic Trap Configuration
```ini
# Basic trap configuration
enable_traps = true
trap_port = 162
trap_community = public
trap_destinations = 192.168.1.100,192.168.1.101
trap_retry_count = 3
trap_timeout = 5
```

### Advanced Trap Configuration
```ini
# Advanced trap configuration
enable_traps = true
trap_port = 162
trap_community = trap_community
trap_destinations = 192.168.1.100:162,192.168.1.101:162,192.168.1.102:162
trap_retry_count = 5
trap_timeout = 10
enable_trap_authentication = true
trap_auth_protocol = MD5
trap_priv_protocol = DES
trap_user_database = /etc/simple-snmpd/trap-users.conf
enable_trap_logging = true
trap_log_file = /var/log/simple-snmpd/traps.log
```

## Logging Examples

### Comprehensive Logging
```ini
# Comprehensive logging configuration
log_level = info
log_file = /var/log/simple-snmpd/simple-snmpd.log
error_log_file = /var/log/simple-snmpd/simple-snmpd.error.log
enable_console_logging = false
enable_syslog = true
syslog_facility = daemon

# Log rotation
log_rotation = true
max_log_size = 100MB
max_log_files = 10
log_rotation_time = daily

# Log format
log_format = "[%Y-%m-%d %H:%M:%S] [%L] [%T] [%P] %M"

# Request logging
log_requests = true
log_responses = false
enable_packet_logging = false
```

### Debug Logging
```ini
# Debug logging configuration
log_level = debug
log_file = /var/log/simple-snmpd/debug.log
error_log_file = /var/log/simple-snmpd/error.log
enable_console_logging = true
enable_packet_logging = true
packet_log_file = /var/log/simple-snmpd/packets.log
log_requests = true
log_responses = true
```

## Backup and Recovery Examples

### Configuration Backup
```ini
# Configuration backup
enable_config_backup = true
backup_interval = 86400
backup_directory = /var/backups/simple-snmpd
max_backup_files = 7
backup_compression = true
backup_encryption = false
```

### Auto-Update Configuration
```ini
# Auto-update configuration
enable_auto_update = false
update_check_interval = 86400
update_server = https://updates.simpledaemons.org
update_channel = stable
update_auto_install = false
update_backup_before_install = true
```

## Integration Examples

### Prometheus Integration
```ini
# Prometheus integration
enable_metrics = true
metrics_endpoint = /metrics
metrics_port = 8080
metrics_format = prometheus
metrics_interval = 60
metrics_path = /metrics
enable_metrics_auth = false
```

### Grafana Integration
```ini
# Grafana integration
enable_metrics = true
metrics_endpoint = /metrics
metrics_port = 8080
metrics_format = prometheus
enable_health_check = true
health_check_endpoint = /health
health_check_port = 8080
```

### Nagios Integration
```ini
# Nagios integration
enable_traps = true
trap_destinations = 192.168.1.100:162
trap_community = nagios_community
enable_health_check = true
health_check_endpoint = /health
```

## Best Practices

### Security Best Practices
1. **Use Strong Community Strings**: Avoid default community strings
2. **Enable Access Control**: Use `allowed_networks` to restrict access
3. **Enable SNMPv3**: Use SNMPv3 for secure environments
4. **Enable Rate Limiting**: Prevent abuse with rate limiting
5. **Regular Updates**: Keep the daemon updated

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

## Getting Help

If you need help with configuration:

1. **Check Examples**: Look for similar examples in this directory
2. **Configuration Guide**: See the [Configuration Guide](../configuration/README.md)
3. **Troubleshooting**: Check the [Troubleshooting Guide](../troubleshooting/README.md)
4. **Support**: Get help from the [Support Guide](../support/README.md)

## Contributing Examples

We welcome contributions of new configuration examples:

1. **Test Your Configuration**: Ensure your example works correctly
2. **Document Clearly**: Provide clear comments and explanations
3. **Follow Naming**: Use descriptive names for your examples
4. **Submit Pull Request**: Submit your example via pull request

## License

All examples are provided under the Apache 2.0 License. See the main LICENSE file for details.
