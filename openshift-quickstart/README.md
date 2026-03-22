# OpenShift QuickStart Labs

**Learn OpenShift deployment patterns with hands-on labs**

Last Updated: 2026-03-22

---

## 📚 Lab Structure

This quickstart is organized into progressive labs:

```
openshift-quickstart/
├── 01-basics/              # OpenShift fundamentals
├── 02-helm-nexus-lab/      # Helm + Centralized Artifact Repository
├── 03-helm-argocd-lab/     # Helm + GitOps (ArgoCD)
└── README.md               # You are here
```

---

## 🎯 Learning Path

### **Prerequisites**
- [ ] Read `PREFLIGHT.md` - System requirements
- [ ] Read `START-HERE.md` - Getting started guide
- [ ] Have CRC (CodeReady Containers) or OpenShift cluster access

---

### **Lab 1: OpenShift Basics** ✅
**Location:** `01-basics/`

**What you'll learn:**
- Basic OpenShift CLI (`oc`) commands
- Deployments, services, routes
- ConfigMaps and secrets
- Simple YAML deployments

**Time:** 1-2 hours

**Start:** [01-basics/README.md](01-basics/README.md)

---

### **Lab 2: Helm + Nexus** 🎯 NEW
**Location:** `02-helm-nexus-lab/`

**What you'll learn:**
- Creating Helm charts
- Packaging Helm charts
- Setting up Nexus repository
- Storing/retrieving charts from Nexus
- Multi-environment deployments

**Pattern:**
```
Developer → Helm Chart → Package → Nexus → Deploy
```

**Benefits:**
- ✅ Centralized artifact storage
- ✅ Version control for charts
- ✅ Artifact scanning/security
- ✅ Reproducible deployments

**Time:** 2-3 hours

**Start:** [02-helm-nexus-lab/README.md](02-helm-nexus-lab/README.md)

---

### **Lab 3: Helm + ArgoCD (GitOps)** 🎯 NEW
**Location:** `03-helm-argocd-lab/`

**What you'll learn:**
- GitOps principles
- Installing ArgoCD on OpenShift
- Creating ArgoCD applications
- Automatic sync from Git
- Drift detection and self-healing
- Multi-environment management

**Pattern:**
```
Developer → Git Commit → ArgoCD Watches → Auto-Deploy
```

**Benefits:**
- ✅ Git as single source of truth
- ✅ Automatic deployments
- ✅ Drift detection
- ✅ Audit trail via Git history
- ✅ Easy rollbacks (Git revert)

**Time:** 2-3 hours

**Start:** [03-helm-argocd-lab/README.md](03-helm-argocd-lab/README.md)

---

## 🔄 Comparison: Nexus vs ArgoCD

| Feature | Helm + Nexus | Helm + ArgoCD |
|---------|--------------|---------------|
| **Deployment trigger** | Manual (`helm install`) | Automatic (Git push) |
| **Source of truth** | Nexus artifact repo | Git repository |
| **Drift detection** | ❌ No | ✅ Yes (auto-corrects) |
| **Rollback** | `helm rollback` | Git revert + auto-sync |
| **Audit trail** | Artifact versions | Git commit history |
| **Multi-cluster** | Manual per cluster | ArgoCD manages multiple |
| **Complexity** | Low | Medium |
| **Best for** | Traditional ops, artifact focus | Cloud-native, automation focus |

---

## 🤔 Which Approach Should I Use?

### **Choose Helm + Nexus if:**
- ✅ You need centralized artifact storage for compliance
- ✅ You have existing Nexus/Artifactory infrastructure
- ✅ You want manual control over deployments
- ✅ Your team is comfortable with traditional deploy workflows
- ✅ You need to scan artifacts before deployment

### **Choose Helm + ArgoCD if:**
- ✅ You want full GitOps automation
- ✅ You manage multiple environments/clusters
- ✅ You want automatic drift correction
- ✅ You value Git as single source of truth
- ✅ You want modern cloud-native practices

### **Use Both if:**
- ✅ Store charts in Nexus (artifact repository)
- ✅ ArgoCD pulls from Nexus (not Git)
- ✅ Best of both worlds: artifact management + GitOps

---

## 🚀 Quick Start

```bash
# Start with basics
cd 01-basics
cat README.md

# Then choose your path:

# Traditional approach
cd ../02-helm-nexus-lab
cat README.md

# Modern GitOps approach
cd ../03-helm-argocd-lab
cat README.md
```

---

## 📖 Additional Resources

**Documentation:**
- `cheatsheet.md` - Quick OpenShift commands
- `PREFLIGHT.md` - Prerequisites and setup
- `START-HERE.md` - First-time setup guide
- `README-local.md` - Local CRC setup

**External Links:**
- [OpenShift Docs](https://docs.openshift.com/)
- [Helm Docs](https://helm.sh/docs/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Nexus Repository OSS](https://help.sonatype.com/repomanager3)

---

## 🎓 Learning Outcomes

After completing these labs, you'll be able to:

- ✅ Deploy applications to OpenShift using Helm
- ✅ Package and version Helm charts
- ✅ Set up and use Nexus for artifact storage
- ✅ Implement GitOps with ArgoCD
- ✅ Manage multi-environment deployments
- ✅ Choose the right deployment pattern for your use case
- ✅ Understand trade-offs between approaches

---

## 💡 Tips

1. **Do both labs** - Understanding both approaches helps you make informed decisions
2. **Start simple** - Lab 1 (basics) builds foundation
3. **Take notes** - Document what works for your environment
4. **Experiment** - Break things and fix them (that's how you learn!)
5. **Compare** - Run the same app through both Lab 2 and Lab 3 to see differences

---

## 🤝 Contributing

Found an issue or want to improve a lab?
- Document your findings
- Share with the team
- Update the labs for the next person

---

## 📝 Change Log

**2026-03-22:**
- ✅ Reorganized into progressive labs
- ✅ Added Lab 2: Helm + Nexus
- ✅ Added Lab 3: Helm + ArgoCD (GitOps)
- ✅ Added comparison guide
- ✅ Moved basic examples to 01-basics/

**Previous:**
- Basic OpenShift examples and cheatsheet

---

Happy learning! 🚀
