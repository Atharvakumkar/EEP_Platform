# Development Phases Roadmap

> [!IMPORTANT]
> **Current Project Status**: **Phase 0 (Requirements and Architecture)**  
> This document defines the sequential roadmap for building the Ephemeral Environment Provisioning Platform. Each phase has explicit boundaries, deliverables, and acceptance criteria. **No phase may begin without explicit approval.**

---

## Roadmap Overview

```
Phase 0: Requirements & Architecture (Current)
   │
   ▼
Phase 1: Development Environment & Kubernetes Foundation (Kind, kubectl)
   │
   ▼
Phase 2: Demo Application & Container Build Pipeline
   │
   ▼
Phase 3: GitHub Integration & Provisioning Engine (Webhook, K8s Deployer)
   │
   ▼
Phase 4: Environment Lifecycle Management (TTL Reaper, Cleanup)
   │
   ▼
Phase 5: Security & Reliability (RBAC, ResourceQuotas, Sandboxing)
   │
   ▼
Phase 6: Backend APIs & Persistent State (PostgreSQL, Audit Logs)
   │
   ▼
Phase 7: Developer Dashboard (React Web UI)
   │
   ▼
Phase 8: Automated Testing & Observability (Metrics, End-to-End Tests)
   │
   ▼
Phase 9: [OPTIONAL] AWS & Terraform Extension (Cloud EKS)
   │
   ▼
Phase 10: Documentation, Demonstration & Project Finalization
```

---

## Phase 0: Requirements and Architecture

- **Identifier**: `PHASE-0`
- **Name**: Requirements, System Architecture, and Documentation Initialization
- **Objective**: Establish the conceptual architecture, development workflow, data lifecycle, technology evaluations, and task logging standards before writing any software.
- **Why Necessary**: Prevents architectural drift, scope creep, and unstructured code creation. Ensures the developer understands Kubernetes concepts and design choices prior to implementation.
- **Scope**:
  - Author comprehensive documentation (`README.md`, `DEVELOPERS-GUIDE.md`, `PROJECT-OVERVIEW.md`, `SYSTEM-ARCHITECTURE.md`, `TECH-STACK.md`, `DEVELOPER-LIFECYCLE.md`, `ARCHITECTURE-DECISIONS.md`).
  - Initialize central and Phase 0 development logs.
  - Define initial `.gitignore` rules.
- **Planned Tasks**:
  - `Task 0.1`: Workspace inspection and `.gitignore` setup.
  - `Task 0.2`: Creation of core documentation suite and architectural diagrams.
  - `Task 0.3`: Verification of documentation integrity, internal links, and ADR consistency.
  - `Task 0.4`: Review and formal user sign-off for Phase 0.
- **Prerequisites & Dependencies**: Clean project workspace.
- **Expected Deliverables**:
  - Complete `docs/` suite.
  - `README.md`.
  - Initial `docs/development-logs/PHASE-0-LOG.md`.
- **Technologies Involved**: Markdown, Mermaid, Git.
- **Acceptance Criteria**:
  - All required documentation files are populated with accurate, honest technical content.
  - No application code or infrastructure manifests are created.
  - Development logs clearly record Phase 0 activities.
- **Testing & Validation Approach**: Review for broken markdown links, markdown syntax errors, and consistency across documents.
- **Potential Risks & Difficulties**: Over-specifying implementation details before validating local tooling.
- **Definition of Done**: Developer reviews documentation suite, resolves open architectural questions, and gives explicit approval.
- **Explicitly Excluded**: Any application code, Python dependencies, Docker builds, or Kubernetes cluster creation.

---

## Phase 1: Development Environment and Kubernetes Foundation

- **Identifier**: `PHASE-1`
- **Name**: Local Development Environment, Tooling Verification, and Kubernetes Cluster Foundation
- **Objective**: Verify WSL2, Docker, and developer tooling; provision and configure a local Kind (Kubernetes in Docker) cluster; verify basic cluster networking and ingress readiness.
- **Why Necessary**: Establishes a reliable, repeatable local Kubernetes sandbox without which deployment testing is impossible.
- **Scope**:
  - Tool availability checks (`docker`, `kind`, `kubectl`, `helm`, `python3`).
  - Configuration of Kind cluster with port mappings (HTTP port 80/8080) for ingress.
  - Installation and verification of Ingress NGINX controller on Kind.
  - Basic namespace creation and verification tests via `kubectl`.
