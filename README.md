# Simple SNMP Daemon

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/simpledaemons/simple-snmpd)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](https://github.com/simpledaemons/simple-snmpd)

A lightweight, secure, and cross-platform SNMP daemon built with modern C++.

## Features

- **Lightweight**: Minimal resource footprint with efficient memory usage
- **Secure**: Built with security best practices and access controls
- **Cross-platform**: Runs on Linux, macOS, and Windows
- **Modern C++**: Built with C++17 and modern development practices
- **SNMP v2c Support**: Full SNMP v2c protocol implementation
- **Docker Ready**: Containerized deployment with multi-architecture support
- **Production Ready**: Comprehensive logging, monitoring, and deployment options

## Quick Start

### Installation

#### From Source

```bash
# Clone the repository
git clone https://github.com/simpledaemons/simple-snmpd.git
cd simple-snmpd

# Build the project
make

# Install (requires sudo on Unix systems)
make install
```

#### Using Docker

```bash
# Pull the Docker image
docker pull simpledaemons/simple-snmpd:latest

# Run the container
docker run -d --name simple-snmpd \
  -p 161:161/udp \
  -v /path/to/config:/etc/simple-snmpd \
  simpledaemons/simple-snmpd:latest
```

### Basic Usage

```bash
# Start with default configuration
sudo simple-snmpd

# Start with custom config
sudo simple-snmpd -c /path/to/config.conf

# Test configuration
simple-snmpd --test-config -c /etc/simple-snmpd/simple-snmpd.conf
```

### Test SNMP Queries

```bash
# Test with snmpget (if available)
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test with snmpwalk (if available)
snmpwalk -v2c -c public localhost
```

## Configuration

Edit `/etc/simple-snmpd/simple-snmpd.conf`:

```ini
# Network Configuration
port=161
enable_ipv6=true

# Community Configuration
community=public

# Connection Limits
max_connections=100
timeout_seconds=30

# Logging Configuration
log_level=info

# Trap Configuration
enable_trap=false
trap_port=162
```

See the [Configuration Guide](docs/configuration/README.md) for detailed options.

## Building

### Prerequisites

- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)
- CMake 3.16 or later
- Git

### Build Commands

```bash
# Basic build
make

# Build with tests
make test

# Build packages
make package

# Clean build
make clean
```

### Platform-Specific Builds

#### Linux

```bash
# Use the Linux build script
./scripts/build/build-linux.sh

# Build with packages
./scripts/build/build-linux.sh --package
```

#### macOS

```bash
# Use the macOS build script
./scripts/build/build-macos.sh

# Build universal binary
ARCHITECTURES="x86_64;arm64" ./scripts/build/build-macos.sh
```

#### Docker

```bash
# Build multi-platform Docker image
./scripts/build-docker.sh

# Build for specific platform
./scripts/build-docker.sh single linux/amd64
```

## Deployment

### System Service

#### Linux (systemd)

```bash
# Enable and start the service
sudo systemctl enable simple-snmpd
sudo systemctl start simple-snmpd

# Check status
sudo systemctl status simple-snmpd
```

#### macOS (launchd)

```bash
# Copy the plist file
sudo cp deployment/launchd/com.simpledaemons.simple-snmpd.plist /Library/LaunchDaemons/

# Load and start the service
sudo launchctl load /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
```

#### Windows

```cmd
# Install as Windows service
sc create "Simple SNMP Daemon" binPath="C:\Program Files\simple-snmpd\simple-snmpd.exe" start=auto
sc start "Simple SNMP Daemon"
```

### Docker Deployment

```bash
# Deploy using the deployment script
./scripts/deploy-docker.sh deploy

# Check status
./scripts/deploy-docker.sh status

# View logs
./scripts/deploy-docker.sh logs
```

## Architecture

```
simple-snmpd/
├── src/                    # Source code
│   ├── main.cpp           # Application entry point
│   └── core/              # Core SNMP implementation
│       ├── snmp_server.cpp    # SNMP server
│       ├── snmp_packet.cpp    # Packet handling
│       ├── snmp_config.cpp    # Configuration
│       ├── logger.cpp         # Logging system
│       └── platform.cpp       # Platform abstraction
├── include/               # Header files
│   └── simple_snmpd/     # Public API headers
├── config/               # Configuration files
├── deployment/           # Service configurations
├── docs/                 # Documentation
├── scripts/              # Build and deployment scripts
└── tests/                # Test suite
```

## Development

### Project Structure

The project follows a modular architecture with clear separation of concerns:

- **Core**: SNMP protocol implementation and server logic
- **Platform**: Cross-platform abstraction layer
- **Configuration**: Flexible configuration management
- **Logging**: Comprehensive logging and error handling
- **Deployment**: Multi-platform service configurations

### Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Development Setup

```bash
# Clone and setup development environment
git clone https://github.com/simpledaemons/simple-snmpd.git
cd simple-snmpd

# Install development dependencies
make dev-deps

# Build in debug mode
make dev-build

# Run tests
make test
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the complete development roadmap.

### Current Version (v0.1.0)
- ✅ Core SNMP daemon implementation
- ✅ Cross-platform build system
- ✅ Basic SNMP v2c support
- ✅ Docker containerization
- ✅ Service configurations

### Upcoming Features
- 🔄 Complete SNMP v2c implementation
- 🔄 SNMP v1 compatibility
- 🔄 Basic MIB support
- 🔄 SNMP trap support
- 🔄 Security enhancements

## Documentation

- [Installation Guide](docs/getting-started/installation.md)
- [Quick Start Guide](docs/getting-started/quick-start.md)
- [Configuration Guide](docs/configuration/README.md)
- [Deployment Guide](docs/deployment/README.md)
- [User Guide](docs/user-guide/README.md)
- [Troubleshooting](docs/troubleshooting/README.md)

## Support

- **Issues**: [GitHub Issues](https://github.com/simpledaemons/simple-snmpd/issues)
- **Discussions**: [GitHub Discussions](https://github.com/simpledaemons/simple-snmpd/discussions)
- **Documentation**: [Project Documentation](docs/README.md)

## License

Copyright 2024 SimpleDaemons

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Acknowledgments

- Built with modern C++ and cross-platform best practices
- Inspired by the need for lightweight, secure SNMP implementations
- Community-driven development and feedback

---

**Simple SNMP Daemon** - Making SNMP monitoring simple, secure, and reliable.