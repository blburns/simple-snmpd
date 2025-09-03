@echo off
REM Simple SNMP Daemon Windows Service Build Script
REM Copyright 2024 SimpleDaemons
REM Licensed under Apache 2.0

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_ROOT=%~dp0..\..
set BUILD_DIR=%PROJECT_ROOT%\build\windows
set DEPLOY_DIR=%~dp0
set SERVICE_NAME=simple-snmpd-service
set DAEMON_NAME=simple-snmpd

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

REM Check if Visual Studio is available
:check_visual_studio
call :log_info "Checking for Visual Studio..."

REM Try to find Visual Studio
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
)

if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        set "VS_INSTALL_PATH=%%i"
    )
)

if defined VS_INSTALL_PATH (
    call :log_success "Visual Studio found at: %VS_INSTALL_PATH%"
    
    REM Set up Visual Studio environment
    set "VS_DEVCMD=%VS_INSTALL_PATH%\Common7\Tools\VsDevCmd.bat"
    if exist "%VS_DEVCMD%" (
        call "%VS_DEVCMD%" -arch=x64
        call :log_success "Visual Studio environment configured"
    ) else (
        call :log_error "VsDevCmd.bat not found"
        exit /b 1
    )
) else (
    call :log_warning "Visual Studio not found, trying with system compiler..."
    
    REM Check for cl.exe in PATH
    where cl.exe >nul 2>&1
    if %errorLevel% neq 0 (
        call :log_error "Visual Studio compiler not found"
        call :log_error "Please install Visual Studio with C++ tools or run from Developer Command Prompt"
        exit /b 1
    )
)

goto :eof

REM Check dependencies
:check_dependencies
call :log_info "Checking dependencies..."

REM Check for required tools
where cl.exe >nul 2>&1
if %errorLevel% neq 0 (
    call :log_error "cl.exe not found"
    exit /b 1
)

where link.exe >nul 2>&1
if %errorLevel% neq 0 (
    call :log_error "link.exe not found"
    exit /b 1
)

where rc.exe >nul 2>&1
if %errorLevel% neq 0 (
    call :log_error "rc.exe not found"
    exit /b 1
)

call :log_success "All required tools found"
goto :eof

REM Create build directory
:create_build_dir
call :log_info "Creating build directory..."
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%BUILD_DIR%\service" mkdir "%BUILD_DIR%\service"
if not exist "%BUILD_DIR%\daemon" mkdir "%BUILD_DIR%\daemon"
call :log_success "Build directory created"
goto :eof

REM Build the main daemon
:build_daemon
call :log_info "Building SNMP daemon..."

REM Change to build directory
cd /d "%BUILD_DIR%\daemon"

REM Compile daemon source files
call :log_info "Compiling daemon source files..."
cl.exe /c /EHsc /O2 /D_WINDOWS /DNDEBUG ^
    "%PROJECT_ROOT%\src\main.cpp" ^
    "%PROJECT_ROOT%\src\core\*.cpp" ^
    /I"%PROJECT_ROOT%\include" ^
    /Fo"%BUILD_DIR%\daemon\\"

if %errorLevel% neq 0 (
    call :log_error "Failed to compile daemon source files"
    exit /b 1
)

REM Link daemon executable
call :log_info "Linking daemon executable..."
link.exe /OUT:"%BUILD_DIR%\daemon\%DAEMON_NAME%.exe" ^
    "%BUILD_DIR%\daemon\*.obj" ^
    ws2_32.lib ^
    advapi32.lib ^
    kernel32.lib ^
    user32.lib ^
    /SUBSYSTEM:CONSOLE

if %errorLevel% neq 0 (
    call :log_error "Failed to link daemon executable"
    exit /b 1
)

call :log_success "Daemon built successfully"
goto :eof

REM Build the service wrapper
:build_service
call :log_info "Building service wrapper..."

REM Change to service build directory
cd /d "%BUILD_DIR%\service"

REM Compile service wrapper
call :log_info "Compiling service wrapper..."
cl.exe /c /EHsc /O2 /D_WINDOWS /DNDEBUG ^
    "%DEPLOY_DIR%simple-snmpd-service.cpp" ^
    /I"%PROJECT_ROOT%\include" ^
    /Fo"%BUILD_DIR%\service\\"

if %errorLevel% neq 0 (
    call :log_error "Failed to compile service wrapper"
    exit /b 1
)

REM Compile resource file
call :log_info "Compiling resource file..."
rc.exe /fo"%BUILD_DIR%\service\simple-snmpd-service.res" ^
    "%DEPLOY_DIR%simple-snmpd-service.rc"

if %errorLevel% neq 0 (
    call :log_error "Failed to compile resource file"
    exit /b 1
)