- **Planned Tasks**:
  - `Task 1.1`: Audit and verify host and WSL2 tools.
  - `Task 1.2`: Author Kind cluster configuration (`kind-config.yaml`) with node port forwarding.
  - `Task 1.3`: Create Kind cluster and verify node readiness.
  - `Task 1.4`: Deploy Ingress NGINX and test basic routing.
  - `Task 1.5`: Document cluster management commands and Phase 1 log.
- **Prerequisites & Dependencies**: Phase 0 approval; Docker running on host/WSL2.
- **Expected Deliverables**:
  - `scripts/setup-kind.sh` / `scripts/teardown-kind.sh`.
  - `k8s/kind-config.yaml`.
  - Verified local running Kind cluster.
  - `docs/development-logs/PHASE-1-LOG.md`.
- **Technologies Involved**: WSL2, Bash, Docker, Kind, kubectl, Helm.
- **Acceptance Criteria**:
  - Kind cluster is healthy and accessible via `kubectl get nodes`.
  - Ingress controller pods reach `Running` and `Ready` state.
  - Workload requests on host port 80 route properly to cluster services.
- **Testing & Validation Approach**: Execute `kubectl get nodes -o wide`, `kubectl get pods -A`, and run a curl test against Ingress.
- **Potential Risks & Difficulties**: Docker WSL2 port binding conflicts (ports 80/443 already in use by Windows services).
- **Definition of Done**: Kind cluster is consistently reproducible using automated scripts, and ingress routing is verified.
- **Explicitly Excluded**: Application backend, GitHub webhooks, automated database setup.

---

## Phase 2: Demo Application and Container Build Pipeline

- **Identifier**: `PHASE-2`
- **Name**: Demo Application and Container Build Pipeline
- **Objective**: Create a representative sample web application with health check endpoints, package it as a Docker image, and establish local registry or image loading into Kind.
- **Why Necessary**: The platform needs a predictable, testable workload to deploy and verify in PR preview environments.
- **Scope**:
  - Create a lightweight web application (e.g., Python FastAPI or Node.js) with dynamic environment display, version endpoint, and `/healthz` probe.
  - Write multi-stage `Dockerfile`.
  - Build and tag demo container images.
  - Implement mechanism to load images into the Kind cluster (`kind load docker-image`).
- **Planned Tasks**:
  - `Task 2.1`: Build minimal demo web application with health endpoints.
  - `Task 2.2`: Create optimized `Dockerfile`.
  - `Task 2.3`: Test local container execution and health verification.
  - `Task 2.4`: Establish Kind image loading pipeline.
  - `Task 2.5`: Create reusable Kubernetes deployment & service template for the demo app.
- **Prerequisites & Dependencies**: Phase 1 verified Kind cluster.
- **Expected Deliverables**:
  - `src/demo-app/` source files and `Dockerfile`.
  - `k8s/templates/demo-app-manifest.yaml`.
  - Image loading script.
  - `docs/development-logs/PHASE-2-LOG.md`.
- **Technologies Involved**: Python / FastAPI (or Node.js), Docker, Kubernetes manifests.
- **Acceptance Criteria**:
  - Demo container runs locally and responds `200 OK` on `/healthz`.
  - Container image loads into Kind and deploys successfully into a test namespace.
- **Testing & Validation Approach**: Deploy demo app manually into a scratch namespace and curl its service endpoint.
- **Potential Risks & Difficulties**: Image pulling errors (`ErrImagePull`, `ImagePullBackOff`) in Kind if local image tags are misconfigured.
- **Definition of Done**: Demo app pod runs in Kind and serves traffic through Ingress.
- **Explicitly Excluded**: Automated webhook triggers, multi-microservice meshes.

---

## Phase 3: GitHub Integration and Provisioning Engine

