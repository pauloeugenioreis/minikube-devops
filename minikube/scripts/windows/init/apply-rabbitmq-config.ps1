# Script para aplicar configuracoes completas do RabbitMQ
# Implementa operacao 1 utilizando Helm

param(
    [switch]$SkipBackup,
    [switch]$ForceApply
)

# Forcar a codificacao UTF-8 para exibir icones corretamente
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error   = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info    = [char]::ConvertFromUtf32(0x1F4A1)

$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
$projectRoot = (Resolve-Path -Path (Join-Path $scriptDir '..\..\..')).ProviderPath
$rabbitmqChartPath = Join-Path $projectRoot 'charts\rabbitmq'

Write-Host '=====================================================' -ForegroundColor Cyan
Write-Host ("{0} APLICANDO CONFIGURACOES RABBITMQ VIA HELM" -f $emoji_success) -ForegroundColor Green
Write-Host '=====================================================' -ForegroundColor Cyan

$ErrorActionPreference = 'Continue'

function Invoke-RabbitMQCommand {
    param(
        [string]$Command
    )

    $rabbitPod = kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
    if (-not $rabbitPod) {
        Write-Host ("{0} Pod RabbitMQ nao encontrado!" -f $emoji_error) -ForegroundColor Red
        return $null
    }

    return kubectl exec $rabbitPod -- /bin/sh -c "$Command" 2>&1
}

function Wait-ForDeployment {
    param(
        [string]$DeploymentName,
        [int]$TimeoutSeconds = 300
    )

    Write-Host ("{0} Aguardando deployment {1}..." -f $emoji_info, $DeploymentName) -ForegroundColor Cyan

    $waited = 0
    $interval = 10

    do {
        Start-Sleep -Seconds $interval
        $waited += $interval

        $status = kubectl get deployment $DeploymentName -o jsonpath='{.status.readyReplicas}' 2>$null
        if ($status -eq '1') {
            Write-Host ("{0} Deployment {1} esta pronto!" -f $emoji_success, $DeploymentName) -ForegroundColor Green
            return $true
        }

        Write-Host ("{0} Aguardando... ({1}/{2} segundos)" -f $emoji_warning, $waited, $TimeoutSeconds) -ForegroundColor Yellow

        if ($waited -ge $TimeoutSeconds) {
            Write-Host ("{0} Timeout aguardando deployment {1}" -f $emoji_error, $DeploymentName) -ForegroundColor Red
            return $false
        }
    } while ($true)
}

