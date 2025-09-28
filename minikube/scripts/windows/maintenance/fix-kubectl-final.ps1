# SOLUCAO COMPLETA - Compatibilidade kubectl/Kubernetes
# Este script resolve definitivamente problemas de incompatibilidade
# Execute sempre que vir avisos sobre versoes incompativeis

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "SOLUCAO FINAL - Compatibilidade kubectl/Kubernetes" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "Resolvendo incompatibilidades de versao..." -ForegroundColor Yellow
Write-Host ""

# Passo 1: Configurar diretorio local
Write-Host "1. Configurando ambiente local..." -ForegroundColor Yellow
$userBin = "$env:USERPROFILE\bin"
if (-not (Test-Path $userBin)) {
    New-Item -ItemType Directory -Path $userBin -Force | Out-Null
    Write-Host "   Diretorio criado: $userBin" -ForegroundColor Green
}

# Passo 2: Configurar PATH
Write-Host "2. Configurando PATH..." -ForegroundColor Yellow
if ($env:PATH -notlike "*$userBin*") {
    $env:PATH = "$userBin;$env:PATH"
    
    # PATH permanente
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notmatch [regex]::Escape($userBin)) {
        [Environment]::SetEnvironmentVariable("PATH", "$userBin;$currentPath", "User")
        Write-Host "   PATH configurado permanentemente" -ForegroundColor Green
    }
}

# Passo 3: Detectar versao correta
Write-Host "3. Detectando versao correta do Kubernetes..." -ForegroundColor Yellow
try {
    $k8sVersion = (minikube kubectl version --client --short 2>$null) -replace 'Client Version: ', ''
    Write-Host "   Versao necessaria: $k8sVersion" -ForegroundColor Green
    
    # Passo 4: Baixar kubectl correto
    Write-Host "4. Baixando kubectl compativel..." -ForegroundColor Yellow
    $url = "https://dl.k8s.io/release/$k8sVersion/bin/windows/amd64/kubectl.exe"
    $destination = "$userBin\kubectl.exe"
    
    Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
    
    if (Test-Path $destination) {
        Write-Host "   kubectl $k8sVersion baixado com sucesso!" -ForegroundColor Green
    } else {
        throw "Falha no download"
    }
    
} catch {
    Write-Host "   ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Tente executar como administrador" -ForegroundColor Yellow
    exit 1
}

# Passo 5: Verificar instalacao
Write-Host "5. Verificando instalacao..." -ForegroundColor Yellow
try {
    $installedVersion = & "$userBin\kubectl.exe" version --client --short 2>$null
    Write-Host "   $installedVersion instalado" -ForegroundColor Green
    
    # Teste de compatibilidade
    if (Test-Path "$userBin\kubectl.exe") {
        & "$userBin\kubectl.exe" version 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Compatibilidade verificada!" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   Aviso: Nao foi possivel testar completamente" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "SOLUCAO APLICADA COM SUCESSO!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proximo passo:" -ForegroundColor Yellow
Write-Host "1. Feche e reabra o PowerShell" -ForegroundColor White
Write-Host "2. Execute: kubectl version" -ForegroundColor White
Write-Host "3. Verifique se nao ha mais avisos de incompatibilidade" -ForegroundColor White
Write-Host ""
Write-Host "Para usar: .\init-minikube-fixed.ps1" -ForegroundColor Blue