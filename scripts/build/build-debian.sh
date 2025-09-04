#!/bin/bash
#
# Simple SNMP Daemon Debian Build Script
# Copyright 2024 SimpleDaemons
# Licensed under Apache 2.0

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/debian"
SOURCE_DIR="$PROJECT_ROOT/src"
INCLUDE_DIR="$PROJECT_ROOT/include"
CONFIG_DIR="$PROJECT_ROOT/config"
DEPLOY_DIR="$PROJECT_ROOT/deployment"

# Build configuration
BUILD_TYPE="${BUILD_TYPE:-Release}"
ARCHITECTURE="${ARCHITECTURE:-amd64}"
PACKAGE_VERSION="${PACKAGE_VERSION:-1.0.0}"
PACKAGE_REVISION="${PACKAGE_REVISION:-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
usage() {
    echo ""
    echo "Simple SNMP Daemon Debian Build Script"
    echo "======================================"
    echo ""
    echo "Usage: $0 [ACTION] [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  clean       - Clean build directory"
    echo "  build       - Build the daemon"
    echo "  package     - Create Debian package"
    echo "  install     - Install the package"
    echo "  test        - Test the build"
    echo "  all         - Clean, build, package, and test"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE        - Build type (Debug, Release) [default: Release]"
    echo "  -a, --arch ARCH        - Target architecture (amd64, arm64, armhf) [default: amd64]"
    echo "  -v, --version VERSION  - Package version [default: 1.0.0]"
    echo "  -r, --revision REV     - Package revision [default: 1]"
    echo "  -j, --jobs JOBS        - Number of parallel jobs [default: $(nproc)]"
    echo "  -d, --deps             - Install build dependencies"
    echo "  -c, --clean-deps       - Clean build dependencies"
    echo "  --verbose              - Verbose output"
    echo "  --no-tests             - Skip tests"
    echo "  -h, --help             - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 build --type Debug --arch arm64"
    echo "  $0 package --version 1.1.0 --revision 2"
    echo "  $0 --deps"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            clean|build|package|install|test|all)
                ACTION="$1"
                shift
                ;;
            -t|--type)
                BUILD_TYPE="$2"
                shift 2
                ;;
            -a|--arch)
                ARCHITECTURE="$2"
                shift 2
                ;;
            -v|--version)
                PACKAGE_VERSION="$2"
                shift 2
                ;;
            -r|--revision)
                PACKAGE_REVISION="$2"
                shift 2
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            -d|--deps)
                INSTALL_DEPS=true
                shift
                ;;
            -c|--clean-deps)
                CLEAN_DEPS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --no-tests)
                NO_TESTS=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Set default action if none specified
    if [[ -z "$ACTION" ]]; then
        ACTION="all"
    fi

    # Set default parallel jobs
    if [[ -z "$PARALLEL_JOBS" ]]; then
        PARALLEL_JOBS=$(nproc)
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. This is not recommended for building."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Install build dependencies
install_dependencies() {
    log_info "Installing build dependencies..."

    # Update package list
    sudo apt-get update

    # Install build dependencies
    sudo apt-get install -y \
        build-essential \
        cmake \
        pkg-config \
        libssl-dev \
        libjsoncpp-dev \
        libsnmp-dev \
        libsnmp-base \
        debhelper \
        devscripts \
        dh-systemd \
        fakeroot \
        lintian \
        git \
        wget \
        curl

    # Install additional dependencies for different architectures
    case "$ARCHITECTURE" in
        arm64|armhf)
            sudo apt-get install -y \
                crossbuild-essential-${ARCHITECTURE} \
                libssl-dev:${ARCHITECTURE} \
                libjsoncpp-dev:${ARCHITECTURE} \
                libsnmp-dev:${ARCHITECTURE}
            ;;
    esac

    log_success "Build dependencies installed"
}

# Clean build dependencies
clean_dependencies() {
    log_info "Cleaning build dependencies..."

    sudo apt-get autoremove -y \
        build-essential \
        cmake \
        pkg-config \
        libssl-dev \
        libjsoncpp-dev \
        libsnmp-dev \
        debhelper \
        devscripts \
        dh-systemd \
        fakeroot \
        lintian

    log_success "Build dependencies cleaned"
}

# Clean build directory
clean_build() {
    log_info "Cleaning build directory..."

    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
        log_success "Build directory cleaned"
    fi
}

