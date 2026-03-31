# TESTE COMPLETO DA ESTRUTURA MINIKUBE + KEDA
# Validacao abrangente de todos os componentes

# Forcar a codificacao UTF-8 para exibir icones corretamente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info = [char]::ConvertFromUtf32(0x1F4A1)

# Importar funcoes de deteccao de paths
$commonScript = Join-Path $PSScriptRoot "utils\common.ps1"
if (Test-Path $commonScript) {
    . $commonScript
    Write-Status "Detectando pasta raiz do projeto..."
    $projectPaths = Get-ProjectPaths
    $basePath = $projectPaths.Minikube
    Write-Success "Pasta base detectada: $basePath"
} else {
    Write-Warning "utils\common.ps1 nao encontrado. Usando deteccao baseada no script atual."
    # Assumir que o script esta em minikube/
    $basePath = $PSScriptRoot
    Write-Status "Pasta base (relativa): $basePath"
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "TESTANDO ESTRUTURA PROFISSIONAL MINIKUBE" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan

# --- Funcao de Teste Centralizada e Contadores Globais ---
$global:successCount = 0
$global:failureCount = 0

function Test-Files {
    param(
        [string]$Category,
        [string]$Directory,
        [array]$Files,
        [string]$BasePathOverride
    )

    Write-Host "`nTestando $Category..." -ForegroundColor Yellow
    $currentBasePath = if ($BasePathOverride) { $BasePathOverride } else { $basePath }

    foreach ($file in $Files) {
        $fullPath = if ([string]::IsNullOrEmpty($Directory)) {
            Join-Path -Path $currentBasePath -ChildPath $file
        } else {
            Join-Path -Path $currentBasePath -ChildPath (Join-Path -Path $Directory -ChildPath $file)
        }

        if (Test-Path $fullPath) {
            Write-Host "  $emoji_success $(Split-Path $file -Leaf) encontrado" -ForegroundColor Green
            $global:successCount++
        } else {
            Write-Host "  $emoji_error $(Split-Path $file -Leaf) NAO encontrado em '$fullPath'" -ForegroundColor Red
            $global:failureCount++
        }
    }
}

# --- Definicao de todas as verificacoes de arquivos ---
$fileChecks = @(
    @{ Category = "Script de Inicializacao"; Directory = "scripts\windows\init"; Files = @("start.ps1", "set-rabbitmq.ps1") },
    @{ Category = "Scripts de Manutencao"; Directory = "scripts\windows\maintenance"; Files = @("dashboard.ps1", "status.ps1", "kubectl.ps1", "test-rabbitmq.ps1") },
    @{ Category = "Scripts de Monitoramento"; Directory = "scripts\windows\monitoring"; Files = @("dashboard-open.ps1", "dashboard-port.ps1") },
    @{ Category = "Scripts KEDA (Windows)"; Directory = "scripts\windows\keda"; Files = @("install-helm.ps1", "install-keda.ps1", "test-keda.ps1") },
    @{ Category = "Utils"; Directory = "scripts\windows\utils"; Files = @("common.ps1") },
    @{ Category = "Setup de Maquina Nova"; Directory = "scripts\windows"; Files = @("Setup-Fresh-Machine.ps1", "Bootstrap-DevOps.ps1", "test-structure.ps1") },
    @{ Category = "Configs KEDA"; Directory = "configs\keda\examples"; Files = @("cpu-scaling-example.yaml", "memory-scaling-example.yaml", "rabbitmq-scaling-example.yaml") },
    @{ Category = "Documentacao"; Directory = "docs"; Files = @("README.md", "KEDA.md") }
)

# --- Execucao dos Testes ---
foreach ($check in $fileChecks) {
    Test-Files -Category $check.Category -Directory $check.Directory -Files $check.Files -BasePathOverride $check.BasePath
}

# --- Teste Especifico para Helm Charts ---
Write-Host "`nTestando estrutura de Helm Charts..." -ForegroundColor Yellow
$chartsPath = Join-Path $basePath "charts"
if (Test-Path $chartsPath) {
    Write-Host "$emoji_success Pasta de charts encontrada" -ForegroundColor Green
    $global:successCount++

    $chartFolders = @("rabbitmq", "mongodb")
    foreach ($chart in $chartFolders) {
        $chartPath = Join-Path $chartsPath $chart
        if (Test-Path $chartPath) {
            Write-Host "  $emoji_success Chart '$chart' encontrado" -ForegroundColor Green
            $global:successCount++

            $chartFiles = @("Chart.yaml", "values.yaml")
            foreach ($file in $chartFiles) {
                if (Test-Path (Join-Path $chartPath $file)) {
                    Write-Host "    $emoji_success $file encontrado" -ForegroundColor Green
                    $global:successCount++
                } else {
                    Write-Host "    $emoji_error $file NAO encontrado em '$chart'" -ForegroundColor Red
                    $global:failureCount++
                }
            }

            $templatesPath = Join-Path $chartPath "templates"
            if (Test-Path $templatesPath) {
                Write-Host "    $emoji_success Pasta 'templates' encontrada" -ForegroundColor Green
                $global:successCount++
            } else {
                Write-Host "    $emoji_error Pasta 'templates' NAO encontrada em '$chart'" -ForegroundColor Red
                $global:failureCount++
            }
        } else {
            Write-Host "  $emoji_error Chart '$chart' NAO encontrado" -ForegroundColor Red
            $global:failureCount++
        }
    }
} else {
    Write-Host "$emoji_error Pasta de charts NAO encontrada" -ForegroundColor Red
    $global:failureCount++
}

# --- Teste Especifico para Estrutura Linux ---
$linuxChecks = @(
    @{ Category = "Scripts de Inicializacao (Linux)"; Directory = "scripts\linux\init"; Files = @("start.sh") },
    @{ Category = "Scripts de Manutencao (Linux)"; Directory = "scripts\linux\maintenance"; Files = @("status.sh", "dashboard.sh", "test-rabbitmq.sh") },
    @{ Category = "Scripts KEDA (Linux)"; Directory = "scripts\linux\keda"; Files = @("install-helm.sh", "install-keda.sh", "test-keda.sh") },
    @{ Category = "Atalhos de Inicializacao (Linux)"; Directory = ""; Files = @("init-minikube-linux.sh") }
)

# --- Teste Especifico para Estrutura macOS ---
$macOsChecks = @(
    @{ Category = "Scripts de Inicializacao (macOS)"; Directory = "scripts\macOs\init"; Files = @("start.sh") },
    @{ Category = "Scripts de Manutencao (macOS)"; Directory = "scripts\macOs\maintenance"; Files = @("status.sh", "dashboard.sh", "test-rabbitmq.sh") },
    @{ Category = "Scripts KEDA (macOS)"; Directory = "scripts\macOs\keda"; Files = @("install-helm.sh", "install-keda.sh", "test-keda.sh") },
    @{ Category = "Atalhos de Inicializacao (macOS)"; Directory = ""; Files = @("init-minikube-macos.sh") }
)

Write-Host "`nTestando estrutura de Scripts Linux..." -ForegroundColor Yellow
foreach ($check in $linuxChecks) {
    Test-Files -Category $check.Category -Directory $check.Directory -Files $check.Files
}

Write-Host "`nTestando estrutura de Scripts macOS..." -ForegroundColor Yellow
foreach ($check in $macOsChecks) {
    Test-Files -Category $check.Category -Directory $check.Directory -Files $check.Files
}


Write-Host "`n=====================================" -ForegroundColor Cyan
if ($global:failureCount -eq 0) {
    Write-Host "$emoji_success SUCESSO! ESTRUTURA COMPLETA E CONSISTENTE!" -ForegroundColor Green
} else {
    Write-Host "$emoji_error FALHA! Foram encontrados $($global:failureCount) problemas na estrutura." -ForegroundColor Red
}
Write-Host "Total de verificacoes: $($global:successCount + $global:failureCount) | Sucessos: $($global:successCount) | Falhas: $($global:failureCount)" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "`nPROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Inicializar (sem KEDA):" -ForegroundColor White
Write-Host "   $basePath\scripts\windows\init\start.ps1" -ForegroundColor Gray
Write-Host "2. Inicializar (com KEDA):" -ForegroundColor White  
Write-Host "   $basePath\scripts\windows\init\start.ps1 -InstallKeda" -ForegroundColor Gray
Write-Host "3. Verificar status:" -ForegroundColor White
Write-Host "   $basePath\scripts\windows\maintenance\status.ps1" -ForegroundColor Gray
Write-Host "4. Dashboard:" -ForegroundColor White
Write-Host "   $basePath\scripts\windows\monitoring\dashboard-open.ps1" -ForegroundColor Gray
Write-Host "5. Documentacao:" -ForegroundColor White
Write-Host "   $basePath\docs\README.md" -ForegroundColor Gray
Write-Host "6. Documentacao KEDA:" -ForegroundColor White
Write-Host "   $basePath\docs\KEDA.md" -ForegroundColor Gray
if ($projectPaths) {
    Write-Host "7. Scripts Linux:" -ForegroundColor White
    Write-Host "   $($projectPaths.Root)\scripts\linux\README.md" -ForegroundColor Gray
}

Write-Host "`nTESTE CONCLUIDO!" -ForegroundColor Green
