# Simple SNMP Daemon Windows Service Manager (PowerShell)
# Copyright 2024 SimpleDaemons
# Licensed under Apache 2.0

param(
    [Parameter(Position=0)]
    [ValidateSet("install", "uninstall", "start", "stop", "restart", "status", "config", "test", "logs", "monitor")]
    [string]$Action = "install",

    [switch]$Force,
    [switch]$Verbose
)

# Configuration
$ServiceName = "SimpleSnmpd"
$ServiceDisplayName = "Simple SNMP Daemon"
$ServiceDescription = "Provides SNMP monitoring services for network devices"
$BinaryPath = Join-Path $PSScriptRoot "simple-snmpd-service.exe"
$ConfigDir = "$env:ProgramData\Simple-SNMPd"
$LogDir = "$ConfigDir\logs"
$DataDir = "$ConfigDir\data"
$MibDir = "$ConfigDir\mibs"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
    White = "White"
}

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Show usage information
function Show-Usage {
    Write-Host ""
    Write-Host "Simple SNMP Daemon Windows Service Manager" -ForegroundColor $Colors.Cyan
    Write-Host "===========================================" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\install-service.ps1 [Action] [-Force] [-Verbose]"
    Write-Host ""
    Write-Host "Actions:"
    Write-Host "  install   - Install the SNMP service"
    Write-Host "  uninstall - Remove the SNMP service"
    Write-Host "  start     - Start the SNMP service"
    Write-Host "  stop      - Stop the SNMP service"
    Write-Host "  restart   - Restart the SNMP service"
    Write-Host "  status    - Show service status and configuration"
    Write-Host "  config    - Create configuration directory and files"
    Write-Host "  test      - Test SNMP connectivity"
    Write-Host "  logs      - Show recent service logs"
    Write-Host "  monitor   - Monitor service in real-time"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Force    - Force operation without confirmation"
    Write-Host "  -Verbose  - Show detailed output"
    Write-Host ""
}

# Install the service
function Install-Service {
    Write-Info "Installing Simple SNMP Daemon service..."

    # Check if binary exists
    if (-not (Test-Path $BinaryPath)) {
        Write-Error "Service binary not found at $BinaryPath"
        Write-Error "Please build the service binary first"
        exit 1
    }

    # Check if service already exists
    $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existingService) {
        if (-not $Force) {
            $choice = Read-Host "Service $ServiceName already exists. Do you want to reinstall it? (y/N)"
            if ($choice -ne "y" -and $choice -ne "Y") {
                Write-Info "Installation cancelled"
                return
            }
        }
        Write-Info "Uninstalling existing service..."
        Uninstall-Service
    }

    # Create service
    Write-Info "Creating service $ServiceName..."
    try {
        New-Service -Name $ServiceName -BinaryPathName $BinaryPath -DisplayName $ServiceDisplayName -Description $ServiceDescription -StartupType Automatic -ErrorAction Stop

        # Configure service
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        $service.Change($null, $null, $null, $null, $null, $null, "Tcpip", $null, $null, $null, $null)

        # Set service to run as Network Service
        $service.Change($null, $null, $null, $null, $null, $null, $null, "NT AUTHORITY\NetworkService", $null, $null, $null)

        # Configure failure actions
        sc.exe failure $ServiceName reset=86400 actions=restart/30000/restart/60000/restart/120000

        Write-Success "Service installed successfully!"
        Write-Info "Next steps:"
        Write-Info "1. Run '.\install-service.ps1 config' to create configuration files"
        Write-Info "2. Run '.\install-service.ps1 start' to start the service"
        Write-Info "3. Run '.\install-service.ps1 status' to check service status"
    }
    catch {
        Write-Error "Failed to create service: $($_.Exception.Message)"
        exit 1
    }
}

# Uninstall the service
function Uninstall-Service {
    Write-Info "Uninstalling Simple SNMP Daemon service..."

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        # Stop service if running
        if ($service.Status -eq "Running") {
            Write-Info "Stopping service..."
            Stop-Service -Name $ServiceName -Force
            $service.WaitForStatus("Stopped", (New-TimeSpan -Seconds 30))
        }

        # Remove service
        Write-Info "Removing service..."
        try {
            $wmiService = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
            $wmiService.Delete()
            Write-Success "Service removed successfully!"
        }
        catch {
            Write-Error "Failed to remove service: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Service was not found"
    }
}

# Start the service
function Start-Service {
    Write-Info "Starting Simple SNMP Daemon service..."
    try {
        Start-Service -Name $ServiceName
        Write-Success "Service started successfully!"
    }
    catch {
        Write-Error "Failed to start service: $($_.Exception.Message)"
        Write-Error "Check the Windows Event Log for details"
    }
}

# Stop the service
function Stop-Service {
    Write-Info "Stopping Simple SNMP Daemon service..."
    try {
        Stop-Service -Name $ServiceName -Force
        Write-Success "Service stopped successfully!"
    }
    catch {
        Write-Error "Failed to stop service: $($_.Exception.Message)"
    }
}

