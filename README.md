# Ephemeral Environment Provisioning Platform

> [!IMPORTANT]
> **Project Status: Planning and Documentation Stage (Phase 0)**  
> This project is currently in the requirements, architecture, and documentation design stage. **No application code, backend services, frontend dashboard, or Kubernetes workloads have been deployed or implemented yet.** All features, workflows, and architectural designs described in this document represent the planned implementation.

---

## 1. Project Summary

The **Ephemeral Environment Provisioning Platform** is a developer self-service and platform engineering solution designed to automate the complete lifecycle of short-lived (ephemeral) application environments in Kubernetes. 

Triggered automatically by GitHub pull request (PR) events, the platform provisions isolated, production-like preview environments, deploys pull-request code, performs automated readiness and health checks, exposes preview endpoints for testing and stakeholder review, and terminates resources cleanly when pull requests are closed, merged, or when a time-to-live (TTL) expiration window is reached.

---

## 2. Problem Statement

In modern software development teams, validating pull requests before merging to mainline branches often suffers from severe testing bottlenecks:

- **Shared Staging Bottlenecks**: Developers compete for shared staging or QA environments, causing scheduling conflicts, configuration drift, and test collisions where one broken branch breaks testing for everyone.
- **"Works on My Machine" Syndrome**: Local developer environments (Docker Compose, Minikube, or bare metal) often fail to replicate target Kubernetes networking, ingress rules, service discovery, or security constraints.
- **Resource and Cloud Cost Sprawl**: When teams create manual preview environments in cloud clusters, they routinely forget to tear them down, resulting in substantial infrastructure waste and high monthly cloud bills.
- **Delayed Feedback Loops**: Product managers, QA engineers, and UX designers cannot easily review feature branches without checking out code, installing dependencies, and running projects locally.

---

## 3. Proposed Solution

The platform provides an automated, Kubernetes-native orchestration engine that manages isolated environments on demand:

- **Per-PR Isolation**: Every pull request receives an isolated Kubernetes namespace running the specific container image version built for that PR branch.
- **Zero-Friction Preview Access**: Non-technical stakeholders and automated testers receive a direct URL to inspect the live application without running local code.
- **Automated Lifecycle Governance**: Environments are created upon PR opening or branch updates, verified for readiness, and decommissioned automatically upon PR closure, merge, or TTL expiration.
- **Platform Engineering Principles**: Abstracting Kubernetes complexity behind a simple webhook and API, turning cluster operations into self-service infrastructure.

---

## 4. Project Objectives

1. **Automate the Full Lifecycle**: Manage provisioning, configuration, health verification, preview URL exposition, and teardown end-to-end.
2. **Local-First, Kubernetes-First Architecture**: Deliver a working, robust MVP locally using [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/) before considering managed cloud environments (such as AWS EKS).
3. **Beginner-Friendly Pedagogical Value**: Design the platform to serve as a practical, understandable guide for developers learning Kubernetes and platform engineering patterns.
4. **Resilience & Governance**: Ensure that failed rollouts are safely reported, stale environments are reliably reaped via TTL, and cluster resources are bounded.

---

## 5. Key Planned Features

| Category | Planned Feature | Description | Status |
| :--- | :--- | :--- | :--- |
| **Automation** | GitHub Webhook Ingestion | Captures `pull_request` events (`opened`, `synchronize`, `closed`). | *Planned* |
| **Orchestration** | Dynamic Namespace Provisioning | Generates isolated Kubernetes namespaces (`pr-<number>-<hash>`). | *Planned* |
| **Deployment** | Automated Workload Rollout | Deploys containerized application workloads into target namespaces. | *Planned* |
| **Verification** | Health & Readiness Probes | Validates Kubernetes pod readiness and HTTP health endpoints before publishing access. | *Planned* |
| **Exposure** | Preview Endpoint Routing | Configures local ingress/port routing to expose preview URLs. | *Planned* |
| **Governance** | TTL-Based Expiration | Automatically terminates environments exceeding permitted lifetime (e.g., 2 hours). | *Planned* |
| **Lifecycle** | Event-Driven Cleanup | Destroys namespaces and all associated resources when PRs close or merge. | *Planned* |
| **Observability** | Central State Tracking | Records environment status, transition logs, and deployment events in PostgreSQL. | *Planned* |
| **UI** | Developer Dashboard | Lightweight React dashboard to view active preview environments, logs, and triggers. | *Planned* |

