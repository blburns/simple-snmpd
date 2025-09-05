# Docker Deployment Guide

This guide covers deploying Simple SNMP Daemon using Docker containers, including single-container deployments, Docker Compose setups, and production container orchestration.

## Docker Overview

Simple SNMP Daemon is designed to work seamlessly in containerized environments. The official Docker images are available on Docker Hub and provide:

- **Multi-architecture support** (amd64, arm64, arm/v7)
- **Minimal base images** for security and performance
- **Configurable via environment variables**
- **Health checks** and proper signal handling
- **Non-root user execution** for security

## Quick Start

### Pull and Run
```bash
# Pull the latest image
docker pull simpledaemons/simple-snmpd:latest

# Run with default configuration
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  simpledaemons/simple-snmpd:latest
```

### Test the Deployment
```bash
# Test SNMP connectivity
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Check container status
docker ps
docker logs simple-snmpd
```

## Docker Images

### Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable release |
| `1.0.0` | Specific version |
| `dev` | Development build |
| `alpine` | Alpine Linux based image |
| `ubuntu` | Ubuntu based image |

### Image Variants

#### Alpine Linux (Recommended)
```bash
# Lightweight Alpine-based image
docker pull simpledaemons/simple-snmpd:alpine
```

#### Ubuntu
```bash
# Ubuntu-based image with more tools
docker pull simpledaemons/simple-snmpd:ubuntu
```

## Basic Docker Deployment

### Single Container

#### Basic Run Command
```bash
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -p 162:162/udp \
  --restart unless-stopped \
  simpledaemons/simple-snmpd:latest
```

#### With Custom Configuration
```bash
# Create configuration directory
mkdir -p ./config

# Create custom configuration
cat > ./config/simple-snmpd.conf << EOF
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = docker_community
log_level = info
system_name = Docker Container
system_description = Simple SNMP Daemon in Docker
EOF

# Run with custom configuration
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v $(pwd)/config:/etc/simple-snmpd:ro \
  --restart unless-stopped \
  simpledaemons/simple-snmpd:latest
```

#### With Environment Variables
```bash
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -e SNMP_COMMUNITY=docker_community \
  -e LOG_LEVEL=info \
  -e SYSTEM_NAME="Docker Container" \
  --restart unless-stopped \
  simpledaemons/simple-snmpd:latest
```

### Docker Compose

#### Basic Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    container_name: simple-snmpd
    ports:
      - "161:161/udp"
      - "162:162/udp"
    volumes:
      - ./config:/etc/simple-snmpd:ro
      - ./logs:/var/log/simple-snmpd
    environment:
      - SNMP_COMMUNITY=docker_community
      - LOG_LEVEL=info
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "snmpget", "-v2c", "-c", "docker_community", "localhost", "1.3.6.1.2.1.1.1.0"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### Advanced Docker Compose
```yaml
# docker-compose.advanced.yml
version: '3.8'

services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    container_name: simple-snmpd
    hostname: snmp-server
    ports:
      - "161:161/udp"
      - "162:162/udp"
    volumes:
      - ./config:/etc/simple-snmpd:ro
      - ./logs:/var/log/simple-snmpd
      - ./data:/var/lib/simple-snmpd
      - ./mibs:/usr/share/snmp/mibs:ro
    environment:
      - SNMP_COMMUNITY=secure_community
      - SNMP_READ_COMMUNITY=readonly_community
      - SNMP_WRITE_COMMUNITY=write_community
      - LOG_LEVEL=info
      - SYSTEM_NAME=Docker SNMP Server
      - SYSTEM_DESCRIPTION=Simple SNMP Daemon in Docker
      - SYSTEM_CONTACT=admin@example.com
      - SYSTEM_LOCATION=Docker Environment
      - ENABLE_STATISTICS=true
      - WORKER_THREADS=4
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "snmpget", "-v2c", "-c", "secure_community", "localhost", "1.3.6.1.2.1.1.1.0"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - snmp-network
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'

networks:
  snmp-network:
    driver: bridge
```

## Environment Variables

### Available Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SNMP_COMMUNITY` | Default community string | `public` |
| `SNMP_READ_COMMUNITY` | Read-only community string | `public` |
| `SNMP_WRITE_COMMUNITY` | Read-write community string | `private` |
| `SNMP_VERSION` | SNMP version (1, 2c, 3) | `2c` |
| `LISTEN_ADDRESS` | Listen address | `0.0.0.0` |
| `LISTEN_PORT` | Listen port | `161` |
| `LOG_LEVEL` | Log level (debug, info, warn, error) | `info` |
| `SYSTEM_NAME` | System name | `Simple SNMP Daemon` |
| `SYSTEM_DESCRIPTION` | System description | `Simple SNMP Daemon` |
| `SYSTEM_CONTACT` | System contact | `admin@example.com` |
| `SYSTEM_LOCATION` | System location | `Unknown` |
| `ENABLE_STATISTICS` | Enable statistics | `true` |
| `WORKER_THREADS` | Number of worker threads | `4` |