# Restart the service
function Restart-Service {
    Write-Info "Restarting Simple SNMP Daemon service..."
    Stop-Service
    Start-Sleep -Seconds 2
    Start-Service
}

# Show service status
function Show-Status {
    Write-Host ""
    Write-Host "Simple SNMP Daemon Service Status" -ForegroundColor $Colors.Cyan
    Write-Host "==================================" -ForegroundColor $Colors.Cyan
    Write-Host ""

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Service Name: $($service.Name)"
        Write-Host "Display Name: $($service.DisplayName)"
        Write-Host "Status: $($service.Status)"
        Write-Host "Start Type: $($service.StartType)"
        Write-Host ""

        # Show service configuration
        $wmiService = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        Write-Host "Binary Path: $($wmiService.PathName)"
        Write-Host "Service Account: $($wmiService.StartName)"
        Write-Host "Dependencies: $($wmiService.ServiceDependencies -join ', ')"
        Write-Host ""

        # Show port status
        $port161 = Get-NetTCPConnection -LocalPort 161 -ErrorAction SilentlyContinue
        if ($port161) {
            Write-Success "Port 161 is listening"
        } else {
            Write-Warning "Port 161 is not listening"
        }

        # Show recent events
        Write-Host ""
        Write-Host "Recent Service Events:"
        Get-WinEvent -FilterHashtable @{LogName='System'; ID=7034,7035,7036} -MaxEvents 5 | Where-Object { $_.Message -like "*$ServiceName*" } | ForEach-Object {
            Write-Host "  $($_.TimeCreated): $($_.Message)"
        }
    }
    else {
        Write-Error "Service not found"
    }
}

# Create configuration
function New-Configuration {
    Write-Info "Creating Simple SNMP Daemon configuration..."

    # Create directories
    Write-Info "Creating directories..."
    @($ConfigDir, $LogDir, $DataDir, $MibDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }

    # Create configuration file
    Write-Info "Creating configuration file..."
    $configContent = @"
# Simple SNMP Daemon Configuration File
# Generated on $(Get-Date)

# Network configuration
listen_address = 0.0.0.0
listen_port = 161
enable_ipv6 = true
max_connections = 1000
connection_timeout = 30

# SNMP configuration
snmp_version = 2c
community_string = public
read_community = public
write_community = private
enable_v3 = false

# Security configuration
enable_authentication = false
authentication_protocol = MD5
privacy_protocol = DES
user_database = $ConfigDir\users.conf
access_control = $ConfigDir\access.conf

# MIB configuration
mib_directory = $MibDir
enable_mib_loading = true
mib_cache_size = 1000

# Logging configuration
log_level = info
log_file = $LogDir\simple-snmpd.log
error_log_file = $LogDir\simple-snmpd.error.log
enable_console_logging = false
enable_syslog = false
log_rotation = true
max_log_size = 10MB
max_log_files = 5

# Performance configuration
worker_threads = 4
max_packet_size = 65507
enable_statistics = true
stats_interval = 60
cache_timeout = 300

# SNMP Agent configuration
system_name = Windows Host
system_description = Simple SNMP Daemon on Windows
system_contact = admin@example.com
system_location = Data Center
system_uptime = true

# Trap configuration
enable_traps = true
trap_port = 162
trap_community = public
trap_destinations =

# Monitoring configuration
enable_system_monitoring = true
enable_network_monitoring = true
enable_disk_monitoring = true
enable_process_monitoring = false
monitoring_interval = 60

# Windows-specific configuration
enable_wmi_monitoring = true
wmi_namespace = root\cimv2
enable_performance_counters = true
performance_counter_interval = 30
"@

    $configContent | Out-File -FilePath "$ConfigDir\simple-snmpd.conf" -Encoding UTF8

    # Create user database file
    Write-Info "Creating user database file..."
    $userContent = @"
# SNMP User Database
# Format: username:auth_protocol:auth_password:priv_protocol:priv_password

# Example users (change passwords in production)
# admin:MD5:adminpass:DES:privpass
# readonly:SHA:readpass::
"@
    $userContent | Out-File -FilePath "$ConfigDir\users.conf" -Encoding UTF8

    # Create access control file
    Write-Info "Creating access control file..."
    $accessContent = @"
# SNMP Access Control
# Format: group:security_model:security_level:read_view:write_view:notify_view

# Default access groups
# readonly:usm:noAuthNoPriv:system::
# readwrite:usm:authPriv:system:system:system
"@
    $accessContent | Out-File -FilePath "$ConfigDir\access.conf" -Encoding UTF8

    # Create log files
    Write-Info "Creating log files..."
    "" | Out-File -FilePath "$LogDir\simple-snmpd.log" -Encoding UTF8
    "" | Out-File -FilePath "$LogDir\simple-snmpd.error.log" -Encoding UTF8

    # Set permissions
    Write-Info "Setting permissions..."
    $directories = @($ConfigDir, $LogDir, $DataDir, $MibDir)
    foreach ($dir in $directories) {
        icacls $dir /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T | Out-Null
        icacls $dir /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T | Out-Null
    }

    Write-Success "Configuration created successfully!"
    Write-Info "Configuration file: $ConfigDir\simple-snmpd.conf"
    Write-Info "User database: $ConfigDir\users.conf"
    Write-Info "Access control: $ConfigDir\access.conf"
    Write-Info "Log directory: $LogDir"
    Write-Info "Data directory: $DataDir"
    Write-Info "MIB directory: $MibDir"
}

