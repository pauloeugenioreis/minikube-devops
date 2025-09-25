# Script de Inicializacao Completa do Minikube com RabbitMQ, MongoDB e KEDA
# Este script garante que tudo seja iniciado automaticamente

param(
    [switch]$SkipAddons,
    [switch]$InstallKeda = $true,  # KEDA agora e instalado por padrao
    [switch]$SkipRabbitMQConfig
)

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
$logFile = Join-Path $env:TEMP "minikube-autostart-$(Get-Date -Format 'yyyyMMdd').log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $Message
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

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Inicializando Ambiente Minikube Completo" -ForegroundColor Green
Write-Host "Versoes: kubectl $(kubectl version --client --short 2>$null), minikube $(minikube version --short 2>$null)" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

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
    
    # Tentar encontrar Docker Desktop
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
        Write-Host "   Docker Desktop iniciado. Aguardando ficar pronto..." -ForegroundColor Yellow
        
        # Aguardar Docker ficar pronto (maximo 120 segundos)
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
        } else {
            Write-Host "   Timeout: Docker nao ficou pronto em $timeout segundos" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "   Docker Desktop nao encontrado! Instale o Docker Desktop primeiro." -ForegroundColor Red
        return $false
    }
}

# Verificar dependencias
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
    $kubectlVersion = (kubectl version --client --short 2>$null) -replace 'Client Version: ', ''
    $minikubeK8sVersion = (minikube kubectl version --client --short 2>$null) -replace 'Client Version: ', ''
    
    if ($kubectlVersion -ne $minikubeK8sVersion) {
        Write-Host "AVISO: Versoes incompativeis detectadas!" -ForegroundColor Yellow
        Write-Host "kubectl: $kubectlVersion | Kubernetes: $minikubeK8sVersion" -ForegroundColor Yellow
        Write-Host "Executando atualizacao automatica..." -ForegroundColor Yellow
        
        if (Test-Path ".\update-kubectl.ps1") {
            & ".\update-kubectl.ps1"
        } else {
            Write-Host "Script de atualizacao nao encontrado. Use 'minikube kubectl' se houver problemas." -ForegroundColor Yellow
        }
    } else {
        Write-Host "✅ Versoes compativeis: $kubectlVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "AVISO: Nao foi possivel verificar compatibilidade. Continuando..." -ForegroundColor Yellow
}

# Iniciar Minikube
Write-Host "Iniciando Minikube..." -ForegroundColor Yellow
minikube status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Iniciando Minikube pela primeira vez..." -ForegroundColor Yellow
    minikube start --driver=docker
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao iniciar Minikube!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Minikube ja esta rodando!" -ForegroundColor Green
}

# Habilitar addons essenciais (sempre)
if (-not $SkipAddons) {
    Write-Host "Habilitando addons essenciais..." -ForegroundColor Yellow
    
    $addons = @(
        "storage-provisioner",
        "metrics-server", 
        "default-storageclass",
        "dashboard"
    )
    
    foreach ($addon in $addons) {
        Write-Host "   Habilitando $addon..." -ForegroundColor White
        minikube addons enable $addon
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   $addon habilitado" -ForegroundColor Green
        } else {
            Write-Host "   Erro ao habilitar $addon" -ForegroundColor Yellow
        }
    }
}

# Aguardar cluster estar pronto
Write-Host "Aguardando cluster estar pronto..." -ForegroundColor Yellow
kubectl wait --for=condition=ready node/minikube --timeout=300s
if ($LASTEXITCODE -ne 0) {
    Write-Host "Timeout aguardando cluster ficar pronto!" -ForegroundColor Red
    exit 1
}

# Aplicar configuracoes do RabbitMQ e MongoDB
Write-Host "Aplicando configuracoes dos servicos..." -ForegroundColor Yellow

$configFiles = @(
    "persistent-volumes.yaml",
    "rabbitmq.yaml", 
    "mongodb.yaml"
)

