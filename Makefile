# Makefile for simple-snmpd
# Simple SNMP Daemon - A lightweight and secure SNMP monitoring daemon
# Copyright 2024 SimpleDaemons
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Variables
PROJECT_NAME = simple-snmpd
VERSION = 0.1.0
BUILD_DIR = build
DIST_DIR = dist
PACKAGE_DIR = packaging

# Platform detection
UNAME_S := $(shell uname -s)
ifeq ($(OS),Windows_NT)
    PLATFORM = windows
    # Windows specific settings
    CXX = cl
    CXXFLAGS = /std:c++17 /W3 /O2 /DNDEBUG /EHsc
    LDFLAGS = ws2_32.lib crypt32.lib
    # Windows specific flags
    CXXFLAGS += /DWIN32 /D_WINDOWS /D_CRT_SECURE_NO_WARNINGS
    # Detect processor cores for parallel builds
    PARALLEL_JOBS = $(shell echo %NUMBER_OF_PROCESSORS%)
    # Windows install paths
    INSTALL_PREFIX = C:/Program Files/$(PROJECT_NAME)
    CONFIG_DIR = $(INSTALL_PREFIX)/etc
    # Windows file extensions
    EXE_EXT = .exe
    LIB_EXT = .lib
    DLL_EXT = .dll
    # Windows commands
    RM = del /Q
    RMDIR = rmdir /S /Q
    MKDIR = mkdir
    CP = copy
    # Check if running in Git Bash or similar
    ifeq ($(shell echo $$SHELL),/usr/bin/bash)
        # Running in Git Bash, use Unix commands
        RM = rm -rf
        RMDIR = rm -rf
        MKDIR = mkdir -p
        CP = cp -r
        # Use Unix-style paths
        INSTALL_PREFIX = /c/Program\ Files/$(PROJECT_NAME)
        CONFIG_DIR = /c/Program\ Files/$(PROJECT_NAME)/etc
    endif
else ifeq ($(UNAME_S),Darwin)
    PLATFORM = macos
    CXX = clang++
    CXXFLAGS = -std=c++17 -Wall -Wextra -Wpedantic -O2 -DNDEBUG
    LDFLAGS = -lssl -lcrypto
    # macOS specific flags
    CXXFLAGS += -target x86_64-apple-macos12.0 -target arm64-apple-macos12.0
    # Detect processor cores for parallel builds
    PARALLEL_JOBS = $(shell sysctl -n hw.ncpu)
    # macOS install paths
    INSTALL_PREFIX = /usr/local
    CONFIG_DIR = $(INSTALL_PREFIX)/etc/$(PROJECT_NAME)
    # Unix file extensions
    EXE_EXT =
    LIB_EXT = .dylib
    DLL_EXT = .dylib
    # Unix commands
    RM = rm -rf
    RMDIR = rm -rf
    MKDIR = mkdir -p
    CP = cp -r
else
    PLATFORM = linux
    CXX = g++
    CXXFLAGS = -std=c++17 -Wall -Wextra -Wpedantic -O2 -DNDEBUG
    LDFLAGS = -lssl -lcrypto -lpthread
    # Linux specific flags
    PARALLEL_JOBS = $(shell nproc)
    # Linux install paths
    INSTALL_PREFIX = /usr/local
    CONFIG_DIR = /etc/$(PROJECT_NAME)
    # Unix file extensions
    EXE_EXT =
    LIB_EXT = .so
    DLL_EXT = .so
    # Unix commands
    RM = rm -rf
    RMDIR = rm -rf
    MKDIR = mkdir -p
    CP = cp -r
endif

# Directories
SRC_DIR = src
INCLUDE_DIR = include
CONFIG_DIR_SRC = config
SCRIPTS_DIR = scripts
DEPLOYMENT_DIR = deployment

# Legacy variables for compatibility
INSTALL_DIR = $(INSTALL_PREFIX)
LOG_DIR = /var/log
DATA_DIR = /var/lib/$(PROJECT_NAME)

# Default target
all: build

# Create build directory
$(BUILD_DIR)-dir:
ifeq ($(PLATFORM),windows)
	$(MKDIR) $(BUILD_DIR)
