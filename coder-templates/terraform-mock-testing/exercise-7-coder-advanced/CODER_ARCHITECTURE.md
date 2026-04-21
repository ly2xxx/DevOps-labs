# Coder Workspace Component Architecture

This document explains the relationship between the five core Coder Terraform provider components visible in a running workspace, illustrated by the `terraform test --verbose` output from Exercise 7.

## Components in a Running Workspace

```
┌─────────────────────────────────────────────────────────────┐
│                    CODER CONTROL PLANE                      │
│                                                             │
│  data.coder_workspace.me      data.coder_workspace_owner.me │
│  ─────────────────────────    ──────────────────────────── │
│  name, id, transition,        name, email, ssh keys,        │
│  template info, start_count   session_token, oidc_token     │
│          │                              │                   │
│          └──────────────┬───────────────┘                   │
│                         │ read-only context                 │
└─────────────────────────┼───────────────────────────────────┘
                          │ informs provisioning (startup_script, env vars)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│               COMPUTE RESOURCE (VM / Container)             │
│                                                             │
│   coder_agent.main                                          │
│   ├── .init_script  → injected as container entrypoint      │
│   ├── .token        → set as CODER_AGENT_TOKEN env var      │
│   └── .id           ──────────────────────────┐            │
│                                               │ agent_id   │
│                          coder_app.code_server ◄────────────┤
│                          url: http://localhost:8080          │
│                          healthcheck: /health               │
│                                               │ agent_id   │
│                          coder_app.terminal   ◄────────────┘│
│                          url: ws://localhost:8080/terminal  │
└─────────────────────────────────────────────────────────────┘
```

## Component Reference

### `data.coder_workspace`
**Role:** Read-only context about the active workspace build.

Key attributes used in templates:
- `name` — workspace name (e.g. for labelling containers)
- `id` — workspace UUID
- `transition` — `"start"` or `"stop"`, drives `count = data.coder_workspace.me.start_count` to create/destroy compute resources
- `start_count` — `1` when starting, `0` when stopping; the standard pattern for conditional resource creation
- `template_id`, `template_name`, `template_version` — template metadata

Official doc: https://github.com/coder/terraform-provider-coder/blob/main/docs/data-sources/workspace.md

---

### `data.coder_workspace_owner`
**Role:** Read-only context about the user who owns the workspace.

Key attributes used in templates:
- `name`, `email`, `full_name` — used to personalise env vars (e.g. `GIT_AUTHOR_EMAIL`)
- `ssh_public_key`, `ssh_private_key` — injected for git/SSH workflows
- `session_token` — regenerated each workspace start; used for Coder CLI auth inside the workspace
- `oidc_access_token` — for SSO-integrated tooling

Official doc: https://github.com/coder/terraform-provider-coder/blob/main/docs/data-sources/workspace_owner.md

---

### `coder_agent`
**Role:** The process that runs *inside* the compute resource and phones home to the Coder control plane. It is the connective tissue that makes a workspace "connected".

How it wires up:
1. Terraform provisions the compute resource (Docker container, VM, pod)
2. `coder_agent.main.init_script` is injected as the container's startup command
3. `coder_agent.main.token` is set as the `CODER_AGENT_TOKEN` environment variable
4. The agent process starts, authenticates with the token, and the workspace status changes to **Connected**
5. `coder_agent.main.id` is then referenced by every `coder_app` via `agent_id`

Key attributes:
- `os`, `arch` — required; describes the compute environment
- `id` — referenced by all `coder_app` resources
- `token` — sensitive; authenticates the agent to the control plane
- `init_script` — generated bootstrap script to inject into compute
- `startup_script` — runs after agent connects (install tools, configure env)

Official doc: https://github.com/coder/terraform-provider-coder/blob/main/docs/resources/agent.md

---

### `coder_app` (e.g. `code_server`, `terminal`)
**Role:** Shortcuts displayed in the Coder dashboard that proxy traffic to services running inside the workspace.

Both apps share the same resource type; the difference is the URL scheme:

| App | URL scheme | Notes |
|-----|-----------|-------|
| `code_server` | `http://` | Web IDE; has a `healthcheck` block so Coder waits until the app is ready |
| `terminal` | `ws://` | WebSocket terminal; no healthcheck needed |

Key attributes:
- `agent_id` — **required**; must reference `coder_agent.main.id` — apps cannot exist without an agent
- `slug` — URL-safe identifier, unique per agent
- `url` — proxied endpoint (always `localhost` from the agent's perspective)
- `healthcheck` — optional HTTP readiness probe (`interval`, `threshold`, `url`)

Official doc: https://github.com/coder/terraform-provider-coder/blob/main/docs/resources/app.md

---

## Dependency Chain Summary

```
data.coder_workspace         ─┐
                              ├─► content of coder_agent.startup_script
data.coder_workspace_owner   ─┘   and environment variables

coder_agent.main  (must exist first)
    └── .id ──► coder_app.code_server (agent_id)  [http, healthcheck]
    └── .id ──► coder_app.terminal   (agent_id)  [websocket]
```

The two **data sources** are pure context — they carry no Terraform state and create no infrastructure.  
The **agent** is the single mandatory bridge between the Coder control plane and the compute resource.  
**Apps** are optional UI shortcuts that cannot be declared without a live agent ID.