### Environment Variable Configuration
```bash
# Using environment variables
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -e SNMP_COMMUNITY=production_community \
  -e SNMP_READ_COMMUNITY=readonly_community \
  -e SNMP_WRITE_COMMUNITY=write_community \
  -e LOG_LEVEL=info \
  -e SYSTEM_NAME="Production SNMP Server" \
  -e SYSTEM_DESCRIPTION="Simple SNMP Daemon - Production" \
  -e SYSTEM_CONTACT="admin@company.com" \
  -e SYSTEM_LOCATION="Production Data Center" \
  -e ENABLE_STATISTICS=true \
  -e WORKER_THREADS=8 \
  --restart unless-stopped \
  simpledaemons/simple-snmpd:latest
```

## Volume Mounts

### Configuration Volume
```bash
# Mount configuration directory
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v /host/config:/etc/simple-snmpd:ro \
  simpledaemons/simple-snmpd:latest
```

### Log Volume
```bash
# Mount log directory
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v /host/logs:/var/log/simple-snmpd \
  simpledaemons/simple-snmpd:latest
```

### Data Volume
```bash
# Mount data directory
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v /host/data:/var/lib/simple-snmpd \
  simpledaemons/simple-snmpd:latest
```

### MIB Volume
```bash
# Mount MIB directory
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v /host/mibs:/usr/share/snmp/mibs:ro \
  simpledaemons/simple-snmpd:latest
```

### Complete Volume Setup
```bash
# Complete volume setup
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v /host/config:/etc/simple-snmpd:ro \
  -v /host/logs:/var/log/simple-snmpd \
  -v /host/data:/var/lib/simple-snmpd \
  -v /host/mibs:/usr/share/snmp/mibs:ro \
  --restart unless-stopped \
  simpledaemons/simple-snmpd:latest
```

## Networking

### Host Networking
```bash
# Use host networking
docker run -d \
  --name simple-snmpd \
  --network host \
  simpledaemons/simple-snmpd:latest
```

### Custom Network
```bash
# Create custom network
docker network create snmp-network

# Run with custom network
docker run -d \
  --name simple-snmpd \
  --network snmp-network \
  -p 161:161/udp \
  simpledaemons/simple-snmpd:latest
```

### Docker Compose Network
```yaml
# docker-compose.yml
version: '3.8'

services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    ports:
      - "161:161/udp"
    networks:
      - snmp-network

  monitoring:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - snmp-network

networks:
  snmp-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Health Checks

### Basic Health Check
```bash
# Run with health check
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  --health-cmd="snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --health-start-period=40s \
  simpledaemons/simple-snmpd:latest
```

### Advanced Health Check
```bash
# Custom health check script
cat > healthcheck.sh << 'EOF'
#!/bin/bash
# Test SNMP connectivity
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0 > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "SNMP service is healthy"
  exit 0
else
  echo "SNMP service is unhealthy"
  exit 1
fi
EOF

chmod +x healthcheck.sh

# Run with custom health check
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v $(pwd)/healthcheck.sh:/usr/local/bin/healthcheck.sh:ro \
  --health-cmd="/usr/local/bin/healthcheck.sh" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  simpledaemons/simple-snmpd:latest
```

## Security

### Non-Root User
```bash
# Run as non-root user
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  --user 1000:1000 \
  simpledaemons/simple-snmpd:latest
```

### Read-Only Root Filesystem
```bash
# Run with read-only root filesystem
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/log/simple-snmpd \
  --tmpfs /var/lib/simple-snmpd \
  simpledaemons/simple-snmpd:latest
```

### Security Options
```bash
# Run with security options
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  simpledaemons/simple-snmpd:latest
```

## Production Deployment

### Production Docker Compose
```yaml
# docker-compose.production.yml
version: '3.8'

services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    container_name: simple-snmpd
    hostname: snmp-server
    ports:
      - "161:161/udp"
      - "162:162/udp"
    volumes:
      - ./config:/etc/simple-snmpd:ro
      - ./logs:/var/log/simple-snmpd
      - ./data:/var/lib/simple-snmpd
    environment:
      - SNMP_COMMUNITY=production_community_2024
      - SNMP_READ_COMMUNITY=readonly_production
      - SNMP_WRITE_COMMUNITY=write_production
      - LOG_LEVEL=info
      - SYSTEM_NAME=Production SNMP Server
      - SYSTEM_DESCRIPTION=Simple SNMP Daemon - Production
      - SYSTEM_CONTACT=admin@company.com
      - SYSTEM_LOCATION=Production Data Center
      - ENABLE_STATISTICS=true
      - WORKER_THREADS=8
      - ENABLE_RATE_LIMITING=true
      - RATE_LIMIT_REQUESTS=1000
      - RATE_LIMIT_WINDOW=60
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "snmpget", "-v2c", "-c", "production_community_2024", "localhost", "1.3.6.1.2.1.1.1.0"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - snmp-network
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp
      - /var/run

  # Monitoring sidecar
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - snmp-network
    restart: unless-stopped

