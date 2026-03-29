---
name: minikube-troubleshooter
description: 'Diagnose and fix recurring Minikube operational issues in this repo, including ImagePullBackOff, probe failures, chart config errors, and startup timeouts.'
argument-hint: 'Provide the symptom, target service, and OS if known.'
user-invocable: true
---

# Minikube Troubleshooter

Use this skill to run a focused diagnose -> fix -> verify loop.

## When to Use
- Pods CrashLoopBackOff, ImagePullBackOff, or pending
- RabbitMQ management is unreachable
- MongoDB readiness/liveness instability
- Init scripts fail due to timeout or environment mismatch
- KEDA or autoscaling behavior is not as expected

## Procedure
1. Gather facts
- Collect pod status, events, logs, and recent script output.

2. Match known issue patterns
- Compare evidence against known repository issues.

3. Apply minimal fix
- Update only required values/template/script blocks.

4. Re-validate
- Re-run affected commands and service checks.

5. Communicate outcome
- Root cause, exact file changes, and what still needs monitoring.

## References
- [Known Issues and Fix Paths](./references/known-issues.md)
