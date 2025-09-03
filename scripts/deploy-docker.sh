#!/bin/bash
#
# Docker deployment script for Simple SNMP Daemon
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pWD)"

# Deployment configuration
IMAGE_NAME="${IMAGE_NAME:-simpledaemons/simple-snmpd}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-simple-snmpd}"
CONFIG_DIR="${CONFIG_DIR:-$PROJECT_ROOT/config}"
LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/logs}"
SNMP_PORT="${SNMP_PORT:-161}"
TRAP_PORT="${TRAP_PORT:-162}"

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

# Check Docker availability
check_docker() {
    log_info "Checking Docker availability..."

    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    log_success "Docker is available"
}

# Check if container exists
container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Check if container is running
container_running() {
    docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Stop existing container
stop_container() {
    if container_running; then
        log_info "Stopping existing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME"
        log_success "Container stopped"
    fi
}

# Remove existing container
remove_container() {
    if container_exists; then
        log_info "Removing existing container: $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME"
        log_success "Container removed"
    fi
}

# Pull latest image
pull_image() {
    log_info "Pulling latest image: ${IMAGE_NAME}:${IMAGE_TAG}"
    docker pull "${IMAGE_NAME}:${IMAGE_TAG}"
    log_success "Image pulled"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"

    log_success "Directories created"
}

# Deploy container
deploy_container() {
    log_info "Deploying container: $CONTAINER_NAME"

    local docker_args=(
        --name "$CONTAINER_NAME"
        --detach
        --restart unless-stopped
        --publish "${SNMP_PORT}:161/udp"
        --publish "${TRAP_PORT}:162/udp"
        --volume "${CONFIG_DIR}:/etc/simple-snmpd:ro"
        --volume "${LOG_DIR}:/var/log/simple-snmpd"
        --env "SNMP_COMMUNITY=${SNMP_COMMUNITY:-public}"
        --env "LOG_LEVEL=${LOG_LEVEL:-info}"
    )

    # Add health check
    docker_args+=(
        --health-cmd "nc -z localhost 161 || exit 1"
        --health-interval 30s
        --health-timeout 10s
        --health-retries 3
        --health-start-period 40s
    )

    docker run "${docker_args[@]}" "${IMAGE_NAME}:${IMAGE_TAG}"

    log_success "Container deployed"
}

# Show container status
show_status() {
    log_info "Container Status:"

    if container_running; then
        log_success "Container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_warning "Container is not running"
    fi

    # Show logs
    log_info "Recent logs:"
    docker logs --tail 10 "$CONTAINER_NAME" 2>/dev/null || log_warning "No logs available"
}

# Show container information
show_info() {
    log_info "Container Information:"
    echo "  Container Name: $CONTAINER_NAME"
    echo "  Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "  SNMP Port: $SNMP_PORT"
    echo "  Trap Port: $TRAP_PORT"
    echo "  Config Directory: $CONFIG_DIR"
    echo "  Log Directory: $LOG_DIR"
    echo "  Community: ${SNMP_COMMUNITY:-public}"
    echo "  Log Level: ${LOG_LEVEL:-info}"
}

# Test SNMP connectivity
test_snmp() {
    log_info "Testing SNMP connectivity..."

    # Wait for container to be ready
    sleep 5

    # Test with netcat if available
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost "$SNMP_PORT"; then
            log_success "SNMP port is accessible"
        else
            log_error "SNMP port is not accessible"
        fi
    else
        log_warning "netcat not available, skipping port test"
    fi

    # Test with snmpget if available
    if command -v snmpget >/dev/null 2>&1; then
        if snmpget -v2c -c "${SNMP_COMMUNITY:-public}" localhost 1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            log_success "SNMP query successful"
        else
            log_warning "SNMP query failed (this may be normal if MIB is not fully implemented)"
        fi
    else
        log_info "snmpget not available, skipping SNMP test"
    fi
}

# Main function
main() {
    log_info "Starting Docker deployment for Simple SNMP Daemon"

    show_info

    check_docker
    create_directories

    case "${1:-deploy}" in
        "deploy")
            stop_container
            remove_container
            pull_image
            deploy_container
            test_snmp
            show_status
            ;;
        "start")
            if container_exists && ! container_running; then
                log_info "Starting container: $CONTAINER_NAME"
                docker start "$CONTAINER_NAME"
                log_success "Container started"
            else
                log_warning "Container does not exist or is already running"
            fi
            show_status
            ;;
        "stop")
            stop_container
            show_status
            ;;
        "restart")
            stop_container
            if container_exists; then
                log_info "Starting container: $CONTAINER_NAME"
                docker start "$CONTAINER_NAME"
                log_success "Container restarted"
            else
                log_warning "Container does not exist"
            fi
            show_status
            ;;
        "remove")
            stop_container
            remove_container
            log_success "Container removed"
            ;;
        "status")
            show_status
            ;;
        "logs")
            log_info "Showing container logs:"
            docker logs -f "$CONTAINER_NAME"
            ;;
        "test")
            test_snmp
            ;;
        *)
            log_error "Unknown command: $1"
            exit 1
            ;;
    esac

    log_success "Deployment operation completed!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [COMMAND] [OPTIONS]"
        echo ""
        echo "Commands:"
        echo "  deploy     Deploy the container (default)"
        echo "  start      Start existing container"
        echo "  stop       Stop running container"
        echo "  restart    Restart container"
        echo "  remove     Remove container"
        echo "  status     Show container status"
        echo "  logs       Show container logs"
        echo "  test       Test SNMP connectivity"
        echo "  --help     Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  IMAGE_NAME      Docker image name [default: simpledaemons/simple-snmpd]"
        echo "  IMAGE_TAG       Docker image tag [default: latest]"
        echo "  CONTAINER_NAME  Container name [default: simple-snmpd]"
        echo "  CONFIG_DIR      Config directory [default: ./config]"
        echo "  LOG_DIR         Log directory [default: ./logs]"
        echo "  SNMP_PORT       SNMP port [default: 161]"
        echo "  TRAP_PORT       Trap port [default: 162]"
        echo "  SNMP_COMMUNITY  SNMP community [default: public]"
        echo "  LOG_LEVEL       Log level [default: info]"
        echo ""
        echo "Examples:"
        echo "  $0 deploy                    # Deploy container"
        echo "  $0 start                     # Start container"
        echo "  $0 logs                      # Show logs"
        echo "  $0 test                      # Test SNMP"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
