# Architecture Decision Records (ADRs)

> [!NOTE]
> **Status**: Architectural Decision Log (Phase 0)  
> This document records key architectural decisions, their context, alternatives evaluated, and consequences. Decisions currently under review are marked **PROPOSED**. Decisions will be marked **ACCEPTED** only after explicit user approval.

---

## Decision Index

| ID | Title | Status | Date |
| :--- | :--- | :--- | :--- |
| **ADR-001** | Kubernetes-First Architecture vs. Cloud-Infrastructure-First | `PROPOSED` | 2026-10-17 |
| **ADR-002** | Kind (Kubernetes in Docker) for Local MVP Cluster | `PROPOSED` | 2026-10-17 |
| **ADR-003** | Modular FastAPI Application vs. Microservice Architecture | `PROPOSED` | 2026-10-17 |
| **ADR-004** | GitHub Actions for CI Build and Test Coordination | `PROPOSED` | 2026-10-17 |
| **ADR-005** | One Kubernetes Namespace per Pull Request for Workload Isolation | `PROPOSED` | 2026-10-17 |
| **ADR-006** | Automated Time-To-Live (TTL) Based Environment Reaping | `PROPOSED` | 2026-10-17 |
| **ADR-007** | PostgreSQL for Persistent Environment State and Audit Logging | `PROPOSED` | 2026-10-17 |
| **ADR-008** | React (Vite + TailwindCSS) for Developer Dashboard | `PROPOSED` | 2026-10-17 |
| **ADR-009** | Local-First Development Prior to Cloud (AWS) Provisioning | `PROPOSED` | 2026-10-17 |
| **ADR-010** | Provisioning Controller Placement and Runtime Model | `PROPOSED` | 2026-10-17 |

---

## ADR-001: Kubernetes-First Architecture vs. Cloud-Infrastructure-First

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  We need to establish the foundational runtime abstraction for preview environments. Options include dynamically provisioning cloud VMs (e.g., AWS EC2), standing up serverless containers (AWS ECS/Fargate), or orchestrating inside a Kubernetes cluster using native primitives (Namespaces, Deployments, Services).
- **Decision**:  
  Adopt a **Kubernetes-First** architecture. Ephemeral environments will be modeled as Kubernetes-native objects within an existing cluster rather than provisioning distinct cloud infrastructure per PR.
- **Alternatives Considered**:
  - *Cloud VM Per PR (EC2)*: Extremely slow provisioning times (3–5 minutes), high costs, complex teardown.
  - *AWS ECS / Fargate*: Vendor lock-in, lacks local reproducibility, slower launch times than local K8s.
- **Consequences**:
  - *Positive*: Sub-minute provisioning times, excellent density, standard API (`kubectl`), rich local development story.
  - *Negative*: Requires learning Kubernetes concepts (networking, RBAC, ingress).

---

## ADR-002: Kind (Kubernetes in Docker) for Local MVP Cluster

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  We require a local Kubernetes distribution that runs smoothly inside Windows WSL2 Ubuntu with Docker.
- **Decision**:  
  Use **Kind** as the primary local cluster engine for Phases 1–8.
- **Alternatives Considered**:
  - *Minikube*: Heavier footprint; more virtualization overhead; less straightforward multi-node configuration.
  - *k3s / k3d*: Lightweight, but Kind is more closely aligned with upstream standard Kubernetes and has excellent multi-platform CI support.
  - *Docker Desktop built-in Kubernetes*: Harder to script programmatic cluster creation and destruction.
- **Consequences**:
  - *Positive*: Fast cluster spin-up, zero cloud costs, declarative YAML cluster config, easy reset.
  - *Negative*: Local ingress routing requires custom port-mapping config on the Kind node.

---

## ADR-003: Modular FastAPI Application vs. Microservice Architecture

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  We must decide how to organize the backend platform engine that handles webhooks, state tracking, background TTL checks, and REST APIs.
- **Decision**:  
  Build a **modular monolithic FastAPI application** rather than distributed microservices for the initial platform.
- **Alternatives Considered**:
  - *Microservices (Separate Webhook Ingestion, Controller Worker, API Service, Reaper Service)*: Introduces distributed messaging (Kafka/RabbitMQ), RPC overhead, complex deployment, and unnecessary cognitive load.
  - *Serverless Functions (AWS Lambda)*: Cannot easily test locally against Kind without emulation tools.
- **Consequences**:
  - *Positive*: Single codebase, easy local debugging, shared data models, straightforward deployment.
  - *Negative*: Background tasks run in the same process loop initially; requires migration to dedicated worker queues (e.g., Celery) if webhook volume scales dramatically.

---

## ADR-004: GitHub Actions for CI Build and Test Coordination

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  Before deploying code into a preview environment, the application container image must be built and unit-tested.
- **Decision**:  
  Use **GitHub Actions** for CI building and automated testing, while providing local shell scripts to emulate this build pipeline during offline local development.
- **Alternatives Considered**:
  - *In-Cluster Tekton / Argo Workflows*: Heavy to run locally inside Kind; adds significant cluster overhead.
  - *Building images inside the FastAPI webhook handler*: Blocks web server threads; security risks running Docker builds inside the API process.
