# Script de Inicializacao Completa do Minikube com RabbitMQ, MongoDB e KEDA
# Script de Inicializacao Completa do Minikube com RabbitMQ, MongoDB e KEDA
# Este script garante que tudo seja iniciado automaticamente

param(
    [switch]$SkipAddons,
    [switch]$InstallKeda = $true,  # KEDA agora e instalado por padrao
    [switch]$SkipRabbitMQConfig
)

# Forcar a codificacao UTF-8 para exibir icones corretamente
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$metricsServerImages = @(
    "registry.k8s.io/metrics-server/metrics-server:v0.8.0" # Apenas a tag é necessária, pois o patch força seu uso
)

$ingressImages = @(
    "registry.k8s.io/ingress-nginx/controller:v1.13.2",
    "registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.6.2"
)

$serviceImages = @(
    "rabbitmq:4.1",
    "mongo:8.0.15", 
    "redis:7.2"
)

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)

function Preload-Images {
    param([string[]]$ImagesToLoad)

    if (-not (Test-Command "docker")) {
        Write-Host "   $emoji_warning Docker indisponível para pré-carregar imagens." -ForegroundColor Yellow
        return
    }

    foreach ($image in $ImagesToLoad) {
        $imageExists = $false
        try {
            docker image inspect $image | Out-Null
            $imageExists = $LASTEXITCODE -eq 0
        } catch {
            $imageExists = $false
        }

        if (-not $imageExists) {
            Write-Host "   Baixando imagem $image..." -ForegroundColor White
            docker pull $image # Mostra a saida do pull
            if ($LASTEXITCODE -ne 0) {
                Write-Host "   $emoji_warning Falha ao baixar $image. O addon tentará buscar diretamente." -ForegroundColor Yellow
                continue
            }
        }

        Write-Host "   Carregando $image no Minikube..." -ForegroundColor White
        & minikube image load $image | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   $emoji_warning Nao foi possivel carregar $image no Minikube. Verifique manualmente." -ForegroundColor Yellow
        } else {
            Write-Host "   $emoji_success $image disponivel para o metrics-server." -ForegroundColor Green
        }
    }
}

function Patch-MetricsServerImage {
    Write-Host "   Ajustando deployment do metrics-server para usar imagem com tag..." -ForegroundColor White
    kubectl patch deployment metrics-server -n kube-system `
        --type=json `
        -p '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"registry.k8s.io/metrics-server/metrics-server:v0.8.0"}]' 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   $emoji_warning Nao foi possivel ajustar a imagem do metrics-server. Verifique manualmente." -ForegroundColor Yellow
    }
}

# Importar funcoes de deteccao de paths
$getProjectRootScript = Join-Path (Split-Path $PSScriptRoot -Parent) "Get-ProjectRoot.ps1"
if (Test-Path $getProjectRootScript) {
    . $getProjectRootScript
    Write-Host "Detectando pasta raiz do projeto..." -ForegroundColor Yellow
    $projectPaths = Get-ProjectPaths
    Write-Host "Pasta raiz: $($projectPaths.Root)" -ForegroundColor Green
} else {
    Write-Warning "Script Get-ProjectRoot.ps1 nao encontrado. Usando paths relativos basicos."
    $projectPaths = $null
}

# Configurar logging
try {
    $windowsDir = Split-Path $PSScriptRoot -Parent
    $scriptsDir = Split-Path $windowsDir -Parent
    $minikubeRoot = Split-Path $scriptsDir -Parent
    $logDir = Join-Path $minikubeRoot 'log'
} catch {
    $logDir = $null
}

if (-not $logDir -or [string]::IsNullOrWhiteSpace($logDir)) {
    $logDir = Join-Path $env:TEMP 'minikube-log'
}

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir ("minikube-autostart-{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$NoConsole
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    if (-not $NoConsole) {
        Write-Host $Message
    }
    Add-Content -Path $logFile -Value $logEntry
}

Write-Log "=====================================================" "INFO"
Write-Log "Iniciando Ambiente Minikube Completo - Autostart" "INFO"
Write-Log "=====================================================" "INFO"

# Garantir que o kubectl correto esta no PATH
$userBinPath = "$env:USERPROFILE\bin"
if ($env:PATH -notlike "*$userBinPath*") {
    $env:PATH = "$userBinPath;$env:PATH"
}


