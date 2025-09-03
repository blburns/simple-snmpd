@echo off
REM Simple SNMP Daemon Windows Firewall Configuration
REM Copyright 2024 SimpleDaemons
REM Licensed under Apache 2.0

setlocal enabledelayedexpansion

REM Configuration
set SERVICE_NAME=SimpleSnmpd
set SNMP_PORT=161
set TRAP_PORT=162

REM Colors for output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

REM Logging functions
:log_info
echo %BLUE%[INFO]%RESET% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%RESET% %~1
goto :eof

:log_warning
echo %YELLOW%[WARNING]%RESET% %~1
goto :eof

:log_error
echo %RED%[ERROR]%RESET% %~1
goto :eof

REM Check if running as administrator
:check_admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    call :log_error "This script must be run as Administrator"
    call :log_error "Right-click on the script and select 'Run as administrator'"
    pause
    exit /b 1
)
goto :eof

REM Show usage
:usage
echo.
echo Simple SNMP Daemon Windows Firewall Configuration
echo ================================================
echo.
echo Usage: %0 [add^|remove^|status^|test]
echo.
echo Commands:
echo   add     - Add firewall rules for SNMP
echo   remove  - Remove firewall rules for SNMP
echo   status  - Show firewall rule status
echo   test    - Test firewall configuration
echo.
goto :eof

REM Add firewall rules
:add_rules
call :log_info "Adding Windows Firewall rules for SNMP..."

REM Check if Windows Firewall is enabled
netsh advfirewall show allprofiles state | find "State" | find "ON" >nul 2>&1
if %errorLevel% neq 0 (
    call :log_warning "Windows Firewall appears to be disabled"
    set /p choice="Do you want to continue anyway? (y/N): "
    if /i "!choice!" neq "y" (
        call :log_info "Firewall configuration cancelled"
        exit /b 0
    )
)

REM Add inbound rule for SNMP agent (port 161)
call :log_info "Adding inbound rule for SNMP agent (port %SNMP_PORT%)..."
netsh advfirewall firewall add rule ^
    name="Simple SNMP Daemon - SNMP Agent" ^
    dir=in ^
    action=allow ^
    protocol=UDP ^
    localport=%SNMP_PORT% ^
    profile=any ^
    description="Allow SNMP agent traffic for Simple SNMP Daemon"

if %errorLevel% equ 0 (
    call :log_success "SNMP agent rule added successfully"
) else (
    call :log_error "Failed to add SNMP agent rule"
)

REM Add inbound rule for SNMP traps (port 162)
call :log_info "Adding inbound rule for SNMP traps (port %TRAP_PORT%)..."
netsh advfirewall firewall add rule ^
    name="Simple SNMP Daemon - SNMP Traps" ^
    dir=in ^
    action=allow ^
    protocol=UDP ^
    localport=%TRAP_PORT% ^
    profile=any ^
    description="Allow SNMP trap traffic for Simple SNMP Daemon"

if %errorLevel% equ 0 (
    call :log_success "SNMP trap rule added successfully"
) else (
    call :log_error "Failed to add SNMP trap rule"
)

REM Add outbound rule for SNMP traps (port 162)
call :log_info "Adding outbound rule for SNMP traps (port %TRAP_PORT%)..."
netsh advfirewall firewall add rule ^
    name="Simple SNMP Daemon - SNMP Trap Outbound" ^
    dir=out ^
    action=allow ^
    protocol=UDP ^
    remoteport=%TRAP_PORT% ^
    profile=any ^
    description="Allow outbound SNMP trap traffic for Simple SNMP Daemon"

if %errorLevel% equ 0 (
    call :log_success "SNMP trap outbound rule added successfully"
) else (
    call :log_error "Failed to add SNMP trap outbound rule"
)

REM Add application rule for the service
call :log_info "Adding application rule for Simple SNMP Daemon service..."
set "SERVICE_PATH=%SystemRoot%\System32\simple-snmpd-service.exe"
if exist "%SERVICE_PATH%" (
    netsh advfirewall firewall add rule ^
        name="Simple SNMP Daemon - Service" ^
        dir=in ^
        action=allow ^
        program="%SERVICE_PATH%" ^
        profile=any ^
        description="Allow Simple SNMP Daemon service"

    if %errorLevel% equ 0 (
        call :log_success "Service application rule added successfully"
    ) else (
        call :log_error "Failed to add service application rule"
    )
) else (
    call :log_warning "Service executable not found at %SERVICE_PATH%"
    call :log_info "Application rule will be added when service is installed"
)

