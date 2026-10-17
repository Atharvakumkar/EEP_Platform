# Project Overview

> [!NOTE]
> **Status**: Proposed / Planning Phase (Phase 0)  
> This document establishes the foundational problem statement, target audiences, use cases, project goals, boundaries, and open questions for the **Ephemeral Environment Provisioning Platform**.

---

## 1. Project Purpose

The purpose of the **Ephemeral Environment Provisioning Platform** is to deliver a developer self-service automation engine that dynamically provisions, verifies, exposes, and decommissions isolated application environments on Kubernetes in direct response to GitHub pull request lifecycles.

Instead of treating environment management as a manual or static chore handled by dedicated operations teams, the platform models environments as short-lived, automated artifacts tied directly to git branches.

---

## 2. Problem Being Solved

In conventional development workflows, testing pull requests in realistic environments creates severe friction:

1. **Shared Staging Bottlenecks**:
   - Multiple developers and feature branches merge into or compete for a single static "staging" or "QA" environment.
   - When one developer's branch introduces a breaking bug or schema migration, the shared environment becomes unusable for the entire engineering organization.
2. **Local Environment Inconsistencies**:
   - Running complex multi-container systems locally via Docker Compose or Minikube taxes developer laptops, consumes battery, and often fails to replicate actual Kubernetes network topologies, ingress rules, service discovery, and security constraints.
3. **Infrastructure Waste & Zombie Environments**:
   - When teams manually spin up preview instances in cloud environments, developers frequently forget to destroy them after PR merge, accumulating unnecessary cloud costs indefinitely.
4. **Stakeholder Feedback Delays**:
   - Product managers, UX designers, and QA engineers cannot easily inspect in-progress work without checking out Git branches, installing language toolchains, and running code locally.

---

## 3. Intended Users & Personas

| Persona | Role | Primary Need | Platform Value |
| :--- | :--- | :--- | :--- |
| **Software Developer** | Authors feature PRs | Fast feedback on how code runs in a realistic Kubernetes environment. | Zero manual cluster setup; automatic preview URL on every PR push. |
| **QA Engineer** | Tests PR functionality | Isolated, repeatable testing environment free from concurrent branch contamination. | Dedicated environment running the exact commit SHA under test. |
| **Product Manager / Designer** | Reviews UX & acceptance criteria | Visual inspection of new features without technical toolchains. | One-click clickable preview URL posted as a PR comment. |
| **Platform Engineer** | Manages cluster resources & stability | Guardrails preventing cost overruns and cluster resource starvation. | Automatic TTL reaping, namespace resource quotas, and auditability. |

---

## 4. Primary Use Cases

1. **Feature Verification & Collaborative Review**:
   - A developer opens a PR with a new UI component. The platform deploys the branch to an isolated namespace and posts a preview URL to the PR. Product and design review the live app directly.
2. **Automated End-to-End Testing**:
   - Automated testing suites (Cypress, Playwright, or API test suites) run against the dedicated ephemeral preview URL before PR merge.
3. **High-Fidelity Bug Reproduction**:
   - A bug reported in production is reproduced in a PR branch with debug logging enabled, verified in its own isolated cluster environment without affecting staging or production.
4. **Automated Teardown & Cost Containment**:
   - When the PR is merged or closed, all allocated Kubernetes resources (namespaces, deployments, services, ingress) are instantly and automatically destroyed. If a PR remains open and idle, a TTL reaper reclaims cluster capacity.

---

## 5. Proposed Core Features

- **Webhook Event Ingestion**: Listens for GitHub `pull_request` events (`opened`, `synchronize`, `closed`, `reopened`) with cryptographic HMAC validation.
- **Dynamic Kubernetes Namespace Provisioning**: Generates dedicated namespaces labeled with PR metadata and expiration timestamps.
- **Automated Workload Deployment**: Applies deployment, service, and routing configurations dynamically tailored to the PR build.
- **Readiness & Health Verification**: Waits for pod readiness gates and conducts HTTP health probe checks before declaring the environment ready.
- **Preview Endpoint Publication**: Generates predictable routing endpoints (e.g., `http://pr-42.preview.local` or port-mapped routes) and reports status.
- **Automated Cleanup**: Deletes namespaces immediately upon PR merge or closure.
- **Time-to-Live (TTL) Reaper**: Background daemon identifying and reclaiming stale environments whose TTL has elapsed.
- **Persistent State & Audit Logs**: Relational tracking (PostgreSQL) of all environment transitions and lifecycle operations.
- **Developer Dashboard**: Web UI to inspect active environments, preview URLs, remaining TTLs, and trigger manual cleanup or extensions.

---

## 6. Project Goals

1. **Full Lifecycle Automation**: Move beyond simple "deployment scripts" by automating the full lifecycle: create, verify, expose, manage TTL, and delete.
2. **Local-First, Kubernetes-First Architecture**: Deliver a fully functional, reproducible system on a local workstation using Kind before introducing cloud dependencies.
3. **Educational Depth**: Provide clean, idiomatic architecture and well-documented rationale to serve as an educational reference for platform engineering.
4. **Resilience & Safe Failure Modes**: Ensure errors (e.g., crashing pods, invalid images, failed health checks) are surfaced clearly and do not leave orphaned resources.

---

## 7. Out-of-Scope Functionality (Initial MVP)

To maintain focus and ensure a reliable, working foundation, the following items are explicitly **out of scope** for the initial MVP:

- Immediate production cloud infrastructure (AWS/EKS is deferred to Phase 9).
- Complex stateful database cloning or production database sanitization pipelines for preview environments.
- Multi-cluster orchestration across geographic regions.
- Commercial single sign-on (SSO) or multi-tenant organizational billing.
- Service mesh implementations (Istio / Linkerd).

---

## 8. Success Criteria

The project will be considered successful when:

1. Opening a simulated or real GitHub PR automatically results in an isolated Kubernetes namespace running the PR's container image within 60 seconds (local cluster).
2. The platform correctly holds preview publication until the deployment passes health probes.
3. A preview URL is generated and accessible via a web browser.
4. Closing the PR triggers automated, clean destruction of all created Kubernetes objects with zero orphaned resources.
5. Environments exceeding their configured TTL are automatically terminated by the background reaper daemon.
6. The entire local platform can be started and verified from scratch by a newcomer following the developer guide.

---

## 9. Known Assumptions

- The host environment runs Docker Desktop or Docker Engine inside WSL2 Ubuntu on Windows.
- The local Kubernetes cluster is Kind (Kubernetes in Docker).
- The initial target application is a lightweight web service with an HTTP health probe.
- Local ingress routing will rely on port-forwarding or local DNS resolution (e.g., `.local` domains mapped via hosts file or localhost port mapping).

---

## 10. Open Questions Requiring Future Decisions

The following architectural questions are tracked in [docs/ARCHITECTURE-DECISIONS.md](ARCHITECTURE-DECISIONS.md) and will be decided during Phase 0 / Phase 1:

1. **Local Domain Resolution**: Should preview URLs use localhost port mappings (e.g., `http://localhost:8080/pr-42/`) or subdomain path-based host headers (e.g., `http://pr-42.local:8080`) requiring local hosts file entries?
2. **Container Image Distribution**: Should container images be loaded directly into Kind via `kind load docker-image` or served via a local Docker container registry (e.g., `localhost:5001`) attached to the Kind network?
3. **Database Timing**: Should persistent PostgreSQL state be introduced in Phase 3 alongside the provisioning engine or deferred to Phase 6 while keeping early phases lightweight with in-memory state?

