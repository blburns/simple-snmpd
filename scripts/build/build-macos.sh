#!/bin/bash
#
# Build script for Simple SNMP Daemon on macOS
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
PARALLEL_JOBS="${PARALLEL_JOBS:-$(sysctl -n hw.ncpu)}"
ENABLE_TESTS="${ENABLE_TESTS:-ON}"
ENABLE_EXAMPLES="${ENABLE_EXAMPLES:-OFF}"
ARCHITECTURES="${ARCHITECTURES:-x86_64;arm64}"

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

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi

    log_info "Building on macOS $(sw_vers -productVersion)"
}

# Check dependencies
check_dependencies() {
    log_info "Checking build dependencies..."

    local missing_deps=()

    # Check for Xcode Command Line Tools
    if ! xcode-select -p >/dev/null 2>&1; then
        log_error "Xcode Command Line Tools not found"
        log_info "Install with: xcode-select --install"
        exit 1
    fi

    # Check for required tools
    command -v cmake >/dev/null 2>&1 || missing_deps+=("cmake")
    command -v make >/dev/null 2>&1 || missing_deps+=("make")
    command -v clang++ >/dev/null 2>&1 || missing_deps+=("clang++")

    # Check for Homebrew packages
    if command -v brew >/dev/null 2>&1; then
        if ! brew list openssl >/dev/null 2>&1; then
            missing_deps+=("openssl (via Homebrew)")
        fi
    else
        log_warning "Homebrew not found. Some dependencies may need manual installation."
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install missing dependencies with:"
        log_info "  Homebrew: brew install ${missing_deps[*]}"
        log_info "  Or install manually from Apple Developer"
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
    log_info "Configuring build for architectures: $ARCHITECTURES..."
    cd "$BUILD_DIR"

    # Set up CMake with macOS-specific options
    local cmake_args=(
        "$PROJECT_ROOT"
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
        -DCMAKE_INSTALL_PREFIX="/usr/local"
        -DCMAKE_OSX_ARCHITECTURES="$ARCHITECTURES"
        -DCMAKE_OSX_DEPLOYMENT_TARGET="12.0"
        -DBUILD_TESTS="$ENABLE_TESTS"
        -DBUILD_EXAMPLES="$ENABLE_EXAMPLES"
        -DENABLE_LOGGING=ON
        -DENABLE_IPV6=ON
    )

    # Add Homebrew paths if available
    if command -v brew >/dev/null 2>&1; then
        local brew_prefix="$(brew --prefix)"
        cmake_args+=(
            -DCMAKE_PREFIX_PATH="$brew_prefix"
            -DCMAKE_INCLUDE_PATH="$brew_prefix/include"
            -DCMAKE_LIBRARY_PATH="$brew_prefix/lib"
        )
    fi

    cmake "${cmake_args[@]}"

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
    log_info "Creating macOS packages..."
    cd "$BUILD_DIR"

    # Create DMG package
    log_info "Creating DMG package..."
    cpack -G DragNDrop
    mv simple-snmpd-*.dmg "$DIST_DIR/" 2>/dev/null || true

    # Create PKG package
    log_info "Creating PKG package..."
    cpack -G productbuild
    mv simple-snmpd-*.pkg "$DIST_DIR/" 2>/dev/null || true

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

# Code signing (if certificates are available)
code_sign() {
    if [ -n "$CODE_SIGN_IDENTITY" ]; then
        log_info "Code signing with identity: $CODE_SIGN_IDENTITY"

        # Sign the binary
        if [ -f "$BUILD_DIR/bin/simple-snmpd" ]; then
            codesign --force --sign "$CODE_SIGN_IDENTITY" "$BUILD_DIR/bin/simple-snmpd"
        fi

        # Sign packages if they exist
        for pkg in "$DIST_DIR"/*.pkg; do
            if [ -f "$pkg" ]; then
                productsign --sign "$CODE_SIGN_IDENTITY" "$pkg" "${pkg%.pkg}-signed.pkg"
            fi
        done

        log_success "Code signing completed"
    else
        log_info "Code signing skipped (no CODE_SIGN_IDENTITY set)"
    fi
}

# Notarization (if credentials are available)
notarize() {
    if [ -n "$NOTARIZE_CREDENTIALS" ]; then
        log_info "Notarizing packages..."

        # Notarize DMG packages
        for dmg in "$DIST_DIR"/*.dmg; do
            if [ -f "$dmg" ]; then
                xcrun notarytool submit "$dmg" \
                    --apple-id "$APPLE_ID" \
                    --password "$APP_PASSWORD" \
                    --team-id "$TEAM_ID" \
                    --wait

                xcrun stapler staple "$dmg"
            fi
        done

        log_success "Notarization completed"
    else
        log_info "Notarization skipped (no credentials provided)"
    fi
}

# Show build information
show_build_info() {
    log_info "Build Information:"
    echo "  Project Root: $PROJECT_ROOT"
    echo "  Build Directory: $BUILD_DIR"
    echo "  Build Type: $BUILD_TYPE"
    echo "  Architectures: $ARCHITECTURES"
    echo "  Parallel Jobs: $PARALLEL_JOBS"
    echo "  Tests Enabled: $ENABLE_TESTS"
    echo "  Examples Enabled: $ENABLE_EXAMPLES"
    echo "  Distribution Directory: $DIST_DIR"
    echo "  macOS Version: $(sw_vers -productVersion)"
    echo "  Xcode Version: $(xcodebuild -version | head -n1)"
}

# Main function
main() {
    log_info "Starting macOS build for Simple SNMP Daemon"

    check_macos
    show_build_info

    check_dependencies
    clean_build
    configure_build
    build_project
    run_tests

    if [ "$1" = "--package" ]; then
        create_packages
        code_sign
        notarize
    fi

    if [ "$1" = "--install" ]; then
        install_local
    fi

    log_success "Build process completed successfully!"

    if [ -f "$BUILD_DIR/bin/simple-snmpd" ]; then
        log_info "Binary location: $BUILD_DIR/bin/simple-snmpd"

        # Show binary info
        file "$BUILD_DIR/bin/simple-snmpd"
        lipo -info "$BUILD_DIR/bin/simple-snmpd" 2>/dev/null || true
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
        echo "  BUILD_TYPE         Build type (Debug|Release) [default: Release]"
        echo "  PARALLEL_JOBS      Number of parallel build jobs [default: hw.ncpu]"
        echo "  ENABLE_TESTS       Enable tests (ON|OFF) [default: ON]"
        echo "  ENABLE_EXAMPLES    Enable examples (ON|OFF) [default: OFF]"
        echo "  ARCHITECTURES      Target architectures [default: x86_64;arm64]"
        echo "  CODE_SIGN_IDENTITY Code signing identity (optional)"
        echo "  NOTARIZE_CREDENTIALS Notarization credentials (optional)"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