- **Identifier**: `PHASE-3`
- **Name**: GitHub Webhook Ingestion and Core Provisioning Engine
- **Objective**: Build the core FastAPI provisioning service that ingests GitHub `pull_request` webhooks, verifies HMAC signatures, and programmatically provisions Kubernetes namespaces and workloads.
- **Why Necessary**: Forms the central automation backbone that replaces manual cluster operations with automated event-driven provisioning.
- **Scope**:
  - FastAPI webhook endpoint handling `opened`, `reopened`, `synchronize`, and `closed` PR events.
  - Secure HMAC signature validation using shared secret.
  - Kubernetes orchestration service using official Python Kubernetes client.
  - Automated namespace creation (`pr-<num>`), deployment instantiation, and Ingress rule generation.
  - Pod readiness and rollout status polling.
- **Planned Tasks**:
  - `Task 3.1`: Scaffold FastAPI backend application and configuration module.
  - `Task 3.2`: Implement GitHub webhook parser and HMAC validator.
  - `Task 3.3`: Implement Kubernetes provisioning service (create namespace, service, deployment, ingress).
  - `Task 3.4`: Implement readiness verification loop (polling rollout status and HTTP probe).
  - `Task 3.5`: End-to-end simulated webhook test.
- **Prerequisites & Dependencies**: Phase 1 (Kind cluster) & Phase 2 (Demo container image).
- **Expected Deliverables**:
  - `src/backend/` core application.
  - Webhook route and Kubernetes client adapter.
  - Mock webhook trigger script for local testing.
  - `docs/development-logs/PHASE-3-LOG.md`.
- **Technologies Involved**: Python, FastAPI, Pydantic, Kubernetes Python Client, `pytest`.
- **Acceptance Criteria**:
  - Webhook endpoint rejects invalid HMAC signatures (`401 Unauthorized`).
  - Valid `pull_request: opened` payload creates a dedicated namespace and deploys the workload.
  - System polls until the deployment reaches `Ready` state.
- **Testing & Validation Approach**: Send simulated GitHub webhook JSON payloads via `curl` or test script, and verify created Kubernetes resources.
- **Potential Risks & Difficulties**: Handling timeouts during pod startup; handling race conditions if multiple webhooks arrive simultaneously.
- **Definition of Done**: Mock PR webhook triggers end-to-end namespace creation and deployment with verified readiness.
- **Explicitly Excluded**: Database persistence (uses in-memory state initially), TTL reaper daemon.

---

## Phase 4: Environment Lifecycle Management

- **Identifier**: `PHASE-4`
- **Name**: Lifecycle Management, TTL Reaping, and Teardown Automation
- **Objective**: Implement automated teardown of environments upon PR closure or merge, and build a background time-to-live (TTL) expiration engine to prevent orphaned preview environments.
- **Why Necessary**: Prevents resource leaks and ensures preview environments are truly ephemeral.
- **Scope**:
  - PR `closed` webhook handler triggering graceful resource destruction.
  - TTL background reaper task (checking environment expiration timestamps).
  - Graceful namespace deletion and orphaned resource cleanup.
  - Idempotent cleanup logic (safe against repeated calls).
- **Planned Tasks**:
  - `Task 4.1`: Implement namespace teardown service.
  - `Task 4.2`: Wire PR `closed` webhook event to teardown service.
  - `Task 4.3`: Implement TTL scheduler / periodic background reaper in Python.
  - `Task 4.4`: Validate TTL expiration and PR closure cleanup under simulated scenarios.
- **Prerequisites & Dependencies**: Phase 3 working provisioning engine.
- **Expected Deliverables**:
  - Lifecycle manager service module.
  - Background reaper worker.
  - `docs/development-logs/PHASE-4-LOG.md`.
- **Technologies Involved**: Python, `asyncio`, Kubernetes Python Client.
- **Acceptance Criteria**:
  - Closing a PR triggers complete deletion of the associated namespace.
  - Environments exceeding TTL (e.g., set to 15 minutes for testing) are automatically reaped.
  - Subsequent webhooks for deleted environments fail gracefully without crashing.
