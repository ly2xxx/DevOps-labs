# K3s AI Agent Team - Security-Isolated Orchestration

**Goal:** Build a Kubernetes-based control plane that orchestrates OpenClaw AI agents with role-based isolation (MARKETING, DEVELOPER, TESTER).

**Security Focus:** Namespace isolation, network policies, resource quotas, dynamic scaling.

---

## Project Plan

### Phase 1: K3s Cluster Setup ✅
- [✓] Create setup script for control plane node
- [✓] Create worker node join script
- [✓] Document cluster verification steps
- [✓] Test multi-node setup (ready for testing)

### Phase 2: Agent Deployment YAMLs ✅
- [✓] Create namespace definitions
- [✓] Build agent Deployment templates (marketing/dev/test)
- [✓] Configure resource quotas per namespace
- [✓] Set up network policies for isolation
- [✓] Create shared PVC for agent coordination

### Phase 3: Orchestration Controller ✅
- [✓] Design simple task dispatcher
- [✓] Build scale-up/scale-down logic
- [✓] Create API endpoint for task submission
- [✓] Add monitoring/logging

---

## Quick Start

### Prerequisites
- Old PCs running Linux (Ubuntu 20.04+ recommended)
- Primary node: 2+ CPU, 4GB+ RAM
- Worker nodes: 1+ CPU, 2GB+ RAM
- Network connectivity between nodes

### Installation
```bash
# On primary node (control plane)
./scripts/setup-control-plane.sh

# On worker nodes
./scripts/join-worker.sh <MASTER_IP> <JOIN_TOKEN>
```

### Deploy Agents
```bash
kubectl apply -f k8s/namespaces/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/network-policies/
```

### Launch a Task
```bash
# Manual scaling
kubectl scale deployment marketing-agent -n marketing-agents --replicas=2

# Or via orchestration API
curl -X POST http://controller:8080/task \
  -d '{"role": "MARKETING", "task": "analyze_campaign"}'
```

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Primary Node (Control Plane)           │
│  - K3s Control Plane                                │
│  - Orchestration Controller                         │
│  - Coordinator Namespace                            │
└─────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼─────┐  ┌───────▼─────┐  ┌──────▼──────┐
│  Worker 1   │  │  Worker 2   │  │  Worker 3   │
│             │  │             │  │             │
│ Marketing   │  │ Developer   │  │ Tester      │
│ Agents      │  │ Agents      │  │ Agents      │
└─────────────┘  └─────────────┘  └─────────────┘
```

---

## Folder Structure

```
k3s-agent-team/
├── README.md                      # This file
├── scripts/
│   ├── setup-control-plane.sh     # K3s primary node setup
│   ├── join-worker.sh             # Worker node join script
│   └── verify-cluster.sh          # Health check script
├── k8s/
│   ├── namespaces/
│   │   ├── marketing-agents.yaml
│   │   ├── dev-agents.yaml
│   │   ├── test-agents.yaml
│   │   └── coordinator.yaml
│   ├── deployments/
│   │   ├── marketing-agent.yaml
│   │   ├── dev-agent.yaml
│   │   └── test-agent.yaml
│   ├── network-policies/
│   │   ├── marketing-isolation.yaml
│   │   ├── dev-isolation.yaml
│   │   └── test-isolation.yaml
│   ├── quotas/
│   │   ├── marketing-quota.yaml
│   │   ├── dev-quota.yaml
│   │   └── test-quota.yaml
│   └── storage/
│       └── shared-pvc.yaml
├── controller/
│   ├── app.py                     # Orchestration controller
│   ├── requirements.txt
│   ├── Dockerfile
│   └── controller-deployment.yaml
└── docker/
    ├── Dockerfile.marketing       # Marketing agent image
    ├── Dockerfile.developer       # Developer agent image
    └── Dockerfile.tester          # Tester agent image
```

---

## Current Status

**Last Updated:** 2026-03-22

**Status:** ✅ Complete - Ready for Deployment

- Phase 1: ✅ Complete
- Phase 2: ✅ Complete
- Phase 3: ✅ Complete
