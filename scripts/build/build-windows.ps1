# Simple SNMP Daemon Windows Build Script
# Copyright 2024 SimpleDaemons
# Licensed under Apache 2.0

param(
    [Parameter(Position=0)]
    [ValidateSet("clean", "build", "package", "install", "test", "all")]
    [string]$Action = "all",

    [string]$Configuration = "Release",
    [string]$Platform = "x64",
    [string]$OutputDir = "build\windows",
    [switch]$Verbose,
    [switch]$SkipTests
)

# Configuration
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$BuildDir = Join-Path $ProjectRoot $OutputDir
$SourceDir = Join-Path $ProjectRoot "src"
$IncludeDir = Join-Path $ProjectRoot "include"
$ConfigDir = Join-Path $ProjectRoot "config"
$DeployDir = Join-Path $ProjectRoot "deployment\windows"

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

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check for Visual Studio
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vsWhere)) {
        $vsWhere = "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
    }

    if (Test-Path $vsWhere) {
        $vsInstallPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vsInstallPath) {
            Write-Success "Visual Studio found at: $vsInstallPath"

            # Set up Visual Studio environment
            $vsDevCmd = Join-Path $vsInstallPath "Common7\Tools\VsDevCmd.bat"
            if (Test-Path $vsDevCmd) {
                Write-Info "Setting up Visual Studio environment..."
                cmd /c "`"$vsDevCmd`" -arch=$Platform && set" | ForEach-Object {
                    if ($_ -match "^([^=]+)=(.*)$") {
                        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
                    }
                }
                Write-Success "Visual Studio environment configured"
            } else {
                Write-Error "VsDevCmd.bat not found"
                exit 1
            }
        } else {
            Write-Error "Visual Studio with C++ tools not found"
            exit 1
        }
    } else {
        Write-Warning "Visual Studio Installer not found, trying system compiler..."

        # Check for cl.exe in PATH
        $clPath = Get-Command cl.exe -ErrorAction SilentlyContinue
        if (-not $clPath) {
            Write-Error "Visual Studio compiler not found"
            Write-Error "Please install Visual Studio with C++ tools or run from Developer Command Prompt"
            exit 1
        }
    }

    # Check for required tools
    $requiredTools = @("cl.exe", "link.exe", "rc.exe")
    foreach ($tool in $requiredTools) {
        $toolPath = Get-Command $tool -ErrorAction SilentlyContinue
        if (-not $toolPath) {
            Write-Error "$tool not found"
            exit 1
        }
    }

    Write-Success "All required tools found"
}

# Clean build directory
function Clear-BuildDirectory {
    Write-Info "Cleaning build directory..."
    if (Test-Path $BuildDir) {
        Remove-Item -Path $BuildDir -Recurse -Force
        Write-Success "Build directory cleaned"
    }
}

# Create build directory structure
function New-BuildDirectory {
    Write-Info "Creating build directory structure..."

    $directories = @(
        $BuildDir,
        (Join-Path $BuildDir "daemon"),
        (Join-Path $BuildDir "service"),
        (Join-Path $BuildDir "package"),
        (Join-Path $BuildDir "package\config"),
        (Join-Path $BuildDir "package\deployment")
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    Write-Success "Build directory structure created"
}

# Build the main daemon
function Build-Daemon {
    Write-Info "Building SNMP daemon..."

    $daemonBuildDir = Join-Path $BuildDir "daemon"
    Set-Location $daemonBuildDir

    # Compile source files
    Write-Info "Compiling daemon source files..."
    $sourceFiles = @(
        (Join-Path $SourceDir "main.cpp"),
        (Join-Path $SourceDir "core\*.cpp")
    )

    $compileArgs = @(
        "/c",
        "/EHsc",
        "/O2",
        "/D_WINDOWS",
        "/DNDEBUG",
        "/I`"$IncludeDir`"",
        "/Fo`"$daemonBuildDir\\`""
    )

    if ($Verbose) {
        $compileArgs += "/v"
    }

    $compileArgs += $sourceFiles

    $result = & cl.exe @compileArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to compile daemon source files"
        exit 1
    }

    # Link daemon executable
    Write-Info "Linking daemon executable..."
    $linkArgs = @(
        "/OUT:`"$daemonBuildDir\simple-snmpd.exe`"",
        "$daemonBuildDir\*.obj",
        "ws2_32.lib",
        "advapi32.lib",
        "kernel32.lib",
        "user32.lib",
        "/SUBSYSTEM:CONSOLE"
    )

    $result = & link.exe @linkArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to link daemon executable"
        exit 1
    }

    Write-Success "Daemon built successfully"
}

