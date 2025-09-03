# Windows Deployment Guide

This directory contains all the necessary files and scripts for deploying Simple SNMP Daemon on Windows systems.

## Files Overview

### Service Management Scripts
- **`install-service.bat`** - Batch script for service installation and management
- **`install-service.ps1`** - PowerShell script with advanced service management features

### Service Wrapper
- **`simple-snmpd-service.cpp`** - Windows service wrapper source code
- **`simple-snmpd-service.rc`** - Resource file for service metadata
- **`simple-snmpd-service.manifest`** - Application manifest for Windows compatibility

### Build System
- **`build-service.bat`** - Build script for compiling the service wrapper

## Quick Start

### 1. Build the Service
```cmd
# From the windows deployment directory
build-service.bat all
```

### 2. Install the Service
```cmd
# Run as Administrator
install-service.bat install
```

### 3. Configure the Service
```cmd
# Create configuration files
install-service.bat config
```

### 4. Start the Service
```cmd
# Start the service
install-service.bat start
```

### 5. Test the Service
```cmd
# Test SNMP connectivity
install-service.bat test
```

## Detailed Installation

### Prerequisites

#### System Requirements
- **Windows 7** or later (Windows 10/11 recommended)
- **Administrator privileges** for installation
- **Visual Studio Build Tools** or **Visual Studio** for building from source
- **PowerShell 5.0** or later (for PowerShell scripts)

#### Network Requirements
- **Port 161/UDP** - SNMP agent port (must be available)
- **Port 162/UDP** - SNMP trap port (optional)
- **Firewall configuration** - Allow SNMP traffic

### Installation Methods

#### Method 1: Batch Script (Recommended for beginners)
```cmd
# Run as Administrator
cd deployment\windows
install-service.bat install
install-service.bat config
install-service.bat start
```

#### Method 2: PowerShell Script (Advanced features)
```powershell
# Run as Administrator
cd deployment\windows
.\install-service.ps1 install
.\install-service.ps1 config
.\install-service.ps1 start
```

#### Method 3: Manual Installation
```cmd
# Copy files to system directories
copy simple-snmpd-service.exe %SystemRoot%\System32\
copy simple-snmpd.exe %SystemRoot%\System32\

# Install service
sc create SimpleSnmpd binPath= "%SystemRoot%\System32\simple-snmpd-service.exe" DisplayName= "Simple SNMP Daemon" start= auto
sc description SimpleSnmpd "Provides SNMP monitoring services for network devices"

# Start service
sc start SimpleSnmpd
```

## Service Management

### Using Batch Script
```cmd
# Service control
install-service.bat start      # Start service
install-service.bat stop       # Stop service
install-service.bat restart    # Restart service
install-service.bat status     # Show status
install-service.bat uninstall  # Remove service

# Configuration
install-service.bat config     # Create config files
install-service.bat test       # Test connectivity
```

### Using PowerShell Script
```powershell
# Service control
.\install-service.ps1 start      # Start service
.\install-service.ps1 stop       # Stop service
.\install-service.ps1 restart    # Restart service
.\install-service.ps1 status     # Show detailed status
.\install-service.ps1 uninstall  # Remove service

# Advanced features
.\install-service.ps1 config     # Create config files
.\install-service.ps1 test       # Test connectivity
.\install-service.ps1 logs       # Show recent logs
.\install-service.ps1 monitor    # Real-time monitoring
```

### Using Windows Services
```cmd
# Service control via sc command
sc start SimpleSnmpd
sc stop SimpleSnmpd
sc query SimpleSnmpd
sc delete SimpleSnmpd

# Service control via net command
net start SimpleSnmpd
net stop SimpleSnmpd
```

### Using Services Management Console
1. Open **Services** (`services.msc`)
2. Find **Simple SNMP Daemon**
3. Right-click for context menu
4. Select desired action (Start, Stop, Restart, Properties)

## Configuration

### Configuration Files
The service creates configuration files in `%ProgramData%\Simple-SNMPd\`:

- **`simple-snmpd.conf`** - Main configuration file
- **`users.conf`** - SNMP user database
- **`access.conf`** - Access control configuration

### Key Configuration Options

#### Network Settings
```ini
listen_address = 0.0.0.0          # Listen on all interfaces
listen_port = 161                 # SNMP agent port
enable_ipv6 = true                # Enable IPv6 support
max_connections = 1000            # Maximum concurrent connections
```

#### SNMP Settings
```ini
snmp_version = 2c                 # SNMP version (1, 2c, 3)
community_string = public         # Default community string
read_community = public           # Read-only community
write_community = private         # Read-write community
enable_v3 = false                 # Enable SNMPv3
```

#### Security Settings
```ini
enable_authentication = false     # Enable SNMPv3 authentication
authentication_protocol = MD5     # Auth protocol (MD5, SHA)
privacy_protocol = DES            # Privacy protocol (DES, AES)
```

#### Logging Settings
```ini
log_level = info                  # Log level (debug, info, warn, error)
log_file = %LOG_DIR%\simple-snmpd.log
enable_console_logging = false    # Console output (service mode)
log_rotation = true               # Enable log rotation
max_log_size = 10MB               # Maximum log file size
```

### Windows-Specific Settings
```ini
enable_wmi_monitoring = true      # Enable WMI monitoring
wmi_namespace = root\cimv2        # WMI namespace
enable_performance_counters = true # Performance counters
performance_counter_interval = 30  # Counter update interval
```

## Testing and Troubleshooting

### SNMP Testing Tools

#### Using snmpget (if available)
```cmd
# Test basic connectivity
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test system information
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.2.0
```

#### Using snmpwalk (if available)
```cmd
# Walk system MIB
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.1

