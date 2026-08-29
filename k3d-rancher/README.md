# k3d + Rancher Lab

Run a local Kubernetes cluster (k3d) inside Docker Desktop, then install the Rancher Manager UI on top of it via Helm.

**Stack:**
- Docker Desktop (with WSL2 on Windows)
- k3d (k3s-in-Docker)
- kubectl
- Helm 3

---

## 0. Prerequisites

Verify each is installed and reachable from PowerShell:

```powershell
docker version         # Docker Desktop running
wsl --status           # WSL2 default distro installed
kubectl version --client
k3d version
helm version
```

If any are missing:

```powershell
# k3d
winget install k3d

# kubectl (if not already present)
winget install Kubernetes.kubectl

# Helm
winget install Helm.Helm
```

> [!NOTE]
> **Hardware Allocation:** Rancher and the k3s control plane require at least 6–8 GB of RAM allocated to WSL2 (`%USERPROFILE%\.wslconfig`). If RAM is restricted below 6 GB, Rancher server pods may encounter `OOMKilled` crashes during startup.

---

## 1. Create the k3d cluster

Expose ports 80 and 443 so the Rancher UI is reachable at `https://rancher.localhost` later. (Ensure port arguments remain quoted so PowerShell does not interpret `@` as splatting).

```powershell
k3d cluster create rancher-cluster `
  --api-port 6550 `
  -p "80:80@loadbalancer" `
  -p "443:443@loadbalancer" `
  --agents 1

# merge context
k3d kubeconfig merge rancher-cluster --kubeconfig-merge-default --kubeconfig-switch-context
```

Verify:

```powershell
kubectl config get-contexts
kubectl get nodes
kubectl get pods -A
```

You should see 1 server + 1 agent, all `Ready`. If not

Manual reboot:

```powershell
k3d cluster stop rancher-cluster
k3d cluster start rancher-cluster
kubectl get nodes
```

If still not working

Install fixed version and fixed ports:

```powershell
k3d cluster delete rancher-cluster
k3d cluster create rancher-cluster `
  --image rancher/k3s:v1.32.5-k3s1 `
  --api-port 6550 `
  -p "8081:80@loadbalancer" `
  -p "8443:443@loadbalancer" `
  --agents 1
```

Rancher UI then at https://rancher.localhost:8443. Keep --set hostname=rancher.localhost in the Helm install unchanged — only the browser URL carries the port.

---

## 2. Install cert-manager

Rancher needs it for TLS cert management.

DON'T USE KUBECTL!!!
```powershell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# Wait explicitly for all 3 cert-manager deployments (especially the mutating webhook) to become fully available before continuing:
kubectl -n cert-manager rollout status deploy/cert-manager
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector
kubectl -n cert-manager rollout status deploy/cert-manager-webhook
```
USE HELM INSTEAD FOR VERSION CONTROL
```powershell
# All three should come back empty
kubectl get ns cert-manager
kubectl get crd | Select-String cert-manager
kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration | Select-String cert-manager

# Install
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager `
  --namespace cert-manager --create-namespace `
  --version v1.21.1 `
  --set crds.enabled=true

# Check rollout status
kubectl -n cert-manager rollout status deploy/cert-manager
```
---

## 3. Install Rancher via Helm

```powershell
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

kubectl create namespace cattle-system

helm install rancher rancher-latest/rancher `
  --namespace cattle-system `
  --set "hostname=rancher.localhost" `
  --set "bootstrapPassword=admin" `
  --set "replicas=1"
```

Watch the rollout (this takes a few minutes):

```powershell
kubectl -n cattle-system rollout status deploy/rancher
```

---

## 4. Open the dashboard

Browse to: **https://rancher.localhost**

- Accept the self-signed cert warning (it's a local Rancher cert-manager cert).
- Username: `admin`
- Password: `admin` (the bootstrap password set above)
- On first login, Rancher forces a password change — set something memorable.

You should land on the Rancher **Cluster Management** dashboard, with your local `rancher-cluster` visible as an imported cluster.

---

## 5. Tear down

```powershell
k3d cluster delete rancher-cluster
```

---

## Troubleshooting

**"rancher.localhost" doesn't resolve:**
While modern browsers and `curl` usually resolve `*.localhost` automatically, Windows network stacks or local DNS settings can sometimes fail to resolve it properly.
1. Open `C:\Windows\System32\drivers\etc\hosts` as Administrator.
2. Add the line: `127.0.0.1 rancher.localhost`
3. Verify with `curl -k https://rancher.localhost`.

**Pods stuck in `CrashLoopBackOff` in cattle-system:**
Check logs — usually means cert-manager's mutating webhook was not fully ready when Rancher started. Delete the rancher Helm release, wait for webhook rollout, then reinstall:
```powershell
helm uninstall rancher -n cattle-system
kubectl -n cert-manager rollout status deploy/cert-manager-webhook
helm install rancher rancher-latest/rancher --namespace cattle-system --set "hostname=rancher.localhost" --set "bootstrapPassword=admin" --set "replicas=1"
```

**Port 80/443 already in use:**
Check `netstat -ano | findstr ":80 "` — common culprit is WSL2 services. Either stop them, or change the host-side port mapping in step 1:
```powershell
-p "8080:80@loadbalancer" -p "8443:443@loadbalancer"
```
Then access via `https://localhost:8443` and update `--set hostname=localhost`.

**Kubectl context wrong:**
```powershell
kubectl config get-contexts
kubectl config use-context k3d-rancher-cluster
```

---

## Optional next steps

- Import an existing local cluster (e.g. kind/minikube) into Rancher via *Cluster Management → Import Existing*
- Deploy a small workload (nginx, whoami) and expose it via Rancher's *Service Discovery*
- Add a second k3d cluster and manage it from the same Rancher instance