- **Testing & Validation Approach**: Trigger PR close event; test TTL expiration by advancing or setting short TTL thresholds.
- **Potential Risks & Difficulties**: Namespaces stuck in `Terminating` state due to lingering finalizers or hung resources.
- **Definition of Done**: Verified teardown on both PR closure and TTL expiry with clean cluster state.
- **Explicitly Excluded**: External cloud DNS cleanup.

---

## Phase 5: Security, Isolation, and Reliability

- **Identifier**: `PHASE-5`
- **Name**: Security Hardening, Resource Governance, and Sandboxing
- **Objective**: Secure preview environments by enforcing Kubernetes RBAC, `ResourceQuota`, `LimitRange`, and basic network isolation.
- **Why Necessary**: Prevents untrusted pull request code from consuming excessive cluster resources or compromising neighboring workloads.
- **Scope**:
  - ServiceAccount and RBAC definitions with least privilege for the provisioning engine.
  - Default `ResourceQuota` per preview namespace (CPU, memory, pod count).
  - `LimitRange` for default container requests/limits.
  - Basic NetworkPolicy to restrict cross-namespace traffic.
- **Planned Tasks**:
  - `Task 5.1`: Define dedicated ServiceAccount, Role, and RoleBinding for the platform.
  - `Task 5.2`: Attach `ResourceQuota` and `LimitRange` to dynamically created namespaces.
  - `Task 5.3`: Define baseline NetworkPolicy restricting preview namespace egress/ingress.
  - `Task 5.4`: Stress-test resource constraints with a resource-hungry test pod.
- **Prerequisites & Dependencies**: Phase 4 functional lifecycle engine.
- **Expected Deliverables**:
  - `k8s/base/rbac.yaml`.
  - Security and quota templates in provisioning engine.
  - `docs/development-logs/PHASE-5-LOG.md`.
- **Technologies Involved**: Kubernetes RBAC, ResourceQuotas, NetworkPolicies.
- **Acceptance Criteria**:
  - Provisioning engine operates under its own restricted ServiceAccount.
  - Pods requesting resources above quota are throttled/rejected by the admission controller.
  - Cross-namespace network requests between preview environments are blocked.
- **Testing & Validation Approach**: Attempt to deploy a pod requesting 10 CPU cores and confirm admission rejection.
- **Potential Risks & Difficulties**: Ingress controller unable to reach preview pods if NetworkPolicies are overly restrictive.
- **Definition of Done**: Cluster and namespaces enforce quotas and policies without breaking legitimate preview traffic.
- **Explicitly Excluded**: Cloud IAM integration, OIDC federation.

---

## Phase 6: Backend APIs and Persistent State

- **Identifier**: `PHASE-6`
- **Name**: Relational Persistence and RESTful Management APIs
- **Objective**: Replace in-memory state with a PostgreSQL database to reliably track environment lifecycles, historical transitions, and operational audit logs; expose REST APIs for environment management.
- **Why Necessary**: In-memory state is lost on server restart; production platform engineering requires auditability, recovery, and persistence.
- **Scope**:
  - PostgreSQL container setup in Kind or local Docker.
  - SQLAlchemy models and Alembic migrations for Environments, AuditLogs, and Events.
  - CRUD REST APIs for listing, inspecting, extending TTL, and manually deleting preview environments.
- **Planned Tasks**:
  - `Task 6.1`: Configure PostgreSQL database and Alembic migrations.
  - `Task 6.2`: Define data models (`Environment`, `LifecycleEvent`, `AuditLog`).
  - `Task 6.3`: Refactor provisioning and teardown services to commit state transitions to DB.
  - `Task 6.4`: Implement REST API endpoints for environment querying and manual management.
- **Prerequisites & Dependencies**: Phase 4 & Phase 5.
- **Expected Deliverables**:
  - Database schema and Alembic migrations.
  - REST API router (`/api/v1/environments`).
  - Integration test suite for DB operations.
  - `docs/development-logs/PHASE-6-LOG.md`.
- **Technologies Involved**: PostgreSQL, SQLAlchemy, Alembic, FastAPI, Pydantic.
- **Acceptance Criteria**:
  - Server restart preserves all active environment states and scheduled TTLs.
  - State transitions (`PENDING` -> `PROVISIONING` -> `READY` -> `CLEANED_UP`) are recorded with timestamps.
