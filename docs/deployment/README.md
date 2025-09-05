# Deployment Guide

This guide covers various deployment strategies for Simple SNMP Daemon in different environments, from development to production.

## Deployment Overview

Simple SNMP Daemon can be deployed in multiple ways:
- **Native Installation**: Direct installation on the host system
- **Container Deployment**: Using Docker containers
- **Service Management**: As a system service (systemd, launchd, Windows Service)
- **Cloud Deployment**: On cloud platforms (AWS, Azure, GCP)
- **Kubernetes**: Container orchestration deployment

## Deployment Strategies

### 1. Native Installation

#### Linux (systemd)
```bash
# Install the package
sudo dpkg -i simple-snmpd_1.0.0_amd64.deb  # Debian/Ubuntu
sudo rpm -i simple-snmpd-1.0.0.x86_64.rpm  # RHEL/CentOS

# Enable and start service
sudo systemctl enable simple-snmpd
sudo systemctl start simple-snmpd
```

#### macOS (launchd)
```bash
# Install the package
sudo installer -pkg simple-snmpd-1.0.0.pkg -target /

# Load and start service
sudo launchctl load /Library/LaunchDaemons/com.simpledaemons.simple-snmpd.plist
sudo launchctl start com.simpledaemons.simple-snmpd
```

#### Windows
```cmd
# Install using the installer
simple-snmpd-setup.exe

# Or install service manually
install-service.bat install
install-service.bat start
```

### 2. Container Deployment

#### Docker
```bash
# Pull the image
docker pull simpledaemons/simple-snmpd:latest

# Run container
docker run -d \
  --name simple-snmpd \
  -p 161:161/udp \
  -v /etc/simple-snmpd:/etc/simple-snmpd \
  -v /var/log/simple-snmpd:/var/log/simple-snmpd \
  simpledaemons/simple-snmpd:latest
```

#### Docker Compose
```yaml
version: '3.8'
services:
  simple-snmpd:
    image: simpledaemons/simple-snmpd:latest
    container_name: simple-snmpd
    ports:
      - "161:161/udp"
    volumes:
      - ./config:/etc/simple-snmpd
      - ./logs:/var/log/simple-snmpd
    restart: unless-stopped
    environment:
      - SNMP_COMMUNITY=public
      - LOG_LEVEL=info
```

### 3. Kubernetes Deployment

#### Basic Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-snmpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: simple-snmpd
  template:
    metadata:
      labels:
        app: simple-snmpd
    spec:
      containers:
      - name: simple-snmpd
        image: simpledaemons/simple-snmpd:latest
        ports:
        - containerPort: 161
          protocol: UDP
        env:
        - name: SNMP_COMMUNITY
          value: "public"
        volumeMounts:
        - name: config
          mountPath: /etc/simple-snmpd
        - name: logs
          mountPath: /var/log/simple-snmpd
      volumes:
      - name: config
        configMap:
          name: simple-snmpd-config
      - name: logs
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: simple-snmpd-service
spec:
  selector:
    app: simple-snmpd
  ports:
  - port: 161
    targetPort: 161
    protocol: UDP
  type: ClusterIP
```

## Environment-Specific Deployments

### Development Environment

#### Local Development
```bash
# Clone repository
git clone https://github.com/simpledaemons/simple-snmpd.git
cd simple-snmpd

# Build from source
make build

# Run in development mode
./build/simple-snmpd --config config/simple-snmpd.conf --debug
```

#### Docker Development
```bash
# Build development image
docker build -t simple-snmpd:dev .

# Run with development configuration
docker run -it --rm \
  -p 161:161/udp \
  -v $(pwd)/config:/etc/simple-snmpd \
  simple-snmpd:dev
```

### Staging Environment

#### Staging Configuration
```ini
# staging.conf
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = staging_community
log_level = info
enable_statistics = true
monitoring_interval = 60
```

#### Staging Deployment
```bash
# Deploy to staging
ansible-playbook -i staging deploy.yml

# Or using Docker
docker-compose -f docker-compose.staging.yml up -d
```

### Production Environment

#### Production Configuration
```ini
# production.conf
listen_address = 0.0.0.0
listen_port = 161
snmp_version = 2c
community_string = secure_production_community
read_community = readonly_production
write_community = write_production

# Security
enable_authentication = true
allowed_networks = 192.168.1.0/24,10.0.0.0/8
enable_rate_limiting = true

# Logging
log_level = info
log_rotation = true
max_log_size = 100MB
max_log_files = 10

