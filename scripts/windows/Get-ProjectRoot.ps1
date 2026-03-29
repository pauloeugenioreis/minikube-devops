# Get-ProjectRoot.ps1
# Funcao utilitaria para detectar automaticamente a pasta raiz do projeto DevOps
# Pode ser importada por outros scripts para paths dinamicos

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info = [char]::ConvertFromUtf32(0x1F4A1)

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
    <#
    .SYNOPSIS
    Detecta automaticamente a pasta raiz do projeto DevOps

    .DESCRIPTION
    Procura pela pasta raiz do projeto DevOps usando arquivos marcadores:
    - README.md
    - Estrutura minikube/scripts/
    - Estrutura minikube/charts/

    .PARAMETER StartPath
    Caminho inicial para busca (padrao: diretorio do script)

    .EXAMPLE
    $projectRoot = Get-ProjectRoot
    $chartsPath = Join-Path $projectRoot "minikube\charts"

    .OUTPUTS
    String com o caminho completo da pasta raiz do projeto
    #>

    param(
        [string]$StartPath = $PSScriptRoot
    )

    # Se PSScriptRoot nao estiver disponivel, usar diretorio atual
    if (-not $StartPath) {
        $StartPath = Get-Location
    }

    $currentPath = $StartPath
    $maxLevels = 10  # Limite para evitar loop infinito
    $levelCount = 0

    while ($levelCount -lt $maxLevels) {
        # Verificar se encontrou a raiz do projeto DevOps
        $rootMarkers = @(
            "README.md"
        )

        $foundRootMarkers = 0
        foreach ($marker in $rootMarkers) {
            $markerPath = Join-Path $currentPath $marker
            if (Test-Path $markerPath) {
                $foundRootMarkers++
            }
        }

        $layoutInfo = Get-ProjectLayoutBase -RootPath $currentPath

        # Se encontrou ao menos um marcador valido e uma estrutura valida, consideramos que e a raiz
        if ($foundRootMarkers -ge 1 -and $layoutInfo) {
            Write-Verbose "Pasta raiz detectada: $currentPath"
            Write-Verbose "Layout detectado: $($layoutInfo.Layout)"
            return $currentPath
        }

        # Subir um nivel
        $parentPath = Split-Path $currentPath -Parent

        # Se chegou na raiz do drive, parar
        if (-not $parentPath -or $parentPath -eq $currentPath) {
            break
        }

        $currentPath = $parentPath
        $levelCount++
    }

    # Se nao encontrou, tentar detectar pela estrutura atual
    Write-Warning "Nao foi possivel detectar a raiz automaticamente"
    Write-Warning "Tentando detectar pela estrutura atual..."

    # Verificar se estamos dentro da estrutura legada minikube
    if ($StartPath -like "*minikube*") {
        $minikubeIndex = $StartPath.LastIndexOf("minikube")
        if ($minikubeIndex -gt 0) {
            $possibleRoot = $StartPath.Substring(0, $minikubeIndex).TrimEnd('\\')
            if (Get-ProjectLayoutBase -RootPath $possibleRoot) {
                Write-Warning "Tentativa baseada em estrutura: $possibleRoot"
                return $possibleRoot
            }
        }
    }

    # Ultimo recurso: usar o caminho inicial
    Write-Error "ERRO: Nao foi possivel detectar a pasta raiz do projeto!"
    Write-Error "Verifique se os arquivos marcadores existem:"
    Write-Error "- README.md"
    Write-Error "- scripts\windows e charts (na raiz), ou minikube\scripts\windows e minikube\charts"
    throw "Pasta raiz do projeto nao encontrada"
}

# Funcao para obter paths padrao do projeto
function Get-ProjectPaths {
    <#
    .SYNOPSIS
    Retorna um objeto com todos os paths importantes do projeto

    .DESCRIPTION
    Baseado na raiz detectada, retorna objeto com paths padronizados

    .EXAMPLE
    $paths = Get-ProjectPaths
    helm upgrade --install rabbitmq $paths.Charts.RabbitMQ.Root
    #>

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
                Autostart = Join-Path $basePath "scripts\windows\autostart"
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

# Funcao para testar se a deteccao esta funcionando
function Test-ProjectRoot {
    <#
    .SYNOPSIS
    Testa se a deteccao da raiz do projeto esta funcionando

    .DESCRIPTION
    Valida que todos os paths importantes existem
    #>

    try {
        $paths = Get-ProjectPaths

        Write-Host "=====================================================" -ForegroundColor Cyan
        Write-Host "TESTE DE DETECCAO DE RAIZ DO PROJETO" -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Cyan

        Write-Host "Pasta raiz detectada:" -ForegroundColor Yellow
        Write-Host "   $($paths.Root)" -ForegroundColor White

        $tests = @(
            @{ Name = "README.md"; Path = Join-Path $paths.Root "README.md" }
            @{ Name = "scripts\\windows"; Path = $paths.Scripts.Windows.Root }
            @{ Name = "charts"; Path = $paths.Charts.Root }
            @{ Name = "RabbitMQ Chart.yaml"; Path = $paths.Charts.RabbitMQ.Chart }
            @{ Name = "MongoDB Chart.yaml"; Path = $paths.Charts.MongoDB.Chart }
            @{ Name = "KEDA examples"; Path = $paths.Configs.KedaExamples }
        )

        Write-Host "`nValidacao de arquivos/pastas:" -ForegroundColor Yellow
        $successCount = 0
        foreach ($test in $tests) {
            if (Test-Path $test.Path) {
                Write-Host "   $emoji_success $($test.Name)" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "   $emoji_error $($test.Name)" -ForegroundColor Red
                Write-Host "      Caminho: $($test.Path)" -ForegroundColor Gray
            }
        }

        Write-Host "`nResultado:" -ForegroundColor Yellow
        if ($successCount -eq $tests.Count) {
            Write-Host "   $emoji_success Deteccao funcionando perfeitamente! ($successCount/$($tests.Count))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   $emoji_warning Alguns arquivos nao encontrados ($successCount/$($tests.Count))" -ForegroundColor Yellow
            return $false
        }

    } catch {
        Write-Host "$emoji_error ERRO na deteccao: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Se executado diretamente, fazer o teste
if ($MyInvocation.ScriptName -eq $PSCommandPath) {
    Test-ProjectRoot
}

