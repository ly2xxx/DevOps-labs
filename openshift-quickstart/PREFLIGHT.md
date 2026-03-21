# Preflight Check - OpenShift Quick Start

**Complete these checks before starting the labs to ensure smooth learning experience.**

---

## ✅ Option 1: Developer Sandbox (Recommended for Quick Start)

**Best for:** Instant start, no installation, cloud-based

### Requirements:
- [ ] Web browser (Chrome, Firefox, Edge, Safari)
- [ ] Internet connection
- [ ] Free Red Hat account

### Setup Steps:

**1. Create Red Hat Developer Account** (2 minutes)
- Go to: https://developers.redhat.com/register
- Fill in details (no credit card required)
- Verify email

**2. Activate Developer Sandbox** (3 minutes)
- Go to: https://developers.redhat.com/developer-sandbox
- Click **"Start your free trial"**
- Login with Red Hat account
- Accept terms
- Click **"Launch"** when ready

**3. Install OpenShift CLI** (5 minutes)

**Windows:**
```powershell
# Using winget (recommended)
winget install RedHat.OpenShift-Client

# Verify
oc version --client
```

**Alternative - Manual download:**
- Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/
- Extract `oc.exe` to `C:\Program Files\OpenShift\`
- Add to PATH

**Mac:**
```bash
# Using Homebrew
brew install openshift-cli

# Verify
oc version --client
```

**Linux:**
```bash
# Download binary
cd /tmp
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz

# Extract
tar xvf openshift-client-linux.tar.gz

# Move to path
sudo mv oc /usr/local/bin/

# Verify
oc version --client
```

**4. Verify Access**
```powershell
# In web console, click User icon → "Copy login command"
# Paste and run in terminal

oc login --token=<your-token> --server=<your-server>

# Check you're logged in
oc whoami
```

---

## ✅ Option 2: OpenShift Local (For Extended Learning)

**Best for:** Offline work, long-term learning, laptop/desktop installation

### System Requirements:

**Minimum:**
- 4 CPU cores (physical)
- 9 GB RAM
- 35 GB free disk space
- Windows 10/11 Pro (Hyper-V), Mac, or Linux

**Recommended:**
- 6+ CPU cores
- 16 GB RAM
- 50 GB SSD storage
- Internet connection for initial download

### Prerequisites Checklist:

**Windows:**
- [ ] Windows 10/11 Pro, Enterprise, or Education
- [ ] Hyper-V enabled
- [ ] Virtualization enabled in BIOS

```powershell
# Check Hyper-V status
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# Enable if needed (requires admin + reboot)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

**Mac:**
- [ ] macOS 12.0 (Monterey) or newer
- [ ] Apple silicon (M1/M2) or Intel
- [ ] HyperKit (installed automatically)

**Linux:**
- [ ] RHEL/CentOS 8+, Fedora 33+, or Ubuntu 20.04+
- [ ] libvirt and NetworkManager installed
- [ ] User in `libvirt` group

### Setup Steps:

**1. Download OpenShift Local**
- Go to: https://console.redhat.com/openshift/create/local
- Login with Red Hat account
- Download for your OS
- Download pull secret
- Mirror: https://mirror.openshift.com/pub/openshift-v4/clients/crc/latest/ 

**2. Install**
```powershell
# Windows: Extract crc-windows-amd64.zip
# Add to PATH or run from extracted folder

# Verify
crc version
```

**3. Setup**
```powershell
# Initial setup (downloads ~3GB image)
crc setup

# Takes 10-15 minutes
```

**4. Start Cluster**
```powershell
# First start (10-15 minutes)
crc start -p <path-to-pull-secret.txt>

# Save kubeadmin password from output!
```

**5. Access**
```powershell
# Open web console
crc console

# Login credentials shown in start output
# Admin: kubeadmin / <password>
# Developer: developer / developer
```

---

## 🔧 Optional Tools (Enhance Experience)

**Helm** (for Lab 4 - Helm deployment)
```powershell
# Windows
winget install Helm.Helm

# Mac
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

**Git** (for source code deployment labs)
```powershell
# Windows
winget install Git.Git

# Mac
brew install git

# Linux
sudo apt install git  # Ubuntu/Debian
sudo yum install git  # RHEL/CentOS