---

## 6. High-Level Workflow

The planned end-to-end flow operates as follows:

```
[ Developer opens/updates PR ] 
              │
              ▼
[ GitHub Webhook ] ──(HMAC Signed)──► [ Provisioning Engine (FastAPI) ]
                                                    │
                                ┌───────────────────┴───────────────────┐
                                ▼                                       ▼
                   [ Build & Image Pipeline ]              [ Validate Event & DB State ]
                   (CI build or local registry)                         │
                                │                                       ▼
                                └─────────────────────────► [ Provision K8s Namespace ]
                                                                        │
                                                                        ▼
                                                            [ Deploy K8s Workloads ]
                                                                        │
                                                                        ▼
                                                            [ Check Pod & HTTP Health ]
                                                                        │
                                                    ┌───────────────────┴───────────────────┐
                                                    ▼ (Healthy)                             ▼ (Failed)
                                        [ Publish Preview URL ]                 [ Mark FAILED in DB ]
                                        [ Set TTL Expiration ]                  [ Post PR Status Comment ]
                                                    │
                                ┌───────────────────┴───────────────────┐
                                ▼                                       ▼
                     [ PR Closed or Merged ]                  [ TTL Expiration Reached ]
                                │                                       │
                                └───────────────────┬───────────────────┘
                                                    ▼
                                        [ Namespace Destruction ]
                                        [ DB Marked CLEANED_UP ]
```

---

## 7. Proposed Technology Stack

| Layer | Proposed Technology | Responsibility |
| :--- | :--- | :--- |
| **Core Platform Engine** | Python 3.11+, FastAPI | Webhook ingestion, API server, and orchestration controller. |
| **Local Kubernetes Engine** | Kind (Kubernetes in Docker) | Local Kubernetes cluster running inside Docker containers. |
| **Kubernetes Tooling** | `kubectl`, Kubernetes Python Client, Helm | Cluster inspection, programmatic manifest application, and packaging. |
| **Containerization** | Docker, Local Registry / GHCR | Building and hosting demo application images. |
| **Data Persistence** | PostgreSQL | Tracking environments, state transitions, lifecycle logs, and audit trails. |
| **CI / Automation** | GitHub Actions | Running automated linters, tests, and build triggers. |
| **Developer Dashboard** | React, Vite, TailwindCSS | Self-service web interface for viewing active environments and logs. |
| **Future Extensions** | AWS (EKS, VPC), Terraform | Optional cloud deployment and Infrastructure-as-Code (Phase 9). |

*For detailed justifications and trade-off analyses, refer to [docs/TECH-STACK.md](docs/TECH-STACK.md).*

---

## 8. High-Level Architecture Overview

The system architecture consists of four primary domains:

1. **Ingress & Integration Domain**: Validates GitHub webhook signatures and translates GitHub events into internal platform jobs.
2. **Control Plane Domain (Provisioning Engine)**: A FastAPI service managing the state machine, scheduling TTL checks, and orchestrating deployment lifecycles.
3. **Cluster Runtime Domain**: A Kind-based Kubernetes cluster where individual namespaces isolate each pull request's workloads, services, and routing rules.
4. **Data & Observability Domain**: PostgreSQL database for persistent state and audit logs, coupled with a React UI for self-service inspection.

*For an in-depth breakdown and architectural diagrams, see [docs/SYSTEM-ARCHITECTURE.md](docs/SYSTEM-ARCHITECTURE.md).*

---

## 9. Repository Documentation Structure

```
Ephemeral-Environment-Provisioning-Platform/
│
├── README.md                      # Primary project overview and roadmap (this file)
├── .gitignore                     # Git ignore rules for documentation and dev files
│
└── docs/
    ├── PROJECT-OVERVIEW.md        # Problem statement, user personas, and success metrics
    ├── DEVELOPERS-GUIDE.md        # Contribution guidelines, WSL2/Windows workflow, conventions
    ├── DEVELOPMENT-PHASES.md      # Detailed 11-phase development roadmap and gates
    ├── DEVELOPER-LIFECYCLE.md     # In-depth PR-to-preview lifecycle and state transitions
    ├── SYSTEM-ARCHITECTURE.md     # Conceptual architecture, component interactions, boundaries
    ├── TECH-STACK.md              # Technical stack selection, roles, and trade-offs
    ├── ARCHITECTURE-DECISIONS.md  # Architecture Decision Records (ADRs)
    ├── DEVELOPMENT-LOG.md         # Central progress log tracking tasks and milestones
    │
    └── development-logs/
        └── PHASE-0-LOG.md         # Phase 0 (Requirements & Architecture) execution log
```