# Create build directory
create_build_dir() {
    log_info "Creating build directory structure..."

    mkdir -p "$BUILD_DIR"/{source,build,package}

    log_success "Build directory structure created"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for required tools
    local required_tools=("gcc" "g++" "cmake" "pkg-config" "dpkg-buildpackage")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool not found"
            if [[ "$tool" == "dpkg-buildpackage" ]]; then
                log_info "Install with: sudo apt-get install devscripts"
            fi
            exit 1
        fi
    done

    # Check for required libraries
    local required_libs=("libssl" "libjsoncpp" "libsnmp")
    for lib in "${required_libs[@]}"; do
        if ! pkg-config --exists "$lib"; then
            log_error "$lib development package not found"
            case "$lib" in
                libssl)
                    log_info "Install with: sudo apt-get install libssl-dev"
                    ;;
                libjsoncpp)
                    log_info "Install with: sudo apt-get install libjsoncpp-dev"
                    ;;
                libsnmp)
                    log_info "Install with: sudo apt-get install libsnmp-dev"
                    ;;
            esac
            exit 1
        fi
    done

    log_success "All prerequisites found"
}

# Build the daemon
build_daemon() {
    log_info "Building SNMP daemon..."

    local build_subdir="$BUILD_DIR/build"
    mkdir -p "$build_subdir"
    cd "$build_subdir"

    # Configure with CMake
    log_info "Configuring with CMake..."
    local cmake_args=(
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
        "-DCMAKE_INSTALL_PREFIX=/usr"
        "-DCMAKE_INSTALL_SYSCONFDIR=/etc"
        "-DCMAKE_INSTALL_LOCALSTATEDIR=/var"
        "-DCMAKE_INSTALL_LIBDIR=lib/$ARCHITECTURE"
    )

    # Add architecture-specific flags
    case "$ARCHITECTURE" in
        arm64|armhf)
            cmake_args+=("-DCMAKE_SYSTEM_PROCESSOR=$ARCHITECTURE")
            cmake_args+=("-DCMAKE_C_COMPILER=${ARCHITECTURE}-linux-gnu-gcc")
            cmake_args+=("-DCMAKE_CXX_COMPILER=${ARCHITECTURE}-linux-gnu-g++")
            ;;
    esac

    if [[ "$VERBOSE" == "true" ]]; then
        cmake_args+=("-DCMAKE_VERBOSE_MAKEFILE=ON")
    fi

    cmake "${cmake_args[@]}" "$PROJECT_ROOT"

    # Build
    log_info "Building with $PARALLEL_JOBS parallel jobs..."
    make -j"$PARALLEL_JOBS"

    # Run tests if not disabled
    if [[ "$NO_TESTS" != "true" ]]; then
        log_info "Running tests..."
        if make test; then
            log_success "All tests passed"
        else
            log_warning "Some tests failed"
        fi
    fi

    log_success "Daemon built successfully"
}

