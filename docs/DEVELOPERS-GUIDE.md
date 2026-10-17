# Developer's Guide

> [!NOTE]
> **Status**: Documentation & Planning Phase  
> This guide outlines the development philosophy, environment requirements, contribution standards, and verification workflow for the Ephemeral Environment Provisioning Platform. **No implementation commands should be executed until Phase 0 is approved.**

---

## 1. Project Development Philosophy

The Ephemeral Environment Provisioning Platform is built under three foundational engineering principles:

1. **Pedagogical Clarity**: The codebase, architecture, and documentation are designed to be thoroughly understandable to developers learning Kubernetes, platform engineering, and automation. Complex patterns are introduced progressively.
2. **Local-First Reliability**: We build and verify a complete, reliable local MVP (using Kind, local registries, and Docker) before introducing cloud complexity or managed services.
3. **Evidence-Based Engineering**: Functionality is never declared working based on assumption. Every component must be accompanied by reproducible tests, observable outputs, and transparent logging.

---

## 2. Guided-Development Workflow

Development proceeds as a structured partnership between the developer and the AI assistant:

- **Incremental Steps**: Work is divided into small, logically bounded tasks rather than monolithic code dumps.
- **Explicit Reviews**: Each major architectural decision, technology introduction, and phase transition requires explicit user review and approval.
- **Architectural Integrity**: The assistant does not silently alter project scope, introduce speculative dependencies, or bypass established workflows.
- **Continuous Documentation**: Documentation and development logs are updated alongside implementation, recording both successes and troubleshooting steps.

---

## 3. Expected Development Environment

The development workstation configuration is:

- **Host Operating System**: Windows 10/11
- **Host Shell**: PowerShell 7+ (or Windows PowerShell 5.1)
- **Linux Subsystem**: WSL2 (Windows Subsystem for Linux), specifically Ubuntu 22.04 LTS or later
- **Container Engine**: Docker Desktop with WSL2 backend integration, or Docker Engine running directly inside WSL2
- **Developer Kubernetes Level**: Beginner to intermediate

---

## 4. Windows, PowerShell, and WSL2 Considerations

Developing across Windows and WSL2 requires careful boundary management to avoid pathing bugs, permission issues, and execution mismatches.

### Environment-Specific Command Labeling
Every command provided in documentation, logs, or guides must be explicitly marked with its target execution shell:

- `[PowerShell]`: Windows host commands (e.g., managing Windows host processes, launching Docker Desktop).
- `[WSL2 / Linux]`: Commands executed inside Ubuntu bash/zsh (e.g., `kubectl`, `kind`, `helm`, Python virtual environments, and bash scripts).

### Path Separation
- **Windows Paths**: Use standard Windows drive notation and backslashes (e.g., `C:\Programming\EEP_Platform`).
- **Linux / WSL2 Paths**: Mounts access the Windows drive via `/mnt/c/` (e.g., `/mnt/c/Programming/EEP_Platform`), while Linux home directory paths reside in `/home/<username>/`.
- **Guideline**: Do not mix Windows and Linux paths in scripts or commands without explicitly documenting the path translation. When running Kubernetes commands and Python code in WSL2, work within the WSL2 filesystem or properly mapped mount paths.

### Tool Execution Location
To avoid cross-environment latency and path translation issues:
- Kubernetes CLI tools (`kind`, `kubectl`, `helm`) should be installed and executed **inside WSL2**.
- Docker CLI can run in both, but socket communication must be verified inside WSL2.
- Python development environments (virtualenvs) and backend processes will run **inside WSL2**.

---

## 5. Expected Tools and Intended Responsibilities

When implementation begins, the following tools will be verified and utilized:

| Tool | Execution Environment | Intended Responsibility |
| :--- | :--- | :--- |
| **Docker** | Host / WSL2 | Container runtime, building container images, hosting local Kind nodes. |
| **Kind** | WSL2 (Linux) | Creating and managing local Kubernetes clusters running in Docker containers. |
| **kubectl** | WSL2 (Linux) | Direct CLI communication, inspection, and manipulation of Kubernetes cluster resources. |
| **Helm** | WSL2 (Linux) | Package management for complex cluster components (e.g., Ingress NGINX). |
| **Python 3.11+** | WSL2 (Linux) | Runtime for the provisioning engine, API server, and automated orchestration scripts. |
| **FastAPI** | WSL2 (Linux) | Asynchronous web framework for handling GitHub webhooks and REST endpoints. |
| **PostgreSQL** | Docker / K8s | Persistent relational store for environment metadata, TTLs, and audit logs. |
| **Git & GitHub** | Host / WSL2 | Source control, pull request triggers, and automated CI pipelines. |

> [!WARNING]
> Tools must **never** be assumed to be installed. In Phase 1, each tool will be checked using verification commands before any operational tasks depend on it.

---

## 6. Planned Repository Organization

Once implementation commences in later phases, the repository will adhere to this structured layout:

