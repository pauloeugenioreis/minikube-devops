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
$getProjectRootScript = Join-Path $PSScriptRoot "scripts\windows\Get-ProjectRoot.ps1"
if (Test-Path $getProjectRootScript) {
    . $getProjectRootScript
    Write-Host "Detectando pasta raiz do projeto..." -ForegroundColor Yellow
    $projectPaths = Get-ProjectPaths
    $basePath = $projectPaths.Minikube
    Write-Host "Pasta base detectada: $basePath" -ForegroundColor Green
} else {
    Write-Warning "Get-ProjectRoot.ps1 nao encontrado. Usando deteccao baseada no script atual."
    # Assumir que o script esta em minikube/
    $basePath = $PSScriptRoot
    Write-Host "Pasta base (relativa): $basePath" -ForegroundColor Yellow
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
    @{ Category = "Script de Inicializacao"; Directory = "scripts\windows\init"; Files = @("init-minikube-fixed.ps1", "apply-rabbitmq-config.ps1", "install-keda.ps1") },
    @{ Category = "Scripts de Manutencao"; Directory = "scripts\windows\maintenance"; Files = @("fix-dashboard.ps1", "quick-status.ps1", "fix-kubectl-final.ps1", "validate-rabbitmq-config.ps1", "fix-dashboard-cronjob.ps1") },
    @{ Category = "Scripts de Monitoramento"; Directory = "scripts\windows\monitoring"; Files = @("open-dashboard.ps1", "change-dashboard-port.ps1") },
    @{ Category = "Scripts KEDA"; Directory = "scripts\windows\keda"; Files = @("install-helm-fixed.ps1", "install-keda.ps1", "test-keda.ps1") },
    @{ Category = "Scripts Autostart"; Directory = "scripts\windows\autostart"; Files = @("minikube-autostart.bat") },
    @{ Category = "Setup de Maquina Nova"; Directory = "scripts\windows"; Files = @("Setup-Fresh-Machine.ps1", "Bootstrap-DevOps.ps1") },
    @{ Category = "Configs KEDA"; Directory = "configs\keda\examples"; Files = @("cpu-scaling-example.yaml", "memory-scaling-example.yaml", "rabbitmq-scaling-example.yaml") },
    @{ Category = "Documentacao"; Directory = "docs"; Files = @("README.md", "KEDA.md") },
    @{ Category = "Documentacao Fresh Machine"; Directory = "docs\fresh-machine"; Files = @("SETUP.md", "DEMO.md", "CHECKLIST.md") },
    @{ Category = "Checklists na Raiz"; Directory = ""; Files = @("STRUCTURE-UPDATES-CHECKLIST.md", "MANDATORY-CHECKLIST.md", "DECISIONS-HISTORY.md", "DYNAMIC-PATHS.md", "MINIKUBE-PROJECT-HISTORY.md", "CONTINUITY-PROMPT.md", "BACKUP-PROMPT.md"); BasePath = if ($projectPaths) { $projectPaths.Root } else { $null } }
)

# --- Execucao dos Testes ---
foreach ($check in $fileChecks) {
    # Pular verificacoes que dependem da raiz do projeto se ela nao foi detectada
    if ($check.BasePath -eq $null -and $check.Category -eq "Checklists na Raiz") {
        Write-Host "`nVerificacao de '$($check.Category)' pulada (raiz do projeto nao detectada)" -ForegroundColor Yellow
        continue
    }
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

# --- Teste Especefico para Estrutura Linux ---
$linuxChecks = @(
    @{ Category = "Scripts de Inicializacao (Linux)"; Directory = "scripts\linux\init"; Files = @("init-minikube-fixed.sh") },
    @{ Category = "Scripts de Manutencao (Linux)"; Directory = "scripts\linux\maintenance"; Files = @("fix-dashboard.sh", "validate-rabbitmq-config.sh") },
    @{ Category = "Scripts de Monitoramento (Linux)"; Directory = "scripts\linux\monitoring"; Files = @("open-dashboard.sh", "change-dashboard-port.sh") },
    @{ Category = "Scripts KEDA (Linux)"; Directory = "scripts\linux\keda"; Files = @("install-helm-fixed.sh", "install-keda.sh", "test-keda.sh") },
    @{ Category = "Scripts Autostart (Linux)"; Directory = "scripts\linux\autostart"; Files = @("minikube-autostart.sh") },
    @{ Category = "Script de Teste de Estrutura (Linux)"; Directory = ""; Files = @("linux-test-structure.sh") }
)

Write-Host "`nTestando estrutura de Scripts Linux..." -ForegroundColor Yellow

foreach ($check in $linuxChecks) {
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
Write-Host "   $basePath\scripts\windows\init\init-minikube-fixed.ps1" -ForegroundColor Gray
Write-Host "2. Inicializar (com KEDA):" -ForegroundColor White  
Write-Host "   $basePath\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda" -ForegroundColor Gray
Write-Host "3. Verificar status:" -ForegroundColor White
Write-Host "   $basePath\scripts\windows\maintenance\quick-status.ps1" -ForegroundColor Gray
Write-Host "4. Dashboard:" -ForegroundColor White
Write-Host "   $basePath\scripts\windows\monitoring\open-dashboard.ps1" -ForegroundColor Gray
Write-Host "5. Documentacao:" -ForegroundColor White
Write-Host "   $basePath\docs\README.md" -ForegroundColor Gray
Write-Host "6. Documentacao KEDA:" -ForegroundColor White
Write-Host "   $basePath\docs\KEDA.md" -ForegroundColor Gray
Write-Host "7. Fresh Machine Setup:" -ForegroundColor White
Write-Host "   $basePath\docs\fresh-machine\SETUP.md" -ForegroundColor Gray
if ($projectPaths) {
    Write-Host "7. Scripts Linux (desenvolvimento):" -ForegroundColor White
    Write-Host "   $($projectPaths.TempLinuxScripts)\README.md" -ForegroundColor Gray
}

Write-Host "`nTESTE CONCLUIDO!" -ForegroundColor Green