networks:
  snmp-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Production Deployment Script
```bash
#!/bin/bash
# deploy-production.sh

set -e

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
BACKUP_DIR="/backup/simple-snmpd"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
echo "Creating backup..."
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" ./config ./logs

# Pull latest image
echo "Pulling latest image..."
docker-compose -f "$COMPOSE_FILE" pull

# Deploy
echo "Deploying..."
docker-compose -f "$COMPOSE_FILE" up -d

# Wait for health check
echo "Waiting for health check..."
timeout 60 bash -c 'until docker-compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; do sleep 5; done'

# Verify deployment
echo "Verifying deployment..."
snmpget -v2c -c production_community_2024 localhost 1.3.6.1.2.1.1.1.0

echo "Deployment completed successfully!"
```

## Monitoring and Logging

### Log Aggregation
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    container_name: simple-snmpd
    ports:
      - "161:161/udp"
    volumes:
      - ./config:/etc/simple-snmpd:ro
      - ./logs:/var/log/simple-snmpd
    environment:
      - SNMP_COMMUNITY=monitoring_community
      - LOG_LEVEL=info
    networks:
      - monitoring-network

  fluentd:
    image: fluent/fluentd:latest
    container_name: fluentd
    volumes:
      - ./fluentd.conf:/fluentd/etc/fluent.conf:ro
      - ./logs:/var/log/simple-snmpd:ro
    ports:
      - "24224:24224"
    networks:
      - monitoring-network

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:latest
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"
    networks:
      - monitoring-network

  kibana:
    image: docker.elastic.co/kibana/kibana:latest
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    networks:
      - monitoring-network

networks:
  monitoring-network:
    driver: bridge
```

### Prometheus Monitoring
```yaml
# docker-compose.prometheus.yml
version: '3.8'

services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    container_name: simple-snmpd
    ports:
      - "161:161/udp"
      - "8080:8080"  # Metrics endpoint
    environment:
      - SNMP_COMMUNITY=prometheus_community
      - ENABLE_METRICS=true
      - METRICS_PORT=8080
      - METRICS_FORMAT=prometheus
    networks:
      - monitoring-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - monitoring-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-storage:/var/lib/grafana
    networks:
      - monitoring-network

networks:
  monitoring-network:
    driver: bridge

volumes:
  grafana-storage:
```

## Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check container logs
docker logs simple-snmpd

# Check container status
docker ps -a

# Check configuration
docker exec simple-snmpd cat /etc/simple-snmpd/simple-snmpd.conf
```

#### Port Binding Issues
```bash
# Check port usage
netstat -tulpn | grep :161
ss -tulpn | grep :161

# Check Docker port mapping
docker port simple-snmpd
```

#### Permission Issues
```bash
# Check volume permissions
ls -la ./config
ls -la ./logs

# Fix permissions
sudo chown -R 1000:1000 ./config ./logs
```

#### Network Connectivity Issues
```bash
# Test from inside container
docker exec simple-snmpd snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Test from host
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0

# Check network connectivity
docker exec simple-snmpd ping -c 3 8.8.8.8
```

### Debug Mode
```bash
# Run in debug mode
docker run -it --rm \
  --name simple-snmpd-debug \
  -p 161:161/udp \
  -e LOG_LEVEL=debug \
  -e ENABLE_CONSOLE_LOGGING=true \
  simpledaemons/simple-snmpd:latest
```

### Health Check Debugging
```bash
# Check health status
docker inspect simple-snmpd | jq '.[0].State.Health'

# Run health check manually
docker exec simple-snmpd snmpget -v2c -c public localhost 1.3.6.1.2.1.1.1.0
```

## Best Practices

### Security Best Practices
1. **Use non-root user**: Run containers as non-root user
2. **Read-only filesystem**: Use read-only root filesystem when possible
3. **Drop capabilities**: Drop unnecessary capabilities
4. **Network isolation**: Use custom networks
5. **Secrets management**: Use Docker secrets or external secret management

### Performance Best Practices
1. **Resource limits**: Set appropriate CPU and memory limits
2. **Health checks**: Implement proper health checks
3. **Logging**: Use structured logging and log rotation
4. **Monitoring**: Implement comprehensive monitoring
5. **Backup**: Regular configuration and data backups

### Operational Best Practices
1. **Version pinning**: Pin specific image versions in production
2. **Rolling updates**: Use rolling update strategies
3. **Configuration management**: Use external configuration management
4. **Documentation**: Document all custom configurations
5. **Testing**: Test deployments in staging environments first

## Next Steps

- **Production Deployment**: See [Production Deployment Guide](production.md)
- **Kubernetes**: Deploy on Kubernetes clusters
- **Monitoring**: Set up comprehensive monitoring and alerting
- **Security**: Implement security best practices
- **Backup**: Set up automated backup and recovery procedures