call :log_success "Firewall rules configuration completed!"
goto :eof

REM Remove firewall rules
:remove_rules
call :log_info "Removing Windows Firewall rules for SNMP..."

REM Remove SNMP agent rule
call :log_info "Removing SNMP agent rule..."
netsh advfirewall firewall delete rule name="Simple SNMP Daemon - SNMP Agent" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP agent rule removed"
) else (
    call :log_warning "SNMP agent rule not found or already removed"
)

REM Remove SNMP trap inbound rule
call :log_info "Removing SNMP trap inbound rule..."
netsh advfirewall firewall delete rule name="Simple SNMP Daemon - SNMP Traps" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP trap inbound rule removed"
) else (
    call :log_warning "SNMP trap inbound rule not found or already removed"
)

REM Remove SNMP trap outbound rule
call :log_info "Removing SNMP trap outbound rule..."
netsh advfirewall firewall delete rule name="Simple SNMP Daemon - SNMP Trap Outbound" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP trap outbound rule removed"
) else (
    call :log_warning "SNMP trap outbound rule not found or already removed"
)

REM Remove service application rule
call :log_info "Removing service application rule..."
netsh advfirewall firewall delete rule name="Simple SNMP Daemon - Service" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "Service application rule removed"
) else (
    call :log_warning "Service application rule not found or already removed"
)

call :log_success "Firewall rules removal completed!"
goto :eof

REM Show firewall rule status
:show_status
call :log_info "Checking Windows Firewall rule status..."

echo.
echo Windows Firewall Status:
echo =======================
netsh advfirewall show allprofiles state

echo.
echo SNMP-related Firewall Rules:
echo ============================
netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Agent" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP Agent rule is present"
    netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Agent"
) else (
    call :log_warning "SNMP Agent rule is not present"
)

echo.
netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Traps" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP Trap inbound rule is present"
    netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Traps"
) else (
    call :log_warning "SNMP Trap inbound rule is not present"
)

echo.
netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Trap Outbound" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP Trap outbound rule is present"
    netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Trap Outbound"
) else (
    call :log_warning "SNMP Trap outbound rule is not present"
)

echo.
netsh advfirewall firewall show rule name="Simple SNMP Daemon - Service" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "Service application rule is present"
    netsh advfirewall firewall show rule name="Simple SNMP Daemon - Service"
) else (
    call :log_warning "Service application rule is not present"
)

echo.
call :log_info "Port status:"
netstat -an | findstr ":%SNMP_PORT% " >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "Port %SNMP_PORT% is listening"
    netstat -an | findstr ":%SNMP_PORT% "
) else (
    call :log_warning "Port %SNMP_PORT% is not listening"
)

netstat -an | findstr ":%TRAP_PORT% " >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "Port %TRAP_PORT% is listening"
    netstat -an | findstr ":%TRAP_PORT% "
) else (
    call :log_warning "Port %TRAP_PORT% is not listening"
)

goto :eof

REM Test firewall configuration
:test_firewall
call :log_info "Testing firewall configuration..."

REM Check if service is running
sc query "%SERVICE_NAME%" | find "RUNNING" >nul 2>&1
if %errorLevel% neq 0 (
    call :log_warning "Simple SNMP Daemon service is not running"
    call :log_info "Please start the service first with: install-service.bat start"
    goto :eof
)

REM Test local connectivity
call :log_info "Testing local SNMP connectivity..."
powershell -Command "Test-NetConnection -ComputerName localhost -Port %SNMP_PORT% -InformationLevel Quiet" 2>nul
if %errorLevel% equ 0 (
    call :log_success "Local SNMP connectivity test passed"
) else (
    call :log_error "Local SNMP connectivity test failed"
)

REM Test with snmpget if available
call :log_info "Testing SNMP GET request..."
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0 >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP GET request test passed"
) else (
    call :log_warning "snmpget not available or request failed"
    call :log_info "You can test manually with: snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0"
)

REM Test firewall rules
call :log_info "Testing firewall rules..."
netsh advfirewall firewall show rule name="Simple SNMP Daemon - SNMP Agent" >nul 2>&1
if %errorLevel% equ 0 (
    call :log_success "SNMP Agent firewall rule is active"
) else (
    call :log_error "SNMP Agent firewall rule is missing"
)

call :log_success "Firewall configuration test completed!"
goto :eof

REM Main script logic
call :check_admin

if "%1"=="add" goto add_rules
if "%1"=="remove" goto remove_rules
if "%1"=="status" goto show_status
if "%1"=="test" goto test_firewall
if "%1"=="" goto usage
goto usage

echo.
pause