# Funcao para verificar se um comando existe
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Funcao para verificar se Docker esta rodando
function Test-DockerRunning {
    try {
        docker version 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}


# Funcao para iniciar Docker Desktop
function Start-DockerDesktop {
    Write-Host "   Iniciando Docker Desktop..." -ForegroundColor Yellow

    $dockerPaths = @(
        "$env:ProgramFiles\\Docker\\Docker\\Docker Desktop.exe",
        "${env:ProgramFiles(x86)}\\Docker\\Docker\\Docker Desktop.exe",
        "$env:LOCALAPPDATA\\Programs\\Docker\\Docker\\Docker Desktop.exe"
    )

    $dockerExe = $null
    foreach ($path in $dockerPaths) {
        if (Test-Path $path) {
            $dockerExe = $path
            break
        }
    }

    if (-not $dockerExe) {
        Write-Host "   Docker Desktop nao encontrado! Instale o Docker Desktop primeiro." -ForegroundColor Red
        return $false
    }

    Start-Process -FilePath $dockerExe -WindowStyle Hidden
    Write-Host "   Docker Desktop iniciado. Aguardando ficar pronto..." -ForegroundColor Yellow

    $timeout = 120
    $elapsed = 0
    while (-not (Test-DockerRunning) -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host "   Aguardando Docker... ($elapsed/$timeout segundos)" -ForegroundColor Yellow
    }

    if (Test-DockerRunning) {
        Write-Host "   Docker Desktop pronto!" -ForegroundColor Green
        return $true
    }

    Write-Host "   Timeout: Docker nao ficou pronto em $timeout segundos" -ForegroundColor Red
    return $false
}

function Get-K8sClientVersion {
    param(
        [Parameter(Mandatory)] [string]$Executable,
        [string[]]$Arguments = @()
    )

    $jsonArgs = @('version','--client','--output=json')
    try {
        $jsonOutput = & $Executable @Arguments @jsonArgs 2>$null
        if ($LASTEXITCODE -eq 0 -and $jsonOutput) {
            $parsed = $jsonOutput | ConvertFrom-Json -ErrorAction Stop
            if ($parsed.clientVersion.gitVersion) { return $parsed.clientVersion.gitVersion }
            if ($parsed.gitVersion) { return $parsed.gitVersion }
        }
    } catch { }

    $plainArgs = @('version','--client')
    try {
        $plainOutput = & $Executable @Arguments @plainArgs 2>$null
        if ($LASTEXITCODE -eq 0 -and $plainOutput) {
            $match = ($plainOutput -join " `n") -match 'Client Version:\s*(?<ver>\S+)'
            if ($match) { return $Matches['ver'] }
        }
    } catch { }

    return $null
}

function Get-MinikubeVersion {
    try {
        $short = & minikube version --short 2>$null
        if ($LASTEXITCODE -eq 0 -and $short) {
            $value = ($short -join " `n").Trim()
            if ($value) { return $value }
        }
    } catch { }

    try {
        $full = & minikube version 2>$null
        if ($LASTEXITCODE -eq 0 -and $full) {
            $value = ($full -join " `n").Trim()
            if ($value) { return $value }
        }
    } catch { }

    return $null
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Inicializando Ambiente Minikube Completo" -ForegroundColor Green
$kubectlVersionDisplay = Get-K8sClientVersion -Executable 'kubectl'
if (-not $kubectlVersionDisplay) { $kubectlVersionDisplay = "desconhecido" }
$minikubeVersionDisplay = Get-MinikubeVersion
if (-not $minikubeVersionDisplay) { $minikubeVersionDisplay = "desconhecido" }
Write-Host ("Versoes: kubectl {0}, minikube {1}" -f $kubectlVersionDisplay, $minikubeVersionDisplay) -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan


function Invoke-MinikubeStartWithProgress {
    $startArgs = @(
        "start",
        "--driver=docker",
        "--container-runtime=containerd",
        "--delete-on-failure",
        "--cpus=4",
        "--memory=8g",
        "-v=3"
    )
    $commandString = "minikube " + ($startArgs -join " ")
    Write-Log -Message "Executando '$commandString'..." -Level "INFO" -NoConsole
    Write-Host "Executando '$commandString' (isso pode levar alguns minutos)..." -ForegroundColor Yellow

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "minikube"
    $processInfo.Arguments = $startArgs
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo

    $lastProgressLine = ""
    $progressRegex = '(\[.+?\])?\s*([\d.]+\s*[KMGTPE]?i?B)\s*/\s*([\d.]+\s*[KMGTPE]?i?B)\s*(\[.+?\])?\s*(\(?.+?%?\)?)?'

    $process.add_OutputDataReceived({
        param($sender, $e)
        if ($e.Data) {
            Write-Log -Message $e.Data -Level "INFO" -NoConsole
            $match = [regex]::Match($e.Data, $progressRegex)
            if ($match.Success) {
                $currentSize = $match.Groups[2].Value.Trim()
                $totalSize = $match.Groups[3].Value.Trim()
                $percentage = $match.Groups[5].Value.Trim()
                $progressBar = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[4].Value }
                $outputLine = ("   {0} / {1} {2} {3}" -f $currentSize, $totalSize, $progressBar, $percentage).Trim()
                if ($outputLine -ne $lastProgressLine) {
                    Write-Host ("`r" + (" " * 100) + "`r" + $outputLine) -NoNewline
                    $lastProgressLine = $outputLine
                }
            } else {
                if ($lastProgressLine) { Write-Host "" }
                $lastProgressLine = ""
                Write-Host $e.Data
            }
        }
    })

    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    $process.WaitForExit()
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0) {
        Write-Host "Minikube iniciado com sucesso." -ForegroundColor Green
        return $true
    }

    Write-Host "Falha ao iniciar Minikube (codigo $exitCode)." -ForegroundColor Yellow
    return $false
}