REM Link service executable
call :log_info "Linking service executable..."
link.exe /OUT:"%BUILD_DIR%\service\%SERVICE_NAME%.exe" ^
    "%BUILD_DIR%\service\*.obj" ^
    "%BUILD_DIR%\service\*.res" ^
    ws2_32.lib ^
    advapi32.lib ^
    kernel32.lib ^
    user32.lib ^
    /SUBSYSTEM:WINDOWS

if %errorLevel% neq 0 (
    call :log_error "Failed to link service executable"
    exit /b 1
)

call :log_success "Service wrapper built successfully"
goto :eof

REM Copy files to deployment directory
:copy_files
call :log_info "Copying files to deployment directory..."

REM Copy executables
copy "%BUILD_DIR%\daemon\%DAEMON_NAME%.exe" "%DEPLOY_DIR%\" >nul
copy "%BUILD_DIR%\service\%SERVICE_NAME%.exe" "%DEPLOY_DIR%\" >nul

REM Copy configuration files
if not exist "%DEPLOY_DIR%\config" mkdir "%DEPLOY_DIR%\config"
copy "%PROJECT_ROOT%\config\simple-snmpd.conf" "%DEPLOY_DIR%\config\" >nul 2>&1

call :log_success "Files copied to deployment directory"
goto :eof

REM Create installer package
:create_package
call :log_info "Creating installer package..."

REM Create package directory
set "PACKAGE_DIR=%BUILD_DIR%\package"
if not exist "%PACKAGE_DIR%" mkdir "%PACKAGE_DIR%"

REM Copy all necessary files
copy "%DEPLOY_DIR%\%DAEMON_NAME%.exe" "%PACKAGE_DIR%\" >nul
copy "%DEPLOY_DIR%\%SERVICE_NAME%.exe" "%PACKAGE_DIR%\" >nul
copy "%DEPLOY_DIR%\install-service.bat" "%PACKAGE_DIR%\" >nul
copy "%DEPLOY_DIR%\install-service.ps1" "%PACKAGE_DIR%\" >nul
copy "%DEPLOY_DIR%\config\simple-snmpd.conf" "%PACKAGE_DIR%\" >nul

REM Create README
(
echo Simple SNMP Daemon Windows Package
echo ==================================
echo.
echo This package contains:
echo - simple-snmpd.exe: The main SNMP daemon
echo - simple-snmpd-service.exe: Windows service wrapper
echo - install-service.bat: Batch installation script
echo - install-service.ps1: PowerShell installation script
echo - simple-snmpd.conf: Configuration file
echo.
echo Installation:
echo 1. Run install-service.bat as Administrator
echo 2. Or use PowerShell: .\install-service.ps1 install
echo.
echo For more information, see the documentation.
) > "%PACKAGE_DIR%\README.txt"

REM Create ZIP package
call :log_info "Creating ZIP package..."
powershell -Command "Compress-Archive -Path '%PACKAGE_DIR%\*' -DestinationPath '%BUILD_DIR%\simple-snmpd-windows.zip' -Force"

if %errorLevel% equ 0 (
    call :log_success "Package created: %BUILD_DIR%\simple-snmpd-windows.zip"
) else (
    call :log_warning "Failed to create ZIP package"
)

goto :eof

REM Clean build directory
:clean
call :log_info "Cleaning build directory..."
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
call :log_success "Build directory cleaned"
goto :eof

REM Show usage
:usage
echo.
echo Simple SNMP Daemon Windows Build Script
echo =======================================
echo.
echo Usage: %0 [clean^|build^|package^|all]
echo.
echo Commands:
echo   clean   - Clean build directory
echo   build   - Build daemon and service wrapper
echo   package - Create installer package
echo   all     - Clean, build, and package
echo.
goto :eof

REM Main script logic
if "%1"=="clean" goto clean
if "%1"=="build" goto build
if "%1"=="package" goto package
if "%1"=="all" goto all
if "%1"=="" goto all
goto usage

:build
call :log_info "Starting Windows build process..."
call :check_visual_studio
call :check_dependencies
call :create_build_dir
call :build_daemon
call :build_service
call :copy_files
call :log_success "Build completed successfully!"
goto :end

:package
call :log_info "Creating package..."
call :create_package
call :log_success "Package created successfully!"
goto :end

:all
call :log_info "Starting complete build process..."
call :clean
call :check_visual_studio
call :check_dependencies
call :create_build_dir
call :build_daemon
call :build_service
call :copy_files
call :create_package
call :log_success "Complete build process finished successfully!"
goto :end

:end
echo.
call :log_info "Build artifacts:"
echo   Daemon: %BUILD_DIR%\daemon\%DAEMON_NAME%.exe
echo   Service: %BUILD_DIR%\service\%SERVICE_NAME%.exe
echo   Package: %BUILD_DIR%\simple-snmpd-windows.zip
echo.
pause
