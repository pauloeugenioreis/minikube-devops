---
name: minikube-validation
description: 'Validate this repository after chart/script changes. Use for structure checks, env checks, service readiness, and pre-commit verification on Windows and Linux.'
argument-hint: 'Describe what changed and target OS: windows, linux, or both.'
user-invocable: true
---

# Minikube Validation

Run a consistent validation workflow after any relevant change.

## When to Use
- After editing Helm charts under `charts/`
- After changing startup, maintenance, or monitoring scripts
- Before commit/push for infra-impacting changes

## Procedure
1. Determine target platform
- If user changed only Windows scripts, run Windows path first.
- If user changed only Linux scripts, run Linux path first.
- If shared config/chart changed, run both.

2. Structure validation
- Windows: run the repository structure test.
- Linux: run the Linux structure test.

3. Runtime validation
- Check Minikube and Kubernetes status.
- Check main workloads and services (RabbitMQ, MongoDB, Redis, KEDA when enabled).

4. Port and ingress sanity
- Validate expected ports and management endpoint reachability.

5. Report
- Mark each area as PASS, WARN, or FAIL.
- Include exact failing command output and next action.

## References
- [Validation Checklist](./references/checklist.md)