# Build the service wrapper
function Build-Service {
    Write-Info "Building service wrapper..."

    $serviceBuildDir = Join-Path $BuildDir "service"
    Set-Location $serviceBuildDir

    # Compile service wrapper
    Write-Info "Compiling service wrapper..."
    $serviceSource = Join-Path $DeployDir "simple-snmpd-service.cpp"

    $compileArgs = @(
        "/c",
        "/EHsc",
        "/O2",
        "/D_WINDOWS",
        "/DNDEBUG",
        "/I`"$IncludeDir`"",
        "/Fo`"$serviceBuildDir\\`"",
        "`"$serviceSource`""
    )

    if ($Verbose) {
        $compileArgs += "/v"
    }

    $result = & cl.exe @compileArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to compile service wrapper"
        exit 1
    }

    # Compile resource file
    Write-Info "Compiling resource file..."
    $rcFile = Join-Path $DeployDir "simple-snmpd-service.rc"
    $resFile = Join-Path $serviceBuildDir "simple-snmpd-service.res"

    $rcArgs = @(
        "/fo`"$resFile`"",
        "`"$rcFile`""
    )

    $result = & rc.exe @rcArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to compile resource file"
        exit 1
    }

    # Link service executable
    Write-Info "Linking service executable..."
    $linkArgs = @(
        "/OUT:`"$serviceBuildDir\simple-snmpd-service.exe`"",
        "$serviceBuildDir\*.obj",
        "$serviceBuildDir\*.res",
        "ws2_32.lib",
        "advapi32.lib",
        "kernel32.lib",
        "user32.lib",
        "/SUBSYSTEM:WINDOWS"
    )

    $result = & link.exe @linkArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to link service executable"
        exit 1
    }

    Write-Success "Service wrapper built successfully"
}

# Create package
function New-Package {
    Write-Info "Creating package..."

    $packageDir = Join-Path $BuildDir "package"

    # Copy executables
    Write-Info "Copying executables..."
    Copy-Item -Path (Join-Path $BuildDir "daemon\simple-snmpd.exe") -Destination $packageDir -Force
    Copy-Item -Path (Join-Path $BuildDir "service\simple-snmpd-service.exe") -Destination $packageDir -Force

    # Copy deployment files
    Write-Info "Copying deployment files..."
    $deployFiles = @(
        "install-service.bat",
        "install-service.ps1",
        "configure-firewall.bat"
    )

    foreach ($file in $deployFiles) {
        $sourceFile = Join-Path $DeployDir $file
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination $packageDir -Force
        }
    }

    # Copy configuration files
    Write-Info "Copying configuration files..."
    $configFiles = @(
        "simple-snmpd-windows.conf"
    )

    foreach ($file in $configFiles) {
        $sourceFile = Join-Path $DeployDir $file
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination (Join-Path $packageDir "config") -Force
        }
    }

    # Copy main configuration
    $mainConfig = Join-Path $ConfigDir "simple-snmpd.conf"
    if (Test-Path $mainConfig) {
        Copy-Item -Path $mainConfig -Destination (Join-Path $packageDir "config") -Force
    }

    # Create README
    Write-Info "Creating package README..."
    $readmeContent = @"
Simple SNMP Daemon Windows Package
==================================

This package contains:
- simple-snmpd.exe: The main SNMP daemon
- simple-snmpd-service.exe: Windows service wrapper
- install-service.bat: Batch installation script
- install-service.ps1: PowerShell installation script
- configure-firewall.bat: Firewall configuration script
- config/: Configuration files

Installation:
1. Run install-service.bat as Administrator
2. Or use PowerShell: .\install-service.ps1 install

For more information, see the documentation.

Build Information:
- Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Platform: $Platform
- Configuration: $Configuration
- Version: 1.0.0
"@

    $readmeContent | Out-File -FilePath (Join-Path $packageDir "README.txt") -Encoding UTF8

    # Create ZIP package
    Write-Info "Creating ZIP package..."
    $zipFile = Join-Path $BuildDir "simple-snmpd-windows-$Platform.zip"

    if (Test-Path $zipFile) {
        Remove-Item -Path $zipFile -Force
    }

    Compress-Archive -Path "$packageDir\*" -DestinationPath $zipFile -Force

    if (Test-Path $zipFile) {
        Write-Success "Package created: $zipFile"
    } else {
        Write-Warning "Failed to create ZIP package"
    }

    Write-Success "Package created successfully"
}