# Create Debian package
create_package() {
    log_info "Creating Debian package..."

    local package_dir="$BUILD_DIR/package"
    local source_dir="$package_dir/simple-snmpd-$PACKAGE_VERSION"

    # Create package source directory
    mkdir -p "$source_dir"

    # Copy source files
    log_info "Copying source files..."
    cp -r "$PROJECT_ROOT/src" "$source_dir/"
    cp -r "$PROJECT_ROOT/include" "$source_dir/"
    cp -r "$PROJECT_ROOT/config" "$source_dir/"
    cp -r "$PROJECT_ROOT/deployment" "$source_dir/"
    cp "$PROJECT_ROOT/CMakeLists.txt" "$source_dir/"
    cp "$PROJECT_ROOT/LICENSE" "$source_dir/"
    cp "$PROJECT_ROOT/README.md" "$source_dir/"

    # Create debian directory
    log_info "Creating Debian package structure..."
    mkdir -p "$source_dir/debian"

    # Create control file
    cat > "$source_dir/debian/control" << EOF
Source: simple-snmpd
Section: net
Priority: optional
Maintainer: SimpleDaemons <admin@simpledaemons.org>
Build-Depends: debhelper (>= 12),
               cmake (>= 3.10),
               pkg-config,
               libssl-dev,
               libjsoncpp-dev,
               libsnmp-dev,
               libsnmp-base
Standards-Version: 4.5.0
Homepage: https://github.com/simpledaemons/simple-snmpd

Package: simple-snmpd
Architecture: $ARCHITECTURE
Depends: \${shlibs:Depends}, \${misc:Depends},
         libssl3,
         libjsoncpp25,
         libsnmp40
Description: Simple SNMP Daemon
 A lightweight SNMP daemon providing essential SNMP monitoring
 capabilities with a focus on simplicity, security, and cross-platform
 compatibility.
 .
 Features:
  * SNMP v1/v2c/v3 support
  * Cross-platform compatibility
  * Easy configuration
  * Built-in system monitoring
  * Extensible MIB support
  * Docker support
  * Service management integration

Package: simple-snmpd-dev
Architecture: $ARCHITECTURE
Depends: \${shlibs:Depends}, \${misc:Depends},
         simple-snmpd (= \${binary:Version})
Description: Simple SNMP Daemon development files
 Development headers and libraries for Simple SNMP Daemon.
EOF

    # Create changelog
    cat > "$source_dir/debian/changelog" << EOF
simple-snmpd ($PACKAGE_VERSION-$PACKAGE_REVISION) unstable; urgency=medium

  * Initial release of Simple SNMP Daemon

 -- SimpleDaemons <admin@simpledaemons.org>  $(date -R)
EOF

    # Create rules file
    cat > "$source_dir/debian/rules" << 'EOF'
#!/usr/bin/make -f

export DH_VERBOSE=1
export DH_OPTIONS=--buildsystem=cmake

%:
	dh $@

override_dh_auto_configure:
	dh_auto_configure -- \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_SYSCONFDIR=/etc \
		-DCMAKE_INSTALL_LOCALSTATEDIR=/var

override_dh_auto_test:
	# Tests are run during build
EOF

    chmod +x "$source_dir/debian/rules"

    # Create install files
    cat > "$source_dir/debian/simple-snmpd.install" << EOF
build/simple-snmpd usr/sbin/
config/simple-snmpd.conf etc/simple-snmpd/
deployment/systemd/simple-snmpd.service lib/systemd/system/
deployment/init.d/simple-snmpd etc/init.d/
EOF

    cat > "$source_dir/debian/simple-snmpd-dev.install" << EOF
include/ usr/include/simple_snmpd/
EOF

    # Create postinst script
    cat > "$source_dir/debian/simple-snmpd.postinst" << 'EOF'
#!/bin/bash
set -e

case "$1" in
    configure)
        # Create user and group
        if ! getent group snmp >/dev/null; then
            addgroup --system snmp
        fi

        if ! getent passwd snmp >/dev/null; then
            adduser --system --ingroup snmp --home /var/lib/simple-snmpd --shell /bin/false snmp
        fi

        # Create directories
        mkdir -p /var/log/simple-snmpd
        mkdir -p /var/lib/simple-snmpd
        mkdir -p /var/run/simple-snmpd

        # Set permissions
        chown snmp:snmp /var/log/simple-snmpd
        chown snmp:snmp /var/lib/simple-snmpd
        chown snmp:snmp /var/run/simple-snmpd

        # Enable systemd service
        if command -v systemctl >/dev/null 2>&1; then
            systemctl daemon-reload
            systemctl enable simple-snmpd.service
        fi
        ;;
esac

exit 0
EOF

    chmod +x "$source_dir/debian/simple-snmpd.postinst"

    # Create prerm script
    cat > "$source_dir/debian/simple-snmpd.prerm" << 'EOF'
#!/bin/bash
set -e

case "$1" in
    remove|purge)
        # Stop service
        if command -v systemctl >/dev/null 2>&1; then
            systemctl stop simple-snmpd.service || true
            systemctl disable simple-snmpd.service || true
        fi
        ;;
esac

exit 0
EOF

    chmod +x "$source_dir/debian/simple-snmpd.prerm"

    # Create postrm script
    cat > "$source_dir/debian/simple-snmpd.postrm" << 'EOF'
#!/bin/bash
set -e

case "$1" in
    purge)
        # Remove user and group
        if getent passwd snmp >/dev/null; then
            deluser snmp || true
        fi

        if getent group snmp >/dev/null; then
            delgroup snmp || true
        fi

        # Remove directories
        rm -rf /var/log/simple-snmpd
        rm -rf /var/lib/simple-snmpd
        rm -rf /var/run/simple-snmpd
        ;;
esac