# Verify
git --version
```

**Docker** (optional - for building local images)
- Windows/Mac: Docker Desktop
- Linux: Docker CE

---

## 🌐 Network Requirements

**For Developer Sandbox:**
- [ ] Internet access
- [ ] No proxy issues with `*.apps-crc.testing` (OpenShift Local only)
- [ ] Firewall allows HTTPS (443) to Red Hat services

**For OpenShift Local:**
- [ ] Initial download: ~3 GB
- [ ] Can work offline after setup
- [ ] DNS resolution for `*.apps-crc.testing` domains

**Test connectivity:**
```powershell
# Test Red Hat access
curl https://developers.redhat.com -I

# Test OpenShift mirror
curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/ -I
```

---

## 📚 Learning Resources (Pre-Read Optional)

**Background reading** (5-10 minutes each):
- [What is OpenShift?](https://www.redhat.com/en/topics/containers/what-is-openshift)
- [OpenShift vs Kubernetes](https://www.redhat.com/en/topics/containers/openshift-vs-kubernetes)
- [Container basics](https://www.redhat.com/en/topics/containers/whats-a-linux-container)

**Not required** - labs are beginner-friendly!

---

## ✅ Preflight Validation

Run these commands to confirm you're ready:

**Developer Sandbox (Cloud):**
```powershell
# ✅ CLI installed
oc version --client

# ✅ Can reach Red Hat
curl https://developers.redhat.com -I

# ✅ Sandbox activated (check in browser)
# Go to: https://developers.redhat.com/developer-sandbox
# Should show "Launch" button or "Active" status
```

**OpenShift Local (Laptop):**
```powershell
# ✅ CRC installed
crc version

# ✅ Hyper-V enabled (Windows)
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | findstr "Enabled"

# ✅ Setup complete
crc status

# ✅ Cluster running
crc status | findstr "Running"
```

---

## 🚨 Common Issues & Fixes

### Issue: "oc: command not found"
**Fix:** Add OpenShift CLI to PATH
```powershell
# Windows: Add directory containing oc.exe to system PATH
# Or run from full path: C:\path\to\oc.exe
```

### Issue: Hyper-V not available (Windows Home)
**Fix:** Windows Home doesn't support Hyper-V
**Options:**
1. Use Developer Sandbox (cloud-based)
2. Upgrade to Windows Pro
3. Use VirtualBox-based alternatives (not officially supported)

### Issue: CRC setup failed
**Fix:**
```powershell
# Clean up and retry
crc cleanup
crc setup
```

### Issue: "Only one usage of each socket address" on port 80 or 443
**Fix:** Configure CRC to use alternate ingress ports if port 80 or 443 is in use by another application.
```powershell
crc config set ingress-http-port 8088
crc config set ingress-https-port 7443
```

### Issue: Can't access OpenShift Local web console
**Fix:** Add DNS entries
```powershell
# Get CRC IP
crc ip

# Edit hosts file (as Administrator)
# Add: <crc-ip> console-openshift-console.apps-crc.testing
notepad C:\Windows\System32\drivers\etc\hosts
```

### Issue: Developer Sandbox expired
**Fix:** Reactivate for another 30 days
- Go to: https://developers.redhat.com/developer-sandbox
- Click **"Renew sandbox"**
- Can repeat indefinitely

---

## 🎯 Ready to Start?

**If using Developer Sandbox:**
✅ Account created → ✅ Sandbox activated → ✅ `oc` CLI installed

**→ Go to README.md → Lab 1**

**If using OpenShift Local:**
✅ CRC installed → ✅ Setup complete → ✅ Cluster running → ✅ `oc` CLI installed

**→ Go to README.md → Lab 1** (works with both!)

---

## 💡 Recommendation

**Start with Developer Sandbox** (instant access) and explore labs 1-5.

**If you like it**, download OpenShift Local for unlimited offline practice.

**Best of both worlds:** Use Sandbox for quick experiments, Local for deep learning.

---

**Estimated total setup time:**
- Developer Sandbox: 10 minutes
- OpenShift Local: 30-45 minutes (including downloads)

**Questions?** See `TROUBLESHOOTING.md` or the main README.md
