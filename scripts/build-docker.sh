#!/bin/bash
#
# Docker build script for Simple SNMP Daemon
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build configuration
IMAGE_NAME="${IMAGE_NAME:-simpledaemons/simple-snmpd}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BUILD_TARGET="${BUILD_TARGET:-runtime}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"

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

# Check Docker Buildx
check_buildx() {
    log_info "Checking Docker Buildx..."

    if ! docker buildx version >/dev/null 2>&1; then
        log_error "Docker Buildx is not available"
        exit 1
    fi

    # Create buildx builder if it doesn't exist
    if ! docker buildx inspect multiarch >/dev/null 2>&1; then
        log_info "Creating multiarch builder..."
        docker buildx create --name multiarch --use
    else
        docker buildx use multiarch
    fi

    log_success "Docker Buildx is ready"
}

# Build single platform image
build_single_platform() {
    local platform="$1"
    local target="$2"

    log_info "Building for platform: $platform (target: $target)"

    docker build \
        --platform "$platform" \
        --target "$target" \
        --tag "${IMAGE_NAME}:${IMAGE_TAG}-$(echo "$platform" | tr '/' '-')" \
        "$PROJECT_ROOT"

    log_success "Built image for $platform"
}

# Build multi-platform image
build_multi_platform() {
    log_info "Building multi-platform image for: $PLATFORMS"

    local build_args=(
        --platform "$PLATFORMS"
        --target "$BUILD_TARGET"
        --tag "${IMAGE_NAME}:${IMAGE_TAG}"
    )

    if [ "$PUSH_IMAGE" = "true" ]; then
        build_args+=(--push)
    else
        build_args+=(--load)
    fi

    docker buildx build "${build_args[@]}" "$PROJECT_ROOT"

    log_success "Multi-platform build completed"
}

# Build development image
build_dev_image() {
    log_info "Building development image..."

    docker build \
        --target dev \
        --tag "${IMAGE_NAME}:dev" \
        "$PROJECT_ROOT"

    log_success "Development image built"
}

# Build all builder images
build_builder_images() {
    log_info "Building builder images for different distributions..."

    local builders=("ubuntu-builder" "centos-builder" "alpine-builder")

    for builder in "${builders[@]}"; do
        log_info "Building $builder..."
        docker build \
            --target "$builder" \
            --tag "${IMAGE_NAME}:${builder}" \
            "$PROJECT_ROOT"
    done

    log_success "All builder images built"
}

# Test image
test_image() {
    local image_name="$1"

    log_info "Testing image: $image_name"

    # Test basic functionality
    if docker run --rm "$image_name" --version >/dev/null 2>&1; then
        log_success "Image test passed"
    else
        log_error "Image test failed"
        exit 1
    fi
}

# Show build information
show_build_info() {
    log_info "Build Information:"
    echo "  Project Root: $PROJECT_ROOT"
    echo "  Image Name: $IMAGE_NAME"
    echo "  Image Tag: $IMAGE_TAG"
    echo "  Build Target: $BUILD_TARGET"
    echo "  Platforms: $PLATFORMS"
    echo "  Push Image: $PUSH_IMAGE"
    echo "  Docker Version: $(docker --version)"
    echo "  Buildx Version: $(docker buildx version | head -n1)"
}

# Clean up old images
cleanup_images() {
    log_info "Cleaning up old images..."

    # Remove dangling images
    docker image prune -f

    # Remove old versions of our image
    docker images "${IMAGE_NAME}" --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}" | \
        grep -v "$IMAGE_TAG" | \
        awk 'NR>1 {print $2}' | \
        xargs -r docker rmi -f

    log_success "Cleanup completed"
}

# Main function
main() {
    log_info "Starting Docker build for Simple SNMP Daemon"

    show_build_info

    check_docker
    check_buildx

    case "${1:-}" in
        "dev")
            build_dev_image
            test_image "${IMAGE_NAME}:dev"
            ;;
        "builders")
            build_builder_images
            ;;
        "single")
            if [ -z "$2" ]; then
                log_error "Platform required for single build"
                exit 1
            fi
            build_single_platform "$2" "$BUILD_TARGET"
            test_image "${IMAGE_NAME}:${IMAGE_TAG}-$(echo "$2" | tr '/' '-')"
            ;;
        "multi"|"")
            build_multi_platform
            if [ "$PUSH_IMAGE" != "true" ]; then
                test_image "${IMAGE_NAME}:${IMAGE_TAG}"
            fi
            ;;
        "cleanup")
            cleanup_images
            ;;
        *)
            log_error "Unknown build type: $1"
            exit 1
            ;;
    esac

    log_success "Docker build process completed successfully!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [BUILD_TYPE] [OPTIONS]"
        echo ""
        echo "Build Types:"
        echo "  dev        Build development image"
        echo "  builders   Build all builder images"
        echo "  single     Build single platform image (requires platform)"
        echo "  multi      Build multi-platform image (default)"
        echo "  cleanup    Clean up old images"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Multi-platform build"
        echo "  $0 dev                                # Development image"
        echo "  $0 single linux/amd64                # Single platform"
        echo "  $0 builders                           # All builders"
        echo ""
        echo "Environment variables:"
        echo "  IMAGE_NAME      Docker image name [default: simpledaemons/simple-snmpd]"
        echo "  IMAGE_TAG       Docker image tag [default: latest]"
        echo "  BUILD_TARGET    Docker build target [default: runtime]"
        echo "  PLATFORMS       Target platforms [default: linux/amd64,linux/arm64]"
        echo "  PUSH_IMAGE      Push image to registry [default: false]"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
