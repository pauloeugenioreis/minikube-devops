# Validation Checklist

Use this checklist as command guidance during validation workflows.

## Windows
1. Structure check
```powershell
.\windows-test-structure.ps1
```

2. Basic runtime state
```powershell
minikube status
kubectl get pods -A
kubectl get svc -A
```

3. Optional quick checks
```powershell
.\scripts\windows\maintenance\quick-status.ps1
.\scripts\windows\maintenance\validate-rabbitmq-config.ps1
```

## Linux
1. Structure check
```bash
bash linux-test-structure.sh
```

2. Basic runtime state
```bash
minikube status
kubectl get pods -A
kubectl get svc -A
```

3. Optional quick checks
```bash
bash scripts/linux/maintenance/quick-status.sh
bash scripts/linux/maintenance/validate-rabbitmq-config.sh
```

## Service-focused checks
```bash
kubectl get scaledobject -A
kubectl get hpa -A
kubectl get pods -n keda
```

## Classification
- PASS: command succeeds and status is healthy
- WARN: command succeeds with non-blocking warnings
- FAIL: command fails or workload not ready
