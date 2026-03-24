# UBI9-Minimal Coder Template
# Purpose: Minimal image for Claude Code skill hosting in Coder platform
# Target Size: <200MB
# Base: Red Hat Universal Base Image 9 Minimal

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

LABEL maintainer="Barclays Platform Engineering"
LABEL description="Minimal UBI9 image for Claude Code + Coder console access"
LABEL version="1.0"

# Install Python 3.11 (minimal dependencies only)
RUN microdnf install -y \
    python3.11 \
    python3.11-pip \
    && microdnf clean all \
    && rm -rf /var/cache/yum

# Create non-root user for security
RUN useradd -m -u 1000 -s /bin/bash coder

# Set working directory
WORKDIR /home/coder

# Switch to non-root user
USER coder

# Set environment variables
ENV PATH="/home/coder/.local/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Health check (optional - for production deployments)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python3 --version || exit 1

# Default command: Start bash for Coder console
CMD ["/bin/bash"]
