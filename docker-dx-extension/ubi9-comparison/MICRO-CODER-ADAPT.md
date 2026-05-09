# Adapting UBI9-Micro for Coder Workspaces

`ubi9-micro` is an excellent base for production containers due to its tiny footprint and reduced attack surface. However, it lacks the essential tools required for a **Coder Workspace** to bootstrap and function correctly.

## The Gap: What's Missing?

To run as a development environment, a container needs to be able to:
1. **Download the Coder Agent** (requires `curl` or `wget`).
2. **Extract the Agent** (requires `tar` and `gzip`).
3. **Manage Users** (requires `shadow-utils` for `useradd`).
4. **Provide a Shell** (Micro has `bash`, but lacks many standard CLI utilities).
5. **Secure Connections** (requires `ca-certificates`).

## The Solution: Multi-Stage Adaptation

Since `ubi9-micro` has no package manager, you must use a "Builder" image to install the necessary tools into a temporary root directory, which is then copied into the final micro image.

### Recommended Dockerfile

```dockerfile
# Stage 1: Build the filesystem
FROM registry.access.redhat.com/ubi9 AS builder

# Create a clean root for the final image
RUN mkdir -p /mnt/rootfs

# Install essential Coder workspace dependencies
RUN dnf install --installroot /mnt/rootfs \
    --releasever 9 \
    --setopt install_weak_deps=false \
    --nodocs -y \
    ca-certificates \
    curl-minimal \
    shadow-utils \
    tar \
    gzip \
    git \
    sudo \
    procps-ng \
    findutils

# Clean up dnf metadata
RUN dnf --installroot /mnt/rootfs clean all

# Stage 2: Final Micro Image
FROM registry.access.redhat.com/ubi9-micro

# Copy the adapted filesystem from the builder
COPY --from=builder /mnt/rootfs /

# Set up the coder user (now that shadow-utils is present)
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER coder
WORKDIR /home/coder
CMD ["/bin/bash"]
```

## Estimated Image Size

| Image Variant | Size (on disk) | Notes |
| :--- | :--- | :--- |
| `ubi9-micro` (Base) | ~23 MB | Bare minimum, missing almost all tools. |
| **Adapted UBI9-Micro** | **~95 MB - 110 MB** | Includes Git, Curl, Tar, and User Management. |
| `ubi9-minimal` | ~105 MB | Includes `microdnf`, but lacks `git` and `sudo` by default. |
| `ubi9` (Full) | ~211 MB | Full environment with all standard utilities. |

### Why use an adapted Micro over Minimal?
While the final size is similar to `ubi9-minimal`, an adapted Micro image is **more secure**. By using the multi-stage approach, you choose exactly which binaries are included. You can omit `microdnf` or `rpm` entirely in the final image, preventing users (or attackers) from installing unapproved software at runtime.
