#!/bin/bash
#
# Build script for Simple SNMP Daemon on Linux
# Copyright 2024 SimpleDaemons
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
PACKAGE_DIR="$PROJECT_ROOT/packaging"

# Build configuration
BUILD_TYPE="${BUILD_TYPE:-Release}"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"
ENABLE_TESTS="${ENABLE_TESTS:-ON}"
ENABLE_EXAMPLES="${ENABLE_EXAMPLES:-OFF}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check dependencies
check_dependencies() {
    log_info "Checking build dependencies..."

    local missing_deps=()

    # Check for required tools
    command -v cmake >/dev/null 2>&1 || missing_deps+=("cmake")
    command -v make >/dev/null 2>&1 || missing_deps+=("make")
    command -v g++ >/dev/null 2>&1 || missing_deps+=("g++")
    command -v pkg-config >/dev/null 2>&1 || missing_deps+=("pkg-config")

    # Check for required libraries
    pkg-config --exists openssl || missing_deps+=("libssl-dev")

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install missing dependencies with:"
        log_info "  Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
        log_info "  CentOS/RHEL: sudo yum install ${missing_deps[*]}"
        log_info "  Fedora: sudo dnf install ${missing_deps[*]}"
        exit 1
    fi

    log_success "All dependencies found"
}

# Clean build directory
clean_build() {
    log_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    rm -rf "$DIST_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    log_success "Build directory cleaned"
}

# Configure build
configure_build() {
    log_info "Configuring build..."
    cd "$BUILD_DIR"

    cmake "$PROJECT_ROOT" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DBUILD_TESTS="$ENABLE_TESTS" \
        -DBUILD_EXAMPLES="$ENABLE_EXAMPLES" \
        -DENABLE_LOGGING=ON \
        -DENABLE_IPV6=ON

    log_success "Build configured"
}

# Build project
build_project() {
    log_info "Building project with $PARALLEL_JOBS parallel jobs..."
    cd "$BUILD_DIR"

    make -j"$PARALLEL_JOBS"

    log_success "Build completed"
}

# Run tests
run_tests() {
    if [ "$ENABLE_TESTS" = "ON" ]; then
        log_info "Running tests..."
        cd "$BUILD_DIR"

        if make test; then
            log_success "All tests passed"
        else
            log_error "Some tests failed"
            exit 1
        fi
    else
        log_info "Tests disabled"
    fi
}

# Create packages
create_packages() {
    log_info "Creating packages..."
    cd "$BUILD_DIR"

    # Create RPM package
    if command -v rpmbuild >/dev/null 2>&1; then
        log_info "Creating RPM package..."
        cpack -G RPM
        mv simple-snmpd-*.rpm "$DIST_DIR/" 2>/dev/null || true
    fi

    # Create DEB package
    if command -v dpkg-deb >/dev/null 2>&1; then
        log_info "Creating DEB package..."
        cpack -G DEB
        mv simple-snmpd-*.deb "$DIST_DIR/" 2>/dev/null || true
    fi

    # Create tarball
    log_info "Creating source tarball..."
    make package_source
    mv simple-snmpd-*.tar.gz "$DIST_DIR/" 2>/dev/null || true

    log_success "Packages created in $DIST_DIR"
}

# Install locally
install_local() {
    log_info "Installing locally..."
    cd "$BUILD_DIR"

    sudo make install

    log_success "Installation completed"
}

# Show build information
show_build_info() {
    log_info "Build Information:"
    echo "  Project Root: $PROJECT_ROOT"
    echo "  Build Directory: $BUILD_DIR"
    echo "  Build Type: $BUILD_TYPE"
    echo "  Parallel Jobs: $PARALLEL_JOBS"
    echo "  Tests Enabled: $ENABLE_TESTS"
    echo "  Examples Enabled: $ENABLE_EXAMPLES"
    echo "  Distribution Directory: $DIST_DIR"
}

# Main function
main() {
    log_info "Starting Linux build for Simple SNMP Daemon"

    show_build_info

    check_dependencies
    clean_build
    configure_build
    build_project
    run_tests

    if [ "$1" = "--package" ]; then
        create_packages
    fi

    if [ "$1" = "--install" ]; then
        install_local
    fi

    log_success "Build process completed successfully!"

    if [ -f "$BUILD_DIR/bin/simple-snmpd" ]; then
        log_info "Binary location: $BUILD_DIR/bin/simple-snmpd"
    fi

    if [ -d "$DIST_DIR" ] && [ "$(ls -A "$DIST_DIR")" ]; then
        log_info "Packages location: $DIST_DIR"
        ls -la "$DIST_DIR"
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --package    Create packages after build"
        echo "  --install    Install locally after build"
        echo "  --help, -h   Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  BUILD_TYPE      Build type (Debug|Release) [default: Release]"
        echo "  PARALLEL_JOBS   Number of parallel build jobs [default: nproc]"
        echo "  ENABLE_TESTS    Enable tests (ON|OFF) [default: ON]"
        echo "  ENABLE_EXAMPLES Enable examples (ON|OFF) [default: OFF]"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
