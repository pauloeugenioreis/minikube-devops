# Known Issues and Fix Paths

This file maps common symptoms to first checks and likely fixes.

## RabbitMQ plugin config error
Symptom:
- Pod fails with plugin file parse errors.

Checks:
```bash
kubectl logs deploy/rabbitmq
kubectl describe pod -l app.kubernetes.io/name=rabbitmq
```

Likely fix:
- Validate plugin and config formatting in chart templates and values.
- Re-deploy chart with corrected values.

## MongoDB readiness instability or OOM
Symptom:
- Repeated restarts, readiness probe failures, OOMKilled events.

Checks:
```bash
kubectl get pods -l app.kubernetes.io/name=mongodb
kubectl describe pod -l app.kubernetes.io/name=mongodb
```

Likely fix:
- Increase memory requests/limits and tune probe timings in chart values/template.

## ImagePullBackOff on cluster services
Symptom:
- Pods pending due to image pull failures.

Checks:
```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
```

Likely fix:
- Ensure image tag is valid.
- Pre-load required image into Minikube image cache when scripts support it.

## Port-forward conflicts
Symptom:
- Script cannot bind expected local ports.

Checks:
```powershell
netstat -ano | findstr "15672 5672 27017"
```
```bash
ss -lntp | grep -E "15672|5672|27017"
```

Likely fix:
- Stop conflicting processes and restart the relevant monitoring/init script.

## KEDA not scaling
Symptom:
- ScaledObject exists but no scale activity.

Checks:
```bash
kubectl get scaledobject -A
kubectl describe scaledobject <name> -n <namespace>
kubectl get hpa -A
kubectl logs -n keda deploy/keda-operator
```

Likely fix:
- Validate trigger metadata, namespace, auth, queue endpoint, and workload selectors.

## Verification after any fix
```bash
kubectl get pods -A
kubectl get svc -A
kubectl get events -A --sort-by=.metadata.creationTimestamp
```
