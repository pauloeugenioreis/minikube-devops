# =====================================================
# KEDA - Instalacao Integrada para Minikube
# =====================================================
# Script para instalar KEDA no ambiente Minikube
# Integrado na estrutura principal do projeto

param(
    [switch]$SkipHelmCheck,
    [switch]$SkipValidation
)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "KEDA - Instalacao para Minikube" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Definir caminhos relativos a partir do script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$minikubeRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptDir))
$kedaScriptsPath = Join-Path $minikubeRoot "scripts\windows\keda"
$configsPath = Join-Path $minikubeRoot "configs"

Write-Host "Caminhos configurados:" -ForegroundColor Green
Write-Host "   Minikube Root: $minikubeRoot" -ForegroundColor Gray
Write-Host "   KEDA Scripts: $kedaScriptsPath" -ForegroundColor Gray
Write-Host "   Configs: $configsPath" -ForegroundColor Gray
Write-Host ""

# 1. Verificar se Minikube esta rodando
Write-Host "1. Verificando status do Minikube..." -ForegroundColor Yellow
try {
    $minikubeStatus = minikube status 2>&1
    if ($minikubeStatus -like "*Running*") {
        Write-Host "   Minikube esta rodando" -ForegroundColor Green
    } else {
        Write-Host "   Minikube nao esta rodando!" -ForegroundColor Red
        Write-Host "   Execute primeiro: minikube start" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "   Erro ao verificar status do Minikube: $_" -ForegroundColor Red
    exit 1
}

# 2. Verificar/Instalar Helm
if (-not $SkipHelmCheck) {
    Write-Host "2. Verificando Helm..." -ForegroundColor Yellow
    try {
        $helmVersion = helm version --short 2>&1
        if ($helmVersion -like "*v3.*") {
            Write-Host "   Helm ja instalado: $helmVersion" -ForegroundColor Green
        } else {
            throw "Helm nao encontrado"
        }
    } catch {
        Write-Host "   Helm nao encontrado. Instalando..." -ForegroundColor Yellow
        
        # Chamar script de instalacao do Helm
        $helmInstaller = Join-Path $kedaScriptsPath "install-helm-fixed.ps1"
        if (Test-Path $helmInstaller) {
            & $helmInstaller
        } else {
            Write-Host "   Script install-helm-fixed.ps1 nao encontrado!" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "2. Verificacao do Helm pulada (SkipHelmCheck)" -ForegroundColor Gray
}

# 3. Instalar KEDA
Write-Host "3. Instalando KEDA..." -ForegroundColor Yellow

# Adicionar repositorio KEDA
Write-Host "   Adicionando repositorio KEDA..." -ForegroundColor Cyan
try {
    helm repo add kedacore https://kedacore.github.io/charts 2>$null
    helm repo update 2>$null
    Write-Host "   Repositorio KEDA adicionado" -ForegroundColor Green
} catch {
    Write-Host "   Erro ao adicionar repositorio KEDA: $_" -ForegroundColor Red
    exit 1
}

# Verificar se namespace keda ja existe
$namespaceExists = kubectl get namespace keda 2>$null
if (-not $namespaceExists) {
    Write-Host "   Criando namespace keda..." -ForegroundColor Cyan
    kubectl create namespace keda 2>$null
}

# Instalar KEDA via Helm
Write-Host "   Instalando KEDA via Helm..." -ForegroundColor Cyan
try {
    helm install keda kedacore/keda --namespace keda --create-namespace 2>$null
    Write-Host "   KEDA instalado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "   Erro ao instalar KEDA: $_" -ForegroundColor Red
    exit 1
}

# 4. Aguardar pods ficarem prontos
Write-Host "4. Aguardando pods KEDA ficarem prontos..." -ForegroundColor Yellow
$maxWait = 120
$elapsed = 0
$interval = 5

do {
    Start-Sleep $interval
    $elapsed += $interval
    
    $kedaPods = kubectl get pods -n keda --no-headers 2>$null
    $readyPods = 0
    $totalPods = 0
    
    if ($kedaPods) {
        foreach ($line in $kedaPods) {
            $totalPods++
            if ($line -match "1/1.*Running") {
                $readyPods++
            }
        }
    }
    
    Write-Host "   ${elapsed}s - Pods prontos: $readyPods/$totalPods" -ForegroundColor Gray
    
    if ($readyPods -eq $totalPods -and $totalPods -gt 0) {
        Write-Host "   Todos os pods KEDA estao prontos!" -ForegroundColor Green
        break
    }
    
    if ($elapsed -ge $maxWait) {
        Write-Host "   Timeout aguardando pods. Continuando..." -ForegroundColor Yellow
        break
    }
} while ($true)

# 5. Validacao
if (-not $SkipValidation) {
    Write-Host "5. Validando instalacao..." -ForegroundColor Yellow
    
    # Verificar namespace
    $namespace = kubectl get namespace keda 2>$null
    if ($namespace) {
        Write-Host "   Namespace keda existe" -ForegroundColor Green
    } else {
        Write-Host "   Namespace keda nao encontrado!" -ForegroundColor Red
    }
    
    # Verificar CRDs
    $crds = @("scaledobjects.keda.sh", "scaledjobs.keda.sh", "triggerauthentications.keda.sh")
    foreach ($crd in $crds) {
        $crdExists = kubectl get crd $crd 2>$null
        if ($crdExists) {
            Write-Host "   CRD $crd existe" -ForegroundColor Green
        } else {
            Write-Host "   CRD $crd nao encontrado!" -ForegroundColor Red
        }
    }
    
    # Verificar versao
    try {
        $kedaVersion = kubectl get deployment -n keda keda-operator -o jsonpath='{.spec.template.spec.containers[0].image}' 2>$null
        if ($kedaVersion) {
            Write-Host "   KEDA versao: $kedaVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Nao foi possivel verificar versao KEDA" -ForegroundColor Yellow
    }
} else {
    Write-Host "5. Validacao pulada (SkipValidation)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "INSTALACAO KEDA CONCLUIDA!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "COMANDOS UTEIS:" -ForegroundColor Yellow
Write-Host "   Ver pods KEDA: kubectl get pods -n keda" -ForegroundColor Gray
Write-Host "   Ver ScaledObjects: kubectl get scaledobject -A" -ForegroundColor Gray
Write-Host "   Ver HPAs: kubectl get hpa -A" -ForegroundColor Gray
Write-Host "   Logs KEDA: kubectl logs -n keda -l app.kubernetes.io/name=keda-operator" -ForegroundColor Gray
Write-Host ""

Write-Host "EXEMPLOS DISPONIVEIS:" -ForegroundColor Yellow
Write-Host "   Localizacao: $configsPath\keda\examples\" -ForegroundColor Gray
Write-Host "   Script de teste: $kedaScriptsPath\test-keda.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "KEDA pronto para uso!" -ForegroundColor Green