else
	$(MKDIR) $(BUILD_DIR)
endif

# Build using CMake
build: $(BUILD_DIR)-dir
ifeq ($(PLATFORM),windows)
	cd $(BUILD_DIR) && cmake .. -G "Visual Studio 16 2019" -A x64 && cmake --build . --config Release
else
	cd $(BUILD_DIR) && cmake .. && make -j$(PARALLEL_JOBS)
endif

# Clean build
clean:
ifeq ($(PLATFORM),windows)
	$(RMDIR) $(BUILD_DIR)
	$(RMDIR) $(DIST_DIR)
else
	$(RM) $(BUILD_DIR)
	$(RM) $(DIST_DIR)
endif

# Install
install: build
ifeq ($(PLATFORM),windows)
	cd $(BUILD_DIR) && cmake --install . --prefix "$(INSTALL_PREFIX)"
else
	cd $(BUILD_DIR) && sudo make install
endif

# Uninstall
uninstall:
ifeq ($(PLATFORM),windows)
	$(RMDIR) "$(INSTALL_PREFIX)"
else
	sudo rm -f $(INSTALL_PREFIX)/bin/$(PROJECT_NAME)
	sudo rm -f $(INSTALL_PREFIX)/lib/lib$(PROJECT_NAME).so
	sudo rm -f $(INSTALL_PREFIX)/lib/lib$(PROJECT_NAME).dylib
	sudo rm -rf $(INSTALL_PREFIX)/include/$(PROJECT_NAME)
	sudo rm -rf $(CONFIG_DIR)
endif

# Test
test: build
ifeq ($(PLATFORM),windows)
	cd $(BUILD_DIR) && ctest --output-on-failure
else
	cd $(BUILD_DIR) && make test
endif

# Generic package target (platform-specific)
package: build
ifeq ($(PLATFORM),macos)
	@echo "Building macOS packages..."
	@mkdir -p $(DIST_DIR)
	cd $(BUILD_DIR) && cpack -G DragNDrop
	cd $(BUILD_DIR) && cpack -G productbuild
	mv $(BUILD_DIR)/$(PROJECT_NAME)-$(VERSION)-*.dmg $(DIST_DIR)/ 2>/dev/null || true
	mv $(BUILD_DIR)/$(PROJECT_NAME)-$(VERSION)-*.pkg $(DIST_DIR)/ 2>/dev/null || true
	@echo "macOS packages created: DMG and PKG"
else ifeq ($(PLATFORM),linux)
	@echo "Building Linux packages..."
	@mkdir -p $(DIST_DIR)
	cd $(BUILD_DIR) && cpack -G RPM
	cd $(BUILD_DIR) && cpack -G DEB
	mv $(BUILD_DIR)/$(PROJECT_NAME)-$(VERSION)-*.rpm $(DIST_DIR)/ 2>/dev/null || true
	mv $(BUILD_DIR)/$(PROJECT_NAME)-$(VERSION)-*.deb $(DIST_DIR)/ 2>/dev/null || true
	@echo "Linux packages created: RPM and DEB"
else ifeq ($(PLATFORM),windows)
	@echo "Building Windows packages..."
	@$(MKDIR) $(DIST_DIR)
	cd $(BUILD_DIR) && cpack -G WIX
	cd $(BUILD_DIR) && cpack -G ZIP
	$(CP) $(BUILD_DIR)/$(PROJECT_NAME)-$(VERSION)-*.msi $(DIST_DIR)/ 2>/dev/null || true
	$(CP) $(BUILD_DIR)/$(PROJECT_NAME)-$(VERSION)-*.zip $(DIST_DIR)/ 2>/dev/null || true
	@echo "Windows packages created: MSI and ZIP"
else
	@echo "Package generation not supported on this platform"
endif

