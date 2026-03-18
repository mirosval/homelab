# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Kubernetes manifests (nixidy)
```bash
make check-manifests      # Validate nixidy definitions without writing (dry-run build)
make generate-manifests   # Generate k3s/generated_manifests/ from k3s/definitions/
make lint                 # Run statix + deadnix on all .nix files
make check                # nix flake check
```

### NixOS nodes
```bash
make nixos-switch-homelab-01   # Build + switch homelab-01 remotely
make nixos-switch-homelab-02   # Build + switch homelab-02 remotely
make nixos-switch-homelab-03   # Build + switch homelab-03 remotely
```

Never run any `nixos-anywhere-*` or `nixos-switch-*` commands without explicit permission.

### Helm chart hash

When adding a new helm chart, just leave `chartHash = ""` and copy the expected hash from the build error.

## Architecture

This is a NixOS-based homelab with a 3-node k3s cluster managed via [nixidy](https://github.com/arnarg/nixidy) (GitOps with ArgoCD).

### Two layers of configuration

**1. NixOS hosts** (`hosts/`)
- `hosts/homelab/configuration.nix` — shared NixOS config for all 3 cluster nodes (networking, k3s, hardware)
- `hosts/homelab-{01,02,03}/` — per-node hardware config and disk layout
- `hosts/tv/` — standalone NixOS machine (not in the cluster)
- Node IPs: homelab-01=`10.42.0.4`, homelab-02=`10.42.0.5`, homelab-03=`10.42.0.6`

**2. Kubernetes workloads** (`k3s/`)
- `k3s/definitions/*.nix` — nixidy app definitions (source of truth)
- `k3s/generated_manifests/` — output YAML committed to git, read by ArgoCD
- `k3s/definitions/default.nix` — imports all app definitions and sets the ArgoCD target repo/branch

### How nixidy works

Each file in `k3s/definitions/` exports an `applications.<name>` attrset using the nixidy DSL. nixidy renders these to Kubernetes YAML in `k3s/generated_manifests/<app-name>/`. ArgoCD then applies the generated YAML from the git repo.

Key DSL patterns:
- `helm.releases.<name>.chart = lib.helm.downloadHelmChart { repo; chart; version; chartHash; }` — fetches and renders a Helm chart
- `helm.releases.<name>.values = { ... }` — Helm values in Nix syntax
- `resources.<kind>s.<name>` — raw Kubernetes resources (deployments, services, ingressRoutes, etc.) in Nix syntax
- `lib.mkForce` — override values (used for patching Helm-generated resources)

### Infrastructure components

| Component | Purpose |
|-----------|---------|
| **Traefik** | Ingress controller. All services use `IngressRoute` (Traefik CRD) + a stub `Ingress` (for tooling compatibility). IngressRoute service port must match the Service's `.spec.ports[].port`, not the `targetPort`. |
| **Longhorn** | Distributed block storage (`storageClass = "longhorn"`) |
| **SMB CSI driver** | Mounts NAS shares as PVs (photos, immich library) |
| **CloudNativePG** | PostgreSQL operator. Databases defined as `resources.clusters.<name>.spec`. The generated secret `<cluster>-app` or `<cluster>-superuser` contains connection details. |
| **MetalLB** | Load balancer for bare-metal (IP pool: `10.42.1.0/24`) |
| **SealedSecrets** | Encrypts secrets for GitOps. Raw secrets are never committed. |
| **ArgoCD** | Applies generated manifests from the `main` branch of this repo. |
| **cert-manager** | TLS via Let's Encrypt. CertResolver `letsencrypt` used in IngressRoutes. |

### CRD type definitions

`lib/generated/` contains Nix type definitions generated from CRDs (metallb, traefik, cnpg, cert-manager). Regenerate with:
```bash
make clean-nixidy-resources
make generate-nixidy-resources
```

### Renovate

`renovate.json` has two custom regex managers:
1. **Helm charts** — matches `lib.helm.downloadHelmChart` blocks with `https://` repos, auto-updates `version`
2. **Container images** — matches `image = "..."` strings in `.nix` files

OCI-based helm charts (`oci://`) are not picked up by Renovate's custom manager and must be updated manually.

### Domain

All services are exposed at `*.doma.lol` via Traefik on the `websecure` entrypoint.
