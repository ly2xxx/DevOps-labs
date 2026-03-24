# Docker Command Cheat Sheet

Quick reference for the most common Docker commands.

---

## 📦 Image Commands

```bash
# Build image from Dockerfile
docker build -t myapp:latest .
docker build -f Dockerfile.dev -t myapp:dev .
docker build --no-cache -t myapp .           # Build without cache

# List images
docker images
docker images -a                              # Include intermediate images

# Remove image
docker rmi myapp:latest
docker rmi $(docker images -q)                # Remove all images

# Tag image
docker tag myapp:latest myapp:v1.0
docker tag myapp:latest myregistry/myapp:v1.0

# Pull/Push from registry
docker pull python:3.11-slim
docker push myregistry/myapp:v1.0

# Inspect image
docker inspect myapp:latest
docker history myapp:latest                   # Show image layers

# Save/Load images (for sharing)
docker save -o myapp.tar myapp:latest
docker load -i myapp.tar
```

---

## 🏃 Container Commands

```bash
# Run container
docker run myapp                              # Foreground
docker run -d myapp                           # Background (detached)
docker run -it myapp /bin/bash               # Interactive shell
docker run --rm myapp                         # Auto-remove when stopped
docker run --name mycontainer myapp          # With custom name

# Port mapping
docker run -p 8080:5000 myapp                # Map host:container
docker run -p 127.0.0.1:8080:5000 myapp      # Bind to specific IP

# Environment variables
docker run -e ENV=prod myapp
docker run -e ENV=prod -e DEBUG=false myapp
docker run --env-file .env myapp             # From file

# Volumes (data persistence)
docker run -v /host/path:/container/path myapp
docker run -v myvolume:/app/data myapp       # Named volume
docker run -v $(pwd):/app myapp              # Current directory

# Resource limits
docker run --memory="512m" --cpus="1.0" myapp

# Network
docker run --network mynetwork myapp
docker run --network host myapp              # Use host network

# Restart policy
docker run --restart unless-stopped myapp
docker run --restart always myapp

# Combined example
docker run -d \
  --name my-api \
  -p 8080:5000 \
  -e ENV=production \
  -v $(pwd)/data:/app/data \
  --restart unless-stopped \
  --memory="512m" \
  myapp:latest
```

---

## 🔧 Container Management

```bash
# List containers
docker ps                                     # Running only
docker ps -a                                  # All (including stopped)
docker ps -q                                  # IDs only

# Start/Stop/Restart
docker start <container-id>
docker stop <container-id>
docker restart <container-id>
docker stop $(docker ps -q)                   # Stop all running

# Remove containers
docker rm <container-id>
docker rm -f <container-id>                   # Force remove (even if running)
docker rm $(docker ps -aq)                    # Remove all stopped

# Logs
docker logs <container-id>
docker logs -f <container-id>                 # Follow logs (tail -f)
docker logs --tail 100 <container-id>         # Last 100 lines
docker logs --since 10m <container-id>        # Last 10 minutes

# Execute commands in container
docker exec <container-id> ls /app
docker exec -it <container-id> /bin/bash     # Interactive shell
docker exec -u root <container-id> apt-get update  # Run as root

# Copy files to/from container
docker cp file.txt <container-id>:/app/
docker cp <container-id>:/app/file.txt ./

# Inspect container
docker inspect <container-id>
docker top <container-id>                     # Process list
docker stats                                  # Resource usage (live)
docker stats --no-stream                      # One-time snapshot

# Attach to running container (see output)
docker attach <container-id>

# Export container as tar
docker export <container-id> > container.tar
```

---

## 🌐 Network Commands

```bash
# List networks
docker network ls

# Create network
docker network create mynetwork
docker network create --driver bridge mynetwork

# Inspect network
docker network inspect mynetwork

# Connect/Disconnect container
docker network connect mynetwork <container-id>
docker network disconnect mynetwork <container-id>

# Remove network
docker network rm mynetwork

# Prune unused networks
docker network prune
```

---

## 💾 Volume Commands

```bash
# List volumes
docker volume ls

# Create volume
docker volume create mydata

# Inspect volume
docker volume inspect mydata

# Remove volume
docker volume rm mydata

# Prune unused volumes
docker volume prune
```

---

## 🎼 Docker Compose Commands