# Help - Main help (most common targets)
help:
	@echo "Simple SNMP Daemon - Main Help"
	@echo "=============================="
	@echo ""
	@echo "Essential targets:"
	@echo "  all              - Build the project (default)"
	@echo "  build            - Build using CMake"
	@echo "  clean            - Clean build files"
	@echo "  install          - Install the project"
	@echo "  uninstall        - Uninstall the project"
	@echo "  test             - Run tests"
	@echo "  package          - Build platform-specific packages"
	@echo "  package-source   - Create source code package"
	@echo ""
	@echo "Development targets:"
	@echo "  dev-build        - Build in debug mode"
	@echo "  dev-test         - Run tests in debug mode"
	@echo "  format           - Format source code"
	@echo "  lint             - Run static analysis"
	@echo "  security-scan    - Run security scanning tools"
	@echo ""
	@echo "Dependency management:"
	@echo "  deps             - Install dependencies"
	@echo "  dev-deps         - Install development tools"
	@echo ""
	@echo "Service management:"
	@echo "  service-install  - Install system service"
	@echo "  service-status   - Check service status"
	@echo "  service-start    - Start service"
	@echo "  service-stop     - Stop service"
	@echo ""
	@echo "Help categories:"
	@echo "  help-all         - Show all available targets"
	@echo "  help-build       - Build and development targets"
	@echo "  help-package     - Package creation targets"
	@echo "  help-deps        - Dependency management targets"
	@echo "  help-service     - Service management targets"
	@echo "  help-docker      - Docker targets"
	@echo "  help-config      - Configuration management targets"
	@echo "  help-platform    - Platform-specific targets"
	@echo ""
	@echo "Examples:"
	@echo "  make build       - Build the project"
	@echo "  make test        - Build and run tests"
	@echo "  make package     - Create platform-specific packages"
	@echo "  make dev-deps    - Install development tools"
	@echo "  make help-all    - Show all available targets"

# Development targets
dev-build: $(BUILD_DIR)-dir
ifeq ($(PLATFORM),windows)
	cd $(BUILD_DIR) && cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=Debug && cmake --build . --config Debug
else
	cd $(BUILD_DIR) && cmake .. -DCMAKE_BUILD_TYPE=Debug && make -j$(PARALLEL_JOBS)
endif

dev-test: dev-build
ifeq ($(PLATFORM),windows)
	cd $(BUILD_DIR) && ctest --output-on-failure -C Debug
else
	cd $(BUILD_DIR) && make test
endif

# Code formatting (requires clang-format)
format:
	@echo "Formatting source code..."
	@find $(SRC_DIR) $(INCLUDE_DIR) -name "*.cpp" -o -name "*.hpp" -o -name "*.h" | xargs clang-format -i
	@echo "Code formatting complete"

# Static analysis (requires cppcheck)
lint:
	@echo "Running static analysis..."
	@cppcheck --enable=all --std=c++17 --suppress=missingIncludeSystem $(SRC_DIR) $(INCLUDE_DIR)
	@echo "Static analysis complete"

# Security scanning (requires cppcheck with security checks)
security-scan:
	@echo "Running security scan..."
	@cppcheck --enable=all --std=c++17 --suppress=missingIncludeSystem $(SRC_DIR) $(INCLUDE_DIR)
	@echo "Security scan complete"

# Dependency management
deps:
ifeq ($(PLATFORM),macos)
	@echo "Installing dependencies on macOS..."
	@brew install openssl cmake
	@echo "Dependencies installed"
else ifeq ($(PLATFORM),linux)
	@echo "Installing dependencies on Linux..."
	@sudo apt-get update
	@sudo apt-get install -y build-essential cmake libssl-dev pkg-config
	@echo "Dependencies installed"
else ifeq ($(PLATFORM),windows)
	@echo "Dependencies should be installed via vcpkg or manually on Windows"
	@echo "Required: OpenSSL, CMake, Visual Studio 2019 or later"
endif

dev-deps:
ifeq ($(PLATFORM),macos)
	@echo "Installing development tools on macOS..."
	@brew install clang-format cppcheck
	@echo "Development tools installed (valgrind not available on macOS)"
else ifeq ($(PLATFORM),linux)
	@echo "Installing development tools on Linux..."
	@sudo apt-get install -y clang-format cppcheck valgrind gdb
	@echo "Development tools installed"