- **Testing & Validation Approach**: Restart FastAPI service while an environment is active and verify state is restored.
- **Potential Risks & Difficulties**: Database connection pool exhaustion under concurrent webhook bursts.
- **Definition of Done**: All environment operations are transactionally persisted and queryable via REST APIs.
- **Explicitly Excluded**: Complex user authorization/OAuth2 login (deferred to Phase 7/future).

---

## Phase 7: Developer Dashboard

- **Identifier**: `PHASE-7`
- **Name**: Self-Service Developer Web Dashboard
- **Objective**: Develop a modern, lightweight single-page web application (React) allowing developers and operators to visualize active preview environments, inspect rollout statuses, view preview URLs, and manually trigger cleanup or TTL extensions.
- **Why Necessary**: Delivers the self-service developer experience, removing the need for developers to run `kubectl` commands directly.
- **Scope**:
  - React + Vite + TailwindCSS application.
  - Environment list view with real-time status indicators (chips for `READY`, `PROVISIONING`, `FAILED`).
  - Environment detail modal (preview URL, commit SHA, PR link, remaining TTL).
  - Action buttons: "Extend TTL (+1 hr)" and "Delete Environment".
- **Planned Tasks**:
  - `Task 7.1`: Scaffold React + Vite application.
  - `Task 7.2`: Build Environment Table and status badge components.
  - `Task 7.3`: Connect frontend to backend REST APIs.
  - `Task 7.4`: Implement manual TTL extension and delete actions with confirmation dialogs.
- **Prerequisites & Dependencies**: Phase 6 REST APIs.
- **Expected Deliverables**:
  - `src/frontend/` source code.
  - Production build and local dev server setup.
  - `docs/development-logs/PHASE-7-LOG.md`.
- **Technologies Involved**: React, TypeScript/JavaScript, Vite, TailwindCSS, Axios/Fetch.
- **Acceptance Criteria**:
  - Dashboard renders active environments retrieved from the backend API.
  - Clicking "Extend TTL" updates remaining time in UI and database.
  - Deleting an environment updates status to `CLEANING_UP` and removes row upon completion.
- **Testing & Validation Approach**: Manual UI testing and end-to-end browser verification against live backend.
- **Potential Risks & Difficulties**: CORS issues between local Vite dev server and FastAPI backend.
- **Definition of Done**: Dashboard renders live environments and executes actions reliably.
- **Explicitly Excluded**: Multi-tenant team management or role-based user authentication.

---

## Phase 8: Automated Testing, Observability, and Health Probes

- **Identifier**: `PHASE-8`
- **Name**: Automated Test Suite, Structured Logging, and Metrics
- **Objective**: Implement comprehensive automated testing across the platform and integrate structured JSON logging and basic Prometheus metrics for platform observability.
- **Why Necessary**: Ensures long-term maintainability, prevents regressions, and provides operational visibility into cluster utilization and webhook latencies.
- **Scope**:
  - End-to-end integration test runner simulating complete PR lifecycles.
  - Structured JSON logging with request correlation IDs across the backend.
  - Basic Prometheus metrics endpoint (`/metrics`) exposing active environment counts and provisioning durations.
- **Planned Tasks**:
  - `Task 8.1`: Author end-to-end test suite (`pytest`) against Kind.
  - `Task 8.2`: Implement structured JSON logger with correlation IDs.
  - `Task 8.3`: Add Prometheus metrics instrumentation (`prometheus-fastapi-instrumentator`).
  - `Task 8.4`: Run automated test suite and record benchmark performance.
- **Prerequisites & Dependencies**: Phases 1–7.
- **Expected Deliverables**:
  - `src/backend/tests/e2e/`.
  - Logging and metrics configuration.
  - `docs/development-logs/PHASE-8-LOG.md`.
- **Technologies Involved**: `pytest`, Prometheus client, Python logging.
- **Acceptance Criteria**:
  - Automated test suite executes PR open -> ready -> close cycle and asserts 100% clean teardown.
  - `/metrics` exposes `eep_active_environments` and `eep_provision_duration_seconds`.
