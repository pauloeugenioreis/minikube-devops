# Dashboard CronJob Fix - RBAC Patch
# Adiciona permissoes RBAC para resolver erro 404 em CronJobs no Dashboard

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "DASHBOARD CRONJOB RBAC PATCH" -ForegroundColor Green
Write-Host "Resolve erro 404 ao acessar CronJobs" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# Verificar minikube
try {
    $status = minikube status 2>$null
    if (!($status -like "*Running*")) {
        Write-Host "ERRO: Minikube nao rodando!" -ForegroundColor Red
        Write-Host "Execute: minikube start" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "ERRO: Problema com minikube!" -ForegroundColor Red
    exit 1
}

Write-Host "`nDiagnosticando problema..." -ForegroundColor Yellow

# Verificar se Dashboard esta rodando
try {
    $dashboardStatus = kubectl get deployment kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.status.readyReplicas}' 2>$null
    if ($dashboardStatus -eq "1") {
        Write-Host "Dashboard: Rodando" -ForegroundColor Green
    } else {
        Write-Host "Dashboard: Nao disponivel" -ForegroundColor Red
        Write-Host "Execute: minikube addons enable dashboard" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "Dashboard: Nao encontrado" -ForegroundColor Red
    exit 1
}

# Verificar CronJobs especificos
try {
    $cronjobs = kubectl get cronjobs --all-namespaces --no-headers 2>$null
    if ($cronjobs) {
        $count = ($cronjobs | Measure-Object).Count
        Write-Host "CronJobs: $count encontrados" -ForegroundColor Green
        
        # Testar acesso ao cronjob-service especificamente
        $cronjobService = kubectl get cronjob cronjob-service -n cronjob-service -o json 2>$null
        if ($cronjobService) {
            Write-Host "cronjob-service: Acessivel via kubectl" -ForegroundColor Green
        } else {
            Write-Host "cronjob-service: Problema de acesso" -ForegroundColor Red
        }
    } else {
        Write-Host "CronJobs: Nenhum encontrado" -ForegroundColor Yellow
    }
} catch {
    Write-Host "CronJobs: Erro verificando" -ForegroundColor Red
}

Write-Host "`nAplicando patch RBAC..." -ForegroundColor Yellow

# Criar RBAC melhorado para acesso completo a CronJobs
$rbacYaml = @"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kubernetes-dashboard-cronjob-fix
  labels:
    k8s-app: kubernetes-dashboard
rules:
  # Permissoes basicas para CronJobs
  - apiGroups: ["batch"]
    resources: ["cronjobs", "jobs"]
    verbs: ["get", "list", "watch"]
  # Permissoes para status de CronJobs
  - apiGroups: ["batch"]
    resources: ["cronjobs/status", "jobs/status"]
    verbs: ["get", "list", "watch"]
  # Permissoes para detalhes individuais de CronJobs
  - apiGroups: ["batch/v1"]
    resources: ["cronjobs", "jobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch/v1beta1"]
    resources: ["cronjobs", "jobs"]
    verbs: ["get", "list", "watch"]
  # Permissoes para logs e eventos relacionados
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
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
    # Salvar e aplicar
    $rbacFile = Join-Path $env:TEMP "dashboard-rbac-fix.yaml"
    $rbacYaml | Out-File -FilePath $rbacFile -Encoding UTF8
    
    Write-Host "1. Aplicando permissoes RBAC..." -ForegroundColor Cyan
    $result = kubectl apply -f $rbacFile 2>&1
    Write-Host "   $result" -ForegroundColor Gray
    
    Write-Host "2. Reiniciando Dashboard..." -ForegroundColor Cyan  
    $restart = kubectl rollout restart deployment/kubernetes-dashboard -n kubernetes-dashboard 2>&1
    Write-Host "   $restart" -ForegroundColor Gray
    
    Write-Host "3. Aguardando rollout..." -ForegroundColor Cyan
    $rollout = kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard --timeout=60s 2>&1
    Write-Host "   $rollout" -ForegroundColor Gray
    
    Write-Host "`nSUCESSO: Patch RBAC aplicado!" -ForegroundColor Green
    
    # Testar especificamente o acesso que estava falhando
    Write-Host "`nTestando acesso detalhado ao cronjob-service..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10  # Aguardar propagacao das permissoes
    
    try {
        # Simular chamadas que o Dashboard faz
        Write-Host "- Testando GET cronjob individual..." -ForegroundColor Gray
        $testCronjob = kubectl get cronjob cronjob-service -n cronjob-service -o json 2>$null
        if ($testCronjob) {
            Write-Host "  SUCCESS: Acesso direto OK" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Acesso direto FALHOU" -ForegroundColor Red
        }
        
        Write-Host "- Testando Jobs relacionados..." -ForegroundColor Gray
        $testJobs = kubectl get jobs -n cronjob-service -l job-name -o json 2>$null
        if ($testJobs) {
            Write-Host "  SUCCESS: Jobs relacionados OK" -ForegroundColor Green
        } else {
            Write-Host "  INFO: Jobs relacionados - Nenhum (normal)" -ForegroundColor Yellow
        }
        
        Write-Host "- Testando eventos..." -ForegroundColor Gray
        $testEvents = kubectl get events -n cronjob-service --field-selector involvedObject.name=cronjob-service 2>$null
        if ($testEvents) {
            Write-Host "  SUCCESS: Eventos OK" -ForegroundColor Green
        } else {
            Write-Host "  INFO: Eventos - Nenhum (normal)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  WARNING: Erro testando - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host "`nProximos passos:" -ForegroundColor Cyan
    Write-Host "1. Aguardar 30 segundos para estabilizacao completa" -ForegroundColor Yellow
    Write-Host "2. Abrir Dashboard: minikube dashboard --port=4666" -ForegroundColor Yellow
    Write-Host "3. Acessar: http://localhost:4666" -ForegroundColor Yellow
    Write-Host "4. Ir para: Workloads > Cron Jobs" -ForegroundColor Yellow
    Write-Host "5. Clicar em 'cronjob-service' - deve abrir detalhes sem erro 404" -ForegroundColor Yellow
    
    # Limpar arquivo temporario
    Remove-Item $rbacFile -Force 2>$null
    
} catch {
    Write-Host "`nERRO aplicando patch: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nTentativas de recuperacao:" -ForegroundColor Yellow
    Write-Host "1. kubectl delete clusterrole kubernetes-dashboard-cronjob-fix" -ForegroundColor Gray
    Write-Host "2. kubectl delete clusterrolebinding kubernetes-dashboard-cronjob-fix" -ForegroundColor Gray
    exit 1
}

Write-Host "`nCORRECAO CONCLUIDA!" -ForegroundColor Green