# Phase 1 Development Log: Development Environment & Kubernetes Foundation

> [!NOTE]
> **Phase Status**: `IN PROGRESS`  
> This log records the actual actions, commands, outputs, errors, and verifications performed during Phase 1: Local Development Environment, Tooling Verification, and Kubernetes Cluster Foundation.

---

## 1. Phase Metadata

- **Phase ID**: `PHASE-1`
- **Phase Name**: Development Environment, Tooling Verification, and Kubernetes Cluster Foundation
- **Start Date**: 2026-10-19
- **Completion Date**: —
- **Primary Goal**: Audit host/WSL2 developer tools, configure and spin up a local Kind Kubernetes cluster with ingress port mappings, install Ingress NGINX, and verify cluster readiness.

---

## 2. Phase Acceptance Criteria Status

| Acceptance Criteria | Verification Method | Status |
| :--- | :--- | :---: |
| Host and WSL2 tool audit completed (Docker, kind, kubectl, helm, python3) | CLI version and status checks | `VERIFIED` |
| Declarative Kind configuration authored with port 8080/8443 mappings | File review of `k8s/kind-config.yaml` | `VERIFIED` |
| Kind cluster provisioned and node status reports `Ready` | `kubectl get nodes -o wide` | `VERIFIED` |
| Ingress NGINX controller deployed and controller pods reach `Ready` | `kubectl get pods -n ingress-nginx` | `VERIFIED` |
| Host port 8080 routing to Kind cluster ingress verified | HTTP probe (`curl -I http://localhost:8080`) | `VERIFIED` |
| Repeatable setup and teardown helper scripts created | Script execution test | `VERIFIED` |
| Phase 1 tasks documented with commands and outputs | Phase 1 log review | `VERIFIED` |

---

## 3. Detailed Task Records

### Task 1.1: Tool Availability & Environment Audit
- **Task ID**: `TASK-1.1`
- **Objective**: Check and record the presence, versions, and runtime status of required tools in Windows (PowerShell) and WSL2 (Ubuntu).
- **Why Necessary**: Avoid broken assumptions; ensure Docker is reachable from WSL2 and identify which Kubernetes CLI tools need installation.
- **Prerequisites**: Windows 10/11 with WSL2 Ubuntu and Docker Desktop or Docker Engine.
- **Planned Actions**:
  1. Check WSL2 distribution status via PowerShell (`wsl -l -v`).
  2. Check Docker version and daemon responsiveness in PowerShell and WSL2 (`docker version`, `docker info`).
  3. Check existence of `kind`, `kubectl`, `helm`, and `python3` inside WSL2 Ubuntu.
  4. Document findings and prescribe exact installation steps for any missing tools.
- **Actual Actions**:
  1. Executed `wsl -l -v` via PowerShell: confirmed `Ubuntu` (v2, default) and `docker-desktop` (v2) are installed, currently `Stopped`.
  2. Executed `docker version`: Client 29.6.2 present, but Docker daemon/engine was initially not running (`open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified`).
  3. Audited WSL2 Ubuntu tools: confirmed `Ubuntu 24.04.4 LTS` and `Python 3.12.3` are present; native Linux `kind`, `kubectl`, and `helm` were missing from `/usr/local/bin`.
  4. Docker Desktop was started and verified working from both PowerShell and WSL2 (`docker ps` returned code 0).
  5. Native Linux `kubectl` (v1.37.1) downloaded and installed to `/usr/local/bin/kubectl`.
  6. Native Linux `kind` (v0.27.0) downloaded and installed to `/usr/local/bin/kind`.
  7. Helm download initially failed with `curl: (18) Transferred a partial file` due to network drop; resolved by downloading with `--retry 5` and installing `helm` (v3.17.1) to `/usr/local/bin/helm`.
  8. Executed unified verification check in WSL2 confirming all tools operate natively without errors.
- **Commands Executed**:
  ```powershell
  # [PowerShell] Audit WSL distributions
  wsl -l -v

  # [PowerShell] Check Docker version and daemon responsiveness
  docker version

  # [PowerShell -> WSL2] Check Ubuntu version and installed tools
  wsl -d Ubuntu bash -c "lsb_release -a; python3 --version"
  wsl -d Ubuntu bash -c "which docker kind kubectl helm python3 git curl jq"

  # [PowerShell] Check Windows host Kubernetes tools
  Get-Command kind, kubectl, helm -ErrorAction SilentlyContinue | Select-Object Name, Source
  kind version; kubectl version --client

  # [WSL2 / Linux] Install native tools
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
  sudo install -o root -g root -m 0755 ./kind /usr/local/bin/kind
  curl -fLo /tmp/helm.tar.gz --retry 5 https://get.helm.sh/helm-v3.17.1-linux-amd64.tar.gz
  tar -zxvf /tmp/helm.tar.gz -C /tmp/ && sudo install -o root -g root -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm

  # [WSL2 / Linux] Complete tool verification as standard user
  docker ps
  kubectl version --client
  kind version
  helm version
  ```
