# Get-ProjectRoot.ps1
# Funcao utilitaria para detectar automaticamente a pasta raiz do projeto DevOps
# Pode ser importada por outros scripts para paths dinamicos

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info = [char]::ConvertFromUtf32(0x1F4A1)

function Get-ProjectRoot {
    <#
    .SYNOPSIS
    Detecta automaticamente a pasta raiz do projeto DevOps
    
    .DESCRIPTION
    Procura pela pasta raiz do projeto DevOps usando arquivos marcadores:
    - CONVERSAS-E-DECISOES.md
    - HISTORICO-PROJETO-MINIKUBE.md  
    - Estrutura minikube/scripts/
    
    .PARAMETER StartPath
    Caminho inicial para busca (padrao: diretorio do script)
    
    .EXAMPLE
    $projectRoot = Get-ProjectRoot
    $configsPath = Join-Path $projectRoot "minikube\configs"
    
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
        $markers = @(
            "CONVERSAS-E-DECISOES.md",
            "HISTORICO-PROJETO-MINIKUBE.md",
            "minikube\scripts\windows",
            "minikube\configs"
        )
        
        $foundMarkers = 0
        foreach ($marker in $markers) {
            $markerPath = Join-Path $currentPath $marker
            if (Test-Path $markerPath) {
                $foundMarkers++
            }
        }
        
        # Se encontrou pelo menos 2 marcadores, consideramos que e a raiz
        if ($foundMarkers -ge 2) {
            Write-Verbose "Pasta raiz detectada: $currentPath"
            Write-Verbose "Marcadores encontrados: $foundMarkers de $($markers.Count)"
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
    
    # Verificar se estamos dentro da estrutura minikube
    if ($StartPath -like "*minikube*") {
        # Extrair a parte ate minikube
        $minikubeIndex = $StartPath.LastIndexOf("minikube")
        if ($minikubeIndex -gt 0) {
            $possibleRoot = $StartPath.Substring(0, $minikubeIndex).TrimEnd('\')
            Write-Warning "Tentativa baseada em estrutura: $possibleRoot"
            return $possibleRoot
        }
    }
    
    # Ultimo recurso: usar o caminho inicial
    Write-Error "ERRO: Nao foi possivel detectar a pasta raiz do projeto!"
    Write-Error "Verifique se os arquivos marcadores existem:"
    Write-Error "- CONVERSAS-E-DECISOES.md"
    Write-Error "- HISTORICO-PROJETO-MINIKUBE.md"
    Write-Error "- minikube\scripts\windows\"
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
    kubectl apply -f $paths.Configs.MongoDB
    #>
    
    $root = Get-ProjectRoot
    
    return [PSCustomObject]@{
        Root = $root
        Minikube = Join-Path $root "minikube"
        Scripts = @{
            Windows = @{
                Root = Join-Path $root "minikube\scripts\windows"
                Init = Join-Path $root "minikube\scripts\windows\init"
                Maintenance = Join-Path $root "minikube\scripts\windows\maintenance"
                Monitoring = Join-Path $root "minikube\scripts\windows\monitoring"
                Keda = Join-Path $root "minikube\scripts\windows\keda"
                Autostart = Join-Path $root "minikube\scripts\windows\autostart"
            }
            Linux = Join-Path $root "minikube\scripts\linux"
        }
        Configs = @{
            Root = Join-Path $root "minikube\configs"
            PersistentVolumes = Join-Path $root "minikube\configs\persistent-volumes.yaml"
            RabbitMQ = Join-Path $root "minikube\configs\rabbitmq.yaml"
            MongoDB = Join-Path $root "minikube\configs\mongodb.yaml"
            Keda = Join-Path $root "minikube\configs\keda"
        }
        Docs = Join-Path $root "minikube\docs"
        Temp = Join-Path $root "temp"
        TempLinuxScripts = Join-Path $root "temp\linux-scripts"
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
            @{ Name = "CONVERSAS-E-DECISOES.md"; Path = Join-Path $paths.Root "CONVERSAS-E-DECISOES.md" }
            @{ Name = "HISTORICO-PROJETO-MINIKUBE.md"; Path = Join-Path $paths.Root "HISTORICO-PROJETO-MINIKUBE.md" }
            @{ Name = "minikube\scripts\windows"; Path = $paths.Scripts.Windows.Root }
            @{ Name = "minikube\configs"; Path = $paths.Configs.Root }
            @{ Name = "persistent-volumes.yaml"; Path = $paths.Configs.PersistentVolumes }
            @{ Name = "rabbitmq.yaml"; Path = $paths.Configs.RabbitMQ }
            @{ Name = "mongodb.yaml"; Path = $paths.Configs.MongoDB }
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