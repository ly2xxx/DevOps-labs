# Template Information

**Name:** UBI9 Claude Code  
**Version:** 1.0.0  
**Created:** April 1, 2026  
**Author:** Master Yang  
**Status:** Stable

---

## Description

Coder workspace template using UBI9-minimal base with Claude Code CLI pre-installed.

Perfect for:
- AI-assisted development
- Learning Claude Code
- Containerized development environments
- Red Hat ecosystem projects

---

## Specifications

### Base Image
- **Image:** `ubi9-minimal-coder:with-claude-code`
- **Base OS:** Red Hat Universal Base Image 9 (Minimal)
- **Size:** ~432 MB
- **User:** coder (UID 1000)

### Pre-installed Software
- Node.js (latest from UBI9 repos)
- npm
- Claude Code CLI (latest)

### Resources
- **CPU:** 1-4 cores (configurable, default: 2)
- **Memory:** 2-8 GB (configurable, default: 4 GB)
- **Storage:** Persistent home directory

---

## Features

- ✅ Claude Code CLI ready to use
- ✅ Persistent `/home/coder` directory
- ✅ VS Code web integration
- ✅ SSH access
- ✅ Port forwarding support
- ✅ Dotfiles integration
- ✅ Resource monitoring
- ✅ Startup script customization

---

## Version History

### v1.0.0 (April 1, 2026)
- Initial release
- Based on UBI9-minimal
- Claude Code CLI pre-installed
- Terraform template with Docker provider
- Configurable CPU and memory
- Persistent storage
- Welcome README in workspace
- Health checks
- Metadata reporting (CPU, memory, disk, Claude version)

---

## Known Issues

None currently.

---

## Roadmap

**Planned for v1.1:**
- [ ] Add git pre-installed
- [ ] Add Python 3 option
- [ ] Add vim/nano editors
- [ ] VS Code extension marketplace support
- [ ] SSH key management improvements

**Planned for v2.0:**
- [ ] Multi-language support (Python, Go, Rust templates)
- [ ] GPU support for AI workloads
- [ ] Integration with external secrets manager
- [ ] Team sharing features

---

## Dependencies

### Required
- Docker (running)
- Coder CLI installed
- Coder server running (local or remote)

### Optional
- Git (for dotfiles)
- VS Code (for remote development)

---

## Maintenance

**Image Updates:**
Rebuild Docker image when:
- Claude Code new version released
- UBI9 security updates
- Node.js version updates

**Template Updates:**
Update template when:
- Coder provider updated
- New features needed
- Bug fixes

**Workspace Updates:**
Users can update workspaces to latest template version:
```bash
coder update workspace-name
```

---

## Support

**Documentation:**
- README.md (full setup guide)
- This file (metadata)

**Troubleshooting:**
See README.md "Troubleshooting" section

**Issues:**
Report issues to: Master Yang

---

## Testing Checklist

Before releasing template updates:

- [ ] Docker image builds successfully
- [ ] Template validates (`terraform validate`)
- [ ] Workspace creates without errors
- [ ] Agent connects successfully
- [ ] Claude Code runs (`claude-code --version`)
- [ ] VS Code web works
- [ ] SSH access works
- [ ] Persistent storage works (stop/start workspace)
- [ ] Dotfiles integration works (if provided)
- [ ] Resource limits apply correctly
- [ ] Monitoring metrics display

---

## Configuration

### Environment Variables (in workspace)

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Claude API key |
| `NPM_CONFIG_PREFIX` | Auto | npm global install path |
| `PATH` | Auto | Includes npm global bin |
| `NODE_ENV` | Auto | Set to "production" |

### Workspace Defaults

| Setting | Default | Range |
|---------|---------|-------|
| CPU | 2 cores | 1-4 |
| Memory | 4 GB | 2-8 GB |
| Disk | 20 GB | Auto (Docker volume) |

---

## Security Considerations

- ✅ Non-root user (coder, UID 1000)
- ✅ Minimal base image (reduced attack surface)
- ✅ No passwords in template
- ✅ API keys via environment variables (not hardcoded)
- ⚠️ Users must secure their own API keys
- ⚠️ Workspace isolation depends on Docker/Coder configuration

**Recommendations:**
- Use secrets manager for API keys
- Enable Coder RBAC
- Regular image updates
- Scan images for vulnerabilities

---

## License

This template is provided as-is for personal and educational use.

Docker image based on Red Hat UBI9 (subject to Red Hat's terms).

---

## Credits

**Built with:**
- Coder (https://coder.com)
- Terraform (https://terraform.io)
- Docker (https://docker.com)
- Red Hat UBI9 (https://access.redhat.com/products/red-hat-universal-base-image)
- Claude Code by Anthropic (https://anthropic.com)

---

**Last Updated:** April 1, 2026  
**Maintainer:** Master Yang
