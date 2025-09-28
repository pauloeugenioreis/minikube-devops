<#
.SYNOPSIS
Bootstrap completo para maquina nova - ambiente offline
Configura ambiente DevOps completo sem necessidade de acesso a repositorio online

.DESCRIPTION
Este script e usado quando o projeto ja foi transferido para a maquina
(via USB, rede ou OneDrive) e precisa apenas configurar dependencias
e inicializar o ambiente.

.PARAMETER ProjectPath
Caminho customizado para o projeto (padrao: pasta atual)

.PARAMETER SkipSetup
Pula a instalacao de dependencias

.PARAMETER SkipInit
Pula a inicializacao do ambiente

.EXAMPLE
.\\Bootstrap-DevOps.ps1
Execucao completa na pasta atual

.EXAMPLE
.\\Bootstrap-DevOps.ps1 -ProjectPath "C:\\MeuProjeto\\DevOps"
Execucao em caminho customizado

.EXAMPLE
.\\Bootstrap-DevOps.ps1 -SkipSetup
Apenas inicializacao, sem instalar dependencias
#>

param(
    [string]$ProjectPath,
    [switch]$SkipSetup,
    [switch]$SkipInit
)

$ErrorActionPreference = "Stop"

if (-not $ProjectPath) {
    $ProjectPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
}

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[STATUS] $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-ProjectStructure {
    param([string]$Path)

    $requiredPaths = @(
        "minikube",
        "minikube\\scripts",
        "minikube\\scripts\\windows",
        "temp"
    )

    foreach ($requiredPath in $requiredPaths) {
        $fullPath = Join-Path $Path $requiredPath
        if (-not (Test-Path $fullPath)) {
            return $false
        }
    }

    return $true
}

function Run-Setup {
    if ($SkipSetup) {
        Write-Warning "Pulando instalacao de dependencias"
        return
    }

    $setupScript = Join-Path $ProjectPath "minikube\scripts\windows\Setup-Fresh-Machine.ps1"

    if (-not (Test-Path $setupScript)) {
        Write-Error "Script de setup nao encontrado: $setupScript"
        throw "Setup script missing"
    }

    Write-Status "Executando instalacao de dependencias..."

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        & $setupScript -RunInitialization
    } else {
        Write-Status "Elevando privilegios para instalacao..."
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$setupScript`" -RunInitialization"
        Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    }

    Write-Success "Setup de dependencias concluido"
}

function Run-Initialization {
    if ($SkipInit) {
        Write-Warning "Pulando inicializacao do ambiente"
        return
    }

    $getProjectRootScript = Join-Path $ProjectPath "minikube\\scripts\\windows\\Get-ProjectRoot.ps1"

    if (Test-Path $getProjectRootScript) {
        Write-Status "Carregando sistema de paths dinamicos..."
        . $getProjectRootScript
        $projectPaths = Get-ProjectPaths
        if ($projectPaths -and $projectPaths.Scripts -and $projectPaths.Scripts.Windows -and $projectPaths.Scripts.Windows.Init) {
            $initScript = Join-Path $projectPaths.Scripts.Windows.Init "init-minikube-fixed.ps1"
        } else {
            $initScript = Join-Path $ProjectPath "minikube\\scripts\\windows\\init\\init-minikube-fixed.ps1"
        }
    } else {
        $initScript = Join-Path $ProjectPath "minikube\\scripts\\windows\\init\\init-minikube-fixed.ps1"
    }

    if (-not (Test-Path $initScript)) {
        Write-Error "Script de inicializacao nao encontrado: $initScript"
        return
    }

    Write-Status "Executando inicializacao do ambiente..."

    try {
        & $initScript -InstallKeda
        Write-Success "Ambiente inicializado com sucesso!"
    } catch {
        Write-Error "Erro na inicializacao: $($_.Exception.Message)"
        throw
    }
}

function Show-FinalInstructions {
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "Bootstrap concluido com sucesso!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green

    Write-Host "`nComandos uteis:" -ForegroundColor Cyan
    Write-Host "Dashboard:  .\\minikube\\scripts\\windows\\monitoring\\open-dashboard.ps1" -ForegroundColor Yellow
    Write-Host "Status:     .\\minikube\\scripts\\windows\\maintenance\\quick-status.ps1" -ForegroundColor Yellow
    Write-Host "Teste:      .\\minikube\\windows-test-structure.ps1" -ForegroundColor Yellow

    Write-Host "`nAcessos:" -ForegroundColor Cyan
    Write-Host "RabbitMQ:   http://localhost:15672 (guest/guest)" -ForegroundColor Yellow
    Write-Host "MongoDB:    mongodb://admin:admin@localhost:27017/admin" -ForegroundColor Yellow
    Write-Host "Dashboard:  http://localhost:53954" -ForegroundColor Yellow

    Write-Host "`nAmbiente DevOps pronto para uso!" -ForegroundColor Green
}

try {
    Write-Host "`nBootstrap DevOps - Configuracao Offline" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta

    if (-not $ProjectPath) {
        $ProjectPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    }

    Write-Status "Verificando projeto em: $ProjectPath"

    if (-not (Test-ProjectStructure $ProjectPath)) {
        Write-Error "Estrutura de projeto nao encontrada em: $ProjectPath"
        Write-Error "Certifique-se de que o projeto DevOps foi transferido corretamente"
        exit 1
    }

    Write-Success "Estrutura de projeto validada"

    Set-Location $ProjectPath
    Write-Status "Pasta atual: $(Get-Location)"

    if (-not $SkipSetup) {
        Run-Setup
    }

    if (-not $SkipInit) {
        Run-Initialization
    }

    Show-FinalInstructions

} catch {
    Write-Error "Erro durante o bootstrap: $($_.Exception.Message)"
    Write-Host "`nVerifique:" -ForegroundColor Yellow
    Write-Host "1. Projeto foi transferido corretamente" -ForegroundColor Yellow
    Write-Host "2. Executando da pasta correta" -ForegroundColor Yellow
    Write-Host "3. Conexao com internet para downloads" -ForegroundColor Yellow
    exit 1
}
