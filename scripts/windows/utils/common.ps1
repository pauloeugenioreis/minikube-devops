# common.ps1
# Script de utilitarios base do projeto
# Contem deteccao de paths, logging padronizado e verificadores universais

# ==============================================================================
# 1. Emojis (Usando globais $script: para serem disponiveis apos dot-sourcing)
# ==============================================================================
$script:emoji_success = [char]::ConvertFromUtf32(0x2705)
$script:emoji_error   = [char]::ConvertFromUtf32(0x274C)
$script:emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$script:emoji_info    = [char]::ConvertFromUtf32(0x1F4A1)
$script:emoji_trash   = [char]::ConvertFromUtf32(0x1F5D1)
$script:emoji_chart   = [char]::ConvertFromUtf32(0x1F4CA)
$script:emoji_clipboard = [char]::ConvertFromUtf32(0x1F4CB)
$script:emoji_scroll  = [char]::ConvertFromUtf32(0x1F4DC)
$script:emoji_book    = [char]::ConvertFromUtf32(0x1F4DA)
$script:emoji_party   = [char]::ConvertFromUtf32(0x1F389)
$script:emoji_wrench  = [char]::ConvertFromUtf32(0x1F527)

# Forcar codificacao UTF-8 para os paineis
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# ==============================================================================
# 2. Funcoes Utilitarias Gerais
# ==============================================================================

function Write-Status {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "$script:emoji_info $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "$script:emoji_success $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "$script:emoji_warning $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "$script:emoji_error $Message" -ForegroundColor Red
}

function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminRights {
    param([string]$ScriptPath, [string]$Arguments = "")
    if (-not (Test-AdminRights)) {
        Write-Warning "Este script requer privilegios de Administrador para ser executado!"
        Write-Status "Reiniciando em modo Elevado..."
        $argsList = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        if ($Arguments) { $argsList += " $Arguments" }
        Start-Process PowerShell -Verb RunAs -ArgumentList $argsList
        exit
    }
}

# ==============================================================================
# 3. Deteccao Dinamica de Caminhos
# ==============================================================================

function Get-ProjectLayoutBase {
    param([Parameter(Mandatory)] [string]$RootPath)

    $legacyBase = Join-Path $RootPath "minikube"
    if ((Test-Path (Join-Path $legacyBase "scripts\windows")) -and (Test-Path (Join-Path $legacyBase "charts"))) {
        return [PSCustomObject]@{
            Layout = "legacy"
            BasePath = $legacyBase
        }
    }

    if ((Test-Path (Join-Path $RootPath "scripts\windows")) -and (Test-Path (Join-Path $RootPath "charts"))) {
        return [PSCustomObject]@{
            Layout = "flat"
            BasePath = $RootPath
        }
    }

    return $null
}

function Get-ProjectRoot {
    param([string]$StartPath = $PSScriptRoot)

    if (-not $StartPath) {
        $StartPath = Get-Location
    }

    $currentPath = $StartPath
    $maxLevels = 10
    $levelCount = 0

    while ($levelCount -lt $maxLevels) {
        $rootMarkers = @("README.md")
        $foundRootMarkers = 0
        foreach ($marker in $rootMarkers) {
            if (Test-Path (Join-Path $currentPath $marker)) {
                $foundRootMarkers++
            }
        }

        $layoutInfo = Get-ProjectLayoutBase -RootPath $currentPath
        if ($foundRootMarkers -ge 1 -and $layoutInfo) {
            return $currentPath
        }

        $parentPath = Split-Path $currentPath -Parent
        if (-not $parentPath -or $parentPath -eq $currentPath) {
            break
        }
        $currentPath = $parentPath
        $levelCount++
    }

    # Tentativa manual para projetos em arvore nao-standard
    if ($StartPath -like "*minikube*") {
        $minikubeIndex = $StartPath.LastIndexOf("minikube")
        if ($minikubeIndex -gt 0) {
            $possibleRoot = $StartPath.Substring(0, $minikubeIndex).TrimEnd('\')
            if (Get-ProjectLayoutBase -RootPath $possibleRoot) {
                return $possibleRoot
            }
        }
    }

    Write-ErrorMsg "Nao foi possivel detectar a pasta raiz do projeto!"
    throw "Pasta raiz do projeto nao encontrada"
}

function Get-ProjectPaths {
    $root = Get-ProjectRoot
    $layoutInfo = Get-ProjectLayoutBase -RootPath $root
    if (-not $layoutInfo) {
        throw "Nao foi possivel identificar o layout do projeto"
    }

    $basePath = $layoutInfo.BasePath
    $chartRoot = Join-Path $basePath "charts"
    $rabbitMqRoot = Join-Path $chartRoot "rabbitmq"
    $mongoRoot = Join-Path $chartRoot "mongodb"

    return [PSCustomObject]@{
        Root = $root
        Layout = $layoutInfo.Layout
        Minikube = $basePath
        Scripts = @{
            Windows = @{
                Root = Join-Path $basePath "scripts\windows"
                Init = Join-Path $basePath "scripts\windows\init"
                Maintenance = Join-Path $basePath "scripts\windows\maintenance"
                Monitoring = Join-Path $basePath "scripts\windows\monitoring"
                Keda = Join-Path $basePath "scripts\windows\keda"
                Utils = Join-Path $basePath "scripts\windows\utils"
            }
        }
        Charts = @{
            Root = $chartRoot
            RabbitMQ = @{
                Root = $rabbitMqRoot
                Chart = Join-Path $rabbitMqRoot "Chart.yaml"
                Values = Join-Path $rabbitMqRoot "values.yaml"
            }
            MongoDB = @{
                Root = $mongoRoot
                Chart = Join-Path $mongoRoot "Chart.yaml"
                Values = Join-Path $mongoRoot "values.yaml"
            }
        }
        Configs = @{
            Root = Join-Path $basePath "configs"
            Keda = Join-Path $basePath "configs\keda"
            KedaExamples = Join-Path $basePath "configs\keda\examples"
        }
        Docs = Join-Path $basePath "docs"
        Temp = Join-Path $root "temp"
    }
}

# Se executado diretamente para diagnostico
if ($MyInvocation.ScriptName -eq $PSCommandPath) {
    try {
        $paths = Get-ProjectPaths
        Write-Success "Deteccao de caminhos operante!"
        Write-Status "Raiz: $($paths.Root)"
    } catch {
        Write-ErrorMsg "Falha na deteccao da Raiz."
    }
}
