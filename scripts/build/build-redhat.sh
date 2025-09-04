#!/bin/bash
#
# Simple SNMP Daemon Red Hat Build Script
# Copyright 2024 SimpleDaemons
# Licensed under Apache 2.0

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/redhat"
SOURCE_DIR="$PROJECT_ROOT/src"
INCLUDE_DIR="$PROJECT_ROOT/include"
CONFIG_DIR="$PROJECT_ROOT/config"
DEPLOY_DIR="$PROJECT_ROOT/deployment"

# Build configuration
BUILD_TYPE="${BUILD_TYPE:-Release}"
ARCHITECTURE="${ARCHITECTURE:-x86_64}"
PACKAGE_VERSION="${PACKAGE_VERSION:-1.0.0}"
PACKAGE_RELEASE="${PACKAGE_RELEASE:-1}"
DISTRIBUTION="${DISTRIBUTION:-el8}"

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
    echo "Simple SNMP Daemon Red Hat Build Script"
    echo "======================================="
    echo ""
    echo "Usage: $0 [ACTION] [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  clean       - Clean build directory"
    echo "  build       - Build the daemon"
    echo "  package     - Create RPM package"
    echo "  install     - Install the package"
    echo "  test        - Test the build"
    echo "  all         - Clean, build, package, and test"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE        - Build type (Debug, Release) [default: Release]"
    echo "  -a, --arch ARCH        - Target architecture (x86_64, aarch64, ppc64le) [default: x86_64]"
    echo "  -v, --version VERSION  - Package version [default: 1.0.0]"
    echo "  -r, --release RELEASE  - Package release [default: 1]"
    echo "  -d, --dist DIST        - Distribution (el7, el8, el9, fc35, fc36, fc37) [default: el8]"
    echo "  -j, --jobs JOBS        - Number of parallel jobs [default: $(nproc)]"
    echo "  -d, --deps             - Install build dependencies"
    echo "  -c, --clean-deps       - Clean build dependencies"
    echo "  --verbose              - Verbose output"
    echo "  --no-tests             - Skip tests"
    echo "  -h, --help             - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 build --type Debug --arch aarch64"
    echo "  $0 package --version 1.1.0 --release 2 --dist el9"
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
            -r|--release)
                PACKAGE_RELEASE="$2"
                shift 2
                ;;
            -d|--dist)
                DISTRIBUTION="$2"
                shift 2
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            --deps)
                INSTALL_DEPS=true
                shift
                ;;
            --clean-deps)
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

# Detect distribution
detect_distribution() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            rhel|centos|almalinux|rocky)
                case "$VERSION_ID" in
                    7*) DISTRIBUTION="el7" ;;
                    8*) DISTRIBUTION="el8" ;;
                    9*) DISTRIBUTION="el9" ;;
                esac
                ;;
            fedora)
                case "$VERSION_ID" in
                    35) DISTRIBUTION="fc35" ;;
                    36) DISTRIBUTION="fc36" ;;
                    37) DISTRIBUTION="fc37" ;;
                    38) DISTRIBUTION="fc38" ;;
                esac
                ;;
        esac
    fi

    log_info "Detected distribution: $DISTRIBUTION"
}

# Install build dependencies
install_dependencies() {
    log_info "Installing build dependencies..."

    # Update package list
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf update -y
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y \
            cmake \
            pkgconfig \
            openssl-devel \
            jsoncpp-devel \
            net-snmp-devel \
            net-snmp-utils \
            rpm-build \
            rpmdevtools \
            git \
            wget \
            curl
    elif command -v yum >/dev/null 2>&1; then
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y \
            cmake \
            pkgconfig \
            openssl-devel \
            jsoncpp-devel \
            net-snmp-devel \
            net-snmp-utils \
            rpm-build \
            rpmdevtools \
            git \
            wget \
            curl
    else
        log_error "Package manager not found (dnf/yum)"
        exit 1
    fi

    # Install additional dependencies for different architectures
    case "$ARCHITECTURE" in
        aarch64|ppc64le)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y \
                    gcc-${ARCHITECTURE}-linux-gnu \
                    gcc-c++-${ARCHITECTURE}-linux-gnu \
                    openssl-devel.${ARCHITECTURE} \
                    jsoncpp-devel.${ARCHITECTURE} \
                    net-snmp-devel.${ARCHITECTURE}
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y \
                    gcc-${ARCHITECTURE}-linux-gnu \
                    gcc-c++-${ARCHITECTURE}-linux-gnu \
                    openssl-devel.${ARCHITECTURE} \
                    jsoncpp-devel.${ARCHITECTURE} \
                    net-snmp-devel.${ARCHITECTURE}
            fi
            ;;
    esac

    log_success "Build dependencies installed"
}