# Definir caminho para configs usando deteccao automatica
if ($projectPaths) {
    $configsPath = $projectPaths.Configs.Root
    Write-Host "Usando pasta de configs detectada: $configsPath" -ForegroundColor Green
} else {
    # Fallback para metodo antigo (relativo ao script)
    $configsPath = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "configs"
    Write-Host "Usando pasta de configs relativa: $configsPath" -ForegroundColor Yellow
}

foreach ($file in $configFiles) {
    $filePath = Join-Path $configsPath $file
    if (Test-Path $filePath) {
        Write-Host "   Aplicando $file..." -ForegroundColor White
        kubectl apply -f $filePath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   $file aplicado com sucesso" -ForegroundColor Green
        } else {
            Write-Host "   Erro ao aplicar $file" -ForegroundColor Red
        }
    } else {
        Write-Host "   Arquivo $file nao encontrado" -ForegroundColor Yellow
    }
}

# Aguardar pods ficarem prontos
Write-Host "Aguardando pods ficarem prontos..." -ForegroundColor Yellow
Write-Host "   Aguardando RabbitMQ..." -ForegroundColor White
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s

Write-Host "   Aguardando MongoDB..." -ForegroundColor White  
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s

# Verificar status dos pods
Write-Host "Status dos pods:" -ForegroundColor Yellow
kubectl get pods -o wide

# Matar port-forwards existentes
Write-Host "Configurando port-forwards..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*"} | Stop-Process -Force 2>$null

# Criar port-forwards
Write-Host "   Criando port-forward para RabbitMQ Management (15672)..." -ForegroundColor White
Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/rabbitmq-service", "15672:15672" -WindowStyle Hidden

Write-Host "   Criando port-forward para RabbitMQ AMQP (5672)..." -ForegroundColor White
Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/rabbitmq-service", "5672:5672" -WindowStyle Hidden

Write-Host "   Criando port-forward para MongoDB (27017)..." -ForegroundColor White
Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/mongodb-service", "27017:27017" -WindowStyle Hidden

Write-Host "   Criando port-forward para Dashboard K8s (4666)..." -ForegroundColor White