exit 0
EOF

    chmod +x "$source_dir/debian/simple-snmpd.postrm"

    # Build the package
    log_info "Building Debian package..."
    cd "$source_dir"

    # Set architecture
    export DEB_BUILD_OPTIONS="parallel=$PARALLEL_JOBS"
    if [[ "$ARCHITECTURE" != "amd64" ]]; then
        export DEB_BUILD_ARCH="$ARCHITECTURE"
    fi

    # Build package
    dpkg-buildpackage -b -us -uc

    # Move packages to build directory
    mv ../simple-snmpd_*.deb "$BUILD_DIR/"
    mv ../simple-snmpd_*.changes "$BUILD_DIR/" 2>/dev/null || true
    mv ../simple-snmpd_*.buildinfo "$BUILD_DIR/" 2>/dev/null || true

    log_success "Debian package created successfully"
}

# Install the package
install_package() {
    log_info "Installing package..."

    local package_file="$BUILD_DIR/simple-snmpd_${PACKAGE_VERSION}-${PACKAGE_REVISION}_${ARCHITECTURE}.deb"

    if [[ ! -f "$package_file" ]]; then
        log_error "Package file not found: $package_file"
        exit 1
    fi

    sudo dpkg -i "$package_file"

    # Fix any dependency issues
    sudo apt-get install -f

    log_success "Package installed successfully"
}

# Test the build
test_build() {
    log_info "Testing build..."

    local daemon_binary="$BUILD_DIR/build/simple-snmpd"

    # Test daemon binary
    if [[ -f "$daemon_binary" ]]; then
        log_info "Testing daemon binary..."
        if "$daemon_binary" --version; then
            log_success "Daemon binary test passed"
        else
            log_warning "Daemon binary test failed"
        fi

        # Test configuration
        if "$daemon_binary" --config-test; then
            log_success "Configuration test passed"
        else
            log_warning "Configuration test failed"
        fi
    else
        log_warning "Daemon binary not found"
    fi

    # Test package if it exists
    local package_file="$BUILD_DIR/simple-snmpd_${PACKAGE_VERSION}-${PACKAGE_REVISION}_${ARCHITECTURE}.deb"
    if [[ -f "$package_file" ]]; then
        log_info "Testing package..."
        if dpkg-deb -I "$package_file"; then
            log_success "Package test passed"
        else
            log_warning "Package test failed"
        fi
    fi

    log_success "Build testing completed"
}

# Main script logic
main() {
    # Parse arguments
    parse_args "$@"

    # Check if running as root
    check_root

    # Change to project root
    cd "$PROJECT_ROOT"

    log_info "Simple SNMP Daemon Debian Build Script"
    log_info "======================================"
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Build Directory: $BUILD_DIR"
    log_info "Architecture: $ARCHITECTURE"
    log_info "Build Type: $BUILD_TYPE"
    log_info "Package Version: $PACKAGE_VERSION-$PACKAGE_REVISION"
    log_info ""

    # Handle special actions
    if [[ "$INSTALL_DEPS" == "true" ]]; then
        install_dependencies
        exit 0
    fi

    if [[ "$CLEAN_DEPS" == "true" ]]; then
        clean_dependencies
        exit 0
    fi

    # Execute main action
    case "$ACTION" in
        "clean")
            clean_build
            ;;
        "build")
            check_prerequisites
            create_build_dir
            build_daemon
            ;;
        "package")
            check_prerequisites
            create_build_dir
            build_daemon
            create_package
            ;;
        "install")
            install_package
            ;;
        "test")
            test_build
            ;;
        "all")
            check_prerequisites
            clean_build
            create_build_dir
            build_daemon
            create_package
            if [[ "$NO_TESTS" != "true" ]]; then
                test_build
            fi
            ;;
        *)
            log_error "Unknown action: $ACTION"
            usage
            exit 1
            ;;
    esac

    log_success "Build process completed successfully!"

    # Show build artifacts
    log_info "Build artifacts:"
    if [[ -f "$BUILD_DIR/build/simple-snmpd" ]]; then
        log_info "  Binary: $BUILD_DIR/build/simple-snmpd"
    fi
    if [[ -f "$BUILD_DIR/simple-snmpd_${PACKAGE_VERSION}-${PACKAGE_REVISION}_${ARCHITECTURE}.deb" ]]; then
        log_info "  Package: $BUILD_DIR/simple-snmpd_${PACKAGE_VERSION}-${PACKAGE_REVISION}_${ARCHITECTURE}.deb"
    fi
}

# Run main function
main "$@"
