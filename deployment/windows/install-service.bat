@echo off
REM Simple SNMP Daemon Windows Service Installer
REM Copyright 2024 SimpleDaemons
REM Licensed under Apache 2.0

setlocal enabledelayedexpansion

REM Configuration
set SERVICE_NAME=SimpleSnmpd
set SERVICE_DISPLAY_NAME=Simple SNMP Daemon
set SERVICE_DESCRIPTION=Provides SNMP monitoring services for network devices
set BINARY_PATH=%~dp0simple-snmpd-service.exe
set CONFIG_DIR=%ProgramData%\Simple-SNMPd
set LOG_DIR=%ProgramData%\Simple-SNMPd\logs
set DATA_DIR=%ProgramData%\Simple-SNMPd\data
set MIB_DIR=%ProgramData%\Simple-SNMPd\mibs

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click on the script and select "Run as administrator"
    pause
    exit /b 1
)

REM Function to display usage
:usage
echo.
echo Simple SNMP Daemon Windows Service Manager
echo ==========================================
echo.
echo Usage: %0 [install^|uninstall^|start^|stop^|restart^|status^|config^|test]
echo.
echo Commands:
echo   install   - Install the SNMP service
echo   uninstall - Remove the SNMP service
echo   start     - Start the SNMP service
echo   stop      - Stop the SNMP service
echo   restart   - Restart the SNMP service
echo   status    - Show service status
echo   config    - Create configuration directory and files
echo   test      - Test SNMP connectivity
echo.
if "%1"=="" (
    set /p choice="Enter command: "
    set "1=!choice!"
)

REM Main command processing
if "%1"=="install" goto install
if "%1"=="uninstall" goto uninstall
if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="restart" goto restart
if "%1"=="status" goto status
if "%1"=="config" goto config
if "%1"=="test" goto test
goto usage

REM Install the service
:install
echo Installing Simple SNMP Daemon service...
echo.

REM Check if binary exists
if not exist "%BINARY_PATH%" (
    echo ERROR: Service binary not found at %BINARY_PATH%
    echo Please build the service binary first
    pause
    exit /b 1
)

REM Check if service already exists
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorLevel% equ 0 (
    echo Service %SERVICE_NAME% already exists
    set /p choice="Do you want to reinstall it? (y/N): "
    if /i "!choice!"=="y" (
        echo Uninstalling existing service...
        call :uninstall
    ) else (
        echo Installation cancelled
        pause
        exit /b 0
    )
)

REM Create service
echo Creating service %SERVICE_NAME%...
sc create "%SERVICE_NAME%" binPath= "%BINARY_PATH%" DisplayName= "%SERVICE_DISPLAY_NAME%" start= auto

if %errorLevel% neq 0 (
    echo ERROR: Failed to create service
    pause
    exit /b 1
)

REM Set service description
sc description "%SERVICE_NAME%" "%SERVICE_DESCRIPTION%"

REM Set service dependencies
sc config "%SERVICE_NAME%" depend= Tcpip

REM Set service failure actions
sc failure "%SERVICE_NAME%" reset= 86400 actions= restart/30000/restart/60000/restart/120000

REM Set service to run as Network Service (for SNMP security)
sc config "%SERVICE_NAME%" obj= "NT AUTHORITY\NetworkService"

echo.
echo Service installed successfully!
echo.
echo Next steps:
echo 1. Run '%0 config' to create configuration files
echo 2. Run '%0 start' to start the service
echo 3. Run '%0 status' to check service status
echo.
pause
exit /b 0

REM Uninstall the service
:uninstall
echo Uninstalling Simple SNMP Daemon service...
echo.

REM Stop service if running
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorLevel% equ 0 (
    echo Stopping service...
    sc stop "%SERVICE_NAME%" >nul 2>&1

    REM Wait for service to stop
    :wait_stop
    sc query "%SERVICE_NAME%" | find "STOPPED" >nul 2>&1
    if %errorLevel% neq 0 (
        timeout /t 1 /nobreak >nul
        goto wait_stop
    )
)

REM Delete service
echo Removing service...
sc delete "%SERVICE_NAME%"

if %errorLevel% equ 0 (
    echo Service removed successfully!
) else (
    echo Service was not found or could not be removed
)

echo.
pause
exit /b 0

REM Start the service
:start
echo Starting Simple SNMP Daemon service...
sc start "%SERVICE_NAME%"

if %errorLevel% equ 0 (
    echo Service started successfully!
) else (
    echo ERROR: Failed to start service
    echo Check the Windows Event Log for details
)

echo.
pause
exit /b 0

REM Stop the service
:stop
echo Stopping Simple SNMP Daemon service...
sc stop "%SERVICE_NAME%"

if %errorLevel% equ 0 (
    echo Service stopped successfully!
) else (
    echo ERROR: Failed to stop service
)

echo.
pause
exit /b 0

REM Restart the service
:restart
echo Restarting Simple SNMP Daemon service...
call :stop
timeout /t 2 /nobreak >nul
call :start
exit /b 0

REM Show service status
:status
echo Simple SNMP Daemon Service Status
echo ==================================
echo.
sc query "%SERVICE_NAME%"
echo.
echo Service Configuration:
sc qc "%SERVICE_NAME%"
echo.
pause
exit /b 0

REM Create configuration
:config
echo Creating Simple SNMP Daemon configuration...
echo.

REM Create directories
echo Creating directories...
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%MIB_DIR%" mkdir "%MIB_DIR%"

