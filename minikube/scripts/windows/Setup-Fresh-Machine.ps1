# Setup-Fresh-Machine.ps1
# Script de instalacao completa para maquina nova Windows
# Instala automaticamente: Docker Desktop, Minikube, kubectl, Helm
# Configurado para usar paths dinamicos e ambiente completo Minikube DevOps


param(
    [switch]$SkipDockerInstall,
    [switch]$SkipMinikubeInstall,
    [switch]$SkipKubectlInstall,
    [switch]$SkipHelmInstall,
    [switch]$SkipValidation,
    [switch]$RunInitialization
)

# Forcar a codificacao UTF-8 para exibir icones corretamente
$PSDefaultParameterValues['*:Encoding'] = 'utf8'


# Importar funcoes de deteccao de paths se disponivel
$getProjectRootScript = Join-Path $PSScriptRoot "Get-ProjectRoot.ps1"
if (Test-Path $getProjectRootScript) {
    . $getProjectRootScript
    Write-Host "Detectando pasta raiz do projeto..." -ForegroundColor Yellow
    try {
        $projectPaths = Get-ProjectPaths
        Write-Host "Pasta raiz detectada: $($projectPaths.Root)" -ForegroundColor Green
    } catch {
        Write-Warning "Erro na deteccao de paths. Usando paths relativos."
        $projectPaths = $null
    }
} else {
    Write-Warning "Get-ProjectRoot.ps1 nao encontrado. Setup independente."
    $projectPaths = $null
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "SETUP COMPLETO - MAQUINA NOVA WINDOWS" -ForegroundColor Green
Write-Host "Minikube DevOps Environment - Instalacao Automatica" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Funcoes utilitarias
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminRights {
    if (-not (Test-AdminRights)) {
        Write-Host "  Este script requer privilegios de Administrador!" -ForegroundColor Yellow
        Write-Host "Reiniciando como Administrador..." -ForegroundColor Yellow
        
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if ($SkipDockerInstall) { $arguments += " -SkipDockerInstall" }
        if ($SkipMinikubeInstall) { $arguments += " -SkipMinikubeInstall" }
        if ($SkipKubectlInstall) { $arguments += " -SkipKubectlInstall" }
        if ($SkipHelmInstall) { $arguments += " -SkipHelmInstall" }
        if ($SkipValidation) { $arguments += " -SkipValidation" }
        if ($RunInitialization) { $arguments += " -RunInitialization" }
        
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
        exit
    }
}

function Test-WindowsFeature($featureName) {
    try {
        $feature = Get-WindowsOptionalFeature -FeatureName $featureName -Online -ErrorAction SilentlyContinue
        return $feature.State -eq "Enabled"
    } catch {
        return $false
    }
}

function Enable-WindowsFeature($featureName, $displayName) {
    Write-Host "Habilitando $displayName..." -ForegroundColor Yellow
    try {
        Enable-WindowsOptionalFeature -FeatureName $featureName -Online -All -NoRestart -ErrorAction Stop
        Write-Host " $displayName habilitado" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " Erro ao habilitar $displayName`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Download-File($url, $outputPath) {
    try {
        Write-Host "Baixando: $url" -ForegroundColor Gray
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $outputPath)
        return $true
    } catch {
        Write-Host " Erro no download: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-DockerRunning {
    try {
        docker version 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Wait-DockerReady {
    param([int]$TimeoutSeconds = 120)
    
    $elapsed = 0
    Write-Host "Aguardando Docker ficar pronto..." -ForegroundColor Yellow
    
    while ($elapsed -lt $TimeoutSeconds) {
        if (Test-DockerRunning) {
            Write-Host " Docker pronto!" -ForegroundColor Green
            return $true
        }
        
        Start-Sleep -Seconds 5
        $elapsed += 5
        
        if ($elapsed % 20 -eq 0) {
            Write-Host " Aguardando Docker... ($elapsed/$TimeoutSeconds segundos)" -ForegroundColor Yellow
        }
    }
    
    Write-Host " Timeout: Docker nao ficou pronto em $TimeoutSeconds segundos" -ForegroundColor Red
    return $false
}

# Verificar privilegios de administrador
Request-AdminRights

Write-Host "`n VERIFICACAO INICIAL DO SISTEMA" -ForegroundColor Yellow
Write-Host "Verificando prerequisitos do Windows..." -ForegroundColor White

# Verificar versao do Windows
$osVersion = [System.Environment]::OSVersion.Version
Write-Host "Sistema: Windows $($osVersion.Major).$($osVersion.Minor)" -ForegroundColor White

if ($osVersion.Major -lt 10) {
    Write-Host " Windows 10 ou superior necessario!" -ForegroundColor Red
    exit 1
}

# Verificar e habilitar Hyper-V (se necessario)
if (-not (Test-WindowsFeature "Microsoft-Hyper-V-All")) {
    Write-Host "  Hyper-V nao esta habilitado" -ForegroundColor Yellow
    $enableHyperV = Read-Host "Habilitar Hyper-V? (Requer reinicializacao) [y/N]"
    if ($enableHyperV -eq 'y' -or $enableHyperV -eq 'Y') {
        if (Enable-WindowsFeature "Microsoft-Hyper-V-All" "Hyper-V") {
            Write-Host "  REQUER REINICIALIZACAO DO SISTEMA!" -ForegroundColor Yellow
            Write-Host "Execute este script novamente apos reiniciar." -ForegroundColor Yellow
            Read-Host "Pressione Enter para continuar..."
            exit 0
        }
    }
} else {
    Write-Host " Hyper-V ja esta habilitado" -ForegroundColor Green
}

# Verificar e habilitar WSL2
if (-not (Test-WindowsFeature "Microsoft-Windows-Subsystem-Linux")) {
    Write-Host "  WSL2 nao esta habilitado" -ForegroundColor Yellow
    if (Enable-WindowsFeature "Microsoft-Windows-Subsystem-Linux" "WSL2") {
        if (Enable-WindowsFeature "VirtualMachinePlatform" "Virtual Machine Platform") {
            Write-Host "  REQUER REINICIALIZACAO DO SISTEMA!" -ForegroundColor Yellow
            Write-Host "Execute este script novamente apos reiniciar." -ForegroundColor Yellow
            Read-Host "Pressione Enter para continuar..."
            exit 0
        }
    }
} else {
    Write-Host " WSL2 ja esta habilitado" -ForegroundColor Green
}

Write-Host "`n INSTALACAO DE DEPENDENCIAS" -ForegroundColor Yellow

# Criar diretorio temporario
$tempDir = Join-Path $env:TEMP "MinikubeDevOpsSetup"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Criar diretorio bin do usuario
$userBinPath = "$env:USERPROFILE\bin"
if (-not (Test-Path $userBinPath)) {
    New-Item -ItemType Directory -Path $userBinPath -Force | Out-Null
    Write-Host "Criado diretorio: $userBinPath" -ForegroundColor Green
}

# Configurar PATH do usuario
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$userBinPath*") {
    $newPath = "$userBinPath;$currentPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$userBinPath;$env:PATH"
    Write-Host " PATH atualizado para incluir $userBinPath" -ForegroundColor Green
}

Write-Host "`n1 DOCKER DESKTOP" -ForegroundColor Cyan

if ($SkipDockerInstall) {
    Write-Host "Pulando instalacao do Docker Desktop (parametro -SkipDockerInstall)" -ForegroundColor Yellow
} elseif (Test-Command "docker") {
    Write-Host " Docker Desktop ja esta instalado" -ForegroundColor Green
    $dockerVersion = docker --version 2>$null
    Write-Host "Versao: $dockerVersion" -ForegroundColor White
    
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker nao esta rodando. Tentando iniciar..." -ForegroundColor Yellow
        # Tentar encontrar e iniciar Docker Desktop
        $dockerPaths = @(
            "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
            "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
            "$env:LOCALAPPDATA\Programs\Docker\Docker\Docker Desktop.exe"
        )
        
        $dockerExe = $null
        foreach ($path in $dockerPaths) {
            if (Test-Path $path) {
                $dockerExe = $path
                break
            }
        }
        
        if ($dockerExe) {
            Start-Process -FilePath $dockerExe -WindowStyle Hidden
            Wait-DockerReady
        } else {
            Write-Host " Nao foi possivel encontrar Docker Desktop executavel" -ForegroundColor Red
        }
    } else {
        Write-Host " Docker Desktop esta rodando" -ForegroundColor Green
    }
} else {
    Write-Host "Docker Desktop nao encontrado. Instalando..." -ForegroundColor Yellow
    
    # Download Docker Desktop
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = Join-Path $tempDir "DockerDesktopInstaller.exe"
    
    Write-Host "Baixando Docker Desktop..." -ForegroundColor White
    if (Download-File $dockerUrl $dockerInstaller) {
        Write-Host "Executando instalador do Docker Desktop..." -ForegroundColor White
        Write-Host "  Isto pode demorar varios minutos e pode requerer reinicializacao!" -ForegroundColor Yellow
        
        # Executar instalador
        $process = Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host " Docker Desktop instalado com sucesso!" -ForegroundColor Green
            Write-Host "Aguardando Docker inicializar..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            
            # Tentar iniciar Docker Desktop
            $dockerDesktopPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerDesktopPath) {
                Start-Process -FilePath $dockerDesktopPath -WindowStyle Hidden
                Wait-DockerReady -TimeoutSeconds 300
            }
        } else {
            Write-Host " Erro na instalacao do Docker Desktop (Exit Code: $($process.ExitCode))" -ForegroundColor Red
            Write-Host "Tente instalar manualmente: https://docs.docker.com/desktop/windows/install/" -ForegroundColor Yellow
        }
    } else {
        Write-Host " Falha no download do Docker Desktop" -ForegroundColor Red
    }
}

