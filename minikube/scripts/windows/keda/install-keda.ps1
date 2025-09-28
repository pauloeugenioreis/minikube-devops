# Script de Instalacao KEDA no Minikube
# KEDA - Kubernetes Event-driven Autoscaling
# Criado em: 21/09/2025

param(
    [switch]$SkipHelm,
    [switch]$Uninstall
)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "KEDA - Kubernetes Event-driven Autoscaling Setup" -ForegroundColor Green
Write-Host "Versao: 2.15+ (Latest)" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Funcao para verificar se um comando existe
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

function Get-KubectlVersionString {
    try {
        $json = kubectl version --client --output=json 2>$null | ConvertFrom-Json -ErrorAction Stop
        if ($json.clientVersion.gitVersion) { return $json.clientVersion.gitVersion }
        if ($json.gitVersion) { return $json.gitVersion }
    } catch { }

    try {
        $plain = kubectl version --client 2>$null
        if ($plain) {
            $match = ($plain -join " `n") -match 'Client Version:\s*(?<ver>\S+)'
            if ($match) { return $Matches['ver'] }
        }
    } catch { }

    return "desconhecido"
}

function Set-KedaImagePolicy {
    param(
        [string[]]$Deployments = @('keda-operator', 'keda-admission-webhooks', 'keda-operator-metrics-apiserver')
    )

    Write-Host "   Ajustando imagePullPolicy dos componentes KEDA..." -ForegroundColor White
    foreach ($deploy in $Deployments) {
        kubectl patch deployment $deploy -n keda --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]' 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ⚠️ Não foi possível ajustar imagePullPolicy de $deploy" -ForegroundColor Yellow
        }
    }
}

# Funcao para verificar se Minikube esta rodando
function Test-MinikubeRunning {
    try {
        $status = minikube status 2>$null
        return $status -match "Running"
    } catch {
        return $false
    }
}

# Verificacoes iniciais
Write-Host "`n1. Verificando prerequisitos..." -ForegroundColor Yellow

