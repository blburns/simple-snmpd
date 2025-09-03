#!/bin/bash
#
# install-systemd-service.sh
# Install systemd service for Simple SNMP Daemon
#
# This script helps install the systemd service file and enables
# the init.d wrapper to use systemd when available.
#
# Author: SimpleDaemons
# License: Apache 2.0

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SERVICE_NAME="simple-snmpd"
SYSTEMD_DIR="/etc/systemd/system"
INITD_DIR="/etc/init.d"

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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if systemd is available
check_systemd() {
    if ! command -v systemctl >/dev/null 2>&1; then
        log_error "systemctl not found. This system may not use systemd."
        exit 1
    fi

    if ! systemctl --version >/dev/null 2>&1; then
        log_error "systemd is not running on this system"
        exit 1
    fi

    log_success "systemd is available"
}

# Install systemd service file
install_systemd_service() {
    log_info "Installing systemd service file..."

    local service_file="$PROJECT_ROOT/deployment/systemd/${SERVICE_NAME}.service"

    if [ ! -f "$service_file" ]; then
        log_error "Service file not found: $service_file"
        exit 1
    fi

    cp "$service_file" "$SYSTEMD_DIR/"
    log_success "Service file installed to $SYSTEMD_DIR/${SERVICE_NAME}.service"
}

# Install init.d script
install_initd_script() {
    log_info "Installing init.d script..."

    local initd_script="$PROJECT_ROOT/deployment/init.d/${SERVICE_NAME}"

    if [ ! -f "$initd_script" ]; then
        log_error "Init.d script not found: $initd_script"
        exit 1
    fi

    cp "$initd_script" "$INITD_DIR/"
    chmod +x "$INITD_DIR/${SERVICE_NAME}"
    log_success "Init.d script installed to $INITD_DIR/${SERVICE_NAME}"
}

# Reload systemd daemon
reload_systemd() {
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload
    log_success "Systemd daemon reloaded"
}

# Enable service
enable_service() {
    log_info "Enabling service..."
    systemctl enable "${SERVICE_NAME}.service"
    log_success "Service enabled"
}

# Start service
start_service() {
    log_info "Starting service..."
    systemctl start "${SERVICE_NAME}.service"
    log_success "Service started"
}

# Show service status
show_status() {
    log_info "Service status:"
    systemctl status "${SERVICE_NAME}.service" --no-pager -l
}

# Test init.d wrapper
test_initd_wrapper() {
    log_info "Testing init.d wrapper..."

    if [ -x "$INITD_DIR/${SERVICE_NAME}" ]; then
        "$INITD_DIR/${SERVICE_NAME}" info
        log_success "Init.d wrapper is working"
    else
        log_error "Init.d wrapper not found or not executable"
        exit 1
    fi
}

# Main installation function
install_service() {
    log_info "Installing Simple SNMP Daemon service..."

    check_root
    check_systemd

    install_systemd_service
    install_initd_script
    reload_systemd
    enable_service

    log_success "Service installation completed!"

    # Show information
    echo ""
    log_info "Service Information:"
    echo "  Systemd service: $SYSTEMD_DIR/${SERVICE_NAME}.service"
    echo "  Init.d script: $INITD_DIR/${SERVICE_NAME}"
    echo "  Service enabled: $(systemctl is-enabled "${SERVICE_NAME}.service" 2>/dev/null || echo 'No')"
    echo ""

    # Test the wrapper
    test_initd_wrapper

    echo ""
    log_info "You can now use either:"
    echo "  systemctl start/stop/restart ${SERVICE_NAME}"
    echo "  service ${SERVICE_NAME} start/stop/restart"
    echo "  /etc/init.d/${SERVICE_NAME} start/stop/restart"
}

# Uninstall service
uninstall_service() {
    log_info "Uninstalling Simple SNMP Daemon service..."

    check_root

    # Stop and disable service
    if systemctl is-active "${SERVICE_NAME}.service" >/dev/null 2>&1; then
        log_info "Stopping service..."
        systemctl stop "${SERVICE_NAME}.service"
    fi

    if systemctl is-enabled "${SERVICE_NAME}.service" >/dev/null 2>&1; then
        log_info "Disabling service..."
        systemctl disable "${SERVICE_NAME}.service"
    fi

    # Remove files
    if [ -f "$SYSTEMD_DIR/${SERVICE_NAME}.service" ]; then
        rm -f "$SYSTEMD_DIR/${SERVICE_NAME}.service"
        log_success "Removed systemd service file"
    fi

    if [ -f "$INITD_DIR/${SERVICE_NAME}" ]; then
        rm -f "$INITD_DIR/${SERVICE_NAME}"
        log_success "Removed init.d script"
    fi

    # Reload systemd
    systemctl daemon-reload

    log_success "Service uninstalled"
}

# Show usage
usage() {
    echo "Usage: $0 {install|uninstall|status|test}"
    echo ""
    echo "Commands:"
    echo "  install     - Install systemd service and init.d wrapper"
    echo "  uninstall   - Remove systemd service and init.d wrapper"
    echo "  status      - Show service status"
    echo "  test        - Test init.d wrapper functionality"
    echo ""
    echo "This script installs both systemd service and init.d wrapper"
    echo "for maximum compatibility across different Linux distributions."
    exit 1
}

# Main script logic
case "${1:-install}" in
    "install")
        install_service
        ;;
    "uninstall")
        uninstall_service
        ;;
    "status")
        check_root
        check_systemd
        show_status
        ;;
    "test")
        check_root
        test_initd_wrapper
        ;;
    "--help"|"-h")
        usage
        ;;
    *)
        log_error "Unknown command: $1"
        usage
        ;;
esac
