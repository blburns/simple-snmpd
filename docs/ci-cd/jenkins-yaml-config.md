# Jenkins YAML Configuration

This document describes the YAML configuration files for Jenkins CI/CD pipeline setup.

## Configuration Files

### 1. `jenkins-config.yaml`
**Full Jenkins Configuration as Code (JCasC)**

This is a comprehensive YAML configuration that includes:
- Complete Jenkins instance configuration
- Job definitions
- Tool configurations
- Security settings
- Plugin configurations

**Usage**: Use with Jenkins Configuration as Code (JCasC) plugin for complete Jenkins setup.

### 2. `jenkins-job-config.yaml`
**Focused Job Configuration**

This is a simplified YAML configuration focused on just the pipeline job:
- Job-specific configuration
- SCM settings
- Build parameters
- Publishers and wrappers

**Usage**: Use for creating individual pipeline jobs or as a reference for job configuration.

## Setup Instructions

### Option 1: Using Jenkins Configuration as Code (JCasC)

1. **Install JCasC Plugin**:
   ```bash
   # In Jenkins plugin manager
   Install "Configuration as Code" plugin
   ```

2. **Configure JCasC**:
   ```yaml
   # In Jenkins system configuration
   jenkins:
     configuration-as-code:
       enabled: true
       configScripts:
         - "jenkins-config.yaml"
   ```

3. **Restart Jenkins**:
   ```bash
   # Restart Jenkins to apply configuration
   sudo systemctl restart jenkins
   ```

### Option 2: Manual Job Creation

1. **Create New Pipeline Job**:
   - Go to Jenkins dashboard
   - Click "New Item"
   - Select "Pipeline"
   - Name: "simple-snmpd-pipeline"

2. **Configure Job**:
   - Copy settings from `jenkins-job-config.yaml`
   - Set SCM to your repository
   - Use the provided `Jenkinsfile`

3. **Set Parameters**:
   - Configure build parameters as defined in YAML
   - Set up credentials for GitHub and Docker registry

## YAML Configuration Details

### Job Configuration

```yaml
job:
  name: "simple-snmpd-pipeline"
  type: "pipeline"
  description: "Simple SNMP Daemon CI/CD Pipeline"
```

### SCM Configuration

```yaml
scm:
  git:
    remote: "https://github.com/SimpleDaemons/simple-snmpd.git"
    credentialsId: "github-credentials"
    branches:
      - "*/main"
      - "*/develop"
    extensions:
      - cleanBeforeCheckout
      - cleanCheckout
      - wipeWorkspace
```

### Build Parameters

```yaml
parameters:
  - choice:
      name: "BUILD_TYPE"
      choices: ["Release", "Debug", "RelWithDebInfo"]
      description: "CMake build type"
  - boolean:
      name: "ENABLE_TESTS"
      defaultValue: true
      description: "Run unit and integration tests"
  # ... more parameters
```

### Publishers

```yaml
publishers:
  - artifactArchiver:
      artifacts: "build/**/*.deb,build/**/*.rpm,build/**/*.dmg,build/**/*.pkg,build/**/*.msi,build/**/*.zip,build/**/*.tar.gz"
      allowEmptyArchive: true
  - testResults:
      testResultsPattern: "build/test-results.xml"
  - cobertura:
      reportFilePattern: "build/coverage.xml"
```

## Advantages of YAML Configuration

### 1. **Readability**
- Human-readable format
- Easy to understand and modify
- Better version control integration

### 2. **Maintainability**
- Version controlled configuration
- Easy to track changes
- Consistent across environments

### 3. **Portability**
- Can be used across different Jenkins instances
- Easy to backup and restore
- Environment-specific configurations

### 4. **Automation**
- Can be generated programmatically
- Integration with Infrastructure as Code
- Automated deployment of Jenkins configuration

## Migration from XML

### Converting XML to YAML

1. **Use Jenkins CLI**:
   ```bash
   # Export job configuration
   java -jar jenkins-cli.jar -s http://localhost:8080 get-job simple-snmpd-pipeline > job.xml
   
   # Convert using online tools or scripts
   ```

2. **Manual Conversion**:
   - Compare XML structure with YAML equivalent
   - Use Jenkins YAML documentation as reference
   - Test configuration in development environment

### Key Differences

| XML | YAML |
|-----|------|
| `<project>` | `job:` |
| `<properties>` | `properties:` |
| `<scm>` | `scm:` |
| `<triggers>` | `triggers:` |
| `<publishers>` | `publishers:` |

## Best Practices

### 1. **Version Control**
- Store YAML files in version control
- Use meaningful commit messages
- Tag releases of configuration

### 2. **Environment Management**
- Use separate YAML files for different environments
- Use environment variables for sensitive data
- Validate configuration before deployment

### 3. **Documentation**
- Document all configuration changes
- Keep README files updated
- Include examples and usage instructions

### 4. **Testing**
- Test configuration in development environment
- Use Jenkins test configuration feature
- Validate YAML syntax before deployment

## Troubleshooting

### Common Issues

1. **YAML Syntax Errors**:
   ```bash
   # Validate YAML syntax
   python -c "import yaml; yaml.safe_load(open('jenkins-config.yaml'))"
   ```

2. **Plugin Dependencies**:
   - Ensure all required plugins are installed
   - Check plugin compatibility
   - Update plugins if needed

3. **Permission Issues**:
   - Check Jenkins user permissions
   - Verify file access rights
   - Review security settings

### Debug Mode

Enable debug mode in Jenkins:
```yaml
jenkins:
  systemMessage: "Debug mode enabled"
  numExecutors: 1
  mode: NORMAL
  scmCheckoutRetryCount: 1
```

## Support

For issues with YAML configuration:

1. Check Jenkins logs for errors
2. Validate YAML syntax
3. Review plugin documentation
4. Create an issue in the repository

## License

This configuration is part of the Simple SNMP Daemon project and is licensed under the Apache License 2.0.