```
EEP_Platform/
├── README.md                      # Project overview and public entry point
├── .gitignore                     # Git ignore rules
│
├── docs/                          # Architecture, lifecycle, and developer documentation
│   ├── PROJECT-OVERVIEW.md
│   ├── DEVELOPERS-GUIDE.md
│   ├── DEVELOPMENT-PHASES.md
│   ├── DEVELOPER-LIFECYCLE.md
│   ├── SYSTEM-ARCHITECTURE.md
│   ├── TECH-STACK.md
│   ├── ARCHITECTURE-DECISIONS.md
│   ├── DEVELOPMENT-LOG.md
│   └── development-logs/
│       └── PHASE-0-LOG.md
│
├── src/                           # Application source code (created in later phases)
│   ├── backend/                   # FastAPI provisioning engine and API
│   │   ├── app/
│   │   │   ├── api/               # Webhook handlers and API routers
│   │   │   ├── core/              # Configuration, logging, security
│   │   │   ├── models/            # SQLAlchemy / Pydantic data models
│   │   │   ├── services/          # K8s orchestrator, TTL manager, GitHub service
│   │   │   └── main.py            # FastAPI entry point
│   │   └── tests/                 # Unit and integration tests
│   │
│   ├── frontend/                  # React developer dashboard (Phase 7)
│   │   ├── src/
│   │   └── package.json
│   │
│   └── demo-app/                  # Sample microservice/web app used for PR deployments
│       ├── Dockerfile
│       └── app.py
│
├── k8s/                           # Kubernetes manifests and Helm charts
│   ├── base/                      # Common K8s manifests (RBAC, namespaces)
│   ├── templates/                 # Environment deployment templates
│   └── charts/                    # Helm charts for platform services
│
├── scripts/                       # Local developer utility and setup scripts
│   ├── setup-kind.sh
│   └── teardown-kind.sh
│
└── .github/                       # GitHub Actions workflows
    └── workflows/
        └── ci.yml
```

*Note: Directory trees under `src/`, `k8s/`, and `scripts/` will be created incrementally during their respective phases.*

---

## 7. Coding and Configuration Conventions

### Python & Backend Standards
- **Python Version**: Python 3.11+.
- **Type Annotations**: Comprehensive type hints across all functions and classes.
- **Data Validation**: Strict Pydantic models for request/response payloads, configuration settings, and state transitions.
- **Linting & Formatting**: Follow PEP 8 standards using `ruff` or `flake8` and `black`.
- **Async Operations**: Use asynchronous endpoints and non-blocking I/O where appropriate, particularly for HTTP webhooks and external API calls.

### Kubernetes Manifest Conventions
- **Labels**: Every Kubernetes resource must include consistent standard labels:
  - `app.kubernetes.io/name`: Name of the workload.
  - `app.kubernetes.io/instance`: Pull request environment identifier (e.g., `pr-42`).
  - `app.kubernetes.io/managed-by`: `eep-platform`.
  - `eep.platform/pr-number`: Target GitHub PR number.
  - `eep.platform/expires-at`: ISO 8601 UTC timestamp of scheduled TTL expiration.
- **Resource Limits**: All deployment manifests must explicitly specify `requests` and `limits` for CPU and memory.

---

## 8. Git and GitHub Workflow

- **Branching Strategy**:
  - `main`: Production-ready, stable codebase.
  - `phase-<number>-<name>`: Feature branches for active development phases.
  - `fix/<issue-description>`: Targeted bug fixes.
- **Commit Messages**: Conventional Commit formatting:
  - `docs: initialize phase 0 architecture documentation`
  - `feat(k8s): add namespace provisioning service`
  - `fix(ttl): correct UTC timestamp parsing for expiration`
- **Pull Request Review**: Changes will be accompanied by descriptive PR summaries explaining what was implemented, how it was verified, and relevant log updates.

---

## 9. Task Breakdown Methodology

To prevent cognitive overload and maintain strict quality control, all work is decomposed into discrete tasks:

1. **Atomic Scope**: Each task addresses a single clear objective (e.g., "Implement webhook HMAC verification" or "Create Kind cluster config").
2. **Explicit Prerequisites**: Tasks state exactly what files, services, or preceding tasks must be in place.
3. **Execution Plan**: A step-by-step sequence is established before modifying code or configurations.
4. **Validation Check**: A verifiable action (running a test, executing a CLI check) concludes every task.

---

## 10. Task Documentation Requirements

Every meaningful task must be recorded in its phase-specific development log with the following schema:

