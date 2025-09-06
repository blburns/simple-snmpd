#!/usr/bin/env groovy

pipeline {
    agent any
    
    parameters {
        choice(
            name: 'BUILD_TYPE',
            choices: ['Release', 'Debug', 'RelWithDebInfo'],
            description: 'CMake build type'
        )
        choice(
            name: 'DOCKER_REGISTRY',
            choices: ['docker.io', 'ghcr.io', 'quay.io'],
            description: 'Docker registry to push images'
        )
        string(
            name: 'DOCKER_NAMESPACE',
            defaultValue: 'simpledaemons',
            description: 'Docker namespace for images'
        )
        booleanParam(
            name: 'ENABLE_TESTS',
            defaultValue: true,
            description: 'Run unit and integration tests'
        )
        booleanParam(
            name: 'ENABLE_SECURITY_SCAN',
            defaultValue: true,
            description: 'Run security scanning'
        )
        booleanParam(
            name: 'ENABLE_COVERAGE',
            defaultValue: true,
            description: 'Generate code coverage reports'
        )
        booleanParam(
            name: 'BUILD_DOCKER_IMAGES',
            defaultValue: true,
            description: 'Build and push Docker images'
        )
        booleanParam(
            name: 'BUILD_PACKAGES',
            defaultValue: true,
            description: 'Build platform-specific packages'
        )
        choice(
            name: 'TARGET_ARCHITECTURES',
            choices: ['x86_64', 'arm64', 'multi-arch'],
            description: 'Target architectures for Docker builds'
        )
    }
    
    environment {
        PROJECT_NAME = 'simple-snmpd'
        VERSION = sh(
            script: 'git describe --tags --always --dirty',
            returnStdout: true
        ).trim()
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        DOCKER_IMAGE = "${params.DOCKER_NAMESPACE}/${PROJECT_NAME}"
        DOCKER_TAG = "${VERSION}-${BUILD_NUMBER}"
        DOCKER_LATEST_TAG = "latest"
        COVERAGE_THRESHOLD = 80
        SONAR_PROJECT_KEY = 'simple-snmpd'
        SONAR_ORGANIZATION = 'simpledaemons'
    }
    
    options {
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        skipDefaultCheckout()
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout scm
                    sh 'git clean -fd'
                }
            }
        }
        
        stage('Environment Setup') {
            parallel {
                stage('Detect Platform') {
                    steps {
                        script {
                            if (isUnix()) {
                                env.PLATFORM = sh(script: 'uname -s', returnStdout: true).trim().toLowerCase()
                                env.ARCH = sh(script: 'uname -m', returnStdout: true).trim()
                            } else {
                                env.PLATFORM = 'windows'
                                env.ARCH = 'x86_64'
                            }
                            echo "Building on ${env.PLATFORM} (${env.ARCH})"
                        }
                    }
                }
                
                stage('Install Dependencies') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    # Install build dependencies
                                    if command -v apt-get >/dev/null 2>&1; then
                                        sudo apt-get update
                                        sudo apt-get install -y build-essential cmake pkg-config libssl-dev
                                    elif command -v yum >/dev/null 2>&1; then
                                        sudo yum update -y
                                        sudo yum install -y gcc-c++ cmake3 openssl-devel pkgconfig
                                    elif command -v brew >/dev/null 2>&1; then
                                        brew install cmake openssl pkg-config
                                    fi
                                    
                                    # Install development tools
                                    if [ "${ENABLE_TESTS}" = "true" ]; then
                                        if command -v apt-get >/dev/null 2>&1; then
                                            sudo apt-get install -y valgrind gdb
                                        elif command -v yum >/dev/null 2>&1; then
                                            sudo yum install -y valgrind gdb
                                        fi
                                    fi
                                    
                                    # Install security scanning tools
                                    if [ "${ENABLE_SECURITY_SCAN}" = "true" ]; then
                                        if command -v apt-get >/dev/null 2>&1; then
                                            sudo apt-get install -y cppcheck
                                        elif command -v yum >/dev/null 2>&1; then
                                            sudo yum install -y cppcheck
                                        fi
                                    fi
                                '''
                            } else {
                                bat '''
                                    echo "Windows build - dependencies should be pre-installed"
                                    echo "Required: Visual Studio 2019+, CMake, OpenSSL"
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Lint') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    echo "Running code linting..."
                                    find src include -name "*.cpp" -o -name "*.hpp" | xargs cppcheck --enable=all --std=c++17 --suppress=missingIncludeSystem --error-exitcode=1 || true
                                '''
                            }
                        }
                    }
                }
                
                stage('Format Check') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    echo "Checking code formatting..."
                                    if command -v clang-format >/dev/null 2>&1; then
                                        find src include -name "*.cpp" -o -name "*.hpp" | xargs clang-format --dry-run --Werror || true
                                    else
                                        echo "clang-format not available, skipping format check"
                                    fi
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build') {
            parallel {
                stage('Linux Build') {
                    when {
                        expression { isUnix() && env.PLATFORM == 'linux' }
                    }
                    steps {
                        sh '''
                            echo "Building for Linux..."
                            mkdir -p build
                            cd build
                            
                            # Configure with CMake
                            cmake .. \
                                -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
                                -DBUILD_TESTS=${ENABLE_TESTS} \
                                -DENABLE_LOGGING=ON \
                                -DENABLE_IPV6=ON
                            
                            # Build
                            make -j$(nproc)
                            
                            # Build packages if requested
                            if [ "${BUILD_PACKAGES}" = "true" ]; then
                                make package
                            fi
                        '''
                    }
                }
                
                stage('macOS Build') {
                    when {
                        expression { isUnix() && env.PLATFORM == 'darwin' }
                    }
                    steps {
                        sh '''
                            echo "Building for macOS..."
                            mkdir -p build
                            cd build
                            
                            # Configure with CMake
                            cmake .. \
                                -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
                                -DBUILD_TESTS=${ENABLE_TESTS} \
                                -DENABLE_LOGGING=ON \
                                -DENABLE_IPV6=ON
                            
                            # Build
                            make -j$(sysctl -n hw.ncpu)
                            
                            # Build packages if requested
                            if [ "${BUILD_PACKAGES}" = "true" ]; then
                                make package
                            fi
                        '''
                    }
                }
                
                stage('Windows Build') {
                    when {
                        expression { !isUnix() }
                    }
                    steps {
                        bat '''
                            echo "Building for Windows..."
                            mkdir build
                            cd build
                            
                            rem Configure with CMake
                            cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
                            
                            rem Build
                            cmake --build . --config %BUILD_TYPE%
                            
                            rem Build packages if requested
                            if "%BUILD_PACKAGES%"=="true" (
                                cpack -G WIX
                                cpack -G ZIP
                            )
                        '''
                    }
                }
            }
        }
        
        stage('Test') {
            when {
                expression { params.ENABLE_TESTS == true }
            }
            parallel {
                stage('Unit Tests') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    echo "Running unit tests..."
                                    cd build
                                    
                                    # Run tests with verbose output
                                    ctest --output-on-failure --verbose
                                    
                                    # Generate test report
                                    ctest --output-junit test-results.xml
                                '''
                            } else {
                                bat '''
                                    echo "Running unit tests on Windows..."
                                    cd build
                                    ctest --output-on-failure --verbose -C %BUILD_TYPE%
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'build/test-results.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    echo "Running integration tests..."
                                    cd build
                                    
                                    # Test daemon startup
                                    ./bin/simple-snmpd --test-config -c ../config/simple-snmpd.conf
                                    
                                    # Test version output
                                    ./bin/simple-snmpd --version
                                    
                                    # Test help output
                                    ./bin/simple-snmpd --help
                                '''
                            } else {
                                bat '''
                                    echo "Running integration tests on Windows..."
                                    cd build
                                    bin\\%BUILD_TYPE%\\simple-snmpd.exe --test-config -c ..\\config\\simple-snmpd.conf
                                    bin\\%BUILD_TYPE%\\simple-snmpd.exe --version
                                    bin\\%BUILD_TYPE%\\simple-snmpd.exe --help
                                '''
                            }
                        }
                    }
                }
                
                stage('Memory Tests') {
                    when {
                        expression { isUnix() && params.ENABLE_TESTS == true }
                    }
                    steps {
                        sh '''
                            echo "Running memory tests with Valgrind..."
                            cd build
                            
                            # Run tests with Valgrind
                            if command -v valgrind >/dev/null 2>&1; then
                                valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=1 ./bin/test_snmp_packet
                                valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=1 ./bin/test_snmp_mib
                                valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=1 ./bin/test_snmp_security
                            else
                                echo "Valgrind not available, skipping memory tests"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Code Coverage') {
            when {
                expression { params.ENABLE_COVERAGE == true && isUnix() }
            }
            steps {
                sh '''
                    echo "Generating code coverage report..."
                    cd build
                    
                    # Configure with coverage flags
                    cmake .. \
                        -DCMAKE_BUILD_TYPE=Debug \
                        -DCMAKE_CXX_FLAGS="--coverage -fprofile-arcs -ftest-coverage" \
                        -DCMAKE_C_FLAGS="--coverage -fprofile-arcs -ftest-coverage"
                    
                    # Rebuild with coverage
                    make clean
                    make -j$(nproc)
                    
                    # Run tests to generate coverage data
                    ctest --output-on-failure
                    
                    # Generate coverage report
                    if command -v gcovr >/dev/null 2>&1; then
                        gcovr --xml-pretty --exclude-unreachable-branches --exclude-throw-branches --output coverage.xml
                        gcovr --html --exclude-unreachable-branches --exclude-throw-branches --output coverage.html
                    elif command -v lcov >/dev/null 2>&1; then
                        lcov --capture --directory . --output-file coverage.info
                        lcov --remove coverage.info '/usr/*' --output-file coverage.info
                        genhtml coverage.info --output-directory coverage_html
                    fi
                '''
            }
            post {
                always {
                    publishCoverage adapters: [
                        coberturaAdapter('build/coverage.xml')
                    ], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                }
            }
        }
        
        stage('Security Scan') {
            when {
                expression { params.ENABLE_SECURITY_SCAN == true }
            }
            steps {
                script {
                    if (isUnix()) {
                        sh '''
                            echo "Running security scan..."
                            
                            # Cppcheck security scan
                            if command -v cppcheck >/dev/null 2>&1; then
                                cppcheck --enable=all --std=c++17 --suppress=missingIncludeSystem \
                                    --xml --xml-version=2 src include 2> security-report.xml || true
                            fi
                            
                            # Bandit security scan (if available)
                            if command -v bandit >/dev/null 2>&1; then
                                find . -name "*.py" | xargs bandit -f json -o bandit-report.json || true
                            fi
                        '''
                    }
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'security-report.xml',
                        reportName: 'Security Report'
                    ])
                }
            }
        }
        
        stage('Docker Build') {
            when {
                expression { params.BUILD_DOCKER_IMAGES == true }
            }
            parallel {
                stage('Build Docker Images') {
                    steps {
                        script {
                            def dockerfile = 'Dockerfile'
                            def platforms = []
                            
                            switch(params.TARGET_ARCHITECTURES) {
                                case 'x86_64':
                                    platforms = ['linux/amd64']
                                    break
                                case 'arm64':
                                    platforms = ['linux/arm64']
                                    break
                                case 'multi-arch':
                                    platforms = ['linux/amd64', 'linux/arm64', 'linux/arm/v7']
                                    break
                            }
                            
                            def buildArgs = [
                                "--platform=${platforms.join(',')}",
                                "--tag=${env.DOCKER_IMAGE}:${env.DOCKER_TAG}",
                                "--tag=${env.DOCKER_IMAGE}:${env.DOCKER_LATEST_TAG}",
                                "--build-arg=VERSION=${env.VERSION}",
                                "--build-arg=BUILD_NUMBER=${env.BUILD_NUMBER}",
                                "--file=${dockerfile}",
                                "."
                            ]
                            
                            if (platforms.size() > 1) {
                                // Multi-architecture build
                                sh """
                                    echo "Building multi-architecture Docker images..."
                                    docker buildx create --use --name multiarch-builder || true
                                    docker buildx build ${buildArgs.join(' ')} --push
                                """
                            } else {
                                // Single architecture build
                                sh """
                                    echo "Building Docker image for ${platforms[0]}..."
                                    docker build ${buildArgs.join(' ')} .
                                    
                                    # Tag for local testing
                                    docker tag ${env.DOCKER_IMAGE}:${env.DOCKER_TAG} ${env.DOCKER_IMAGE}:local
                                """
                            }
                        }
                    }
                }
                
                stage('Test Docker Images') {
                    steps {
                        sh '''
                            echo "Testing Docker images..."
                            
                            # Test basic functionality
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} --version
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} --help
                            
                            # Test configuration validation
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} --test-config
                            
                            # Test daemon startup (briefly)
                            timeout 10s docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                        '''
                    }
                }
            }
        }
        
        stage('Package') {
            when {
                expression { params.BUILD_PACKAGES == true }
            }
            steps {
                script {
                    if (isUnix()) {
                        sh '''
                            echo "Creating packages..."
                            cd build
                            
                            # Create source package
                            make package-source
                            
                            # Create platform-specific packages
                            if [ "${PLATFORM}" = "linux" ]; then
                                make package
                            elif [ "${PLATFORM}" = "darwin" ]; then
                                make package
                            fi
                            
                            # List created packages
                            find . -name "*.tar.gz" -o -name "*.deb" -o -name "*.rpm" -o -name "*.dmg" -o -name "*.pkg" | head -10
                        '''
                    } else {
                        bat '''
                            echo "Creating Windows packages..."
                            cd build
                            
                            rem Create Windows packages
                            cpack -G WIX
                            cpack -G ZIP
                            
                            rem List created packages
                            dir *.msi *.zip
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Archive build artifacts
            archiveArtifacts artifacts: 'build/**/*.deb,build/**/*.rpm,build/**/*.dmg,build/**/*.pkg,build/**/*.msi,build/**/*.zip,build/**/*.tar.gz', allowEmptyArchive: true
            
            // Clean up workspace
            cleanWs()
        }
        
        success {
            script {
                if (params.BUILD_DOCKER_IMAGES) {
                    echo "Build successful! Docker images available:"
                    echo "- ${env.DOCKER_IMAGE}:${env.DOCKER_TAG}"
                    echo "- ${env.DOCKER_IMAGE}:${env.DOCKER_LATEST_TAG}"
                }
            }
        }
        
        failure {
            echo "Build failed! Check the logs for details."
        }
        
        unstable {
            echo "Build unstable! Some tests may have failed."
        }
    }
}
