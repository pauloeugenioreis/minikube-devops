<#
.SYNOPSIS
Bootstrap completo para máquina nova - Sistema offline
Configura ambiente DevOps completo sem necessidade de repositório online

.DESCRIPTION
Este script é usado quando o projeto já foi transferido para a máquina
(via USB, rede ou OneDrive) e precisa apenas configurar as dependências
e inicializar o ambiente.

.PARAMETER ProjectPath
Caminho customizado para o projeto (padrão: pasta atual)

.PARAMETER SkipSetup
Pula a instalação de dependências

.PARAMETER SkipInit
Pula a inicialização do ambiente

.EXAMPLE
.\Bootstrap-DevOps.ps1
Execução completa na pasta atual

.EXAMPLE
.\Bootstrap-DevOps.ps1 -ProjectPath "C:\MeuProjeto\DevOps"
Execução em caminho customizado

.EXAMPLE
.\Bootstrap-DevOps.ps1 -SkipSetup
Apenas inicialização, sem instalar dependências
#>

param(
    [string]$ProjectPath,
    [switch]$SkipSetup,
    [switch]$SkipInit
)

$ErrorActionPreference = "Stop"

# Se ProjectPath não foi especificado, detectar automaticamente
if (!$ProjectPath) {
    # Assumir que estamos em minikube/scripts/windows/, subir 3 níveis para raiz
    $ProjectPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
}

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "🔧 $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-ProjectStructure {
    param([string]$Path)
    
    $requiredPaths = @(
        "minikube",
        "minikube\scripts",
        "minikube\scripts\windows",
        "temp"
    )
    
    foreach ($requiredPath in $requiredPaths) {
        $fullPath = Join-Path $Path $requiredPath
        if (!(Test-Path $fullPath)) {
            return $false
        }
    }
    return $true
}

function Run-Setup {
    if ($SkipSetup) {
        Write-Warning "Pulando instalação de dependências"
        return
    }
    
    $setupScript = Join-Path $ProjectPath "temp\Setup-Fresh-Machine.ps1"
    
    if (!(Test-Path $setupScript)) {
        Write-Error "Script de setup não encontrado: $setupScript"
        throw "Setup script missing"
    }
    
    Write-Status "Executando instalação de dependências..."
    
    # Verificar se já está executando como admin
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        # Já é admin, executar diretamente
        & $setupScript -RunInitialization
    } else {
        # Elevar privilégios e executar
        Write-Status "Elevando privilégios para instalação..."
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$setupScript`" -RunInitialization"
        Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -Wait
    }
    
    Write-Success "Setup de dependências concluído"
}

function Run-Initialization {
    if ($SkipInit) {
        Write-Warning "Pulando inicialização do ambiente"
        return
    }
    
    # Tentar carregar sistema de paths dinâmicos
    $getProjectRootScript = Join-Path $ProjectPath "minikube\scripts\windows\Get-ProjectRoot.ps1"
    
    if (Test-Path $getProjectRootScript) {
        Write-Status "Carregando sistema de paths dinâmicos..."
        . $getProjectRootScript
        $projectPaths = Get-ProjectPaths
        
        $initScript = $projectPaths.Scripts.Init
    } else {
        # Fallback para path fixo
        $initScript = Join-Path $ProjectPath "minikube\scripts\windows\init\init-minikube-fixed.ps1"
    }
    
    if (!(Test-Path $initScript)) {
        Write-Error "Script de inicialização não encontrado: $initScript"
        return
    }
    
    Write-Status "Executando inicialização do ambiente..."
    
    try {
        & $initScript -InstallKeda
        Write-Success "Ambiente inicializado com sucesso!"
    } catch {
        Write-Error "Erro na inicialização: $($_.Exception.Message)"
        throw
    }
}

function Show-FinalInstructions {
    Write-Host "`n🎉 Bootstrap concluído com sucesso!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    
    Write-Host "`n📊 Comandos úteis:" -ForegroundColor Cyan
    Write-Host "Dashboard:  .\minikube\scripts\windows\monitoring\open-dashboard.ps1" -ForegroundColor Yellow
    Write-Host "Status:     .\minikube\scripts\windows\maintenance\quick-status.ps1" -ForegroundColor Yellow
    Write-Host "Teste:      .\minikube\windows-test-structure.ps1" -ForegroundColor Yellow
    
    Write-Host "`n🌐 Acessos:" -ForegroundColor Cyan
    Write-Host "RabbitMQ:   http://localhost:15672 (guest/guest)" -ForegroundColor Yellow
    Write-Host "MongoDB:    mongodb://admin:admin@localhost:27017/admin" -ForegroundColor Yellow
    Write-Host "Dashboard:  http://localhost:53954" -ForegroundColor Yellow
    
    Write-Host "`n✅ Ambiente DevOps pronto para uso!" -ForegroundColor Green
}

# ================== EXECUÇÃO PRINCIPAL ==================

try {
    Write-Host "`n🚀 Bootstrap DevOps - Configuração Offline" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
    
    # Se ProjectPath não foi especificado, detectar automaticamente
    if (!$ProjectPath) {
        # Assumir que estamos em minikube/scripts/windows/, subir 3 níveis para raiz
        $ProjectPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    }
    
    Write-Status "Verificando projeto em: $ProjectPath"
    
    if (!(Test-ProjectStructure $ProjectPath)) {
        Write-Error "Estrutura de projeto não encontrada em: $ProjectPath"
        Write-Error "Certifique-se de que o projeto DevOps foi transferido corretamente"
        exit 1
    }
    
    Write-Success "Estrutura de projeto validada"
    
    # Navegar para pasta do projeto
    Set-Location $ProjectPath
    Write-Status "Pasta atual: $(Get-Location)"
    
    # Executar setup se necessário
    if (!$SkipSetup) {
        Run-Setup
    }
    
    # Executar inicialização se necessário
    if (!$SkipInit) {
        Run-Initialization
    }
    
    # Mostrar instruções finais
    Show-FinalInstructions
    
} catch {
    Write-Error "Erro durante o bootstrap: $($_.Exception.Message)"
    Write-Host "`n📋 Verifique:" -ForegroundColor Yellow
    Write-Host "1. Projeto foi transferido corretamente" -ForegroundColor Yellow
    Write-Host "2. Executando da pasta correta" -ForegroundColor Yellow
    Write-Host "3. Conexão com internet para downloads" -ForegroundColor Yellow
    exit 1
}