# Performance
worker_threads = 8
enable_statistics = true
enable_response_cache = true
```

#### Production Deployment
```bash
# Deploy to production
ansible-playbook -i production deploy.yml

# Verify deployment
systemctl status simple-snmpd
snmpget -v2c -c secure_production_community localhost 1.3.6.1.2.1.1.1.0
```

## High Availability Deployment

### Load Balancer Configuration

#### HAProxy Configuration
```
# haproxy.cfg
global
    daemon
    maxconn 4096

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend snmp_frontend
    bind *:161
    default_backend snmp_backend

backend snmp_backend
    balance roundrobin
    server snmp1 192.168.1.10:161 check
    server snmp2 192.168.1.11:161 check
    server snmp3 192.168.1.12:161 check
```

#### Nginx Configuration
```nginx
# nginx.conf
stream {
    upstream snmp_backend {
        server 192.168.1.10:161;
        server 192.168.1.11:161;
        server 192.168.1.12:161;
    }

    server {
        listen 161 udp;
        proxy_pass snmp_backend;
        proxy_timeout 1s;
        proxy_responses 1;
    }
}
```

### Clustering Configuration

#### Multi-Instance Deployment
```bash
# Instance 1
simple-snmpd --config /etc/simple-snmpd/instance1.conf --pid-file /var/run/simple-snmpd1.pid

# Instance 2
simple-snmpd --config /etc/simple-snmpd/instance2.conf --pid-file /var/run/simple-snmpd2.pid

# Instance 3
simple-snmpd --config /etc/simple-snmpd/instance3.conf --pid-file /var/run/simple-snmpd3.pid
```

## Cloud Deployment

### AWS Deployment

#### EC2 Instance
```bash
# Launch EC2 instance
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678 \
  --user-data file://user-data.sh
```

#### Security Group Configuration
```json
{
  "SecurityGroupRules": [
    {
      "IpProtocol": "udp",
      "FromPort": 161,
      "ToPort": 161,
      "CidrIpv4": "0.0.0.0/0"
    },
    {
      "IpProtocol": "udp",
      "FromPort": 162,
      "ToPort": 162,
      "CidrIpv4": "0.0.0.0/0"
    }
  ]
}
```

#### ECS Task Definition
```json
{
  "family": "simple-snmpd",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "simple-snmpd",
      "image": "simpledaemons/simple-snmpd:latest",
      "portMappings": [
        {
          "containerPort": 161,
          "protocol": "udp"
        }
      ],
      "environment": [
        {
          "name": "SNMP_COMMUNITY",
          "value": "aws_community"
        }
      ]
    }
  ]
}
```

### Azure Deployment

#### Azure Container Instances
```bash
# Deploy to Azure Container Instances
az container create \
  --resource-group myResourceGroup \
  --name simple-snmpd \
  --image simpledaemons/simple-snmpd:latest \
  --ports 161 \
  --environment-variables SNMP_COMMUNITY=azure_community
```

#### Azure Kubernetes Service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-snmpd
spec:
  replicas: 3
  selector:
    matchLabels:
      app: simple-snmpd
  template:
    metadata:
      labels:
        app: simple-snmpd
    spec:
      containers:
      - name: simple-snmpd
        image: simpledaemons/simple-snmpd:latest
        ports:
        - containerPort: 161
          protocol: UDP
        env:
        - name: SNMP_COMMUNITY
          value: "azure_community"
```

### Google Cloud Platform

#### Cloud Run
```bash
# Deploy to Cloud Run
gcloud run deploy simple-snmpd \
  --image gcr.io/my-project/simple-snmpd:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 161
```

#### Google Kubernetes Engine
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-snmpd
spec:
  replicas: 3
  selector:
    matchLabels:
      app: simple-snmpd
  template:
    metadata:
      labels:
        app: simple-snmpd
    spec:
      containers:
      - name: simple-snmpd
        image: gcr.io/my-project/simple-snmpd:latest
        ports:
        - containerPort: 161
          protocol: UDP
        env:
        - name: SNMP_COMMUNITY
          value: "gcp_community"
```

## Monitoring and Observability

### Health Checks

#### HTTP Health Check
```bash
# Configure health check endpoint
curl http://localhost:8080/health

