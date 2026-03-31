# install-keda.ps1 - Script de Instalacao KEDA no Minikube (Windows)
# Garante a instalacao do KEDA usando Helm

param(
    [switch]$SkipHelm,
    [switch]$Uninstall,
    [switch]$SkipHelmCheck,
    [switch]$SkipValidation
)

# Definicao de Emojis
$emoji_success  = [char]::ConvertFromUtf32(0x2705)
$emoji_error    = [char]::ConvertFromUtf32(0x274C)
$emoji_warning  = [char]::ConvertFromUtf32(0x26A0)
$emoji_info     = [char]::ConvertFromUtf32(0x1F4A1)
$emoji_book     = [char]::ConvertFromUtf32(0x1F4DA)
$emoji_party    = [char]::ConvertFromUtf32(0x1F389)
$emoji_wrench   = [char]::ConvertFromUtf32(0x1F527)
$emoji_trash    = [char]::ConvertFromUtf32(0x1F5D1)
$emoji_chart    = [char]::ConvertFromUtf32(0x1F4CA)
$emoji_clipboard = [char]::ConvertFromUtf32(0x1F4CB)
$emoji_scroll   = [char]::ConvertFromUtf32(0x1F4DC)
$emoji_globe    = [char]::ConvertFromUtf32(0x1F310)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "KEDA - Kubernetes Event-driven Autoscaling Setup" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Verificacoes iniciais
if ($Uninstall) {
    Write-Host "`n$($emoji_trash) Desinstalando KEDA..." -ForegroundColor Yellow
    helm uninstall keda --namespace keda 2>$null
    kubectl delete namespace keda --ignore-not-found=true 2>$null
    Write-Host "$($emoji_success) KEDA removido!" -ForegroundColor Green
    exit 0
}

if (-not (Get-Command "helm" -ErrorAction SilentlyContinue)) {
    Write-Host "$($emoji_error) Helm nao encontrado!" -ForegroundColor Red
    exit 1
}

# 1. Configurar Repositorio
if (-not $SkipHelm) {
    Write-Host "`n1. Configurando repositorio Helm..." -ForegroundColor Yellow
    helm repo add kedacore https://kedacore.github.io/charts 2>$null
    helm repo update 2>$null
}

# 2. Namespace
Write-Host "`n2. Criando namespace keda..." -ForegroundColor Yellow
kubectl create namespace keda --dry-run=client -o yaml | kubectl apply -f - | Out-Null

# 3. Instalacao
Write-Host "`n3. Instalando KEDA via Helm..." -ForegroundColor Yellow
$helmArgs = @(
    "install", "keda", "kedacore/keda",
    "--namespace", "keda",
    "--set", "prometheus.metricServer.enabled=true",
    "--set", "prometheus.operator.enabled=true"
)

# Tenta instalar. Se já existir, avisa.
$checkKeda = helm list -n keda -q
if ($checkKeda -match "keda") {
    Write-Host "   $($emoji_info) KEDA ja esta instalado. Pulando instalacao Helm." -ForegroundColor Cyan
} else {
    helm @helmArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$($emoji_error) Falha ao instalar KEDA!" -ForegroundColor Red
        exit 1
    }
}

# 4. Validacao
if (-not $SkipValidation) {
    Write-Host "`n4. Aguardando pods do KEDA..." -ForegroundColor Yellow
    Write-Host "   Pode levar ate 2 minutos..." -ForegroundColor Gray
    
    # Aguarda o operator especificamente
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keda-operator -n keda --timeout=120s 2>$null
    
    Write-Host "`n$($emoji_chart) Status dos componentes:" -ForegroundColor Cyan
    kubectl get pods -n keda --no-headers | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor White
    }
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "$($emoji_party) INSTALACAO KEDA CONCLUIDA!" -ForegroundColor Green
Write-Host "$($emoji_success) KEDA pronto para uso!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