```bash
# Start services
docker-compose up
docker-compose up -d                          # Background
docker-compose up --build                     # Rebuild images first
docker-compose up service1 service2           # Start specific services

# Stop services
docker-compose stop
docker-compose down                           # Stop and remove containers
docker-compose down -v                        # Also remove volumes

# View status
docker-compose ps
docker-compose logs
docker-compose logs -f                        # Follow logs
docker-compose logs -f service1               # Specific service

# Execute commands
docker-compose exec service1 /bin/bash
docker-compose exec service1 python manage.py migrate

# Build images
docker-compose build
docker-compose build --no-cache

# Restart services
docker-compose restart
docker-compose restart service1

# Scale services
docker-compose up -d --scale service1=3

# Config validation
docker-compose config                         # Validate and view config
```

---

## 🧹 Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune
docker image prune -a                         # Remove all unused (not just dangling)

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused (containers, images, networks, volumes)
docker system prune
docker system prune -a                        # More aggressive
docker system prune -a --volumes              # Include volumes

# Disk usage
docker system df                              # Show Docker disk usage
```

---

## 🔍 Inspection & Debugging

```bash
# Container info
docker inspect <container-id>                 # Full JSON details
docker inspect <container-id> | grep IPAddress  # Specific field

# Process info
docker top <container-id>                     # Running processes

# Resource usage
docker stats                                  # All containers (live)
docker stats <container-id>                   # Specific container

# Events
docker events                                 # Real-time events
docker events --since 1h                      # Last hour

# Port mappings
docker port <container-id>

# Disk usage
docker system df                              # Disk usage summary
docker system df -v                           # Verbose (per-resource)
```

---

## 🏷️ Common Flags

| Flag | Description |
|------|-------------|
| `-d` | Detached (background) mode |
| `-it` | Interactive with TTY (shell access) |
| `-p` | Publish port (host:container) |
| `-v` | Mount volume |
| `-e` | Set environment variable |
| `--name` | Container name |
| `--rm` | Auto-remove container when stopped |
| `--network` | Connect to network |
| `--restart` | Restart policy |
| `-f` | Follow logs / Force action |
| `-a` | All (ps, images, etc.) |
| `-q` | Quiet mode (IDs only) |

---

## 📋 Dockerfile Instructions

```dockerfile
FROM python:3.11-slim          # Base image
WORKDIR /app                   # Set working directory
COPY file.txt /app/            # Copy files from host
ADD archive.tar.gz /app/       # Copy + auto-extract archives
RUN pip install -r req.txt     # Execute command during build
ENV VAR=value                  # Set environment variable
EXPOSE 5000                    # Document port (not publish)
VOLUME /app/data               # Create mount point
USER appuser                   # Switch user
CMD ["python", "app.py"]       # Default command
ENTRYPOINT ["python"]          # Fixed command prefix
ARG BUILD_VERSION=1.0          # Build-time variable
LABEL version="1.0"            # Metadata
HEALTHCHECK CMD curl localhost:5000  # Health check command
```

---

## 🎯 Quick Workflows

### Development Workflow
```bash
# 1. Edit code
# 2. Rebuild image
docker build -t myapp:dev .

# 3. Run with volume mount (hot reload)
docker run -v $(pwd):/app -p 5000:5000 myapp:dev

# Or use compose
docker-compose up --build
```

### Debug Workflow
```bash
# 1. Run with debug port
docker run -p 5000:5000 -p 5678:5678 myapp:debug

# 2. Attach debugger from VSCode
# 3. Set breakpoints and test
```

### Production Deployment
```bash
# 1. Build production image
docker build -t myapp:v1.0 .

# 2. Tag for registry
docker tag myapp:v1.0 myregistry/myapp:v1.0

# 3. Push to registry
docker push myregistry/myapp:v1.0

# 4. Deploy to server
ssh server "docker pull myregistry/myapp:v1.0 && docker-compose up -d"
```

### Cleanup Everything
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Nuclear option (careful!)
docker system prune -a --volumes
```

---

## 💡 Pro Tips

**1. Use .dockerignore**
```
__pycache__
*.pyc
.git
.venv
node_modules
```

**2. Multi-stage builds for smaller images**
```dockerfile
FROM python:3.11 AS builder
RUN pip install --user -r requirements.txt

FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
```

**3. Layer caching optimization**
```dockerfile
# Put least-changed files first
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .  # App code (changes frequently)
```

**4. Use specific tags (not :latest)**
```dockerfile
FROM python:3.11.8-slim  # ✅ Good
FROM python:latest        # ❌ Bad (unpredictable)
```

**5. Run as non-root user**
```dockerfile
RUN useradd -m appuser
USER appuser
```

**6. Combine RUN commands to reduce layers**
```dockerfile
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean
```

---

## 📚 Resources

- [Official Docker Docs](https://docs.docker.com/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Print this cheat sheet and keep it handy! 📋**
