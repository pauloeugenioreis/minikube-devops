# SOLUCAO COMPLETA - Compatibilidade kubectl/Kubernetes
# Este script resolve definitivamente problemas de incompatibilidade
# Execute sempre que vir avisos sobre versoes incompativeis

param(
    [switch]$AutoElevate,
    [switch]$SkipElevationCheck
)

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$scriptPath = $MyInvocation.MyCommand.Path
$isAdmin = Test-IsAdministrator
function Test-RequiresAdminPath {
    param([string]$Path)

    if (-not $Path) {
        return $false
    }

    $normalized = ($Path -replace '/', '\').Trim()
    $programFilesRoots = @()
    $pf = [Environment]::GetFolderPath('ProgramFiles')
    if ($pf) { $programFilesRoots += $pf }
    $pf86 = [Environment]::GetFolderPath('ProgramFilesX86')
    if ($pf86) { $programFilesRoots += $pf86 }

    foreach ($root in $programFilesRoots) {
        if ($normalized.StartsWith($root, [System.StringComparison]::InvariantCultureIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Get-KubectlPaths {
    param([string[]]$SeedPaths)

    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($seed in ($SeedPaths | Where-Object { $_ })) {
        $trimmed = $seed.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
            $candidates.Add($trimmed) | Out-Null
        }
    }

    $kubectlCommands = Get-Command kubectl -ErrorAction SilentlyContinue -All
    foreach ($cmd in ($kubectlCommands | Where-Object { $_ })) {
        foreach ($prop in 'Source', 'Definition', 'Path') {
            $value = $cmd.$prop
            if ($value -and -not [string]::IsNullOrWhiteSpace($value)) {
                $candidates.Add($value.Trim()) | Out-Null
            }
        }
    }

    try {
        $whereOutput = & where.exe kubectl 2>$null
        foreach ($path in ($whereOutput | Where-Object { $_ })) {
            $candidates.Add($path.Trim()) | Out-Null
        }
    } catch {
        # Ignorar se where.exe nao estiver disponivel ou nao encontrar nada
    }

    $unique = $candidates | Where-Object { $_ -and (Test-Path $_) } | Sort-Object -Unique
    if (-not $unique) {
        return ($SeedPaths | Where-Object { $_ }) | Sort-Object -Unique
    }
    return $unique
}



if (-not $SkipElevationCheck -and $AutoElevate -and -not $isAdmin) {
    Write-Host "Solicitando elevacao de privilegios..." -ForegroundColor Yellow
    $arguments = @(
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File',
        ('"{0}"' -f $scriptPath)
    )
    $arguments += '-AutoElevate'
    $arguments += '-SkipElevationCheck'
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs | Out-Null
    exit
}

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
$successfulTargets = @()
try {
    $kubectlJson = minikube kubectl -- version --client -o json 2>$null
    if (-not $kubectlJson) {
        throw "Nao foi possivel obter a versao do kubectl"
    }

    $kubectlVersion = $kubectlJson | ConvertFrom-Json
    $k8sVersion = $kubectlVersion.clientVersion.gitVersion

    if (-not $k8sVersion) {
        $shortOutput = minikube kubectl -- version --client --short 2>$null
        if ($shortOutput) {
            $firstLine = ($shortOutput -split "\r?\n")[0]
            $k8sVersion = ($firstLine -replace 'Client Version: ', '').Trim()
        }
    }

    if (-not $k8sVersion) {
        throw "Nao foi possivel detectar a versao do kubectl"
    }

    Write-Host "   Versao necessaria: $k8sVersion" -ForegroundColor Green

    $userKubectlPath = Join-Path $userBin 'kubectl.exe'
    $targetPaths = Get-KubectlPaths -SeedPaths @($userKubectlPath)

    if (-not $targetPaths) {
        $targetPaths = @($userKubectlPath)
    } elseif (-not ($targetPaths -contains $userKubectlPath)) {
        $targetPaths = @($userKubectlPath) + $targetPaths
    }

    $targetPaths = $targetPaths | Where-Object { $_ } | Sort-Object -Unique

    $failedTargets = @()
    $permissionDeniedTargets = @()

    $adminCandidateTargets = ($targetPaths | Where-Object { Test-RequiresAdminPath $_ }) | Sort-Object -Unique
    if ($adminCandidateTargets -and -not $isAdmin -and -not $AutoElevate) {
        Write-Host "   Aviso: alguns destinos exigem privilegios administrativos: $($adminCandidateTargets -join ', ')" -ForegroundColor Yellow
        Write-Host "   Execute o script em um PowerShell elevado ou utilize '-AutoElevate' para atualizar todos os caminhos." -ForegroundColor Yellow
    }
    # Passo 4: Baixar kubectl correto
    Write-Host "4. Baixando kubectl compativel..." -ForegroundColor Yellow
    $url = "https://dl.k8s.io/release/$k8sVersion/bin/windows/amd64/kubectl.exe"
    $safeVersion = ($k8sVersion -replace '[^0-9A-Za-z\.\-]', '_')
    $tempDownload = Join-Path ([System.IO.Path]::GetTempPath()) ("kubectl-$safeVersion.exe")

    Invoke-WebRequest -Uri $url -OutFile $tempDownload -UseBasicParsing

    if (-not (Test-Path $tempDownload)) {
        throw "Falha no download"
    }

    Write-Host "   Atualizando kubectl nos destinos detectados..." -ForegroundColor Yellow
    foreach ($target in ($targetPaths | Sort-Object -Unique)) {
        try {
            $targetDir = Split-Path $target -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            Copy-Item -Path $tempDownload -Destination $target -Force -ErrorAction Stop
            Write-Host "   kubectl $k8sVersion instalado em $target" -ForegroundColor Green
            $successfulTargets += $target
        } catch {
            $failedTargets += $target

            if ($_.Exception -is [System.UnauthorizedAccessException]) {
                $permissionDeniedTargets += $target

                if (-not $isAdmin) {
                    Write-Host "   Permissao negada ao atualizar ${target}. Reabra o PowerShell como Administrador ou utilize '-AutoElevate'." -ForegroundColor Yellow
                } else {
                    Write-Host "   Permissao negada ao atualizar ${target}: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   Nao foi possivel atualizar ${target}: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    if ($permissionDeniedTargets) {
        $deniedList = ($permissionDeniedTargets | Sort-Object -Unique)
        $joinedDenied = ($deniedList -join ', ')

        if (-not $isAdmin) {
            Write-Host "   AVISO: Estes destinos exigem PowerShell elevado: $joinedDenied" -ForegroundColor Yellow
            if (-not $AutoElevate) {
                Write-Host "   Dica: execute este script como Administrador ou use '-AutoElevate' para tentar novamente automaticamente." -ForegroundColor Yellow
            }
        } else {
            Write-Host "   AVISO: Permissao negada mesmo com privilegios elevados: $joinedDenied" -ForegroundColor Yellow
        }
    }

    if (-not $successfulTargets) {
        throw "Nao foi possivel atualizar kubectl em nenhum destino. Execute o PowerShell como Administrador ou reexecute com '-AutoElevate'."
    }

    Remove-Item -Path $tempDownload -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "   ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Tente executar como administrador" -ForegroundColor Yellow
    exit 1
}

# Passo 5: Verificar instalacao
Write-Host "5. Verificando instalacao..." -ForegroundColor Yellow
try {
    $pathsToValidate = if ($successfulTargets) { $successfulTargets } else { @($userKubectlPath) }
    foreach ($path in ($pathsToValidate | Sort-Object -Unique)) {
        if (Test-Path $path) {
            $installedVersion = & $path version --client --short 2>$null
            Write-Host "   $installedVersion instalado ($path)" -ForegroundColor Green
        } else {
            Write-Host "   Caminho nao encontrado: $path" -ForegroundColor Yellow
        }
    }

    $primaryKubectl = ($pathsToValidate | Where-Object { Test-Path $_ } | Select-Object -First 1)
    if ($primaryKubectl) {
        & $primaryKubectl version 2>$null | Out-Null
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





