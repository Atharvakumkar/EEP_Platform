# Technology Stack Evaluation & Selection

> [!NOTE]
> **Status**: Proposed Technology Stack (Phase 0)  
> This document evaluates each proposed technology for the Ephemeral Environment Provisioning Platform, establishing its role, rationale, architectural placement, lifecycle tier (Core MVP vs. Extension), and trade-offs.

---

## Technology Stack Overview

| Category | Technology | Tier | Placement |
| :--- | :--- | :--- | :--- |
| **Control Plane Runtime** | Python 3.11+ | Core MVP | Webhook handler, state machine, background reaper |
| **API Framework** | FastAPI | Core MVP | Ingestion endpoint & REST management API |
| **Containerization** | Docker | Core MVP | Application packaging & Kind cluster node host |
| **Local Kubernetes Engine** | Kind (Kubernetes in Docker) | Core MVP | Local development Kubernetes cluster |
| **Cluster CLI** | `kubectl` | Core MVP | Cluster management, inspection, and verification |
| **Package Manager** | Helm | Core MVP | Deploying cluster add-ons (Ingress NGINX) |
| **Source Control & VCS** | GitHub | Core MVP | Repository hosting, PR triggers, webhook emission |
| **CI / Automation** | GitHub Actions | Core MVP | Code linting, test suites, container image builds |
| **Persistence Store** | PostgreSQL 16 | Core MVP | Environment lifecycle state, events, audit trails |
| **Developer UI** | React (Vite + TailwindCSS) | Core MVP | Self-service web dashboard for developers |
| **Container Registry** | Local Registry / GHCR | Core MVP | Distributing demo application container images |
| **Cloud Infrastructure** | AWS (EKS, VPC) | *Optional Extension* | Cloud production preview environments (Phase 9) |
| **Infrastructure as Code** | Terraform | *Optional Extension* | Automated cloud cluster provisioning (Phase 9) |

---

## Detailed Technology Evaluations

### 1. Python 3.11+
- **Intended Responsibility**: Primary programming language for the platform backend, orchestration logic, and automation scripts.
- **Why It Is Appropriate**: Python offers excellent mature libraries for interacting with the Kubernetes API (`kubernetes-client`), robust asynchronous support via `asyncio`, and clean readability for developers learning platform engineering.
- **Where It Fits**: Powers the core provisioning engine service, webhook parsers, and background reaper daemons.
- **Tier**: **Core MVP**.
- **Trade-offs**: Slower execution speed compared to Go or Rust, but execution speed is not the bottleneck; Kubernetes API latency and network I/O dominate provisioning time.

---

### 2. FastAPI
- **Intended Responsibility**: Asynchronous web framework for the webhook receiver and REST management endpoints.
- **Why It Is Appropriate**: Automatic OpenAPI documentation, high performance with `uvicorn`, native Pydantic data validation for webhook schemas, and native `async`/`await` support.
- **Where It Fits**: Entry point for GitHub webhooks and developer dashboard REST queries.
- **Tier**: **Core MVP**.
- **Trade-offs**: Lightweight and modular, but requires manual structuring for large background worker tasks.

---

### 3. Docker
- **Intended Responsibility**: Container engine used to build application images and host Kind cluster nodes.
- **Why It Is Appropriate**: Industry standard for containerization; seamlessly integrated with Windows via WSL2.
- **Where It Fits**: Workstation runtime environment supporting both application packaging and local Kubernetes nodes.
- **Tier**: **Core MVP**.
- **Trade-offs**: Resource consumption on developer workstations; must be properly configured with WSL2 memory bounds.

---

### 4. Kind (Kubernetes in Docker)
- **Intended Responsibility**: Local Kubernetes cluster running directly inside Docker containers.
- **Why It Is Appropriate**: Extremely lightweight, fast to spin up and tear down, natively supports multi-node and custom port-forwarding configurations, and requires no virtualization hypervisors outside of Docker.
- **Where It Fits**: The local execution sandbox for all preview environments and platform services.
- **Tier**: **Core MVP**.
- **Trade-offs**: Networking and ingress behavior can require specific port-forwarding configs compared to cloud load balancers.

---