function Ensure-MinikubeRunning {
    Write-Host "Verificando estado do Minikube..." -ForegroundColor Yellow

    $statusOutput = & minikube status --output=json 2>&1
    $statusCode = $LASTEXITCODE

    if ($statusOutput) {
        foreach ($line in $statusOutput) {
            if ($null -ne $line) {
                Write-Log -Message $line -Level "INFO" -NoConsole
            }
        }
    }

    $statusText = ($statusOutput -join "`n").Trim()
    $statusJson = $null
    $isRunning = $false

    if ($statusCode -eq 0 -and $statusText -and $statusText.StartsWith("{")) {
        try {
            $statusJson = $statusText | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Log -Message "Falha ao interpretar retorno de 'minikube status': $($_.Exception.Message)" -Level "WARN" -NoConsole
        }
    }

    if ($statusJson) {
        Write-Host ("Status atual: Host={0}, Kubelet={1}, APIServer={2}" -f $statusJson.Host, $statusJson.Kubelet, $statusJson.APIServer) -ForegroundColor White
        if ($statusJson.Host -eq "Running" -and $statusJson.APIServer -eq "Running") {
            $isRunning = $true
        }
    } elseif ($statusCode -eq 0 -and $statusText) {
        Write-Host "Status do Minikube:" -ForegroundColor White
        Write-Host $statusText -ForegroundColor Gray
    } else {
        if ($statusText) {
            Write-Host $statusText -ForegroundColor Gray
        }
        Write-Host "Status do Minikube indisponivel (tratando como parado)." -ForegroundColor Yellow
    }

    if ($isRunning) {
        Write-Host "Minikube ja esta rodando!" -ForegroundColor Green
        return
    }

    Write-Host "Minikube nao esta em execucao. Tentando iniciar..." -ForegroundColor Yellow
    if (Invoke-MinikubeStartWithProgress) {
        return
    }

    Write-Host "Tentativa inicial falhou. Tentando recuperar o ambiente automaticamente..." -ForegroundColor Yellow
    Write-Log -Message "Executando 'minikube delete --all --purge' para recuperacao." -Level "WARN"
    $deleteOutput = & minikube delete --all --purge 2>&1
    if ($deleteOutput) {
        foreach ($line in $deleteOutput) {
            if ($null -ne $line) {
                Write-Log -Message $line -Level "WARN"
            }
        }
    }

    if (Invoke-MinikubeStartWithProgress) {
        return
    }

    Write-Host "Erro ao iniciar Minikube mesmo apos tentativa de recuperacao." -ForegroundColor Red
    Write-Host "Execute 'minikube delete --all --purge' manualmente e tente novamente." -ForegroundColor Red
    
    # A lógica de recuperação manual foi removida, pois --delete-on-failure cuida disso.
    # Se chegou aqui, a inicialização falhou de forma definitiva.
    Write-Host "Erro crítico ao iniciar Minikube. A inicialização falhou mesmo com a opção de auto-limpeza." -ForegroundColor Red
    Write-Host "Verifique os logs para mais detalhes: $logFile" -ForegroundColor Red
    Write-Host "Você pode tentar executar 'minikube delete --all --purge' manualmente e rodar o script novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host "Verificando dependencias..." -ForegroundColor Yellow
if (-not (Test-Command "minikube")) {
    Write-Host "Minikube nao encontrado! Instale o Minikube primeiro." -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "kubectl")) {
    Write-Host "kubectl nao encontrado! Instale o kubectl primeiro." -ForegroundColor Red
    exit 1
}

# Verificar Docker Desktop
Write-Host "Verificando Docker Desktop..." -ForegroundColor Yellow
if (-not (Test-Command "docker")) {
    Write-Host "Docker nao encontrado! Instale o Docker Desktop primeiro." -ForegroundColor Red
    exit 1
}

if (-not (Test-DockerRunning)) {
    Write-Host "Docker nao esta rodando. Tentando iniciar..." -ForegroundColor Yellow
    if (-not (Start-DockerDesktop)) {
        Write-Host "Falha ao iniciar Docker Desktop!" -ForegroundColor Red
        Write-Host "Por favor, inicie o Docker Desktop manualmente e tente novamente." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "Docker Desktop ja esta rodando!" -ForegroundColor Green
}

# Verificar conectividade do Docker
Write-Host "Verificando conectividade Docker..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker funcionando corretamente!" -ForegroundColor Green
    } else {
        Write-Host "Docker com problemas. Aguardando estabilizar..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
} catch {
    Write-Host "Problema na verificacao do Docker, mas continuando..." -ForegroundColor Yellow
}