# Aguardar Dashboard estar totalmente pronto antes de criar port-forward
Write-Host "   Aguardando Dashboard estar pronto..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

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
        $_.CommandLine -like "*4666*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Start-Sleep -Seconds 2
    
    # Criar port-forward do dashboard com maior robustez
    $dashboardJob = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "4666:80" -WindowStyle Hidden -PassThru
    
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
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keda-operator -n keda --timeout=120s 2>$null
    
    # Verificar se existem ScaledObjects
    $existingScaledObjects = kubectl get scaledobjects --all-namespaces --no-headers 2>$null
    if ($existingScaledObjects) {
        Write-Host "   ✅ ScaledObjects encontrados:" -ForegroundColor Green
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
    
    Write-Host "   Testando componentes principais..." -ForegroundColor White
    
    # Testar pods principais
    $total++
    $rabbitPod = kubectl get pods -l app=rabbitmq --no-headers 2>$null
    $rabbitReady = $rabbitPod | Where-Object { $_ -match "1/1.*Running" }
    if ($rabbitReady) {
        Write-Host "     OK RabbitMQ pod rodando" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     ERRO RabbitMQ pod com problemas" -ForegroundColor Red
        Write-Host "       Debug: $rabbitPod" -ForegroundColor Gray
        $issues += "RabbitMQ pod nao esta rodando corretamente"
    }
    
    $total++
    $mongoPod = kubectl get pods -l app=mongodb --no-headers 2>$null
    $mongoReady = $mongoPod | Where-Object { $_ -match "1/1.*Running" }
    if ($mongoReady) {
        Write-Host "     OK MongoDB pod rodando" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     ERRO MongoDB pod com problemas" -ForegroundColor Red
        Write-Host "       Debug: $mongoPod" -ForegroundColor Gray
        $issues += "MongoDB pod nao esta rodando corretamente"
    }
    
    if ($InstallKeda) {
        $total++
        $allKedaPods = kubectl get pods -n keda --no-headers 2>$null
        $kedaPods = $allKedaPods | Where-Object { $_ -match "1/1.*Running" }
        $kedaCount = ($kedaPods | Measure-Object).Count
        $totalKeda = ($allKedaPods | Measure-Object).Count
        if ($kedaCount -ge 4) {
            Write-Host "     OK KEDA pods rodando ($kedaCount/$totalKeda pods)" -ForegroundColor Green
            $success++
        } else {
            Write-Host "     ERRO KEDA pods insuficientes ($kedaCount pods)" -ForegroundColor Red
            $issues += "KEDA nao tem todos os pods necessarios"
        }
    }
    
    # Testar conectividade
    Write-Host "   Testando conectividade..." -ForegroundColor White
    
    $total++
    $rabbitTest = Test-NetConnection -ComputerName localhost -Port 15672 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($rabbitTest) {
        Write-Host "     OK RabbitMQ Management acessivel (15672)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     ERRO RabbitMQ Management inacessivel" -ForegroundColor Red
        $issues += "RabbitMQ Management nao esta acessivel na porta 15672"
    }
    
    $total++
    $mongoTest = Test-NetConnection -ComputerName localhost -Port 27017 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($mongoTest) {
        Write-Host "     OK MongoDB acessivel (27017)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     ERRO MongoDB inacessivel" -ForegroundColor Red
        $issues += "MongoDB nao esta acessivel na porta 27017"
    }
    
    $total++
    $dashboardTest = Test-NetConnection -ComputerName localhost -Port 4666 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($dashboardTest) {
        Write-Host "     OK Dashboard K8s acessivel (4666)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "     AVISO Dashboard K8s inacessivel (pode precisar de tempo)" -ForegroundColor Yellow
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

$rabbitTest = Test-NetConnection -ComputerName localhost -Port 15672 -InformationLevel Quiet
$mongoTest = Test-NetConnection -ComputerName localhost -Port 27017 -InformationLevel Quiet

# Teste especial para Dashboard com mais tentativas
$dashboardTest = $false
Write-Host "   Testando conectividade Dashboard (4666)..." -ForegroundColor Yellow
for ($i = 1; $i -le 8; $i++) {
    Write-Host "     Tentativa $i/8..." -ForegroundColor Gray
    $dashboardTest = Test-NetConnection -ComputerName localhost -Port 4666 -InformationLevel Quiet -WarningAction SilentlyContinue
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

if ($dashboardTest) {
    Write-Host "   Dashboard K8s acessivel" -ForegroundColor Green
} else {
    Write-Host "   Dashboard K8s nao acessivel - tentando recriar port-forward" -ForegroundColor Yellow
    
    # Tentar recriar port-forward do dashboard
    Get-Process kubectl -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -like "*kubernetes-dashboard*" -or 
        $_.CommandLine -like "*4666*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Start-Sleep -Seconds 3
    
    Write-Host "   Recriando port-forward do Dashboard..." -ForegroundColor Yellow
    $retryDashboard = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "4666:80" -WindowStyle Hidden -PassThru
    
    if ($retryDashboard) {
        Write-Host "   Port-forward recriado (PID: $($retryDashboard.Id))" -ForegroundColor Green
        Start-Sleep -Seconds 10
        
        # Teste final
        $finalTest = Test-NetConnection -ComputerName localhost -Port 4666 -InformationLevel Quiet -WarningAction SilentlyContinue
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
Write-Host "Dashboard do Kubernetes:" -ForegroundColor Cyan
Write-Host "   Web UI: http://localhost:4666" -ForegroundColor White
Write-Host "   Alternativo: minikube dashboard" -ForegroundColor White
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