# Test SNMP connectivity
function Test-SNMPConnectivity {
    Write-Info "Testing SNMP connectivity..."

    # Check if service is running
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $service -or $service.Status -ne "Running") {
        Write-Error "Service is not running"
        Write-Error "Please start the service first with: .\install-service.ps1 start"
        return
    }

    # Test port connectivity
    Write-Info "Testing port connectivity..."
    $port161 = Get-NetTCPConnection -LocalPort 161 -ErrorAction SilentlyContinue
    if ($port161) {
        Write-Success "Port 161 is listening"
    } else {
        Write-Warning "Port 161 is not listening"
    }

    # Test with snmpget if available
    Write-Info "Testing SNMP GET request..."
    try {
        $result = & snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "SNMP GET request successful"
            if ($Verbose) {
                Write-Host "Response: $result"
            }
        } else {
            Write-Warning "snmpget not available or request failed"
        }
    }
    catch {
        Write-Warning "snmpget not available or request failed"
    }

    # Test with snmpwalk if available
    Write-Info "Testing SNMP WALK request..."
    try {
        $result = & snmptable -v2c -c public localhost 1.3.6.1.2.1.1 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "SNMP WALK request successful"
        } else {
            Write-Warning "snmptable not available or request failed"
        }
    }
    catch {
        Write-Warning "snmptable not available or request failed"
    }

    Write-Success "SNMP connectivity test completed!"
}

# Show service logs
function Show-Logs {
    Write-Info "Showing recent service logs..."

    if (Test-Path "$LogDir\simple-snmpd.log") {
        Write-Host ""
        Write-Host "Recent Log Entries:" -ForegroundColor $Colors.Cyan
        Get-Content "$LogDir\simple-snmpd.log" -Tail 20
    } else {
        Write-Warning "Log file not found: $LogDir\simple-snmpd.log"
    }

    if (Test-Path "$LogDir\simple-snmpd.error.log") {
        Write-Host ""
        Write-Host "Recent Error Log Entries:" -ForegroundColor $Colors.Cyan
        Get-Content "$LogDir\simple-snmpd.error.log" -Tail 10
    }
}

# Monitor service in real-time
function Start-Monitoring {
    Write-Info "Starting real-time service monitoring..."
    Write-Info "Press Ctrl+C to stop monitoring"

    while ($true) {
        Clear-Host
        Write-Host "Simple SNMP Daemon Service Monitor" -ForegroundColor $Colors.Cyan
        Write-Host "===================================" -ForegroundColor $Colors.Cyan
        Write-Host "Time: $(Get-Date)" -ForegroundColor $Colors.White
        Write-Host ""

        # Service status
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { $Colors.Green } else { $Colors.Red })
        } else {
            Write-Host "Service Status: Not Found" -ForegroundColor $Colors.Red
        }

        # Port status
        $port161 = Get-NetTCPConnection -LocalPort 161 -ErrorAction SilentlyContinue
        Write-Host "Port 161: $(if ($port161) { 'Listening' } else { 'Not Listening' })" -ForegroundColor $(if ($port161) { $Colors.Green } else { $Colors.Red })

        # Recent log entries
        if (Test-Path "$LogDir\simple-snmpd.log") {
            Write-Host ""
            Write-Host "Recent Log Entries:" -ForegroundColor $Colors.Cyan
            Get-Content "$LogDir\simple-snmpd.log" -Tail 5 | ForEach-Object { Write-Host "  $_" }
        }

        Start-Sleep -Seconds 5
    }
}

# Main script logic
if (-not (Test-Administrator)) {
    Write-Error "This script must be run as Administrator"
    Write-Error "Right-click on PowerShell and select 'Run as administrator'"
    exit 1
}

switch ($Action) {
    "install" { Install-Service }
    "uninstall" { Uninstall-Service }
    "start" { Start-Service }
    "stop" { Stop-Service }
    "restart" { Restart-Service }
    "status" { Show-Status }
    "config" { New-Configuration }
    "test" { Test-SNMPConnectivity }
    "logs" { Show-Logs }
    "monitor" { Start-Monitoring }
    default { Show-Usage }
}