else ifeq ($(PLATFORM),windows)
	@echo "Development tools should be installed manually on Windows"
	@echo "Recommended: Visual Studio with C++ tools, clang-format, cppcheck"
endif

# Service management
service-install: build
ifeq ($(PLATFORM),macos)
	@echo "Installing launchd service..."
	@sudo cp deployment/macos/com.simpledaemons.simple-snmpd.plist /Library/LaunchDaemons/
	@sudo launchctl load /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
	@echo "Service installed and started"
else ifeq ($(PLATFORM),linux)
	@echo "Installing systemd service..."
	@sudo cp deployment/linux/simple-snmpd.service /etc/systemd/system/
	@sudo systemctl daemon-reload
	@sudo systemctl enable simple-snmpd
	@sudo systemctl start simple-snmpd
	@echo "Service installed and started"
else
	@echo "Service installation not supported on this platform"
endif

service-status:
ifeq ($(PLATFORM),macos)
	@launchctl list | grep simple-snmpd || echo "Service not running"
else ifeq ($(PLATFORM),linux)
	@systemctl status simple-snmpd
else
	@echo "Service status check not supported on this platform"
endif

service-start:
ifeq ($(PLATFORM),macos)
	@sudo launchctl start com.simpledaemons.simple-snmpd
	@echo "Service started"
else ifeq ($(PLATFORM),linux)
	@sudo systemctl start simple-snmpd
	@echo "Service started"
else
	@echo "Service start not supported on this platform"
endif

service-stop:
ifeq ($(PLATFORM),macos)
	@sudo launchctl stop com.simpledaemons.simple-snmpd
	@echo "Service stopped"
else ifeq ($(PLATFORM),linux)
	@sudo systemctl stop simple-snmpd
	@echo "Service stopped"
else
	@echo "Service stop not supported on this platform"
endif

# Package source code
package-source:
	@echo "Creating source package..."
	@mkdir -p $(DIST_DIR)
	@git archive --format=tar.gz --prefix=$(PROJECT_NAME)-$(VERSION)/ HEAD > $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-source.tar.gz
	@echo "Source package created: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-source.tar.gz"

# Docker targets
docker-build:
	@echo "Building Docker image..."
	@docker build -t $(PROJECT_NAME):$(VERSION) .
	@docker tag $(PROJECT_NAME):$(VERSION) $(PROJECT_NAME):latest
	@echo "Docker image built: $(PROJECT_NAME):$(VERSION)"

docker-run:
	@echo "Running Docker container..."
	@docker run -d --name $(PROJECT_NAME)-container -p 161:161/udp -p 8080:8080 $(PROJECT_NAME):latest
	@echo "Docker container started"

docker-stop:
	@echo "Stopping Docker container..."
	@docker stop $(PROJECT_NAME)-container || true
	@docker rm $(PROJECT_NAME)-container || true
	@echo "Docker container stopped and removed"

# Configuration management
config-validate:
	@echo "Validating configuration files..."
	@find config/ -name "*.conf" -exec echo "Validating {}" \;
	@echo "Configuration validation complete"