# Walk interface MIB
snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2
```

#### Using PowerShell
```powershell
# Test port connectivity
Test-NetConnection -ComputerName localhost -Port 161

# Check service status
Get-Service -Name SimpleSnmpd

# View service logs
Get-WinEvent -FilterHashtable @{LogName='System'; ID=7034,7035,7036} | Where-Object { $_.Message -like "*SimpleSnmpd*" }
```

### Common Issues and Solutions

#### Service Won't Start
1. **Check Event Log**: Look in Windows Event Viewer for error messages
2. **Verify Binary**: Ensure `simple-snmpd.exe` exists and is executable
3. **Check Port**: Verify port 161 is not in use by another service
4. **Permissions**: Ensure service account has necessary permissions

#### SNMP Requests Fail
1. **Firewall**: Check Windows Firewall settings
2. **Community String**: Verify community string matches configuration
3. **Network Interface**: Ensure service is listening on correct interface
4. **SNMP Version**: Verify SNMP version compatibility

#### Permission Issues
1. **Service Account**: Service runs as NetworkService by default
2. **File Permissions**: Check permissions on config and log directories
3. **Registry Access**: Ensure service has necessary registry permissions

### Log Files
- **Service Logs**: `%ProgramData%\Simple-SNMPd\logs\simple-snmpd.log`
- **Error Logs**: `%ProgramData%\Simple-SNMPd\logs\simple-snmpd.error.log`
- **Windows Event Log**: System log for service events

## Security Considerations

### Network Security
- **Firewall Rules**: Restrict SNMP access to trusted networks
- **Community Strings**: Use strong, non-default community strings
- **SNMPv3**: Enable SNMPv3 for production environments
- **Access Control**: Configure proper access control lists

### Service Security
- **Service Account**: Runs as NetworkService (limited privileges)
- **File Permissions**: Config files protected by ACLs
- **Registry Access**: Minimal registry access required
- **Network Binding**: Can be configured to bind to specific interfaces

### Best Practices
1. **Change Default Passwords**: Update all default community strings
2. **Enable Logging**: Monitor SNMP access and errors
3. **Regular Updates**: Keep the service updated
4. **Network Segmentation**: Isolate SNMP traffic when possible
5. **Monitoring**: Monitor service health and performance

## Performance Tuning

### Service Configuration
```ini
# Performance settings
worker_threads = 4                # Number of worker threads
max_connections = 1000            # Maximum concurrent connections
connection_timeout = 30           # Connection timeout (seconds)
cache_timeout = 300               # MIB cache timeout (seconds)
```

### System Optimization
- **CPU Affinity**: Set CPU affinity for better performance
- **Memory Limits**: Configure memory limits if needed
- **Network Buffers**: Tune network buffer sizes
- **Disk I/O**: Use SSD for log files if possible

## Uninstallation

### Complete Removal
```cmd
# Stop and remove service
install-service.bat uninstall

# Remove files (manual)
del "%SystemRoot%\System32\simple-snmpd-service.exe"
del "%SystemRoot%\System32\simple-snmpd.exe"

# Remove configuration (optional)
rmdir /s /q "%ProgramData%\Simple-SNMPd"
```

### PowerShell Removal
```powershell
# Stop and remove service
.\install-service.ps1 uninstall

# Remove configuration (optional)
Remove-Item -Path "$env:ProgramData\Simple-SNMPd" -Recurse -Force
```

## Support and Documentation

### Getting Help
- **Log Files**: Check service and error logs first
- **Event Viewer**: Look in Windows Event Viewer for system events
- **Documentation**: Refer to main project documentation
- **Community**: Check project issues and discussions

### Useful Commands
```cmd
# Service information
sc query SimpleSnmpd
sc qc SimpleSnmpd

# Process information
tasklist /fi "imagename eq simple-snmpd.exe"
netstat -an | findstr :161

# Log analysis
type "%ProgramData%\Simple-SNMPd\logs\simple-snmpd.log" | findstr ERROR
```

## License

Apache 2.0 - See LICENSE file for details.