---

## 10. Planned Development Phases

Development is structured into sequential, milestone-gated phases:

- **Phase 0: Requirements and Architecture** *(Current Phase)*
- **Phase 1: Development Environment and Kubernetes Foundation**
- **Phase 2: Demo Application and Container Build Pipeline**
- **Phase 3: GitHub Integration and Provisioning Engine**
- **Phase 4: Environment Lifecycle Management (TTL & Cleanup)**
- **Phase 5: Security and Reliability (Resource Quotas & RBAC)**
- **Phase 6: Backend APIs and Persistent State (PostgreSQL)**
- **Phase 7: Developer Dashboard (React)**
- **Phase 8: Automated Testing and Observability**
- **Phase 9: Optional AWS and Terraform Extension**
- **Phase 10: Documentation, Demonstration, and Project Finalization**

*Detailed deliverables, acceptance criteria, and definitions of done for each phase are documented in [docs/DEVELOPMENT-PHASES.md](docs/DEVELOPMENT-PHASES.md).*

---

## 11. Current Project Status

- **Current Status**: **Phase 0 - Requirements & Architecture (Planning and Documentation Stage)**.
- **Implemented Work**: Initial project documentation structure, architecture design records, and developer guidelines.
- **Application Code**: None. Application source code, Kubernetes manifests, and database schemas have **not** been implemented yet.
- **Cluster State**: No clusters or workloads have been provisioned.

---

## 12. Expected Prerequisites for Future Development

When implementation is approved in subsequent phases, the development workstation will require:

- **Host OS**: Windows 10/11 with PowerShell 7+ and **WSL2 (Ubuntu 22.04 LTS or later)**.
- **Container Runtime**: Docker Desktop or Docker Engine running inside WSL2.
- **CLI Utilities** (to be verified and installed during Phase 1):
  - `kind` (Kubernetes in Docker)
  - `kubectl` (Kubernetes CLI)
  - `helm` (Package manager for Kubernetes)
  - `python` (3.11+) and `pip`
  - `git`
  - `curl` / `jq`

*Note: Prerequisites will be checked and verified step-by-step during Phase 1. No tools are assumed to be pre-installed.*

---

## 13. Development, Testing, and Verification Methodology

To maintain software reliability and practical learning:
1. **Guided Progression**: Every major phase requires review and explicit approval before proceeding.
2. **No Fabricated Verification**: A task is never marked as verified without concrete command outputs or automated test passes.
3. **Incremental Validation**: Each component (e.g., webhook receiver, Kubernetes client, cleanup reaper) will be built and tested in isolation before being integrated.
4. **Transparent Logging**: Every task, failure, root cause, and fix will be recorded in the development logs.

---

## 14. Security and Reliability Considerations

- **Namespace Isolation**: Workloads deployed for PRs must be constrained to their dedicated namespaces.
- **Resource Quotas & Limits**: Prevent runaway container memory or CPU usage from starving the host cluster.
- **Least Privilege RBAC**: The platform engine's Kubernetes ServiceAccount will only hold permissions necessary to manage preview namespaces.
- **Secret Hygiene**: Webhook secrets and database credentials will never be committed to source control; `.gitignore` and environment variables will be enforced.
- **Idempotent Operations**: The platform must handle duplicate or out-of-order GitHub webhook events without corrupting cluster state.

---

## 15. Future Scope

The following capabilities are deferred until after the local MVP is fully verified:
- Production multi-tenant AWS EKS deployment via Terraform.
- Dynamic DNS and automated TLS/HTTPS certificate generation (Let's Encrypt / cert-manager).
- Complex multi-service microservice previews (the initial MVP will focus on single-tier and two-tier web workloads).
- Distributed tracing (OpenTelemetry / Jaeger).

---

## 16. Planning Notice

> This README is maintained as a living document. It reflects the architecture and requirements agreed upon during Phase 0. No application code or deployments should be assumed to exist until recorded as verified in [docs/DEVELOPMENT-LOG.md](docs/DEVELOPMENT-LOG.md).