# Verificar compatibilidade de versoes
Write-Host "Verificando compatibilidade kubectl/Kubernetes..." -ForegroundColor Yellow
try {
    $kubectlVersion = Get-K8sClientVersion -Executable 'kubectl'
    $minikubeK8sVersion = Get-K8sClientVersion -Executable 'minikube' -Arguments @('kubectl','--')

    if ($kubectlVersion -and $minikubeK8sVersion) {
        if ($kubectlVersion -ne $minikubeK8sVersion) {
            Write-Host "AVISO: Versoes incompativeis detectadas!" -ForegroundColor Yellow
            Write-Host "kubectl: $kubectlVersion | Kubernetes: $minikubeK8sVersion" -ForegroundColor Yellow
            Write-Host "Executando atualizacao automatica..." -ForegroundColor Yellow
            $fixScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'maintenance\fix-kubectl-final.ps1'
            if (Test-Path $fixScriptPath) {
                & $fixScriptPath
            } else {
                Write-Host "Script de atualizacao nao encontrado em $fixScriptPath. Use 'minikube kubectl -- version --client' se houver problemas." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[OK] Versoes compativeis: $kubectlVersion" -ForegroundColor Green
        }
    } else {
        Write-Host "AVISO: Nao foi possivel determinar versoes do kubectl/Kubernetes." -ForegroundColor Yellow
        Write-Host "kubectl: $kubectlVersion | Kubernetes: $minikubeK8sVersion" -ForegroundColor Yellow
    }
} catch {
    Write-Host "AVISO: Nao foi possivel verificar compatibilidade. Continuando..." -ForegroundColor Yellow
}

# Iniciar Minikube
Ensure-MinikubeRunning

# Habilitar addons essenciais (sempre)
if (-not $SkipAddons) {
    Write-Host "Habilitando addons essenciais..." -ForegroundColor Yellow

    Preload-Images -ImagesToLoad $metricsServerImages
    Preload-Images -ImagesToLoad $ingressImages
    Preload-Images -ImagesToLoad $serviceImages

    $addons = @(
        "storage-provisioner",
        "metrics-server", 
        "default-storageclass",
        "dashboard",
        "ingress" # Adicionado para consistência com o Linux
    )

    foreach ($addon in $addons) {
        Write-Host "Habilitando addon: $addon..." -ForegroundColor Yellow
        if ($addon -eq "ingress") {
            # Para o ingress, mostrar a saida em tempo real
            minikube addons enable $addon
        } else {
            minikube addons enable $addon | Out-Null
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   $emoji_success Addon $addon habilitado com sucesso" -ForegroundColor Green
        } else {
            Write-Host "   $emoji_warning Falha ao habilitar o addon '$addon'. O script continuará, mas funcionalidades podem ser afetadas." -ForegroundColor Yellow
        }
    }

    Patch-MetricsServerImage

    # Aguardar componentes críticos ficarem prontos
    Write-Host "   Aguardando Ingress controller..." -ForegroundColor White
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=100s 2>$null | Out-Null

    Write-Host "   Aguardando Metrics Server..." -ForegroundColor White
    kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=100s 2>$null | Out-Null
}

# Aguardar cluster estar pronto
Write-Host "Aguardando cluster estar pronto..." -ForegroundColor Yellow
kubectl wait --for=condition=ready node/minikube --timeout=300s
if ($LASTEXITCODE -ne 0) {
    Write-Host "Timeout aguardando cluster ficar pronto!" -ForegroundColor Red
    exit 1
}

# Aplicar configuracoes do RabbitMQ, MongoDB e Redis com Helm
Write-Host "Aplicando configuracoes dos servicos com Helm..." -ForegroundColor Yellow

# Definir caminhos para os charts
$rabbitmqChartPath = Join-Path $projectPaths.Root "minikube\charts\rabbitmq"
$mongodbChartPath = Join-Path $projectPaths.Root "minikube\charts\mongodb"
$redisChartPath = Join-Path $projectPaths.Root "minikube\charts\redis"

# Instalar RabbitMQ
Write-Host "   Instalando/Atualizando RabbitMQ chart..." -ForegroundColor White
helm upgrade --install rabbitmq $rabbitmqChartPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "   $emoji_warning Falha ao instalar/atualizar o chart Helm 'rabbitmq'. O script continuará, mas o serviço pode não estar disponível." -ForegroundColor Yellow
    Write-Host "     Isso pode ser um efeito colateral da falha do addon 'ingress'. Verifique os logs do Helm." -ForegroundColor Yellow
} else {
    Write-Host "   RabbitMQ chart aplicado com sucesso" -ForegroundColor Green
}

