# Init.d Service Scripts

This directory contains traditional init.d service scripts for Simple SNMP Daemon with enhanced systemd compatibility.

## Files

### `simple-snmpd`
The main init.d service script that provides:
- **Traditional init.d compatibility** for older Linux distributions
- **Systemd wrapper functionality** when systemd is available
- **Automatic detection** of the init system
- **Fallback mechanisms** for systems without standard init.d functions

### `install-systemd-service.sh`
Installation script that:
- Installs both systemd service and init.d wrapper
- Enables automatic systemd detection
- Provides unified service management
- Supports uninstallation and testing

## Features

### 🔄 Dual Compatibility
- **Systemd Systems**: Automatically uses systemd when available
- **Traditional Systems**: Falls back to classic init.d methods
- **Seamless Operation**: Same commands work on both systems

### 🛠️ Enhanced Functionality
- **Smart Detection**: Automatically detects init system
- **Robust Fallbacks**: Works even without standard init.d functions
- **Cross-Distribution**: Compatible with RHEL, Debian, Ubuntu, etc.
- **Service Information**: Built-in system information display

### 📋 Available Commands
```bash
# Traditional init.d commands
/etc/init.d/simple-snmpd start
/etc/init.d/simple-snmpd stop
/etc/init.d/simple-snmpd restart
/etc/init.d/simple-snmpd reload
/etc/init.d/simple-snmpd status
/etc/init.d/simple-snmpd configtest
/etc/init.d/simple-snmpd info

# Service command (if available)
service simple-snmpd start
service simple-snmpd stop
service simple-snmpd restart
service simple-snmpd status

# Systemctl commands (on systemd systems)
systemctl start simple-snmpd
systemctl stop simple-snmpd
systemctl restart simple-snmpd
systemctl status simple-snmpd
```

## Installation

### Quick Installation
```bash
# Install both systemd service and init.d wrapper
sudo ./deployment/init.d/install-systemd-service.sh install
```

### Manual Installation
```bash
# Copy init.d script
sudo cp deployment/init.d/simple-snmpd /etc/init.d/
sudo chmod +x /etc/init.d/simple-snmpd

# Copy systemd service (if using systemd)
sudo cp deployment/systemd/simple-snmpd.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable simple-snmpd
```

## How It Works

### 1. Init System Detection
The script automatically detects the init system:
- Checks for systemd directories and commands
- Verifies systemctl availability
- Falls back to traditional init.d if systemd unavailable

### 2. Service Management
When systemd is available:
- Uses `systemctl` commands for service management
- Leverages systemd's advanced features (logging, dependencies, etc.)
- Maintains init.d compatibility for legacy scripts

When systemd is not available:
- Uses traditional init.d methods
- Supports multiple init.d implementations (RHEL, Debian, etc.)
- Provides fallbacks for missing functions

### 3. Configuration
The script uses these default paths:
- **Binary**: `/usr/sbin/simple-snmpd`
- **Config**: `/etc/simple-snmpd/simple-snmpd.conf`
- **PID File**: `/var/run/simple-snmpd/simple-snmpd.pid`
- **User**: `snmp`
- **Group**: `snmp`

## Compatibility

### Supported Distributions
- **RHEL/CentOS**: 6.x, 7.x, 8.x, 9.x
- **Fedora**: All versions
- **Debian**: 8.x, 9.x, 10.x, 11.x, 12.x
- **Ubuntu**: 16.04, 18.04, 20.04, 22.04, 24.04
- **SUSE**: openSUSE, SLES
- **Arch Linux**: All versions

### Init Systems
- **systemd**: Primary (when available)
- **SysV init**: Fallback support
- **Upstart**: Limited support
- **OpenRC**: Basic support

## Troubleshooting

### Service Won't Start
```bash
# Check service status
/etc/init.d/simple-snmpd status

# Check system information
/etc/init.d/simple-snmpd info

# Test configuration
/etc/init.d/simple-snmpd configtest

# Check logs
journalctl -u simple-snmpd -f
```

### Init System Detection Issues
```bash
# Force systemd detection
systemctl --version

# Check init system
ps -p 1 -o comm=

# Verify systemd directories
ls -la /run/systemd/system/
```

### Permission Issues
```bash
# Ensure proper ownership
sudo chown snmp:snmp /var/run/simple-snmpd/
sudo chown snmp:snmp /var/log/simple-snmpd/
sudo chown snmp:snmp /var/lib/simple-snmpd/

# Check file permissions
ls -la /etc/init.d/simple-snmpd
ls -la /usr/sbin/simple-snmpd
```

## Advanced Usage

### Custom Configuration
Edit the script variables for custom paths:
```bash
# Edit these variables in the script
SNMPD_BIN="/usr/local/bin/simple-snmpd"
SNMPD_CONF="/etc/simple-snmpd/custom.conf"
SNMPD_USER="custom-user"
SNMPD_GROUP="custom-group"
```

### Integration with Monitoring
```bash
# Check service health
if /etc/init.d/simple-snmpd status >/dev/null 2>&1; then
    echo "Service is running"
else
    echo "Service is not running"
    /etc/init.d/simple-snmpd start
fi
```

### Logging Integration
```bash
# Redirect output to syslog
/etc/init.d/simple-snmpd start 2>&1 | logger -t simple-snmpd

# Check service logs
tail -f /var/log/simple-snmpd/simple-snmpd.log
```

## Contributing

When modifying the init.d script:
1. Test on both systemd and traditional systems
2. Ensure backward compatibility
3. Update this documentation
4. Test with different Linux distributions

## License

Apache 2.0 - See LICENSE file for details.