Write-Host "`n2 MINIKUBE" -ForegroundColor Cyan

if ($SkipMinikubeInstall) {
    Write-Host "Pulando instalacao do Minikube (parametro -SkipMinikubeInstall)" -ForegroundColor Yellow
} elseif (Test-Command "minikube") {
    Write-Host " Minikube ja esta instalado" -ForegroundColor Green
    $minikubeVersion = minikube version --short 2>$null
    Write-Host "Versao: $minikubeVersion" -ForegroundColor White
} else {
    Write-Host "Minikube nao encontrado. Instalando..." -ForegroundColor Yellow
    
    # Download Minikube
    $minikubeUrl = "https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe"
    $minikubeExe = Join-Path $userBinPath "minikube.exe"
    
    Write-Host "Baixando Minikube..." -ForegroundColor White
    if (Download-File $minikubeUrl $minikubeExe) {
        Write-Host " Minikube instalado em: $minikubeExe" -ForegroundColor Green
        
        # Testar instalacao
        $minikubeVersion = & $minikubeExe version --short 2>$null
        Write-Host "Versao: $minikubeVersion" -ForegroundColor White
    } else {
        Write-Host " Falha no download do Minikube" -ForegroundColor Red
    }
}

Write-Host "`n3 KUBECTL" -ForegroundColor Cyan