### 5. kubectl
- **Intended Responsibility**: Official command-line tool for controlling Kubernetes clusters.
- **Why It Is Appropriate**: Essential for cluster diagnostics, inspection, manual verification, and debugging.
- **Where It Fits**: Used by developers and scripts in WSL2 to inspect namespaces, pods, and ingress rules.
- **Tier**: **Core MVP**.
- **Trade-offs**: None; standard tool for any Kubernetes workflow.

---

### 6. Helm
- **Intended Responsibility**: Kubernetes package manager.
- **Why It Is Appropriate**: Standard method for installing complex third-party cluster components such as Ingress NGINX with well-tested defaults.
- **Where It Fits**: Used in Phase 1 to install cluster-level ingress controllers and shared dependencies.
- **Tier**: **Core MVP**.
- **Trade-offs**: Can add templating complexity; for simple demo app deployments, raw YAML or lightweight Kustomize is preferred over Helm.

---

### 7. GitHub & GitHub Actions
- **Intended Responsibility**: Source code hosting, pull request lifecycle management, webhook emission, and automated CI pipelines.
- **Why It Is Appropriate**: GitHub is the default collaboration platform; its webhook ecosystem is robust and realistic. GitHub Actions allows automated building of container images on PR creation.
- **Where It Fits**: External trigger initiating all platform workflows.
- **Tier**: **Core MVP**.
- **Trade-offs**: In local-only testing without public IP exposition, webhooks must be delivered via tools like `ngrok` or simulated with local scripts.

---

### 8. PostgreSQL
- **Intended Responsibility**: Relational database for environment records, state transitions, TTL expirations, and audit logs.
- **Why It Is Appropriate**: ACID compliance prevents race conditions during state transitions; robust JSONB support allows storing flexible webhook payload metadata and diagnostic logs.
- **Where It Fits**: Data persistence layer queried by the FastAPI engine and TTL reaper daemon.
- **Tier**: **Core MVP** (introduced in Phase 6).
- **Trade-offs**: Adds a dependency compared to in-memory SQLite, but SQLite suffers from concurrency locks in multi-worker environments.

---

### 9. React (Vite + TailwindCSS)
- **Intended Responsibility**: Single-page developer self-service dashboard.
- **Why It Is Appropriate**: Fast iteration with Vite, component-driven design, and responsive styling with TailwindCSS. Provides an accessible UI for viewing active environments and logs.
- **Where It Fits**: Frontend user interface interacting with the FastAPI REST API.
- **Tier**: **Core MVP** (Phase 7).
- **Trade-offs**: Introduces Node.js / NPM build toolchain, but decoupled from backend operations.

---

### 10. Container Registry (Local Registry / GHCR)
- **Intended Responsibility**: Storing and distributing demo application container images for cluster nodes to pull.
- **Why It Is Appropriate**: Allows Kind nodes to pull built images. Alternately, `kind load docker-image` can be used to bypass the registry for completely offline development.
- **Where It Fits**: Artifact pipeline between container build and Kubernetes deployment.
- **Tier**: **Core MVP** (Phase 2).
- **Trade-offs**: Local registry requires managing a registry container; `kind load` is simpler for single-node setups. (See ADR-002).

---

### 11. [Optional] AWS (EKS, VPC)
- **Intended Responsibility**: Managed cloud Kubernetes cluster and networking infrastructure.
- **Why It Is Appropriate**: Validates production readiness and cloud platform engineering patterns.
- **Where It Fits**: Phase 9 cloud extension.
- **Tier**: **Optional Extension** (Phase 9).
- **Trade-offs**: Incurs real cloud billing costs, increases complexity, and requires cloud credential management.

---

### 12. [Optional] Terraform
- **Intended Responsibility**: Infrastructure as Code (IaC) tool to declaratively provision AWS VPC, subnets, and EKS clusters.
- **Why It Is Appropriate**: Industry standard for repeatable cloud infrastructure provisioning.
- **Where It Fits**: Phase 9 cloud extension.
- **Tier**: **Optional Extension** (Phase 9).
- **Trade-offs**: Unnecessary for local Kind MVP; strictly isolated to Phase 9.