- **Testing & Validation Approach**: Run `pytest src/backend/tests/e2e` in WSL2 and scrape `/metrics`.
- **Potential Risks & Difficulties**: Flaky tests due to Kubernetes pod startup latencies.
- **Definition of Done**: All automated tests pass consistently and metrics accurately report system state.
- **Explicitly Excluded**: Grafana dashboard provisioning (left optional).

---

## Phase 9: [OPTIONAL] AWS and Terraform Extension

- **Identifier**: `PHASE-9`
- **Name**: Cloud Extension: AWS EKS and Terraform Infrastructure as Code
- **Objective**: Optionally extend the platform architecture to provision and manage preview environments in a managed cloud Kubernetes cluster (AWS EKS) using Terraform.
- **Why Necessary**: Demonstrates how local platform engineering patterns translate to production cloud infrastructure.
- **Scope**:
  - Terraform modules for VPC, subnets, and AWS EKS cluster.
  - AWS IAM Roles for Service Accounts (IRSA).
  - External-DNS and AWS Load Balancer Controller integration.
- **Planned Tasks**:
  - `Task 9.1`: Author Terraform modules for AWS VPC and EKS.
  - `Task 9.2`: Configure AWS credentials and Terraform plan validation.
  - `Task 9.3`: Test cluster provisioning and deploy EEP platform into AWS.
  - `Task 9.4`: Test preview URL generation with route53 / public domain.
- **Prerequisites & Dependencies**: Phase 8 completion; AWS account with billing limits; explicit developer approval.
- **Expected Deliverables**:
  - `terraform/` directory with modular HCL configurations.
  - `docs/development-logs/PHASE-9-LOG.md`.
- **Technologies Involved**: Terraform, AWS (VPC, EKS, Route53, IAM), Helm.
- **Acceptance Criteria**:
  - Terraform plan executes cleanly.
  - Platform provisions preview workloads on real AWS EKS nodes.
- **Testing & Validation Approach**: Dry-run via `terraform plan` and isolated AWS staging deployment.
- **Potential Risks & Difficulties**: Cloud infrastructure costs, complex AWS IAM networking.
- **Definition of Done**: Complete cloud lifecycle verified with immediate teardown to prevent costs.
- **Explicitly Excluded**: Running live cloud workloads continuously; multi-region failover.

---

## Phase 10: Documentation, Demonstration, and Project Finalization

- **Identifier**: `PHASE-10`
- **Name**: Project Finalization, Demonstration Walkthrough, and Retrospective
- **Objective**: Consolidate all project documentation, record end-to-end demonstration runs, author troubleshooting and operational runbooks, and perform a final architectural retrospective.
- **Why Necessary**: Delivers a polished, professional portfolio project with reproducible demonstration evidence and clear operational guidance.
- **Scope**:
  - Complete architectural retrospective comparing planned vs. actual outcomes.
  - Comprehensive troubleshooting runbook.
  - Step-by-step demonstration walkthrough guide with reproduction scripts.
  - Final validation of all documentation links and development logs.
- **Planned Tasks**:
  - `Task 10.1`: Complete end-to-end verification walkthrough.
  - `Task 10.2`: Author operational troubleshooting runbook.
  - `Task 10.3`: Perform final documentation audit and update README with verified badges.
  - `Task 10.4`: Review project achievements against original Phase 0 goals.
- **Prerequisites & Dependencies**: Phases 1–8 (and optionally Phase 9).
- **Expected Deliverables**:
  - `docs/RUNBOOK.md`.
  - `docs/DEMO-GUIDE.md`.
  - Finalized central development log.
  - `docs/development-logs/PHASE-10-LOG.md`.
- **Technologies Involved**: Markdown, Git.
- **Acceptance Criteria**:
  - Entire platform can be spun up from scratch by following the demonstration guide.
  - All phase logs are marked with accurate final statuses.
- **Testing & Validation Approach**: Perform fresh checkout and execute setup from end to end.
- **Potential Risks & Difficulties**: Undocumented environment dependencies.
- **Definition of Done**: Project is verified, documented, and approved for demonstration.
- **Explicitly Excluded**: Ongoing production operations.