# Clean build dependencies
clean_dependencies() {
    log_info "Cleaning build dependencies..."

    if command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y \
            cmake \
            pkgconfig \
            openssl-devel \
            jsoncpp-devel \
            net-snmp-devel \
            rpm-build \
            rpmdevtools
    elif command -v yum >/dev/null 2>&1; then
        sudo yum remove -y \
            cmake \
            pkgconfig \
            openssl-devel \
            jsoncpp-devel \
            net-snmp-devel \
            rpm-build \
            rpmdevtools
    fi

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

    mkdir -p "$BUILD_DIR"/{source,build,package,rpmbuild}

    # Set up RPM build environment
    export RPM_BUILD_ROOT="$BUILD_DIR/rpmbuild"
    mkdir -p "$RPM_BUILD_ROOT"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

    log_success "Build directory structure created"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for required tools
    local required_tools=("gcc" "g++" "cmake" "pkg-config" "rpmbuild")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool not found"
            if [[ "$tool" == "rpmbuild" ]]; then
                log_info "Install with: sudo dnf install rpm-build"
            fi
            exit 1
        fi
    done

    # Check for required libraries
    local required_libs=("openssl" "jsoncpp" "netsnmp")
    for lib in "${required_libs[@]}"; do
        if ! pkg-config --exists "$lib"; then
            log_error "$lib development package not found"
            case "$lib" in
                openssl)
                    log_info "Install with: sudo dnf install openssl-devel"
                    ;;
                jsoncpp)
                    log_info "Install with: sudo dnf install jsoncpp-devel"
                    ;;
                netsnmp)
                    log_info "Install with: sudo dnf install net-snmp-devel"
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
        "-DCMAKE_INSTALL_LIBDIR=lib64"
    )

    # Add architecture-specific flags
    case "$ARCHITECTURE" in
        aarch64|ppc64le)
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