- **Files Created/Modified**:
  - `docs/development-logs/PHASE-1-LOG.md`
- **Validation**:
  - Docker daemon is running and communicates with WSL2 Ubuntu (`docker ps` exit code 0).
  - `kubectl` client version: `v1.37.1` verified.
  - `kind` version: `v0.27.0` verified.
  - `helm` version: `v3.17.1` verified.
  - `python3` version: `3.12.3` verified.
- **Errors Encountered**:
  - Docker daemon initially stopped (`open //./pipe/dockerDesktopLinuxEngine`).
  - Helm script failed with `curl: (18) Transferred a partial file` due to transient network interruption during large tarball download.
- **Root Cause & Fix**:
  - Docker Desktop application started.
  - Helm archive downloaded with resilient curl flags (`--retry 5`), extracted, and installed directly.
- **Current Status**: `VERIFIED`
- **Next Task**: `TASK-1.2` (Author Kind Cluster Configuration with Ingress Port Mappings).

---

### Task 1.2: Author Kind Cluster Configuration with Ingress Port Mappings
- **Task ID**: `TASK-1.2`
- **Objective**: Author a declarative Kind cluster specification (`k8s/kind-config.yaml`) configuring a single control-plane node with extra port mappings for Ingress (8080 -> 80, 8443 -> 443) and an `ingress-ready=true` node label.
- **Why Necessary**: Enables the cluster to run Ingress NGINX and expose preview environments to the Windows host browser without conflicting with existing Windows services on port 80.
- **Prerequisites**: Task 1.1 complete. Host port availability audited (confirmed port 80 in use by IIS `W3SVC`; ports 8080/8443 free).
- **Planned Actions**:
  1. Create `k8s/kind-config.yaml`.
  2. Configure cluster name `eep-cluster`.
  3. Inject `ingress-ready=true` node label via `kubeadmConfigPatches`.
  4. Map hostPort `8080` to containerPort `80`, and hostPort `8443` to containerPort `443`.
- **Actual Actions**:
  - Authored `k8s/kind-config.yaml` using `write_to_file`.
  - Configured TCP port forwardings: `8080:80` and `8443:443`.
- **Commands Executed**: None (declarative manifest authoring).
- **Files Created/Modified**:
  - [`k8s/kind-config.yaml`](../../k8s/kind-config.yaml)
  - `docs/development-logs/PHASE-1-LOG.md`
- **Validation**:
  - Verified YAML syntax and schema against Kind v1alpha4 specification.
- **Errors Encountered**: None.
- **Current Status**: `VERIFIED`
- **Next Task**: `TASK-1.3` (Kind Cluster Creation and Node Readiness Verification).

---

### Task 1.3: Kind Cluster Creation and Node Readiness Verification
- **Task ID**: `TASK-1.3`
- **Objective**: Execute cluster creation using Kind inside WSL2 Ubuntu and verify that the single-node control plane attains `Ready` status with the `ingress-ready=true` label applied.
- **Why Necessary**: Provides the live Kubernetes runtime environment needed to host all subsequent ephemeral preview namespaces and Ingress routing controllers.
- **Prerequisites**: Task 1.1 and Task 1.2 complete. Docker Desktop running.
- **Planned Actions**:
  1. Execute `kind create cluster --config /mnt/c/Programming/EEP_Platform/k8s/kind-config.yaml` inside WSL2 Ubuntu.
  2. Verify cluster context via `kubectl cluster-info`.
  3. Inspect node status via `kubectl get nodes -o wide`.
  4. Verify the `ingress-ready=true` node label via `kubectl get nodes -L ingress-ready`.
  5. Verify all system pods in `kube-system` reach `Running` and `Ready`.
- **Actual Actions**:
  - Ran `kind create cluster --config /mnt/c/Programming/EEP_Platform/k8s/kind-config.yaml` inside WSL2 Ubuntu.
  - Successfully pulled `kindest/node:v1.32.2` and bootstrapped the `eep-cluster-control-plane` container.
  - Port forwardings confirmed bound on Windows host: `8080->80/tcp`, `8443->443/tcp`, and API server on `127.0.0.1:39763->6443/tcp`.
  - Executed node and pod verification commands in WSL2 Ubuntu.
- **Commands Executed**:
  ```bash
  # [WSL2 / Linux] Create Kind cluster
  kind create cluster --config /mnt/c/Programming/EEP_Platform/k8s/kind-config.yaml

  # [WSL2 / Linux] Verify node status and ingress label
  kubectl get nodes -o wide
  kubectl get nodes -L ingress-ready

  # [WSL2 / Linux] Verify cluster pods
  kubectl get pods -A
  ```
- **Files Created/Modified**:
  - `docs/development-logs/PHASE-1-LOG.md`