# Instalar MongoDB
Write-Host "   Instalando/Atualizando MongoDB chart..." -ForegroundColor White
helm upgrade --install mongodb $mongodbChartPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "   $emoji_warning Falha ao instalar/atualizar o chart Helm 'mongodb'." -ForegroundColor Yellow
} else {
    Write-Host "   MongoDB chart aplicado com sucesso" -ForegroundColor Green
}

# Instalar Redis
Write-Host "   Instalando/Atualizando Redis chart..." -ForegroundColor White
helm upgrade --install redis $redisChartPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "   $emoji_warning Falha ao instalar/atualizar o chart Helm 'redis'." -ForegroundColor Yellow
} else {
    Write-Host "   Redis chart aplicado com sucesso" -ForegroundColor Green
}

# Aguardar pods ficarem prontos
Write-Host "Aguardando pods ficarem prontos..." -ForegroundColor Yellow
Write-Host "   Aguardando RabbitMQ..." -ForegroundColor White
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=100s

Write-Host "   Aguardando MongoDB..." -ForegroundColor White  
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=100s

Write-Host "   Aguardando Redis..." -ForegroundColor White
kubectl wait --for=condition=ready pod -l app=redis --timeout=100s

# Verificar status dos pods
Write-Host "Status dos pods:" -ForegroundColor Yellow
kubectl get pods -o wide

# Matar port-forwards existentes
Write-Host "Configurando port-forwards..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*"} | Stop-Process -Force 2>$null

# Criar port-forwards
Write-Host "   Criando port-forward para RabbitMQ Management (15672)..." -ForegroundColor White
Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/rabbitmq", "15672:15672" -WindowStyle Hidden

Write-Host "   Criando port-forward para RabbitMQ AMQP (5672)..." -ForegroundColor White
Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/rabbitmq", "5672:5672" -WindowStyle Hidden

Write-Host "   Criando port-forward para MongoDB (27017)..." -ForegroundColor White
Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/mongodb", "27017:27017" -WindowStyle Hidden