# Response
{
  "status": "healthy",
  "uptime": 3600,
  "version": "1.0.0",
  "connections": 5
}
```

#### SNMP Health Check
```bash
# SNMP-based health check
snmpget -v2c -c public localhost 1.3.6.1.2.1.1.3.0
```

### Metrics Collection

#### Prometheus Metrics
```bash
# Configure Prometheus scraping
curl http://localhost:8080/metrics

# Example metrics
# HELP snmp_requests_total Total number of SNMP requests
# TYPE snmp_requests_total counter
snmp_requests_total{version="2c",community="public"} 1234
```

#### Grafana Dashboard
```json
{
  "dashboard": {
    "title": "Simple SNMP Daemon",
    "panels": [
      {
        "title": "SNMP Requests",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(snmp_requests_total[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      }
    ]
  }
}
```

### Logging

#### Centralized Logging
```yaml
# Fluentd configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/simple-snmpd/simple-snmpd.log
      pos_file /var/log/fluentd/simple-snmpd.log.pos
      tag simple-snmpd
      format json
    </source>
    <match simple-snmpd>
      @type elasticsearch
      host elasticsearch.logging.svc.cluster.local
      port 9200
      index_name simple-snmpd
    </match>
```

## Security Considerations

### Network Security

#### Firewall Configuration
```bash
# UFW (Ubuntu)
sudo ufw allow from 192.168.1.0/24 to any port 161
sudo ufw allow from 10.0.0.0/8 to any port 161

# iptables
sudo iptables -A INPUT -p udp --dport 161 -s 192.168.1.0/24 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 161 -s 10.0.0.0/8 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 161 -j DROP
```

#### VPN Integration
```bash
# OpenVPN configuration
client
dev tun
proto udp
remote vpn.example.com 1194
cipher AES-256-CBC
auth SHA256
```

### Access Control

#### SNMPv3 Configuration
```ini
# SNMPv3 security
enable_v3 = true
v3_user_database = /etc/simple-snmpd/v3-users.conf

# User configuration
admin:MD5:adminpass:DES:privpass
readonly:SHA:readpass::
```

#### Community String Security
```ini
# Secure community strings
community_string = $(openssl rand -hex 16)
read_community = $(openssl rand -hex 16)
write_community = $(openssl rand -hex 16)
```

## Backup and Recovery

### Configuration Backup
```bash
# Backup configuration
tar -czf simple-snmpd-config-$(date +%Y%m%d).tar.gz /etc/simple-snmpd/

# Automated backup script
#!/bin/bash
BACKUP_DIR="/backup/simple-snmpd"
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" /etc/simple-snmpd/
find "$BACKUP_DIR" -name "config-*.tar.gz" -mtime +30 -delete
```

### Data Recovery
```bash
# Restore configuration
tar -xzf simple-snmpd-config-20240101.tar.gz -C /

# Restart service
systemctl restart simple-snmpd
```

## Performance Tuning

### System Optimization

#### Kernel Parameters
```bash
# /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.ipv4.udp_mem = 102400 873800 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
```

#### Service Optimization
```ini
# High-performance configuration
worker_threads = 16
max_connections = 10000
enable_response_cache = true
response_cache_size = 10000
response_cache_timeout = 300
```

### Load Testing

#### SNMP Load Testing
```bash
# Using snmpbulkget for load testing
for i in {1..1000}; do
  snmpbulkget -v2c -c public localhost 1.3.6.1.2.1.1 &
done
wait
```

#### Performance Monitoring
```bash
# Monitor performance
htop
iotop
netstat -i
ss -tuln
```

## Troubleshooting Deployment

### Common Issues

#### Port Binding Issues
```bash
# Check port usage
netstat -tulpn | grep :161
ss -tulpn | grep :161

# Kill process using port
sudo fuser -k 161/udp
```

#### Permission Issues
```bash
# Check file permissions
ls -la /etc/simple-snmpd/
ls -la /var/log/simple-snmpd/

# Fix permissions
sudo chown -R snmp:snmp /etc/simple-snmpd/
sudo chown -R snmp:snmp /var/log/simple-snmpd/
```

#### Service Startup Issues
```bash
# Check service status
systemctl status simple-snmpd
journalctl -u simple-snmpd -f

# Check configuration
simple-snmpd --config-test
```

## Next Steps

- **Docker Deployment**: See [Docker Deployment Guide](docker.md) for containerized deployments
- **Production Deployment**: See [Production Deployment Guide](production.md) for enterprise deployments
- **Configuration**: Review the [Configuration Guide](../configuration/README.md)
- **Monitoring**: Set up monitoring and alerting systems