try {
    if (-not (Test-Path -Path $rabbitmqChartPath)) {
        Write-Host ("{0} Chart do RabbitMQ nao encontrado em: {1}" -f $emoji_error, $rabbitmqChartPath) -ForegroundColor Red
        exit 1
    }

    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Host ("{0} Helm nao esta instalado ou nao esta no PATH." -f $emoji_error) -ForegroundColor Red
        Write-Host '    Execute scripts\windows\keda\install-helm.ps1 ou instale manualmente.' -ForegroundColor Yellow
        exit 1
    }

    Write-Host '1. Verificando namespace...' -ForegroundColor Cyan
    $namespace = kubectl get namespace default -o name 2>$null
    if (-not $namespace) {
        Write-Host ("{0} Namespace default nao encontrado!" -f $emoji_error) -ForegroundColor Red
        exit 1
    }
    Write-Host ("{0} Namespace default OK" -f $emoji_success) -ForegroundColor Green

    if (-not $SkipBackup) {
        Write-Host '2. Fazendo backup dos recursos existentes...' -ForegroundColor Cyan

        $backupDir = Join-Path $projectRoot ("backup-rabbitmq-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
        if (-not (Test-Path -Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        kubectl get configmap rabbitmq-config -o yaml > (Join-Path $backupDir 'rabbitmq-config-backup.yaml') 2>$null
        kubectl get deployment rabbitmq -o yaml > (Join-Path $backupDir 'rabbitmq-deployment-backup.yaml') 2>$null
        kubectl get service rabbitmq-service -o yaml > (Join-Path $backupDir 'rabbitmq-service-backup.yaml') 2>$null

        Write-Host ("{0} Backup salvo em: {1}" -f $emoji_success, $backupDir) -ForegroundColor Green
    } else {
        Write-Host '2. Backup ignorado por parametro.' -ForegroundColor Yellow
    }

    Write-Host '3. Aplicando chart do RabbitMQ...' -ForegroundColor Cyan
    $helmArgs = @('upgrade','--install','rabbitmq',$rabbitmqChartPath,'--atomic')
    if ($ForceApply) {
        $helmArgs += '--force'
        $helmArgs += '--reset-values'
    }
    $helmResult = helm @helmArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("{0} Falha ao aplicar chart do RabbitMQ!" -f $emoji_error) -ForegroundColor Red
        if ($helmResult) {
            $helmResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        }
        exit 1
    }
    Write-Host ("{0} Chart aplicado com sucesso" -f $emoji_success) -ForegroundColor Green
    if ($helmResult) {
        $helmResult | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }

    Write-Host '4. Aguardando deployment ficar pronto...' -ForegroundColor Cyan
    if (-not (Wait-ForDeployment -DeploymentName 'rabbitmq' -TimeoutSeconds 300)) {
        Write-Host ("{0} Deployment nao ficou pronto no tempo esperado!" -f $emoji_error) -ForegroundColor Red
        Write-Host ("{0} Status do deployment:" -f $emoji_info) -ForegroundColor Yellow
        kubectl describe deployment rabbitmq
        exit 1
    }

    Write-Host '5. Verificacao final...' -ForegroundColor Cyan

    Write-Host ("{0} Status dos pods:" -f $emoji_info) -ForegroundColor Yellow
    kubectl get pods -l app=rabbitmq

    Write-Host ("{0} Verificando filas criadas:" -f $emoji_info) -ForegroundColor Yellow
    $queues = Invoke-RabbitMQCommand 'rabbitmqctl list_queues name messages'
    if ($queues) {
        $queues | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    } else {
        Write-Host '    Nao foi possivel listar filas.' -ForegroundColor Yellow
    }

    Write-Host ("{0} Verificando configuracao loopback:" -f $emoji_info) -ForegroundColor Yellow
    $loopback = Invoke-RabbitMQCommand "rabbitmqctl eval 'application:get_env(rabbit, loopback_users).'"
    if ($loopback) {
        $loopback | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    } else {
        Write-Host '    Nao foi possivel obter configuracao loopback.' -ForegroundColor Yellow
    }

    Write-Host ("{0} Verificando plugins habilitados:" -f $emoji_info) -ForegroundColor Yellow
    $plugins = Invoke-RabbitMQCommand 'rabbitmq-plugins list --enabled --minimal'
    if ($plugins) {
        $plugins | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
    } else {
        Write-Host '    Nao foi possivel listar plugins.' -ForegroundColor Yellow
    }

    Write-Host '=====================================================' -ForegroundColor Cyan
    Write-Host ("{0} CONFIGURACAO RABBITMQ CONCLUIDA COM SUCESSO!" -f $emoji_success) -ForegroundColor Green
    Write-Host '=====================================================' -ForegroundColor Cyan

    Write-Host ("{0} RECURSOS APLICADOS:" -f $emoji_info) -ForegroundColor Cyan
    Write-Host ("{0} ConfigMap renderizado via Helm" -f $emoji_success) -ForegroundColor Green
    Write-Host ("{0} Deployment atualizado pelo chart" -f $emoji_success) -ForegroundColor Green
    Write-Host ("{0} Loopback liberado (loopback_users = none)" -f $emoji_success) -ForegroundColor Green

    Write-Host ("{0} CONEXOES:" -f $emoji_info) -ForegroundColor Cyan
    Write-Host '  - AMQP: rabbitmq-service:5672' -ForegroundColor White
    Write-Host '  - Management: http://localhost:15672 (port-forward)' -ForegroundColor White
    Write-Host '  - Usuario: guest / Senha: guest' -ForegroundColor White

    Write-Host ("{0} TESTES RECOMENDADOS:" -f $emoji_info) -ForegroundColor Cyan
    Write-Host '  - Verificar Azure Functions conectando' -ForegroundColor White
    Write-Host '  - Testar envio de mensagens' -ForegroundColor White
    Write-Host '  - Monitorar logs das functions' -ForegroundColor White

} catch {
    Write-Host ("{0} ERRO DURANTE APLICACAO:" -f $emoji_error) -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ("{0} Script concluido com sucesso!" -f $emoji_success) -ForegroundColor Green