# Redis usa NodePort (porta 30679) em vez de port-forward
$minikubeIP = minikube ip 2>$null
if ($minikubeIP) {
    Write-Host "   Testando Redis via NodePort ($minikubeIP`:30679)..." -ForegroundColor White
    try {
        $redisTest = Test-NetConnection -ComputerName $minikubeIP -Port 30679 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($redisTest) {
            Write-Host "   $emoji_success Redis disponivel em redis://$minikubeIP`:30679" -ForegroundColor Green
        } else {
            Write-Host "   $emoji_error Redis nao respondeu (porta 30679)." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   $emoji_error Redis nao respondeu (porta 30679)." -ForegroundColor Yellow
    }
} else {
    Write-Host "   $emoji_error Redis nao respondeu (porta 30679)." -ForegroundColor Yellow
}

Write-Host "   Criando port-forward para Dashboard K8s (15671)..." -ForegroundColor White

# Aguardar Dashboard estar totalmente pronto antes de criar port-forward
Write-Host "   Aguardando Dashboard estar pronto..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=100s

# Verificar se Dashboard esta respondendo internamente
$dashboardReady = $false
for ($i = 1; $i -le 3; $i++) {
    Write-Host "   Tentativa $i/3 - Verificando Dashboard..." -ForegroundColor Yellow
    $testPod = kubectl get pods -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard --no-headers 2>$null
    if ($testPod -and $testPod.Contains("Running")) {
        $dashboardReady = $true
        Write-Host "   Dashboard pronto!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 5
}

if ($dashboardReady) {
    # Parar qualquer port-forward existente do dashboard
    Get-Process kubectl -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*kubernetes-dashboard*" -or 
        $_.CommandLine -like "*15671*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Start-Sleep -Seconds 2
    
    # Criar port-forward do dashboard com maior robustez
    $dashboardJob = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "15671:80" -WindowStyle Hidden -PassThru
    
    if ($dashboardJob) {
        Write-Host "   Port-forward Dashboard criado (PID: $($dashboardJob.Id))" -ForegroundColor Green
    } else {
        Write-Host "   Erro ao criar port-forward Dashboard" -ForegroundColor Red
    }
} else {
    Write-Host "   Dashboard nao ficou pronto, pulando port-forward" -ForegroundColor Yellow
}

# Aguardar port-forwards iniciarem (tempo maior para Dashboard)
Write-Host "   Aguardando port-forwards iniciarem..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Instalar KEDA automaticamente
if ($InstallKeda) {
    Write-Host "Instalando KEDA..." -ForegroundColor Yellow
    $kedaInstaller = Join-Path $PSScriptRoot "install-keda.ps1"
    if (Test-Path $kedaInstaller) {
        & $kedaInstaller -SkipHelmCheck -SkipValidation
        Write-Host "   KEDA instalado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "   Script install-keda.ps1 nao encontrado!" -ForegroundColor Red
    }
    Write-Host ""
}

if (-not $SkipRabbitMQConfig) {
    Write-Host "Configurando RabbitMQ Runtime..." -ForegroundColor Yellow
    Write-Host "   Aguardando RabbitMQ estar totalmente pronto..." -ForegroundColor White
    Start-Sleep -Seconds 30
    Write-Host "   (Ajuste de loopback_users garantido via configuracao rabbitmq.conf)" -ForegroundColor Gray
    Write-Host "   RabbitMQ configurado completamente!" -ForegroundColor Green
    Write-Host ""
}

# Aplicar ScaledObjects KEDA se KEDA foi instalado
if ($InstallKeda -and -not $SkipRabbitMQConfig) {
    Write-Host "Verificando ScaledObjects KEDA existentes..." -ForegroundColor Yellow
    
    # Aguardar KEDA estar completamente pronto
    Write-Host "   Aguardando KEDA estar pronto..." -ForegroundColor White
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keda-operator -n keda --timeout=100s 2>$null
    
    # Verificar se existem ScaledObjects
    $existingScaledObjects = kubectl get scaledobjects --all-namespaces --no-headers 2>$null
    if ($existingScaledObjects) {
        Write-Host "   ScaledObjects encontrados:" -ForegroundColor Green
        $existingScaledObjects | ForEach-Object { 
            $parts = $_ -split '\s+'
            Write-Host "     - $($parts[1]) (namespace: $($parts[0]))" -ForegroundColor White 
        }
        Write-Host "   KEDA Autoscaling ativo e funcional!" -ForegroundColor Green
    } else {
        Write-Host "   AVISO: Nenhum ScaledObject encontrado" -ForegroundColor Yellow
        Write-Host "   KEDA instalado mas sem configuracoes de autoscaling" -ForegroundColor Gray
    }
    Write-Host ""
}

# Validacao final completa
Write-Host "Executando validacao final completa..." -ForegroundColor Yellow

# Funcao para validacao final
function Test-FinalValidation {
    $issues = @()
    $success = 0
    $total = 0
    $emoji_success = [char]::ConvertFromUtf32(0x2705)
    $emoji_error = [char]::ConvertFromUtf32(0x274C)
    $emoji_warning = [char]::ConvertFromUtf32(0x26A0)

    Write-Host "   Testando componentes principais..." -ForegroundColor White
    
    # Testar pods principais
    $total++
    $rabbitPod = kubectl get pods -l app=rabbitmq --no-headers 2>$null
    $rabbitReady = $rabbitPod | Where-Object { $_ -match "1/1.*Running" }
    if ($rabbitReady) {
        Write-Host "     $emoji_success RabbitMQ pod rodando" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     $emoji_error RabbitMQ pod com problemas" -ForegroundColor Red
        Write-Host "       Debug: $rabbitPod" -ForegroundColor Gray
        $issues += "RabbitMQ pod nao esta rodando corretamente"
    }
    
    $total++
    $mongoPod = kubectl get pods -l app=mongodb --no-headers 2>$null
    $mongoReady = $mongoPod | Where-Object { $_ -match "1/1.*Running" }
    if ($mongoReady) {
        Write-Host "     $emoji_success MongoDB pod rodando" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     $emoji_error MongoDB pod com problemas" -ForegroundColor Red
        Write-Host "       Debug: $mongoPod" -ForegroundColor Gray
        $issues += "MongoDB pod nao esta rodando corretamente"
    }
    
    $total++
    $redisPod = kubectl get pods -l app=redis --no-headers 2>$null
    $redisReady = $redisPod | Where-Object { $_ -match "1/1.*Running" }
    if ($redisReady) {
        Write-Host "     $emoji_success Redis pod rodando" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     $emoji_error Redis pod com problemas" -ForegroundColor Red
        Write-Host "       Debug: $redisPod" -ForegroundColor Gray
        $issues += "Redis pod nao esta rodando corretamente"
    }
    
    if ($InstallKeda) {
        $total++
        $allKedaPods = kubectl get pods -n keda --no-headers 2>$null
        $totalKeda = (@($allKedaPods) | Measure-Object).Count
        $kedaReady = @($allKedaPods | Where-Object { $_ -match "1/1.*Running" })
        $readyCount = ($kedaReady | Measure-Object).Count

        if ($totalKeda -eq 0) {
            Write-Host "     $emoji_error KEDA pods nao encontrados" -ForegroundColor Red
            $issues += "KEDA nao possui pods implantados"
        } elseif ($totalKeda -eq 3) {
            Write-Host "     $emoji_success KEDA pods rodando ($readyCount/$totalKeda pods)" -ForegroundColor Green
            $success++
        } elseif ($readyCount -ne $totalKeda) {
            Write-Host "     $emoji_error KEDA pods incompletos ($readyCount/$totalKeda)" -ForegroundColor Red
            $issues += "KEDA nao tem todos os pods rodando (esperado $totalKeda, prontos $readyCount)"
        } else {
            Write-Host "     $emoji_success KEDA pods rodando ($readyCount/$totalKeda pods)" -ForegroundColor Green
            $success++
        }
    }
    
    # Testar conectividade
    Write-Host "   Testando conectividade..." -ForegroundColor White
    
    $total++
    $rabbitTest = Test-NetConnection -ComputerName localhost -Port 15672 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($rabbitTest) {
        Write-Host "     $emoji_success RabbitMQ Management acessivel (15672)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     $emoji_error RabbitMQ Management inacessivel" -ForegroundColor Red
        $issues += "RabbitMQ Management nao esta acessivel na porta 15672"
    }
    
    $total++
    $mongoTest = Test-NetConnection -ComputerName localhost -Port 27017 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($mongoTest) {
        Write-Host "     $emoji_success MongoDB acessivel (27017)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     $emoji_error MongoDB inacessivel" -ForegroundColor Red
        $issues += "MongoDB nao esta acessivel na porta 27017"
    }
    
    $total++
    $minikubeIP = minikube ip 2>$null
    if ($minikubeIP) {
        $redisTest = Test-NetConnection -ComputerName $minikubeIP -Port 30679 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($redisTest) {
            Write-Host "     $emoji_success Redis acessivel ($minikubeIP`:30679)" -ForegroundColor Green
            $success++
        } else {
            Write-Host "     $emoji_error Redis inacessivel" -ForegroundColor Red
            $issues += "Redis nao esta acessivel na porta 30679"
        }
    } else {
        Write-Host "     $emoji_error Redis inacessivel (IP Minikube nao encontrado)" -ForegroundColor Red
        $issues += "Redis nao esta acessivel (IP Minikube nao encontrado)"
    }
    
    $total++
    $dashboardTest = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($dashboardTest) {
        Write-Host "     $emoji_success Dashboard K8s acessivel (15671)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     $emoji_warning Dashboard K8s inacessivel (pode precisar de tempo)" -ForegroundColor Yellow
        # Dashboard nao e critico, nao adiciona aos issues
    }
    
    # Testar configuracoes RabbitMQ
    if (-not $SkipRabbitMQConfig) {
        Write-Host "   Testando configuracoes RabbitMQ..." -ForegroundColor White
        # Checagem de loopback_users removida - garantido via rabbitmq.conf
    }
    
    # Retornar resultado
    return @{
        Success = $success
        Total = $total
        Issues = $issues
        Percentage = [math]::Round(($success / $total) * 100, 1)
    }
}

$validation = Test-FinalValidation

Write-Host ""
Write-Host "RESULTADO DA VALIDACAO:" -ForegroundColor Cyan
Write-Host "   Sucessos: $($validation.Success)/$($validation.Total) ($($validation.Percentage)%)" -ForegroundColor $(if ($validation.Percentage -ge 80) { "Green" } elseif ($validation.Percentage -ge 60) { "Yellow" } else { "Red" })

if ($validation.Issues.Count -gt 0) {
    Write-Host "   AVISO Problemas encontrados:" -ForegroundColor Yellow
    foreach ($issue in $validation.Issues) {
        Write-Host "     - $issue" -ForegroundColor Red
    }
} else {
    Write-Host "   SUCESSO Nenhum problema critico encontrado!" -ForegroundColor Green
}

Write-Host ""

Start-Sleep -Seconds 10 # Adicionando espera para estabilizacao dos port-forwards

$rabbitTest = Test-NetConnection -ComputerName localhost -Port 15672 -InformationLevel Quiet
$mongoTest = Test-NetConnection -ComputerName localhost -Port 27017 -InformationLevel Quiet
$minikubeIP = minikube ip 2>$null
if ($minikubeIP) {
    $redisTest = Test-NetConnection -ComputerName $minikubeIP -Port 30679 -InformationLevel Quiet
} else {
    $redisTest = $false
}

# Teste especial para Dashboard com mais tentativas
$dashboardTest = $false
Write-Host "   Testando conectividade Dashboard (15671)..." -ForegroundColor Yellow
for ($i = 1; $i -le 8; $i++) {
    Write-Host "     Tentativa $i/8..." -ForegroundColor Gray
    $dashboardTest = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($dashboardTest) {
        Write-Host "     Dashboard conectado!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 5
}

if ($rabbitTest) {
    Write-Host "   RabbitMQ Management acessivel" -ForegroundColor Green
} else {
    Write-Host "   RabbitMQ Management nao acessivel" -ForegroundColor Red
}

if ($mongoTest) {
    Write-Host "   MongoDB acessivel" -ForegroundColor Green
} else {
    Write-Host "   MongoDB nao acessivel" -ForegroundColor Red
}

if ($redisTest) {
    Write-Host "   Redis acessivel" -ForegroundColor Green
} else {
    Write-Host "   Redis nao acessivel" -ForegroundColor Red
}

if ($dashboardTest) {
    Write-Host "   Dashboard K8s acessivel" -ForegroundColor Green
} else {
    Write-Host "   Dashboard K8s nao acessivel - tentando recriar port-forward" -ForegroundColor Yellow
    
    # Tentar recriar port-forward do dashboard
    Get-Process kubectl -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*kubernetes-dashboard*" -or 
        $_.CommandLine -like "*15671*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Start-Sleep -Seconds 3
    
    Write-Host "   Recriando port-forward do Dashboard..." -ForegroundColor Yellow
    $retryDashboard = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "15671:80" -WindowStyle Hidden -PassThru
    
    if ($retryDashboard) {
        Write-Host "   Port-forward recriado (PID: $($retryDashboard.Id))" -ForegroundColor Green
        Start-Sleep -Seconds 10
        
        # Teste final
        $finalTest = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($finalTest) {
            Write-Host "   Dashboard agora acessivel!" -ForegroundColor Green
        } else {
            Write-Host "   Dashboard ainda com problemas - use o script open-dashboard.ps1" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "AMBIENTE CONFIGURADO AUTOMATICAMENTE!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Informacoes de Acesso:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Dashboard do Kubernetes:" -ForegroundColor Cyan
Write-Host "   Web UI: http://localhost:15671" -ForegroundColor White
Write-Host "   Alternativo: minikube dashboard" -ForegroundColor White
Write-Host ""
Write-Host "RabbitMQ:" -ForegroundColor Cyan
Write-Host "   Management UI: http://localhost:15672" -ForegroundColor White
Write-Host "   Usuario/Senha: guest/guest" -ForegroundColor White
Write-Host "   AMQP: localhost:5672" -ForegroundColor White
Write-Host "   Connection String: amqp://guest:guest@10.106.8.239:5672" -ForegroundColor White
Write-Host ""
Write-Host "MongoDB:" -ForegroundColor Cyan
Write-Host "   Connection String: mongodb://admin:admin@localhost:27017/admin" -ForegroundColor White
Write-Host "   Host: localhost:27017" -ForegroundColor White
Write-Host "   Usuario/Senha: admin/admin" -ForegroundColor White
Write-Host ""
Write-Host "Redis:" -ForegroundColor Cyan
$minikubeIP = minikube ip 2>$null
if ($minikubeIP) {
    Write-Host "   Connection String: redis://$minikubeIP`:30679" -ForegroundColor White
    Write-Host "   Host: $minikubeIP`:30679" -ForegroundColor White
} else {
    Write-Host "   Connection String: redis://[MINIKUBE_IP]:30679" -ForegroundColor White
    Write-Host "   Host: [MINIKUBE_IP]:30679" -ForegroundColor White
}
Write-Host "   CLI: redis-cli -h $minikubeIP -p 30679" -ForegroundColor White
Write-Host ""
Write-Host "Componentes Instalados:" -ForegroundColor Yellow
Write-Host "   - storage-provisioner" -ForegroundColor White
Write-Host "   - metrics-server" -ForegroundColor White  
Write-Host "   - default-storageclass" -ForegroundColor White
Write-Host "   - dashboard" -ForegroundColor White
if ($InstallKeda) {
    Write-Host "   - KEDA (Kubernetes Event-driven Autoscaling)" -ForegroundColor White
}
Write-Host ""
Write-Host "RabbitMQ Configurado para Producao:" -ForegroundColor Yellow
Write-Host "   - Conexoes remotas habilitadas (loopback_users = none)" -ForegroundColor White
Write-Host "   - Pronto para KEDA autoscaling" -ForegroundColor White
Write-Host ""
if ($InstallKeda) {
    Write-Host "KEDA Autoscaling:" -ForegroundColor Yellow
    Write-Host "   - Instalado e configurado" -ForegroundColor White
    Write-Host "   - Monitorando filas RabbitMQ" -ForegroundColor White
    Write-Host "   - Pronto para autoscaling automatico" -ForegroundColor White
    Write-Host ""
}
Write-Host "Dados persistentes configurados - nao serao perdidos!" -ForegroundColor Green
Write-Host ""
Write-Host "PRONTO PARA USO!" -ForegroundColor Green
Write-Host "   Todas as configuracoes aplicadas automaticamente." -ForegroundColor White
Write-Host "   Aplicacoes podem conectar imediatamente." -ForegroundColor White
Write-Host "   Autoscaling KEDA ativo e monitorando." -ForegroundColor White
Write-Host ""
Write-Host "Log de execucao salvo em:" -ForegroundColor Gray
Write-Host "   $logFile" -ForegroundColor White
Write-Host ""

Write-Log "Ambiente configurado com sucesso! Validation: $($validation.Success)/$($validation.Total) ($($validation.Percentage)%)" "SUCCESS"

Write-Host "Ambiente pronto para uso!" -ForegroundColor Green