- **Consequences**:
  - *Positive*: Native GitHub integration, offloads compute-heavy container builds from the local platform engine.
  - *Negative*: Requires webhook delivery tunnels (like `ngrok`) to connect GitHub Actions to local development clusters.

---

## ADR-005: One Kubernetes Namespace per Pull Request for Workload Isolation

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  We must determine how multiple concurrent pull request environments are isolated from each other in the cluster.
- **Decision**:  
  Assign **one dedicated Kubernetes Namespace per pull request** (e.g., `pr-42-feat-auth`).
- **Alternatives Considered**:
  - *Single Shared Namespace with Name Prefixing (e.g., `pr42-web-deployment`)*: Dangerous; easy for resources to leak or clash; impossible to apply per-PR `ResourceQuota` or clean up with a single namespace deletion command.
  - *Separate Cluster Per PR (vCluster or separate Kind clusters)*: Heavyweight; consumes excessive CPU and memory on developer workstations.
- **Consequences**:
  - *Positive*: Complete logical separation, instant teardown (`kubectl delete namespace`), isolated RBAC and ResourceQuotas.
  - *Negative*: Namespaces have slight metadata overhead; ingress controller must support cross-namespace routing.

---

## ADR-006: Automated Time-To-Live (TTL) Based Environment Reaping

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  Pull requests often remain open, inactive, or abandoned for days or weeks. Without automatic reaping, clusters run out of resources.
- **Decision**:  
  Implement an automated **TTL reaper daemon** that monitors an `expires_at` timestamp on each environment and reclaims resources when expired.
- **Alternatives Considered**:
  - *Manual Developer Teardown Only*: Developers routinely forget; results in cluster saturation.
  - *Nightly Sweeps (Cron)*: Inflexible; doesn't accommodate short-lived tests during the workday.
- **Consequences**:
  - *Positive*: Guarantees bounded resource consumption and prevents orphaned workloads.
  - *Negative*: Active debugging sessions may be interrupted if developers forget to extend the TTL via the dashboard.

---

## ADR-007: PostgreSQL for Persistent Environment State and Audit Logging

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  The platform must track active environments, historical state transitions, and audit records.
- **Decision**:  
  Use **PostgreSQL** as the persistent relational database, managed via SQLAlchemy and Alembic. In early phases (Phases 3–5), an in-memory/SQLite state may be used temporarily, formalizing PostgreSQL in Phase 6.
- **Alternatives Considered**:
  - *Kubernetes Custom Resource Definitions (CRDs)*: Highly Kubernetes-native, but introduces complex operator development (Kubebuilder/Kopf) and lacks standard relational SQL reporting.
  - *In-Memory / Flat JSON Files*: Prone to corruption, lost on restarts, lacks transactional concurrency.
- **Consequences**:
  - *Positive*: Robust ACID transactions, rich JSONB querying, standard migration tooling (Alembic).
  - *Negative*: Adds a database dependency that must be run in Docker or Kubernetes.

---

## ADR-008: React (Vite + TailwindCSS) for Developer Dashboard

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  We need a self-service UI for developers and product managers to view active environments and trigger actions.
- **Decision**:  
  Build a lightweight single-page application using **React, Vite, and TailwindCSS** (Phase 7).
- **Alternatives Considered**:
  - *Server-Side Rendered Templates (Jinja2 / FastAPI)*: Simpler setup, but less dynamic for live polling and modern interactive UI.
  - *CLI-Only Tool*: Non-technical stakeholders (PMs, QA) cannot use a CLI effectively.
- **Consequences**:
  - *Positive*: Fast developer experience, clean UI components, easy to host as static files.
  - *Negative*: Requires Node.js and NPM build toolchain.

---

## ADR-009: Local-First Development Prior to Cloud (AWS) Provisioning

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  Should cloud infrastructure (AWS/EKS) be introduced from day one or built as an optional extension?
- **Decision**:  
  Follow a **strict Local-First approach**. Build, test, and verify the platform entirely on Kind and local Docker before touching cloud resources. AWS and Terraform are designated as an optional Phase 9 extension.
- **Alternatives Considered**:
  - *Cloud-First (Developing directly on AWS EKS)*: Incurs cloud costs from day one, introduces slow network iterations, IAM complexity, and credential management burdens.
- **Consequences**:
  - *Positive*: Zero cloud billing risk, rapid local feedback loop, accessible offline development.
  - *Negative*: Cloud-specific networking (e.g., AWS ALB, Route53) must be adapted later in Phase 9.

---

## ADR-010: Provisioning Controller Placement and Runtime Model

- **Status**: `PROPOSED`
- **Date**: 2026-10-17
- **Context**:  
  Where should the FastAPI provisioning engine run during local development? Inside the Kind cluster as a pod, or outside the cluster on the host/WSL2 machine?
- **Decision**:  
  Run the provisioning engine **outside the cluster in WSL2** during early phases (connecting via `~/.kube/config`), with the option to containerize and deploy in-cluster once stable.
- **Alternatives Considered**:
  - *In-Cluster Pod from Day One*: Requires rebuilding and reloading the platform image into Kind on every code change, significantly slowing the development feedback loop.
- **Consequences**:
  - *Positive*: Instant code reloading via `uvicorn --reload`, native debugger attachment, fast iteration.
  - *Negative*: Controller networking differs slightly from in-cluster ServiceAccount authentication (addressed in Phase 5).