- **Validation Results**:
  - Node `eep-cluster-control-plane` reports `STATUS: Ready`, Kubernetes version `v1.32.2`.
  - Node label `INGRESS-READY: true` verified.
  - System pods (`coredns`, `etcd`, `kindnet`, `kube-apiserver`, `kube-controller-manager`, `kube-proxy`, `kube-scheduler`, `local-path-provisioner`) are all `1/1 Running`.
- **Errors Encountered**: None.
- **Current Status**: `VERIFIED`
- **Next Task**: `TASK-1.4` (Deploy Ingress NGINX and Verify Routing).

---

### Task 1.4: Deploy Ingress NGINX and Verify Ingress Routing
- **Task ID**: `TASK-1.4`
- **Objective**: Deploy the official Ingress NGINX controller for Kind and verify that HTTP traffic on Windows host port 8080 routes into the cluster's ingress controller.
- **Why Necessary**: Acts as the reverse proxy that will route preview environment URLs (`http://localhost:8080` or `http://pr-*.local:8080`) to isolated pull-request application services.
- **Prerequisites**: Task 1.3 complete. Cluster `eep-cluster` active with port 8080 forwarded to container port 80.
- **Planned Actions**:
  1. Apply Ingress NGINX manifest: `https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml`.
  2. Wait for `ingress-nginx-controller` pod to reach `Ready` status.
  3. Probe `http://localhost:8080` from WSL2 Ubuntu and Windows PowerShell.
  4. Verify NGINX default backend 404 response.
- **Actual Actions**:
  - Applied manifest via `kubectl apply -f ...`. All namespaces, CRDs, deployments, roles, and admission webhooks created cleanly.
  - Executed `kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s`.
  - Condition met: `ingress-nginx-controller-76f9746865-2dbdh` reached `1/1 Running`.
  - Executed `curl -I http://localhost:8080` in WSL2: received `HTTP/1.1 404 Not Found`.
  - Executed `curl.exe -s http://localhost:8080` in PowerShell: received NGINX 404 HTML body (`<center>nginx</center>`).
- **Commands Executed**:
  ```bash
  # [WSL2 / Linux] Deploy Ingress NGINX
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

  # [WSL2 / Linux] Wait for controller readiness
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

  # [WSL2 / Linux] Verify ingress controller pod
  kubectl get pods -n ingress-nginx -o wide

  # [WSL2 / Linux] Probe HTTP routing
  curl -I http://localhost:8080

  # [PowerShell] Probe HTTP routing from Windows host
  curl.exe -I http://localhost:8080
  curl.exe -s http://localhost:8080
  ```
- **Files Created/Modified**:
  - `docs/development-logs/PHASE-1-LOG.md`
- **Validation Results**:
  - Ingress NGINX controller pod is `1/1 Running` and `Ready` on node `eep-cluster-control-plane`.
  - HTTP requests hitting Windows host port `8080` routed into Kind and returned NGINX 404 default backend.
- **Errors Encountered**: None.
- **Current Status**: `VERIFIED`
- **Next Task**: `TASK-1.5` (Cluster Automation Helper Scripts).

---

### Task 1.5: Repeatable Cluster Automation Helper Scripts
- **Task ID**: `TASK-1.5`
- **Objective**: Author automated helper shell scripts (`scripts/setup-kind.sh` and `scripts/teardown-kind.sh`) for idempotent cluster lifecycle operations.
- **Why Necessary**: Enables the developer or any contributor to reliably spin up or destroy the local Kubernetes foundation with a single command.
- **Prerequisites**: Tasks 1.1–1.4 complete and verified.
- **Planned Actions**:
  1. Author `scripts/setup-kind.sh`: checks prerequisites, creates cluster if absent, applies Ingress NGINX, and waits for readiness.
  2. Author `scripts/teardown-kind.sh`: checks if cluster exists and deletes it cleanly via Kind.
  3. Make scripts executable (`chmod +x`).
  4. Test idempotency by running `setup-kind.sh` against the running cluster.
- **Actual Actions**:
  - Created `scripts/setup-kind.sh` and `scripts/teardown-kind.sh`.
  - Set executable permissions via `chmod +x`.
  - Executed `setup-kind.sh`: confirmed it detects existing cluster, ensures ingress, and reports healthy cluster state.
- **Commands Executed**:
  ```bash
  # [WSL2 / Linux] Set script permissions
  chmod +x scripts/setup-kind.sh scripts/teardown-kind.sh

  # [WSL2 / Linux] Test setup script idempotency
  ./scripts/setup-kind.sh
  ```
- **Files Created/Modified**:
  - [`scripts/setup-kind.sh`](../../scripts/setup-kind.sh)
  - [`scripts/teardown-kind.sh`](../../scripts/teardown-kind.sh)
  - `docs/development-logs/PHASE-1-LOG.md`
- **Validation Results**:
  - Script correctly detected running cluster and reported readiness with exit code 0.
- **Errors Encountered**: None.
- **Current Status**: `VERIFIED`
- **Next Task**: Phase 1 Final Review and Sign-Off.