1. **Task Identifier & Title**: e.g., `Task 1.2: Kind Cluster Provisioning`.
2. **Objective**: What the task accomplishes.
3. **Rationale**: Why the task is necessary.
4. **Prerequisites**: Required prior states or dependencies.
5. **Planned Actions**: Steps planned prior to execution.
6. **Actual Actions**: Exact steps carried out.
7. **Commands Executed**: Full commands run, including environment labels.
8. **Files Modified/Created**: Links to all affected files.
9. **Implementation Decisions**: Key technical trade-offs made during the task.
10. **Validation Results**: Concrete evidence of success (test output, status checks).
11. **Errors Encountered**: Failures or unexpected behaviors observed.
12. **Root Cause Analysis**: Why the failure occurred.
13. **Fix Applied**: How the issue was resolved.
14. **Current Status**: `NOT STARTED`, `IN PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `TESTED`, `VERIFIED`, or `DEFERRED`.
15. **Limitations**: Known remaining constraints.
16. **Next Step**: The recommended subsequent action.

---

## 11. Testing and Validation Expectations

The project enforces an evidence-based testing policy:

- **Unit Testing**: Business logic, webhook validation, and TTL calculations must have unit tests.
- **Integration Testing**: Interfacing with the Kubernetes API, Docker daemon, and PostgreSQL must be validated against real or containerized instances.
- **End-to-End Testing**: Provisioning, deployment, readiness verification, and TTL cleanup must be verified end-to-end against the local Kind cluster.
- **Zero Fabrication**: Test outputs and status reports must reflect actual execution results. Never fabricate command logs or test assertions.

---

## 12. Error Reporting and Troubleshooting Policy

Errors and unexpected failures are valuable learning opportunities:

- **Do Not Hide Errors**: Failed commands or runtime exceptions must be documented in the development log along with terminal output.
- **Structured Troubleshooting**:
  1. Capture raw error output.
  2. Diagnose root cause (configuration, network, permission, or code defect).
  3. Formulate and review fix.
  4. Apply fix and re-run verification.
  5. Document resolution in the task log.

---

## 13. Secret Management Principles

- **No Hardcoded Secrets**: API tokens, webhook secrets, database passwords, and cryptographic keys must **never** be placed in git-tracked files.
- **Environment Variables**: Local secrets must be supplied via uncommitted `.env` files (excluded via `.gitignore`) or command-line environment injection.
- **Kubernetes Secrets**: In-cluster credentials must be stored as native Kubernetes `Secret` objects.

---

## 14. Security Expectations

- **Workload Sandboxing**: Untrusted PR code must run in isolated namespaces with restrictive RBAC.
- **Webhook Authenticity**: All incoming GitHub webhook payloads must be verified using HMAC-SHA256 signatures before processing.
- **Resource Constraints**: Cluster namespaces must enforce `ResourceQuota` and `LimitRange` to protect the host against resource exhaustion or denial-of-service.

---

## 15. Rules for Changing Architectural Decisions

When an agreed architectural direction must be revised:
1. Document the proposed change in [docs/ARCHITECTURE-DECISIONS.md](ARCHITECTURE-DECISIONS.md) with status `PROPOSED`.
2. Detail the context, trade-offs, and downstream impacts.
3. Discuss and seek explicit developer approval before altering established code or configurations.
4. Update the ADR status to `ACCEPTED` or `REJECTED` following review.

---

## 16. Phase Approval Requirements

No phase of development may begin until:
1. The preceding phase has met all its acceptance criteria and definition of done.
2. A formal Phase Plan has been presented with tasks, dependencies, and validation criteria.
3. The developer has explicitly given approval to proceed.

---

## 17. Definition of Done for Individual Tasks

A task is marked **VERIFIED** only when:
- [ ] Planned code or configuration changes are completely implemented.
- [ ] Code adheres to formatting, linting, and typing standards.
- [ ] Unit or integration tests covering the task pass successfully.
- [ ] The task log in the development log is updated with actual commands and outputs.
- [ ] No regression is introduced to existing functionality.

---

## 18. Definition of Done for a Major Phase

A major phase is considered **COMPLETE** only when:
- [ ] All mandatory phase tasks are in `VERIFIED` status.
- [ ] Phase acceptance criteria defined in [docs/DEVELOPMENT-PHASES.md](DEVELOPMENT-PHASES.md) are satisfied.
- [ ] Phase development log is finalized and reviewed.
- [ ] The central development log is updated.
- [ ] Formal review and sign-off are provided by the developer.

---

## 19. Keeping Documentation Synchronized

Documentation must reflect reality:
- When a command changes, update the guide.
- When an architecture assumption evolves, update the architecture document.
- Never defer documentation updates to the end of a milestone; update documentation immediately upon completing the task.

---

## 20. How Future Contributors Get Started (Post-Phase 0)

Once Phase 0 is approved and implementation commences:
1. Review [docs/PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md) and [docs/SYSTEM-ARCHITECTURE.md](SYSTEM-ARCHITECTURE.md).
2. Follow Phase 1 instructions for setting up the local Kind cluster and WSL2 tooling.
3. Check [docs/DEVELOPMENT-LOG.md](DEVELOPMENT-LOG.md) for current sprint status and active tasks.
4. Execute tests inside WSL2 before submitting pull requests.

