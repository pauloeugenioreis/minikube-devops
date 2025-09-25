# Script para Instalar Helm no Windows
# Prerequisito para KEDA

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Instalando Helm - Package Manager para Kubernetes" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Funcao para verificar se um comando existe
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Verificar se Helm ja esta instalado
if (Test-Command "helm") {
    $helmVersion = helm version --short 2>$null
    Write-Host "OK Helm ja esta instalado: $helmVersion" -ForegroundColor Green
    exit 0
}

Write-Host "`n1. Verificando prerequisitos..." -ForegroundColor Yellow

# Verificar se temos acesso a internet
try {
    Invoke-WebRequest -Uri "https://get.helm.sh" -Method Head -TimeoutSec 10 | Out-Null
    Write-Host "   OK Conectividade com internet OK" -ForegroundColor Green
} catch {
    Write-Host "   ERRO Sem conectividade com internet!" -ForegroundColor Red
    Write-Host "   Verifique sua conexao e tente novamente" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n2. Baixando Helm..." -ForegroundColor Yellow

# Definir versao e arquitetura
$helmVersion = "v3.16.2"  # Versao estavel mais recente
$arch = "amd64"
$os = "windows"

$downloadUrl = "https://get.helm.sh/helm-$helmVersion-$os-$arch.zip"
$tempDir = "$env:TEMP\helm-install"
$zipFile = "$tempDir\helm.zip"

# Criar diretorio temporario
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "   Baixando de: $downloadUrl" -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -TimeoutSec 120
    Write-Host "   OK Download concluido" -ForegroundColor Green
} catch {
    Write-Host "   ERRO Falha no download do Helm!" -ForegroundColor Red
    Write-Host "   Erro: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n3. Extraindo Helm..." -ForegroundColor Yellow

try {
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
    Write-Host "   OK Arquivos extraidos" -ForegroundColor Green
} catch {
    Write-Host "   ERRO Falha ao extrair arquivos!" -ForegroundColor Red
    exit 1
}

Write-Host "`n4. Instalando Helm..." -ForegroundColor Yellow

# Criar diretorio bin do usuario se nao existir
$userBinPath = "$env:USERPROFILE\bin"
if (-not (Test-Path $userBinPath)) {
    New-Item -ItemType Directory -Path $userBinPath -Force | Out-Null
    Write-Host "   Criado diretorio: $userBinPath" -ForegroundColor Cyan
}

# Copiar helm.exe
$helmSource = "$tempDir\$os-$arch\helm.exe"
$helmDestination = "$userBinPath\helm.exe"

if (Test-Path $helmSource) {
    Copy-Item $helmSource $helmDestination -Force
    Write-Host "   OK helm.exe copiado para $userBinPath" -ForegroundColor Green
} else {
    Write-Host "   ERRO Arquivo helm.exe nao encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "`n5. Configurando PATH..." -ForegroundColor Yellow

# Verificar se o PATH ja inclui o diretorio bin do usuario
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$userBinPath*") {
    $newPath = "$userBinPath;$currentPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "   OK PATH atualizado (persistente)" -ForegroundColor Green
} else {
    Write-Host "   OK PATH ja configurado" -ForegroundColor Green
}

# Atualizar PATH da sessao atual
if ($env:PATH -notlike "*$userBinPath*") {
    $env:PATH = "$userBinPath;$env:PATH"
    Write-Host "   OK PATH da sessao atual atualizado" -ForegroundColor Green
}

Write-Host "`n6. Verificando instalacao..." -ForegroundColor Yellow

# Verificar se helm funciona
try {
    $helmVersionOutput = & "$helmDestination" version --short 2>$null
    if ($helmVersionOutput) {
        Write-Host "   OK Helm instalado com sucesso!" -ForegroundColor Green
        Write-Host "   Versao: $helmVersionOutput" -ForegroundColor Cyan
    } else {
        Write-Host "   ERRO Helm nao responde corretamente" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ERRO ao verificar instalacao Helm" -ForegroundColor Red
    Write-Host "   Erro: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n7. Configurando repositorios Helm basicos..." -ForegroundColor Yellow

try {
    # Adicionar repositorios uteis
    & "$helmDestination" repo add stable https://charts.helm.sh/stable 2>$null
    & "$helmDestination" repo add bitnami https://charts.bitnami.com/bitnami 2>$null
    & "$helmDestination" repo update 2>$null
    Write-Host "   OK Repositorios basicos configurados" -ForegroundColor Green
} catch {
    Write-Host "   AVISO Repositorios podem precisar ser configurados manualmente" -ForegroundColor Yellow
}

Write-Host "`n8. Limpeza..." -ForegroundColor Yellow
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   OK Arquivos temporarios removidos" -ForegroundColor Green

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "HELM INSTALADO COM SUCESSO!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`nINFORMACOES IMPORTANTES:" -ForegroundColor Yellow
Write-Host "   Localizacao: $helmDestination" -ForegroundColor Cyan
Write-Host "   Comando: helm" -ForegroundColor Cyan
Write-Host "   PATH: $userBinPath" -ForegroundColor Cyan

Write-Host "`nPROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "   1. Reinicie o PowerShell para garantir PATH atualizado" -ForegroundColor Cyan
Write-Host "   2. Teste: helm version" -ForegroundColor Cyan
Write-Host "   3. Continue com a instalacao KEDA" -ForegroundColor Cyan

Write-Host "`nCOMANDOS HELM UTEIS:" -ForegroundColor Yellow
Write-Host "   - helm version" -ForegroundColor Cyan
Write-Host "   - helm repo list" -ForegroundColor Cyan
Write-Host "   - helm search repo nome" -ForegroundColor Cyan
Write-Host "   - helm install nome chart" -ForegroundColor Cyan

Write-Host "`nHelm pronto para uso!" -ForegroundColor Green