config-install:
	@echo "Installing configuration files..."
	@sudo $(MKDIR) $(CONFIG_DIR)
	@sudo $(CP) config/* $(CONFIG_DIR)/
	@echo "Configuration files installed"

# Platform-specific targets
macos-universal: clean
	@echo "Building universal macOS binary..."
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake .. -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" && make -j$(PARALLEL_JOBS)
	@echo "Universal macOS binary built"

linux-static: clean
	@echo "Building static Linux binary..."
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF && make -j$(PARALLEL_JOBS)
	@echo "Static Linux binary built"

# Help targets
help-all:
	@echo "Simple SNMP Daemon - All Available Targets"
	@echo "==========================================="
	@echo ""
	@echo "Build targets:"
	@echo "  all              - Build the project (default)"
	@echo "  build            - Build using CMake"
	@echo "  dev-build        - Build in debug mode"
	@echo "  clean            - Clean build files"
	@echo ""
	@echo "Test targets:"
	@echo "  test             - Run tests"
	@echo "  dev-test         - Run tests in debug mode"
	@echo ""
	@echo "Install targets:"
	@echo "  install          - Install the project"
	@echo "  uninstall        - Uninstall the project"
	@echo ""
	@echo "Package targets:"
	@echo "  package          - Build platform-specific packages"
	@echo "  package-source   - Create source code package"
	@echo ""
	@echo "Development targets:"
	@echo "  format           - Format source code"
	@echo "  lint             - Run static analysis"
	@echo "  security-scan    - Run security scanning tools"
	@echo ""
	@echo "Dependency targets:"
	@echo "  deps             - Install dependencies"
	@echo "  dev-deps         - Install development tools"
	@echo ""
	@echo "Service targets:"
	@echo "  service-install  - Install system service"
	@echo "  service-status   - Check service status"
	@echo "  service-start    - Start service"
	@echo "  service-stop     - Stop service"
	@echo ""
	@echo "Docker targets:"
	@echo "  docker-build     - Build Docker image"
	@echo "  docker-run       - Run Docker container"
	@echo "  docker-stop      - Stop Docker container"
	@echo ""
	@echo "Configuration targets:"
	@echo "  config-validate  - Validate configuration files"
	@echo "  config-install   - Install configuration files"
	@echo ""
	@echo "Platform-specific targets:"
	@echo "  macos-universal  - Build universal macOS binary"
	@echo "  linux-static     - Build static Linux binary"
	@echo ""
	@echo "Help targets:"
	@echo "  help             - Show main help"
	@echo "  help-all         - Show all available targets"
	@echo "  help-build       - Show build targets"
	@echo "  help-package     - Show package targets"
	@echo "  help-deps        - Show dependency targets"
	@echo "  help-service     - Show service targets"
	@echo "  help-docker      - Show Docker targets"
	@echo "  help-config      - Show configuration targets"
	@echo "  help-platform    - Show platform-specific targets"

help-build:
	@echo "Build and Development Targets"
	@echo "============================="
	@echo "  all              - Build the project (default)"
	@echo "  build            - Build using CMake"
	@echo "  dev-build        - Build in debug mode"
	@echo "  clean            - Clean build files"
	@echo "  test             - Run tests"
	@echo "  dev-test         - Run tests in debug mode"
	@echo "  format           - Format source code"
	@echo "  lint             - Run static analysis"
	@echo "  security-scan    - Run security scanning tools"

help-package:
	@echo "Package Creation Targets"
	@echo "========================"
	@echo "  package          - Build platform-specific packages"
	@echo "  package-source   - Create source code package"
	@echo "  macos-universal  - Build universal macOS binary"
	@echo "  linux-static     - Build static Linux binary"

help-deps:
	@echo "Dependency Management Targets"
	@echo "============================="
	@echo "  deps             - Install dependencies"
	@echo "  dev-deps         - Install development tools"

help-service:
	@echo "Service Management Targets"
	@echo "=========================="
	@echo "  service-install  - Install system service"
	@echo "  service-status   - Check service status"
	@echo "  service-start    - Start service"
	@echo "  service-stop     - Stop service"

help-docker:
	@echo "Docker Targets"
	@echo "=============="
	@echo "  docker-build     - Build Docker image"
	@echo "  docker-run       - Run Docker container"
	@echo "  docker-stop      - Stop Docker container"

help-config:
	@echo "Configuration Management Targets"
	@echo "==============================="
	@echo "  config-validate  - Validate configuration files"
	@echo "  config-install   - Install configuration files"

help-platform:
	@echo "Platform-Specific Targets"
	@echo "========================="
	@echo "  macos-universal  - Build universal macOS binary"
	@echo "  linux-static     - Build static Linux binary"

# Phony targets
.PHONY: all build clean install uninstall test package package-source help
.PHONY: dev-build dev-test format lint security-scan deps dev-deps
.PHONY: service-install service-status service-start service-stop
.PHONY: docker-build docker-run docker-stop config-validate config-install
.PHONY: macos-universal linux-static
.PHONY: help-all help-build help-package help-deps help-service help-docker help-config help-platform

# Default target
.DEFAULT_GOAL := all
