# CI/CD Pipeline Documentation

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for the Simple SNMP Daemon project.

## Overview

The CI/CD pipeline is built using Jenkins and provides comprehensive automation for:

- **Code Quality**: Linting, formatting checks, and static analysis
- **Building**: Multi-platform builds (Linux, macOS, Windows)
- **Testing**: Unit tests, integration tests, and memory tests
- **Security**: Security scanning and vulnerability assessment
- **Packaging**: Platform-specific packages (DEB, RPM, DMG, MSI)
- **Docker**: Multi-architecture Docker image builds
- **Deployment**: Automated deployment to various environments

## Pipeline Stages

### 1. Checkout
- Checks out the source code from the repository
- Cleans the workspace for a fresh build

### 2. Environment Setup
- Detects the build platform (Linux, macOS, Windows)
- Installs required dependencies
- Sets up development tools

### 3. Code Quality
- **Lint**: Runs Cppcheck for static analysis
- **Format Check**: Validates code formatting with clang-format

### 4. Build
- **Linux Build**: CMake-based build for Linux systems
- **macOS Build**: CMake-based build for macOS systems
- **Windows Build**: Visual Studio-based build for Windows

### 5. Test
- **Unit Tests**: Runs the complete test suite
- **Integration Tests**: Tests daemon functionality
- **Memory Tests**: Valgrind-based memory leak detection

### 6. Code Coverage
- Generates code coverage reports
- Publishes coverage metrics
- Enforces coverage thresholds

### 7. Security Scan
- Cppcheck security analysis
- Bandit security scanning (if Python files present)
- Publishes security reports

### 8. Docker Build
- **Multi-architecture builds**: x86_64, ARM64, ARMv7
- **Image testing**: Validates Docker images
- **Registry push**: Publishes to configured registry

### 9. Package
- Creates platform-specific packages
- Archives build artifacts
- Prepares for distribution

## Configuration

### Jenkinsfile Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `BUILD_TYPE` | CMake build type | Release | Release, Debug, RelWithDebInfo |
| `DOCKER_REGISTRY` | Docker registry | docker.io | docker.io, ghcr.io, quay.io |
| `DOCKER_NAMESPACE` | Docker namespace | simpledaemons | Any valid namespace |
| `ENABLE_TESTS` | Run tests | true | true, false |
| `ENABLE_SECURITY_SCAN` | Security scanning | true | true, false |
| `ENABLE_COVERAGE` | Code coverage | true | true, false |
| `BUILD_DOCKER_IMAGES` | Build Docker images | true | true, false |
| `BUILD_PACKAGES` | Build packages | true | true, false |
| `TARGET_ARCHITECTURES` | Docker architectures | x86_64 | x86_64, arm64, multi-arch |

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_NAME` | Project name | simple-snmpd |
| `VERSION` | Git tag/commit | v0.1.0 |
| `BUILD_NUMBER` | Jenkins build number | 123 |
| `DOCKER_IMAGE` | Docker image name | simpledaemons/simple-snmpd |
| `DOCKER_TAG` | Docker tag | v0.1.0-123 |
| `COVERAGE_THRESHOLD` | Minimum coverage % | 80 |

## Setup Instructions

### 1. Jenkins Installation

#### Using Docker Compose (Recommended)
```bash
# Start Jenkins with Docker support
docker-compose -f docker-compose.jenkins.yml up -d

# Access Jenkins at http://localhost:8080
# Initial admin password: Check logs with:
docker logs simple-snmpd-jenkins
```

#### Manual Installation
1. Install Jenkins on your system
2. Install required plugins:
   - Pipeline
   - Docker Pipeline
   - Git
   - Cobertura
   - HTML Publisher
   - Build Timeout
   - AnsiColor

### 2. Configure Jenkins

1. **Create Credentials**:
   - GitHub credentials for repository access
   - Docker registry credentials for image pushing

2. **Create Pipeline Job**:
   - Create new "Pipeline" job
   - Set SCM to your repository
   - Use the provided `Jenkinsfile`

3. **Configure Build Triggers**:
   - SCM polling (every 5 minutes)
   - Webhook triggers (recommended)

### 3. Required Tools

#### Build Dependencies
- **Linux**: build-essential, cmake, pkg-config, libssl-dev
- **macOS**: Xcode Command Line Tools, CMake, OpenSSL
- **Windows**: Visual Studio 2019+, CMake, OpenSSL

#### Development Tools
- **Testing**: Valgrind, GDB
- **Security**: Cppcheck, Bandit
- **Coverage**: gcovr, lcov
- **Docker**: Docker with buildx support

### 4. Docker Registry Setup

#### Docker Hub
```bash
# Login to Docker Hub
docker login

# Configure Jenkins credentials
# Username: your-dockerhub-username
# Password: your-dockerhub-token
```

#### GitHub Container Registry
```bash
# Create GitHub Personal Access Token
# Scopes: write:packages, read:packages

# Configure Jenkins credentials
# Username: your-github-username
# Password: your-github-token
```

## Usage

### Running the Pipeline

1. **Manual Trigger**:
   - Go to Jenkins dashboard
   - Click "Build with Parameters"
   - Configure parameters as needed
   - Click "Build"

2. **Automatic Trigger**:
   - Push to main/develop branch
   - Pipeline runs automatically
   - Uses default parameters

### Monitoring Builds

1. **Build Status**:
   - Green: All stages passed
   - Yellow: Some non-critical failures
   - Red: Critical failures

2. **Artifacts**:
   - Packages: `build/**/*.deb`, `build/**/*.rpm`, etc.
   - Docker images: Available in configured registry
   - Reports: Coverage, security, test results

3. **Logs**:
   - Console output for each stage
   - Detailed error messages
   - Performance metrics

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check dependency installation
   - Verify CMake configuration
   - Review compiler errors

2. **Test Failures**:
   - Check test environment
   - Verify test data
   - Review test logs

3. **Docker Build Failures**:
   - Check Docker daemon status
   - Verify registry credentials
   - Review Dockerfile syntax

4. **Security Scan Failures**:
   - Review security report
   - Fix identified vulnerabilities
   - Update security policies

### Debug Mode

Enable debug mode by setting:
```groovy
// In Jenkinsfile
options {
    timeout(time: 120, unit: 'MINUTES')  // Increase timeout
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '50'))  // Keep more builds
}
```

## Best Practices

1. **Regular Maintenance**:
   - Update dependencies regularly
   - Review and update security policies
   - Clean up old artifacts

2. **Monitoring**:
   - Set up build notifications
   - Monitor build performance
   - Track coverage trends

3. **Security**:
   - Use secure credentials
   - Regular security scans
   - Keep tools updated

4. **Documentation**:
   - Keep pipeline documentation updated
   - Document custom configurations
   - Maintain troubleshooting guides

## Support

For issues with the CI/CD pipeline:

1. Check the Jenkins console output
2. Review the troubleshooting section
3. Check project documentation
4. Create an issue in the repository

## License

This CI/CD pipeline is part of the Simple SNMP Daemon project and is licensed under the Apache License 2.0.