if ($SkipKubectlInstall) {
    Write-Host "Pulando instalacao do kubectl (parametro -SkipKubectlInstall)" -ForegroundColor Yellow
} elseif (Test-Command "kubectl") {
    Write-Host " kubectl ja esta instalado" -ForegroundColor Green
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "Versao: $kubectlVersion" -ForegroundColor White
} else {
    Write-Host "kubectl nao encontrado. Instalando..." -ForegroundColor Yellow
    
    # Download kubectl
    try {
        # Obter versao estavel
        $stableVersion = (Invoke-RestMethod -Uri "https://dl.k8s.io/release/stable.txt").Trim()
        $kubectlUrl = "https://dl.k8s.io/release/$stableVersion/bin/windows/amd64/kubectl.exe"
        $kubectlExe = Join-Path $userBinPath "kubectl.exe"
        
        Write-Host "Baixando kubectl versao $stableVersion..." -ForegroundColor White
        if (Download-File $kubectlUrl $kubectlExe) {
            Write-Host " kubectl instalado em: $kubectlExe" -ForegroundColor Green
            
            # Testar instalacao
            $kubectlVersion = & $kubectlExe version --client --short 2>$null
            Write-Host "Versao: $kubectlVersion" -ForegroundColor White
        } else {
            Write-Host " Falha no download do kubectl" -ForegroundColor Red
        }
    } catch {
        Write-Host " Erro ao obter versao do kubectl: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n4 HELM" -ForegroundColor Cyan

if ($SkipHelmInstall) {
    Write-Host "Pulando instalacao do Helm (parametro -SkipHelmInstall)" -ForegroundColor Yellow
} elseif (Test-Command "helm") {
    Write-Host " Helm ja esta instalado" -ForegroundColor Green
    $helmVersion = helm version --short 2>$null
    Write-Host "Versao: $helmVersion" -ForegroundColor White
} else {
    Write-Host "Helm nao encontrado. Instalando..." -ForegroundColor Yellow
    
    try {
        # Obter ultima versao do Helm
        $helmReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/helm/helm/releases/latest"
        $helmVersion = $helmReleases.tag_name
        $helmUrl = "https://get.helm.sh/helm-$helmVersion-windows-amd64.zip"
        $helmZip = Join-Path $tempDir "helm.zip"
        
        Write-Host "Baixando Helm $helmVersion..." -ForegroundColor White
        if (Download-File $helmUrl $helmZip) {
            # Extrair Helm
            $helmExtractPath = Join-Path $tempDir "helm"
            if (Test-Path $helmExtractPath) {
                Remove-Item $helmExtractPath -Recurse -Force
            }
            
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($helmZip, $helmExtractPath)
            
            # Copiar helm.exe
            $helmSource = Join-Path $helmExtractPath "windows-amd64\helm.exe"
            $helmDestination = Join-Path $userBinPath "helm.exe"
            
            if (Test-Path $helmSource) {
                Copy-Item $helmSource $helmDestination -Force
                Write-Host " Helm instalado em: $helmDestination" -ForegroundColor Green
                
                # Testar instalacao
                $helmVersionInstalled = & $helmDestination version --short 2>$null
                Write-Host "Versao: $helmVersionInstalled" -ForegroundColor White
            } else {
                Write-Host " Arquivo helm.exe nao encontrado no pacote" -ForegroundColor Red
            }
        } else {
            Write-Host " Falha no download do Helm" -ForegroundColor Red
        }
    } catch {
        Write-Host " Erro na instalacao do Helm: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Validacao final
if (-not $SkipValidation) {
    Write-Host "`n VALIDACAO FINAL" -ForegroundColor Yellow
    
    $validationPassed = $true
    
    # Testar Docker
    if (Test-Command "docker") {
        if (Test-DockerRunning) {
            Write-Host " Docker: Instalado e funcionando" -ForegroundColor Green
        } else {
            Write-Host "  Docker: Instalado mas nao esta rodando" -ForegroundColor Yellow
            $validationPassed = $false
        }
    } else {
        Write-Host " Docker: Nao instalado" -ForegroundColor Red
        $validationPassed = $false
    }
    
    # Testar Minikube
    if (Test-Command "minikube") {
        Write-Host " Minikube: Instalado" -ForegroundColor Green
    } else {
        Write-Host " Minikube: Nao instalado" -ForegroundColor Red
        $validationPassed = $false
    }
    
    # Testar kubectl
    if (Test-Command "kubectl") {
        Write-Host " kubectl: Instalado" -ForegroundColor Green
    } else {
        Write-Host " kubectl: Nao instalado" -ForegroundColor Red
        $validationPassed = $false
    }
    
    # Testar Helm
    if (Test-Command "helm") {
        Write-Host " Helm: Instalado" -ForegroundColor Green
    } else {
        Write-Host " Helm: Nao instalado" -ForegroundColor Red
        $validationPassed = $false
    }
    
    if ($validationPassed) {
        Write-Host "`n SETUP CONCLUIDO COM SUCESSO!" -ForegroundColor Green
        Write-Host "Todas as dependencias foram instaladas e validadas." -ForegroundColor White
        
        if ($RunInitialization -and $projectPaths) {
            Write-Host "`n EXECUTANDO INICIALIZACAO AUTOMATICA" -ForegroundColor Yellow
            $initScript = Join-Path $projectPaths.Scripts.Windows.Init "init-minikube-fixed.ps1"
            if (Test-Path $initScript) {
                Write-Host "Executando: $initScript" -ForegroundColor White
                & $initScript
            } else {
                Write-Host "  Script de inicializacao nao encontrado: $initScript" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`n< PROXIMOS PASSOS:" -ForegroundColor Yellow
        if ($projectPaths) {
            Write-Host "1. Inicializar ambiente:" -ForegroundColor White
            Write-Host "   $($projectPaths.Scripts.Windows.Init)\init-minikube-fixed.ps1" -ForegroundColor Gray
            Write-Host "2. Testar estrutura:" -ForegroundColor White
            Write-Host "   $($projectPaths.Minikube)\windows-test-structure.ps1" -ForegroundColor Gray
        } else {
            Write-Host "1. Reinicie o PowerShell para atualizar PATH" -ForegroundColor White
            Write-Host "2. Execute: minikube start --driver=docker" -ForegroundColor White
            Write-Host "3. Execute: kubectl cluster-info" -ForegroundColor White
        }
        
    } else {
        Write-Host "`n SETUP INCOMPLETO" -ForegroundColor Red
        Write-Host "Algumas dependencias nao foram instaladas corretamente." -ForegroundColor White
        Write-Host "Verifique os erros acima e tente novamente." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nValidacao pulada (parametro -SkipValidation)" -ForegroundColor Yellow
}

# Limpeza
Write-Host "`n Limpando arquivos temporarios..." -ForegroundColor Gray
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "SETUP FINALIZADO!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

Read-Host "Pressione Enter para continuar..."

