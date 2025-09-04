# Troubleshooting Guide

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with Simple SNMP Daemon.

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Service Issues](#service-issues)
3. [Network Issues](#network-issues)
4. [Configuration Issues](#configuration-issues)
5. [Permission Issues](#permission-issues)
6. [Performance Issues](#performance-issues)
7. [Log Analysis](#log-analysis)
8. [Common Error Messages](#common-error-messages)
9. [Platform-Specific Issues](#platform-specific-issues)
10. [Advanced Troubleshooting](#advanced-troubleshooting)

## Quick Diagnostics

### Health Check Commands

#### Check Service Status
```bash
# Linux (systemd)
sudo systemctl status simple-snmpd

# Linux (init.d)
sudo service simple-snmpd status

# macOS
sudo launchctl list | grep simple-snmpd

# Windows
sc query SimpleSnmpd
```

#### Check Process
```bash
# Check if process is running
ps aux | grep simple-snmpd
pgrep -f simple-snmpd

# Check process details
ps -ef | grep simple-snmpd
```

#### Check Port Binding
```bash
# Check if port 161 is listening
netstat -tulpn | grep :161
ss -tulpn | grep :161
lsof -i :161

# Check UDP port specifically
netstat -ulpn | grep :161
```

#### Test SNMP Connectivity
```bash
# Test basic connectivity
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test with timeout
snmpget -v2c -c public -t 5 localhost 1.3.6.1.2.1.1.1.0

# Test from remote host
snmpget -v2c -c public 192.168.1.100 1.3.6.1.2.1.1.1.0
```

### Configuration Validation

#### Test Configuration File
```bash
# Test configuration syntax
simple-snmpd --config-test

# Test with specific file
simple-snmpd --config-test --config /path/to/config.conf

# Show configuration summary
simple-snmpd --config-summary
```

#### Validate Configuration
```bash
# Validate configuration and dependencies
simple-snmpd --config-validate

# Dry run
simple-snmpd --dry-run
```

## Service Issues

### Service Won't Start

#### Check Service Status
```bash
# Check service status
sudo systemctl status simple-snmpd

# Check service logs
sudo journalctl -u simple-snmpd -f

# Check for errors
sudo journalctl -u simple-snmpd --since "1 hour ago" | grep -i error
```

#### Common Causes and Solutions

##### Configuration Error
```bash
# Test configuration
simple-snmpd --config-test

# Check configuration file
cat /etc/simple-snmpd/simple-snmpd.conf

# Validate configuration
simple-snmpd --config-validate
```

##### Port Already in Use
```bash
# Check what's using port 161
sudo netstat -tulpn | grep :161
sudo lsof -i :161

# Kill process using port
sudo fuser -k 161/udp

# Use different port
simple-snmpd --listen-port 1161
```

##### Permission Issues
```bash
# Check file permissions
ls -la /etc/simple-snmpd/
ls -la /var/log/simple-snmpd/
ls -la /var/lib/simple-snmpd/

# Fix permissions
sudo chown -R snmp:snmp /etc/simple-snmpd/
sudo chown -R snmp:snmp /var/log/simple-snmpd/
sudo chown -R snmp:snmp /var/lib/simple-snmpd/
```

##### Missing Dependencies
```bash
# Check for missing libraries
ldd /usr/sbin/simple-snmpd

# Install missing dependencies
sudo apt-get install libssl-dev libjsoncpp-dev libsnmp-dev
```

### Service Crashes

#### Check Crash Logs
```bash
# Check system logs
sudo journalctl -u simple-snmpd --since "1 hour ago"

# Check core dumps
ls -la /var/crash/
ls -la /core

# Check memory usage
free -h
```

#### Common Crash Causes

##### Out of Memory
```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head

# Check memory limits
ulimit -a

# Increase memory limits
ulimit -m unlimited
```

##### Segmentation Fault
```bash
# Enable core dumps
ulimit -c unlimited

# Run with debugger
gdb /usr/sbin/simple-snmpd core

# Check for corrupted files
fsck /dev/sda1
```

### Service Restart Issues

#### Check Restart Policy
```bash
# Check systemd restart policy
systemctl show simple-snmpd | grep Restart

# Check service dependencies
systemctl list-dependencies simple-snmpd
```

#### Manual Restart
```bash
# Stop service
sudo systemctl stop simple-snmpd

# Wait for cleanup
sleep 5

# Start service
sudo systemctl start simple-snmpd

# Check status
sudo systemctl status simple-snmpd
```

## Network Issues

### Port Binding Issues

#### Check Port Availability
```bash
# Check if port is available
netstat -tulpn | grep :161

# Check for conflicting services
sudo lsof -i :161

# Check firewall rules
sudo ufw status
sudo iptables -L
```

#### Resolve Port Conflicts
```bash
# Stop conflicting service
sudo systemctl stop snmpd
sudo systemctl disable snmpd

# Use different port
simple-snmpd --listen-port 1161

# Configure firewall
sudo ufw allow 161/udp
```

### Network Connectivity Issues

#### Test Local Connectivity
```bash
# Test localhost
snmpget -v2c -c public 127.0.0.1 1.3.6.1.2.1.1.1.0

# Test with different community
snmpget -v2c -c private 127.0.0.1 1.3.6.1.2.1.1.1.0

# Test with timeout
snmpget -v2c -c public -t 10 127.0.0.1 1.3.6.1.2.1.1.1.0
```

#### Test Remote Connectivity
```bash
# Test from remote host
snmpget -v2c -c public 192.168.1.100 1.3.6.1.2.1.1.1.0

# Test with different SNMP version
snmpget -v1 -c public 192.168.1.100 1.3.6.1.2.1.1.1.0

# Test with SNMPv3
snmpget -v3 -l authPriv -u admin -a SHA -A adminpass -x AES -X privpass 192.168.1.100 1.3.6.1.2.1.1.1.0
```

### Firewall Issues

#### Check Firewall Rules
```bash
# Check UFW status
sudo ufw status

# Check iptables rules
sudo iptables -L -n

# Check for SNMP rules
sudo iptables -L | grep 161
```

#### Configure Firewall
```bash
# Allow SNMP (UFW)
sudo ufw allow 161/udp
sudo ufw allow from 192.168.1.0/24 to any port 161

# Allow SNMP (iptables)
sudo iptables -A INPUT -p udp --dport 161 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 161 -s 192.168.1.0/24 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Network Interface Issues

#### Check Network Interfaces
```bash
# List network interfaces
ip addr show
ifconfig

# Check interface status
ip link show
```

#### Configure Network Interface
```bash
# Bind to specific interface
simple-snmpd --listen-address 192.168.1.100

# Check interface configuration
ip addr show eth0
```

## Configuration Issues

### Configuration File Problems

#### Syntax Errors
```bash
# Test configuration syntax
simple-snmpd --config-test

# Check for common syntax errors
grep -n "=" /etc/simple-snmpd/simple-snmpd.conf | grep -v "^[[:space:]]*#"

# Validate configuration
simple-snmpd --config-validate
```

#### Common Syntax Issues
```ini
# Incorrect syntax
listen_address=0.0.0.0  # Missing space around =

# Correct syntax
listen_address = 0.0.0.0

# Incorrect boolean values
enable_ipv6=1  # Should be true/false

# Correct boolean values
enable_ipv6 = true
```

#### Missing Configuration
```bash
# Check for required settings
grep -E "^(listen_address|listen_port|snmp_version|community_string)" /etc/simple-snmpd/simple-snmpd.conf

# Check for missing sections
grep -E "^\[.*\]" /etc/simple-snmpd/simple-snmpd.conf
```

### Configuration Validation Issues

#### Test Configuration
```bash
# Test configuration file
simple-snmpd --config-test --config /etc/simple-snmpd/simple-snmpd.conf

# Test with verbose output
simple-snmpd --config-test --verbose

# Test with specific options
simple-snmpd --config-test --log-level debug
```

#### Configuration Dependencies
```bash
# Check for missing files
ls -la /etc/simple-snmpd/
ls -la /var/log/simple-snmpd/
ls -la /var/lib/simple-snmpd/

# Check for missing directories
mkdir -p /var/log/simple-snmpd
mkdir -p /var/lib/simple-snmpd
mkdir -p /var/run/simple-snmpd
```

## Permission Issues

### File Permission Problems

#### Check File Permissions
```bash
# Check configuration file permissions
ls -la /etc/simple-snmpd/simple-snmpd.conf

# Check log directory permissions
ls -la /var/log/simple-snmpd/

# Check data directory permissions
ls -la /var/lib/simple-snmpd/
```

#### Fix File Permissions
```bash
# Fix configuration file permissions
sudo chown snmp:snmp /etc/simple-snmpd/simple-snmpd.conf
sudo chmod 644 /etc/simple-snmpd/simple-snmpd.conf

# Fix directory permissions
sudo chown -R snmp:snmp /var/log/simple-snmpd/
sudo chown -R snmp:snmp /var/lib/simple-snmpd/
sudo chown -R snmp:snmp /var/run/simple-snmpd/

# Set proper permissions
sudo chmod 755 /var/log/simple-snmpd/
sudo chmod 755 /var/lib/simple-snmpd/
sudo chmod 755 /var/run/simple-snmpd/
```

### User and Group Issues

#### Check User and Group
```bash
# Check if snmp user exists
id snmp
getent passwd snmp

# Check if snmp group exists
getent group snmp
```

#### Create User and Group
```bash
# Create snmp group
sudo groupadd -r snmp

# Create snmp user
sudo useradd -r -g snmp -d /var/lib/simple-snmpd -s /bin/false snmp

# Set user shell
sudo usermod -s /bin/false snmp
```

### SELinux Issues (Linux)

#### Check SELinux Status
```bash
# Check SELinux status
sestatus

# Check SELinux context
ls -Z /usr/sbin/simple-snmpd
ls -Z /etc/simple-snmpd/
```

#### Fix SELinux Issues
```bash
# Set SELinux context
sudo setsebool -P snmpd_connect_any 1
sudo setsebool -P snmpd_use_tcp_wrapper 1

# Create SELinux policy
sudo semanage fcontext -a -t snmpd_exec_t /usr/sbin/simple-snmpd
sudo restorecon /usr/sbin/simple-snmpd
```

## Performance Issues

### High CPU Usage

#### Check CPU Usage
```bash
# Check CPU usage
top -p $(pidof simple-snmpd)
htop -p $(pidof simple-snmpd)

# Check CPU usage over time
sar -u 1 10
```

#### Optimize CPU Usage
```ini
# Reduce worker threads
worker_threads = 2

# Disable unnecessary features
enable_statistics = false
enable_packet_logging = false

# Optimize logging
log_level = warn
```

### High Memory Usage

#### Check Memory Usage
```bash
# Check memory usage
ps aux --sort=-%mem | head
free -h

# Check memory usage over time
sar -r 1 10
```

#### Optimize Memory Usage
```ini
# Reduce cache sizes
response_cache_size = 100
mib_cache_size = 100

# Set memory limits
memory_limit = 256MB

# Optimize logging
log_rotation = true
max_log_size = 10MB
max_log_files = 3
```

### Slow Response Times

#### Check Response Times
```bash
# Test response time
time snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test with multiple requests
for i in {1..10}; do time snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0; done
```

#### Optimize Response Times
```ini
# Enable response caching
enable_response_cache = true
response_cache_size = 1000
response_cache_timeout = 300

# Optimize worker threads
worker_threads = 4

# Enable connection pooling
enable_connection_pooling = true
connection_pool_size = 100
```

## Log Analysis

### Log File Locations

#### Default Log Locations
| Platform | Log Location |
|----------|--------------|
| Linux | `/var/log/simple-snmpd/simple-snmpd.log` |
| macOS | `/usr/local/var/log/simple-snmpd/simple-snmpd.log` |
| Windows | `%ProgramData%\Simple-SNMPd\logs\simple-snmpd.log` |

#### System Log Locations
| Platform | System Log Location |
|----------|-------------------|
| Linux (systemd) | `journalctl -u simple-snmpd` |
| Linux (syslog) | `/var/log/syslog` |
| macOS | `log show --predicate 'process == "simple-snmpd"'` |
| Windows | Event Viewer → Windows Logs → System |

### Log Analysis Commands

#### View Recent Logs
```bash
# View recent logs
tail -f /var/log/simple-snmpd/simple-snmpd.log

# View last 100 lines
tail -n 100 /var/log/simple-snmpd/simple-snmpd.log

# View logs from last hour
journalctl -u simple-snmpd --since "1 hour ago"
```

#### Search Logs
```bash
# Search for errors
grep -i error /var/log/simple-snmpd/simple-snmpd.log

# Search for warnings
grep -i warning /var/log/simple-snmpd/simple-snmpd.log

# Search for specific patterns
grep "SNMP request" /var/log/simple-snmpd/simple-snmpd.log
```

#### Log Statistics
```bash
# Count log entries by level
grep -c "ERROR" /var/log/simple-snmpd/simple-snmpd.log
grep -c "WARN" /var/log/simple-snmpd/simple-snmpd.log
grep -c "INFO" /var/log/simple-snmpd/simple-snmpd.log

# Count requests by community
grep "community" /var/log/simple-snmpd/simple-snmpd.log | cut -d' ' -f5 | sort | uniq -c
```

### Log Rotation Issues

#### Check Log Rotation
```bash
# Check log file sizes
ls -lh /var/log/simple-snmpd/

# Check log rotation configuration
grep -i rotation /etc/simple-snmpd/simple-snmpd.conf
```

#### Fix Log Rotation
```bash
# Manual log rotation
sudo kill -USR1 $(pidof simple-snmpd)

# Configure logrotate
sudo nano /etc/logrotate.d/simple-snmpd
```

## Common Error Messages

### Configuration Errors

#### "Configuration file not found"
```bash
# Check if file exists
ls -la /etc/simple-snmpd/simple-snmpd.conf

# Create default configuration
sudo cp /etc/simple-snmpd/simple-snmpd.conf.example /etc/simple-snmpd/simple-snmpd.conf
```

#### "Invalid configuration syntax"
```bash
# Test configuration
simple-snmpd --config-test

# Check for syntax errors
grep -n "=" /etc/simple-snmpd/simple-snmpd.conf | grep -v "^[[:space:]]*#"
```

#### "Permission denied"
```bash
# Check file permissions
ls -la /etc/simple-snmpd/simple-snmpd.conf

# Fix permissions
sudo chown snmp:snmp /etc/simple-snmpd/simple-snmpd.conf
sudo chmod 644 /etc/simple-snmpd/simple-snmpd.conf
```

### Network Errors

#### "Address already in use"
```bash
# Check what's using the port
sudo netstat -tulpn | grep :161

# Kill process using port
sudo fuser -k 161/udp

# Use different port
simple-snmpd --listen-port 1161
```

#### "Connection refused"
```bash
# Check if service is running
sudo systemctl status simple-snmpd

# Check firewall
sudo ufw status
sudo iptables -L
```

#### "Timeout"
```bash
# Test with longer timeout
snmpget -v2c -c public -t 10 localhost 1.3.6.1.2.1.1.1.0

# Check network connectivity
ping localhost
```

### SNMP Errors

#### "No such object"
```bash
# Check if OID exists
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.1

# Check MIB loading
grep -i mib /etc/simple-snmpd/simple-snmpd.conf
```

#### "Community string mismatch"
```bash
# Check community string
grep community_string /etc/simple-snmpd/simple-snmpd.conf

# Test with correct community
snmpget -v2c -c correct_community localhost 1.3.6.1.2.1.1.1.0
```

#### "Access denied"
```bash
# Check access control
grep -i access /etc/simple-snmpd/simple-snmpd.conf

# Check allowed networks
grep allowed_networks /etc/simple-snmpd/simple-snmpd.conf
```

## Platform-Specific Issues

### Linux Issues

#### systemd Issues
```bash
# Check systemd status
systemctl status simple-snmpd

# Reload systemd
systemctl daemon-reload

# Check systemd logs
journalctl -u simple-snmpd -f
```

#### SELinux Issues
```bash
# Check SELinux status
sestatus

# Set SELinux context
sudo setsebool -P snmpd_connect_any 1
```

#### AppArmor Issues
```bash
# Check AppArmor status
sudo aa-status

# Disable AppArmor for SNMP
sudo aa-complain /usr/sbin/simple-snmpd
```

### macOS Issues

#### launchd Issues
```bash
# Check launchd status
sudo launchctl list | grep simple-snmpd

# Reload launchd
sudo launchctl unload /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
sudo launchctl load /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
```

#### Permission Issues
```bash
# Check file permissions
ls -la /usr/local/etc/simple-snmpd/
ls -la /usr/local/var/log/simple-snmpd/

# Fix permissions
sudo chown -R $(whoami):staff /usr/local/etc/simple-snmpd/
sudo chown -R $(whoami):staff /usr/local/var/log/simple-snmpd/
```

### Windows Issues

#### Service Issues
```cmd
# Check service status
sc query SimpleSnmpd

# Start service
net start SimpleSnmpd

# Stop service
net stop SimpleSnmpd
```

#### Permission Issues
```cmd
# Check file permissions
icacls "%ProgramData%\Simple-SNMPd"

# Fix permissions
icacls "%ProgramData%\Simple-SNMPd" /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T
```

#### Firewall Issues
```cmd
# Check firewall rules
netsh advfirewall firewall show rule name="Simple SNMP Daemon"

# Add firewall rule
netsh advfirewall firewall add rule name="Simple SNMP Daemon" dir=in action=allow protocol=UDP localport=161
```

## Advanced Troubleshooting

### Debug Mode

#### Enable Debug Logging
```bash
# Run with debug logging
simple-snmpd --foreground --log-level debug --enable-console-logging

# Enable packet logging
simple-snmpd --enable-packet-logging --packet-log-file /tmp/packets.log
```

#### Debug with GDB
```bash
# Run with GDB
gdb /usr/sbin/simple-snmpd

# Set breakpoints
(gdb) break main
(gdb) break snmp_handler

# Run with arguments
(gdb) set args --foreground --log-level debug
(gdb) run
```

### Network Debugging

#### Packet Capture
```bash
# Capture SNMP packets
sudo tcpdump -i any -n port 161

# Capture with detailed output
sudo tcpdump -i any -n -v port 161

# Save packets to file
sudo tcpdump -i any -n -w snmp.pcap port 161
```

#### Network Analysis
```bash
# Check network statistics
netstat -s

# Check UDP statistics
netstat -su

# Check interface statistics
cat /proc/net/dev
```

### Performance Analysis

#### System Monitoring
```bash
# Monitor system resources
top -p $(pidof simple-snmpd)
htop -p $(pidof simple-snmpd)

# Monitor I/O
iotop -p $(pidof simple-snmpd)

# Monitor network
nethogs
```

#### Profiling
```bash
# Profile with perf
sudo perf record -p $(pidof simple-snmpd)
sudo perf report

# Profile with valgrind
valgrind --tool=callgrind /usr/sbin/simple-snmpd --foreground
```

### Memory Analysis

#### Check Memory Usage
```bash
# Check memory usage
ps aux --sort=-%mem | head
free -h

# Check memory maps
cat /proc/$(pidof simple-snmpd)/maps

# Check memory statistics
cat /proc/$(pidof simple-snmpd)/status
```

#### Memory Leak Detection
```bash
# Check for memory leaks
valgrind --tool=memcheck --leak-check=full /usr/sbin/simple-snmpd --foreground

# Monitor memory usage over time
while true; do ps -p $(pidof simple-snmpd) -o pid,vsz,rss,comm; sleep 60; done
```

## Getting Help

### Self-Help Resources

1. **Check Logs**: Always check logs first
2. **Test Configuration**: Use `--config-test`
3. **Verify Network**: Test SNMP connectivity
4. **Check Permissions**: Verify file permissions
5. **Review Documentation**: Check relevant documentation

### Community Support

- **GitHub Issues**: [GitHub Issues](https://github.com/simpledaemons/simple-snmpd/issues)
- **Documentation**: [Documentation](https://docs.simpledaemons.org)
- **Community Forum**: [Community Forum](https://community.simpledaemons.org)

### Professional Support

- **Enterprise Support**: [Enterprise Support](https://simpledaemons.org/support)
- **Consulting**: [Professional Services](https://simpledaemons.org/services)
- **Training**: [Training Programs](https://simpledaemons.org/training)

### Reporting Issues

When reporting issues, please include:

1. **System Information**: OS, version, architecture
2. **Simple SNMP Daemon Version**: `simple-snmpd --version`
3. **Configuration**: Relevant configuration sections
4. **Logs**: Error logs and relevant log entries
5. **Steps to Reproduce**: Clear steps to reproduce the issue
6. **Expected Behavior**: What you expected to happen
7. **Actual Behavior**: What actually happened

## Prevention

### Best Practices

1. **Regular Updates**: Keep the daemon and dependencies updated
2. **Configuration Backup**: Regular configuration backups
3. **Monitoring**: Set up monitoring and alerting
4. **Testing**: Test changes in development first
5. **Documentation**: Document all custom configurations

### Maintenance

1. **Log Rotation**: Ensure log rotation is working
2. **Disk Space**: Monitor disk space usage
3. **Performance**: Regular performance monitoring
4. **Security**: Regular security audits
5. **Backups**: Regular configuration and data backups