if (-not (Test-Command "kubectl")) {
    Write-Host "   ❌ kubectl nao encontrado!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "helm")) {
    Write-Host "   ❌ Helm nao encontrado!" -ForegroundColor Red
    Write-Host "   Instale o Helm: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Command "minikube")) {
    Write-Host "   ❌ Minikube nao encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ kubectl: $(Get-KubectlVersionString)" -ForegroundColor Green
Write-Host "   ✅ helm: $(helm version --short 2>$null)" -ForegroundColor Green
Write-Host "   ✅ minikube: $(minikube version --short 2>$null)" -ForegroundColor Green

# Verificar se Minikube esta rodando
Write-Host "`n2. Verificando status do Minikube..." -ForegroundColor Yellow
if (-not (Test-MinikubeRunning)) {
    Write-Host "   ❌ Minikube nao esta rodando!" -ForegroundColor Red
    Write-Host "   Inicie o Minikube primeiro com o script principal" -ForegroundColor Yellow
    exit 1
}
Write-Host "   ✅ Minikube esta rodando" -ForegroundColor Green

# Se uninstall foi solicitado
if ($Uninstall) {
    Write-Host "`n🗑️ Desinstalando KEDA..." -ForegroundColor Yellow
    
    Write-Host "   Removendo KEDA via Helm..." -ForegroundColor Yellow
    helm uninstall keda --namespace keda 2>$null
    
    Write-Host "   Removendo namespace keda..." -ForegroundColor Yellow
    kubectl delete namespace keda --ignore-not-found=true 2>$null
    
    Write-Host "   Removendo CRDs do KEDA..." -ForegroundColor Yellow
    kubectl delete crd scaledobjects.keda.sh --ignore-not-found=true 2>$null
    kubectl delete crd scaledjobs.keda.sh --ignore-not-found=true 2>$null
    kubectl delete crd triggerauthentications.keda.sh --ignore-not-found=true 2>$null
    kubectl delete crd clustertriggerauthentications.keda.sh --ignore-not-found=true 2>$null
    
    Write-Host "`n✅ KEDA removido com sucesso!" -ForegroundColor Green
    exit 0
}

# Instalacao do KEDA
Write-Host "`n3. Configurando repositorio Helm do KEDA..." -ForegroundColor Yellow

if (-not $SkipHelm) {
    Write-Host "   Adicionando repositorio kedacore..." -ForegroundColor Cyan
    helm repo add kedacore https://kedacore.github.io/charts
    
    Write-Host "   Atualizando repositorios Helm..." -ForegroundColor Cyan
    helm repo update
    
    Write-Host "   ✅ Repositorio KEDA configurado" -ForegroundColor Green
}

Write-Host "`n4. Criando namespace keda..." -ForegroundColor Yellow
kubectl create namespace keda --dry-run=client -o yaml | kubectl apply -f -
Write-Host "   ✅ Namespace 'keda' criado/verificado" -ForegroundColor Green

Write-Host "`n5. Instalando KEDA via Helm..." -ForegroundColor Yellow
Write-Host "   Isso pode levar alguns minutos..." -ForegroundColor Cyan

$helmInstallCmd = @"
helm install keda kedacore/keda \
    --namespace keda \
    --set prometheus.metricServer.enabled=true \
    --set prometheus.operator.enabled=true \
    --set prometheus.operator.prometheusConfig.enabled=true
"@

Write-Host "   Executando: $helmInstallCmd" -ForegroundColor Cyan
helm install keda kedacore/keda --namespace keda --set prometheus.metricServer.enabled=true --set prometheus.operator.enabled=true --set prometheus.operator.prometheusConfig.enabled=true

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Falha na instalacao do KEDA!" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ KEDA instalado com sucesso!" -ForegroundColor Green
Set-KedaImagePolicy

Write-Host "`n6. Aguardando pods do KEDA ficarem prontos..." -ForegroundColor Yellow
Write-Host "   Isso pode levar 1-2 minutos..." -ForegroundColor Cyan

# Aguardar pods estarem prontos
$maxWait = 180  # 3 minutos
$waited = 0
$interval = 10

do {
    Start-Sleep $interval
    $waited += $interval
    
    $pods = kubectl get pods -n keda --no-headers 2>$null
    if ($pods) {
        $totalPods = ($pods | Measure-Object).Count
        $readyPods = ($pods | Where-Object { $_ -match "Running.*1/1" } | Measure-Object).Count
        
        Write-Host "   Progresso: $readyPods/$totalPods pods prontos..." -ForegroundColor Cyan
        
        if ($readyPods -eq $totalPods) {
            break
        }
    }
    
    if ($waited -ge $maxWait) {
        Write-Host "   ⚠️ Timeout aguardando pods. Verificando status..." -ForegroundColor Yellow
        break
    }
} while ($true)

Write-Host "`n7. Verificando instalacao do KEDA..." -ForegroundColor Yellow

Write-Host "`n   📊 Status dos Pods KEDA:" -ForegroundColor Cyan
kubectl get pods -n keda

Write-Host "`n   📋 Services KEDA:" -ForegroundColor Cyan
kubectl get svc -n keda

Write-Host "`n   🔧 CRDs do KEDA:" -ForegroundColor Cyan
kubectl get crd | grep keda

Write-Host "`n   📜 Versao do KEDA:" -ForegroundColor Cyan
$kedaVersion = kubectl get crd/scaledobjects.keda.sh -o jsonpath='{.metadata.labels.app\.kubernetes\.io/version}' 2>$null
if ($kedaVersion) {
    Write-Host "   Versao: $kedaVersion" -ForegroundColor Green
} else {
    Write-Host "   Versao nao detectada automaticamente" -ForegroundColor Yellow
}

# Verificar se componentes principais estao rodando
Write-Host "`n8. Validacao final..." -ForegroundColor Yellow

$operatorPod = kubectl get pods -n keda -l app.kubernetes.io/name=keda-operator --no-headers 2>$null
$metricsServerPod = kubectl get pods -n keda -l app.kubernetes.io/name=keda-operator-metrics-apiserver --no-headers 2>$null
$webhookPod = kubectl get pods -n keda -l app.kubernetes.io/name=keda-admission-webhooks --no-headers 2>$null

$components = @{
    "KEDA Operator" = $operatorPod -match "Running"
    "Metrics Server" = $metricsServerPod -match "Running"
    "Admission Webhooks" = $webhookPod -match "Running"
}

foreach ($component in $components.GetEnumerator()) {
    if ($component.Value) {
        Write-Host "   ✅ $($component.Key): Running" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $($component.Key): Not Running" -ForegroundColor Red
    }
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "🎉 INSTALACAO KEDA CONCLUIDA!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`n📚 PROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "   1. Teste a instalacao com:" -ForegroundColor Cyan
Write-Host "      kubectl get scaledobjects -A" -ForegroundColor White
Write-Host "`n   2. Crie um ScaledObject de exemplo:" -ForegroundColor Cyan
Write-Host "      kubectl apply -f exemplos/" -ForegroundColor White
Write-Host "`n   3. Monitore os logs do KEDA:" -ForegroundColor Cyan
Write-Host "      kubectl logs -n keda -l app.kubernetes.io/name=keda-operator" -ForegroundColor White

Write-Host "`n🌐 DOCUMENTACAO:" -ForegroundColor Yellow
Write-Host "   - KEDA Official: https://keda.sh/" -ForegroundColor Cyan
Write-Host "   - Scalers: https://keda.sh/docs/scalers/" -ForegroundColor Cyan
Write-Host "   - Examples: https://github.com/kedacore/samples" -ForegroundColor Cyan

Write-Host "`n🔧 COMANDOS UTEIS:" -ForegroundColor Yellow
Write-Host "   - Status: kubectl get pods -n keda" -ForegroundColor Cyan
Write-Host "   - Logs: kubectl logs -n keda -l app.kubernetes.io/name=keda-operator" -ForegroundColor Cyan
Write-Host "   - Uninstall: .\install-keda.ps1 -Uninstall" -ForegroundColor Cyan

Write-Host "`n✅ KEDA pronto para uso!" -ForegroundColor Green