# Install the service
function Install-Service {
    Write-Info "Installing service..."

    $packageDir = Join-Path $BuildDir "package"
    $installScript = Join-Path $packageDir "install-service.ps1"

    if (Test-Path $installScript) {
        & $installScript install
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Service installed successfully"
        } else {
            Write-Error "Failed to install service"
        }
    } else {
        Write-Error "Install script not found"
    }
}

# Test the build
function Test-Build {
    Write-Info "Testing build..."

    $daemonExe = Join-Path $BuildDir "daemon\simple-snmpd.exe"
    $serviceExe = Join-Path $BuildDir "service\simple-snmpd-service.exe"

    # Test daemon
    if (Test-Path $daemonExe) {
        Write-Info "Testing daemon executable..."
        $result = & $daemonExe --version
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Daemon executable test passed"
        } else {
            Write-Warning "Daemon executable test failed"
        }
    }

    # Test service wrapper
    if (Test-Path $serviceExe) {
        Write-Info "Testing service wrapper executable..."
        $result = & $serviceExe --help
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Service wrapper executable test passed"
        } else {
            Write-Warning "Service wrapper executable test failed"
        }
    }

    # Test configuration
    Write-Info "Testing configuration..."
    $configFile = Join-Path $ConfigDir "simple-snmpd.conf"
    if (Test-Path $configFile) {
        Write-Success "Configuration file found"
    } else {
        Write-Warning "Configuration file not found"
    }

    Write-Success "Build testing completed"
}

# Show usage
function Show-Usage {
    Write-Host ""
    Write-Host "Simple SNMP Daemon Windows Build Script" -ForegroundColor $Colors.Cyan
    Write-Host "=======================================" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\build-windows.ps1 [Action] [Options]"
    Write-Host ""
    Write-Host "Actions:"
    Write-Host "  clean     - Clean build directory"
    Write-Host "  build     - Build daemon and service wrapper"
    Write-Host "  package   - Create installer package"
    Write-Host "  install   - Install the service"
    Write-Host "  test      - Test the build"
    Write-Host "  all       - Clean, build, package, and test"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Configuration <config>  - Build configuration (Debug, Release)"
    Write-Host "  -Platform <platform>     - Target platform (x64, x86)"
    Write-Host "  -OutputDir <dir>         - Output directory"
    Write-Host "  -Verbose                 - Verbose output"
    Write-Host "  -SkipTests               - Skip tests"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build-windows.ps1 all"
    Write-Host "  .\build-windows.ps1 build -Configuration Debug -Platform x86"
    Write-Host "  .\build-windows.ps1 package -Verbose"
    Write-Host ""
}

# Main script logic
try {
    # Change to project root
    Set-Location $ProjectRoot

    Write-Info "Simple SNMP Daemon Windows Build Script"
    Write-Info "======================================="
    Write-Info "Project Root: $ProjectRoot"
    Write-Info "Build Directory: $BuildDir"
    Write-Info "Platform: $Platform"
    Write-Info "Configuration: $Configuration"
    Write-Info ""

    switch ($Action) {
        "clean" {
            Clear-BuildDirectory
        }
        "build" {
            Test-Prerequisites
            New-BuildDirectory
            Build-Daemon
            Build-Service
        }
        "package" {
            New-Package
        }
        "install" {
            Install-Service
        }
        "test" {
            Test-Build
        }
        "all" {
            Test-Prerequisites
            Clear-BuildDirectory
            New-BuildDirectory
            Build-Daemon
            Build-Service
            New-Package
            if (-not $SkipTests) {
                Test-Build
            }
        }
        default {
            Show-Usage
        }
    }

    Write-Success "Build process completed successfully!"

    # Show build artifacts
    Write-Info "Build artifacts:"
    Write-Info "  Daemon: $BuildDir\daemon\simple-snmpd.exe"
    Write-Info "  Service: $BuildDir\service\simple-snmpd-service.exe"
    Write-Info "  Package: $BuildDir\simple-snmpd-windows-$Platform.zip"

} catch {
    Write-Error "Build process failed: $($_.Exception.Message)"
    exit 1
} finally {
    # Return to original directory
    Set-Location $ProjectRoot
}