# Create RPM package
create_package() {
    log_info "Creating RPM package..."

    local package_dir="$BUILD_DIR/package"
    local source_dir="$package_dir/simple-snmpd-$PACKAGE_VERSION"
    local rpmbuild_dir="$BUILD_DIR/rpmbuild"

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

    # Create source tarball
    log_info "Creating source tarball..."
    cd "$package_dir"
    tar -czf "$rpmbuild_dir/SOURCES/simple-snmpd-$PACKAGE_VERSION.tar.gz" "simple-snmpd-$PACKAGE_VERSION"

    # Create spec file
    log_info "Creating RPM spec file..."
    cat > "$rpmbuild_dir/SPECS/simple-snmpd.spec" << EOF
Name:           simple-snmpd
Version:        $PACKAGE_VERSION
Release:        $PACKAGE_RELEASE%{?dist}
Summary:        Simple SNMP Daemon

License:        Apache-2.0
URL:            https://github.com/simpledaemons/simple-snmpd
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.10
BuildRequires:  pkgconfig
BuildRequires:  openssl-devel
BuildRequires:  jsoncpp-devel
BuildRequires:  net-snmp-devel
BuildRequires:  systemd-devel

Requires:       openssl-libs
Requires:       jsoncpp
Requires:       net-snmp-libs
Requires:       systemd

%description
A lightweight SNMP daemon providing essential SNMP monitoring
capabilities with a focus on simplicity, security, and cross-platform
compatibility.

Features:
* SNMP v1/v2c/v3 support
* Cross-platform compatibility
* Easy configuration
* Built-in system monitoring
* Extensible MIB support
* Docker support
* Service management integration

%package devel
Summary:        Development files for %{name}
Requires:       %{name} = %{version}-%{release}

%description devel
Development headers and libraries for %{name}.

%prep
%setup -q

%build
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \\
      -DCMAKE_INSTALL_PREFIX=%{_prefix} \\
      -DCMAKE_INSTALL_SYSCONFDIR=%{_sysconfdir} \\
      -DCMAKE_INSTALL_LOCALSTATEDIR=%{_localstatedir} \\
      -DCMAKE_INSTALL_LIBDIR=%{_libdir} \\
      ..
make %{?_smp_mflags}

%check
cd build
make test

%install
cd build
make install DESTDIR=%{buildroot}

# Create systemd service file
mkdir -p %{buildroot}%{_unitdir}
cp deployment/systemd/simple-snmpd.service %{buildroot}%{_unitdir}/

# Create init.d script
mkdir -p %{buildroot}%{_sysconfdir}/rc.d/init.d
cp deployment/init.d/simple-snmpd %{buildroot}%{_sysconfdir}/rc.d/init.d/
chmod +x %{buildroot}%{_sysconfdir}/rc.d/init.d/simple-snmpd

# Create configuration directory
mkdir -p %{buildroot}%{_sysconfdir}/simple-snmpd
cp config/simple-snmpd.conf %{buildroot}%{_sysconfdir}/simple-snmpd/

# Create log directory
mkdir -p %{buildroot}%{_localstatedir}/log/simple-snmpd

# Create data directory
mkdir -p %{buildroot}%{_localstatedir}/lib/simple-snmpd

# Create run directory
mkdir -p %{buildroot}%{_localstatedir}/run/simple-snmpd

%files
%defattr(-,root,root,-)
%{_sbindir}/simple-snmpd
%{_unitdir}/simple-snmpd.service
%{_sysconfdir}/rc.d/init.d/simple-snmpd
%config(noreplace) %{_sysconfdir}/simple-snmpd/simple-snmpd.conf
%dir %{_localstatedir}/log/simple-snmpd
%dir %{_localstatedir}/lib/simple-snmpd
%dir %{_localstatedir}/run/simple-snmpd

%files devel
%defattr(-,root,root,-)
%{_includedir}/simple_snmpd/

%pre
# Create snmp user and group
if ! getent group snmp >/dev/null 2>&1; then
    groupadd -r snmp
fi

if ! getent passwd snmp >/dev/null 2>&1; then
    useradd -r -g snmp -d %{_localstatedir}/lib/simple-snmpd -s /sbin/nologin snmp
fi

%post
# Enable systemd service
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
    systemctl enable simple-snmpd.service
fi

# Set permissions
chown snmp:snmp %{_localstatedir}/log/simple-snmpd
chown snmp:snmp %{_localstatedir}/lib/simple-snmpd
chown snmp:snmp %{_localstatedir}/run/simple-snmpd

%preun
# Stop service before removal
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop simple-snmpd.service || true
    systemctl disable simple-snmpd.service || true
fi

%postun
# Clean up after removal
if [ \$1 -eq 0 ]; then
    # Package was removed, not upgraded
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
    fi
fi

%changelog
* $(date '+%a %b %d %Y') SimpleDaemons <admin@simpledaemons.org> - $PACKAGE_VERSION-$PACKAGE_RELEASE
- Initial release of Simple SNMP Daemon
EOF

    # Build the RPM package
    log_info "Building RPM package..."
    cd "$rpmbuild_dir"

    # Set architecture
    export RPM_BUILD_ARCH="$ARCHITECTURE"

    # Build package
    rpmbuild -ba SPECS/simple-snmpd.spec

    # Move packages to build directory
    find RPMS -name "*.rpm" -exec cp {} "$BUILD_DIR/" \;
    find SRPMS -name "*.rpm" -exec cp {} "$BUILD_DIR/" \;

    log_success "RPM package created successfully"
}

# Install the package
install_package() {
    log_info "Installing package..."

    local package_file="$BUILD_DIR/simple-snmpd-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${DISTRIBUTION}.${ARCHITECTURE}.rpm"

    if [[ ! -f "$package_file" ]]; then
        # Try to find any RPM file
        package_file=$(find "$BUILD_DIR" -name "simple-snmpd-*.rpm" | head -1)
        if [[ -z "$package_file" ]]; then
            log_error "Package file not found"
            exit 1
        fi
    fi

    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$package_file"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "$package_file"
    else
        log_error "Package manager not found (dnf/yum)"
        exit 1
    fi

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
    local package_file=$(find "$BUILD_DIR" -name "simple-snmpd-*.rpm" | head -1)
    if [[ -n "$package_file" ]]; then
        log_info "Testing package..."
        if rpm -qp "$package_file"; then
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

    # Detect distribution
    detect_distribution

    # Change to project root
    cd "$PROJECT_ROOT"

    log_info "Simple SNMP Daemon Red Hat Build Script"
    log_info "======================================="
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Build Directory: $BUILD_DIR"
    log_info "Architecture: $ARCHITECTURE"
    log_info "Build Type: $BUILD_TYPE"
    log_info "Package Version: $PACKAGE_VERSION-$PACKAGE_RELEASE"
    log_info "Distribution: $DISTRIBUTION"
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
    local package_file=$(find "$BUILD_DIR" -name "simple-snmpd-*.rpm" | head -1)
    if [[ -n "$package_file" ]]; then
        log_info "  Package: $package_file"
    fi
}

# Run main function
main "$@"