REM Create configuration file
echo Creating configuration file...
(
echo # Simple SNMP Daemon Configuration File
echo # Generated on %date% %time%
echo.
echo # Network configuration
echo listen_address = 0.0.0.0
echo listen_port = 161
echo enable_ipv6 = true
echo max_connections = 1000
echo connection_timeout = 30
echo.
echo # SNMP configuration
echo snmp_version = 2c
echo community_string = public
echo read_community = public
echo write_community = private
echo enable_v3 = false
echo.
echo # Security configuration
echo enable_authentication = false
echo authentication_protocol = MD5
echo privacy_protocol = DES
echo user_database = %CONFIG_DIR%\users.conf
echo access_control = %CONFIG_DIR%\access.conf
echo.
echo # MIB configuration
echo mib_directory = %MIB_DIR%
echo enable_mib_loading = true
echo mib_cache_size = 1000
echo.
echo # Logging configuration
echo log_level = info
echo log_file = %LOG_DIR%\simple-snmpd.log
echo error_log_file = %LOG_DIR%\simple-snmpd.error.log
echo enable_console_logging = false
echo enable_syslog = false
echo log_rotation = true
echo max_log_size = 10MB
echo max_log_files = 5
echo.
echo # Performance configuration
echo worker_threads = 4
echo max_packet_size = 65507
echo enable_statistics = true
echo stats_interval = 60
echo cache_timeout = 300
echo.
echo # SNMP Agent configuration
echo system_name = Windows Host
echo system_description = Simple SNMP Daemon on Windows
echo system_contact = admin@example.com
echo system_location = Data Center
echo system_uptime = true
echo.
echo # Trap configuration
echo enable_traps = true
echo trap_port = 162
echo trap_community = public
echo trap_destinations =
echo.
echo # Monitoring configuration
echo enable_system_monitoring = true
echo enable_network_monitoring = true
echo enable_disk_monitoring = true
echo enable_process_monitoring = false
echo monitoring_interval = 60
echo.
echo # Windows-specific configuration
echo enable_wmi_monitoring = true
echo wmi_namespace = root\cimv2
echo enable_performance_counters = true
echo performance_counter_interval = 30
) > "%CONFIG_DIR%\simple-snmpd.conf"

REM Create user database file
echo Creating user database file...
(
echo # SNMP User Database
echo # Format: username:auth_protocol:auth_password:priv_protocol:priv_password
echo.
echo # Example users (change passwords in production)
echo # admin:MD5:adminpass:DES:privpass
echo # readonly:SHA:readpass::
) > "%CONFIG_DIR%\users.conf"

REM Create access control file
echo Creating access control file...
(
echo # SNMP Access Control
echo # Format: group:security_model:security_level:read_view:write_view:notify_view
echo.
echo # Default access groups
echo # readonly:usm:noAuthNoPriv:system::
echo # readwrite:usm:authPriv:system:system:system
) > "%CONFIG_DIR%\access.conf"

REM Create log files
echo Creating log files...
echo. > "%LOG_DIR%\simple-snmpd.log"
echo. > "%LOG_DIR%\simple-snmpd.error.log"

REM Set permissions (basic - in production you'd want more security)
echo Setting permissions...
icacls "%CONFIG_DIR%" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T
icacls "%CONFIG_DIR%" /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T
icacls "%LOG_DIR%" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T
icacls "%LOG_DIR%" /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T
icacls "%DATA_DIR%" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T
icacls "%DATA_DIR%" /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T
icacls "%MIB_DIR%" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T
icacls "%MIB_DIR%" /grant "NT AUTHORITY\NetworkService:(OI)(CI)F" /T

echo.
echo Configuration created successfully!
echo.
echo Configuration file: %CONFIG_DIR%\simple-snmpd.conf
echo User database: %CONFIG_DIR%\users.conf
echo Access control: %CONFIG_DIR%\access.conf
echo Log directory: %LOG_DIR%
echo Data directory: %DATA_DIR%
echo MIB directory: %MIB_DIR%
echo.
echo You can now edit the configuration files and start the service.
echo.
pause
exit /b 0

REM Test SNMP connectivity
:test
echo Testing SNMP connectivity...
echo.

REM Check if service is running
sc query "%SERVICE_NAME%" | find "RUNNING" >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Service is not running
    echo Please start the service first with: %0 start
    pause
    exit /b 1
)

REM Test with snmpget if available
echo Testing SNMP GET request...
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0 2>nul
if %errorLevel% equ 0 (
    echo SUCCESS: SNMP GET request successful
) else (
    echo WARNING: snmpget not available or request failed
    echo You can test manually with: snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0
)

REM Test with snmpwalk if available
echo.
echo Testing SNMP WALK request...
snmptable -v2c -c public localhost 1.3.6.1.2.1.1 2>nul
if %errorLevel% equ 0 (
    echo SUCCESS: SNMP WALK request successful
) else (
    echo WARNING: snmptable not available or request failed
    echo You can test manually with: snmptable -v2c -c public localhost 1.3.6.1.2.1.1
)

REM Test port connectivity
echo.
echo Testing port connectivity...
netstat -an | find ":161 " >nul 2>&1
if %errorLevel% equ 0 (
    echo SUCCESS: Port 161 is listening
) else (
    echo WARNING: Port 161 is not listening
)

echo.
echo SNMP connectivity test completed!
echo.
pause
exit /b 0
