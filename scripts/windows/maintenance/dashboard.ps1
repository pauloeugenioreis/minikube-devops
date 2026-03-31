# Diagnostico e Correcao Completa do Dashboard K8s
# Resolve problemas de port-forward e permissoes RBAC (erro 404 em CronJobs)

# ==============================================================================
# Carregar Utilitarios Basicos
# ==============================================================================
$commonScript = Join-Path (Split-Path $PSScriptRoot -Parent) "utils\common.ps1"
if (Test-Path $commonScript) { . $commonScript } else { Write-Warning "common.ps1 nao encontrado!" }

Write-Status "====================================================="
Write-Success "DIAGNOSTICO E CORRECAO DO DASHBOARD"
Write-Status "====================================================="

# 1. Verificar Minikube
Write-Status "`nVerificando conectividade Minikube..."
try {
    $status = minikube status 2>$null
    if (!($status -like "*Running*")) {
        Write-ErrorMsg "Minikube nao esta rodando! Execute: minikube start"
        exit 1
    }
} catch {
    Write-ErrorMsg "Problema ao checar o minikube!"
    exit 1
}

# 2. Verificar Dashboard e Servicos
Write-Status "`nVerificando pods do Dashboard..."
$dashboardPods = kubectl get pods -n kubernetes-dashboard --no-headers 2>$null
if ($dashboardPods) {
    $dashboardPods | ForEach-Object {
        $parts = $_ -split '\s+'
        $name = $parts[0]
        $statusPod = $parts[2]
        if ($statusPod -eq "Running") {
            Write-Success "$name - $statusPod"
        } else {
            Write-Warning "$name - $statusPod"
        }
    }
} else {
    Write-ErrorMsg "Nenhum pod encontrado. Verifique se o addon esta habilitado (minikube addons enable dashboard)"
    exit 1
}

# 3. Aplicar Patch RBAC para CronJobs (Erro 404)
Write-Status "`nAplicando patch RBAC para CronJobs..."
$rbacYaml = @"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kubernetes-dashboard-cronjob-fix
  labels:
    k8s-app: kubernetes-dashboard
rules:
  - apiGroups: ["batch"]
    resources: ["cronjobs", "jobs", "cronjobs/status", "jobs/status"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch/v1", "batch/v1beta1"]
    resources: ["cronjobs", "jobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events", "pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard-cronjob-fix
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubernetes-dashboard-cronjob-fix
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard
"@

try {
    $rbacFile = Join-Path $env:TEMP "dashboard-rbac-fix.yaml"
    $rbacYaml | Out-File -FilePath $rbacFile -Encoding UTF8
    
    $result = kubectl apply -f $rbacFile 2>&1
    Write-Status "RBAC: $result"
    Remove-Item $rbacFile -Force 2>$null
} catch {
    Write-Warning "Falha ao aplicar RBAC extra: $($_.Exception.Message)"
}

# 4. Refazer Port-forwards
Write-Status "`nTestando conectividade e corrigindo port-forward..."
$dashboardTest = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue

if ($dashboardTest) {
    Write-Success "Porta 15671 ja esta ACESSIVEL."
} else {
    Write-Warning "Porta 15671 NAO ACESSIVEL. TENTANDO CORRIGIR..."
    
    Get-Process kubectl -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*kubernetes-dashboard*" -or $_.CommandLine -like "*15671*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Status "Aguardando Dashboard estar pronto..."
    kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=60s 2>$null | Out-Null
    
    Write-Status "Criando novo port-forward na porta 15671..."
    Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "15671:80" -WindowStyle Hidden
    
    Start-Sleep -Seconds 5
    $dashboardTest2 = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue
    
    if ($dashboardTest2) {
        Write-Success "CORRIGIDO! Dashboard agora acessivel"
    } else {
        Write-ErrorMsg "Ainda com problemas. Verifique manualmente."
    }
}

Write-Status "`n====================================================="
if ($dashboardTest -or $dashboardTest2) {
    Write-Success "Dashboard 100% Funcional"
    Write-Status "URL: http://localhost:15671"
} else {
    Write-ErrorMsg "Dashboard com problemas de acesso local"
}
Write-Status "====================================================="
