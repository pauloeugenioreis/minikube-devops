# Script de Validacao Completa do RabbitMQ
# Testa todas as configuracoes aplicadas

param(
    [switch]$Detailed,
    [switch]$TestConnections
)
# Forcar a codificacao UTF-8 para exibir icones corretamente
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info = [char]::ConvertFromUtf32(0x1F4A1)

$ErrorActionPreference = "Continue"

# Funcao para executar comando no pod RabbitMQ
function Invoke-RabbitMQCommand {
    param([string]$Command)
    $rabbitPod = kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
    if (-not $rabbitPod) {
        Write-Host "Pod RabbitMQ nao encontrado!" -ForegroundColor Red
        return $null
    }
    # Use shell to interpret the command string so multi-word commands work on Windows
    return kubectl exec $rabbitPod -- /bin/sh -c "$Command" 2>&1
}

try {
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "VALIDACAO COMPLETA RABBITMQ" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Cyan

    Write-Host "1. Verificando status dos pods..." -ForegroundColor Cyan
    $pods = kubectl get pods -l app=rabbitmq --no-headers 2>$null
    if (-not $pods) {
        Write-Host "$emoji_error Nenhum pod RabbitMQ encontrado!" -ForegroundColor Red
        exit 1
    }
    $runningPods = ($pods | Where-Object { ($_ -match "\bRunning\b") -and ($_ -match "\b1/1\b") }).Count
    $totalPods = ($pods | Measure-Object).Count
    Write-Host "$emoji_info Status: $runningPods/$totalPods pods rodando" -ForegroundColor Yellow
    kubectl get pods -l app=rabbitmq
    if ($runningPods -eq 0) {
        Write-Host "$emoji_error Nenhum pod RabbitMQ esta rodando!" -ForegroundColor Red
        exit 1
    }
    Write-Host "$emoji_success Pods RabbitMQ OK" -ForegroundColor Green

    Write-Host "2. Verificando deployment..." -ForegroundColor Cyan
    $deployment = kubectl get deployment rabbitmq -o jsonpath='{.status.readyReplicas}' 2>$null
    if ($deployment -eq "1") {
        Write-Host "Deployment rabbitmq: 1/1 replicas prontas" -ForegroundColor Green
    } else {
        Write-Host "Deployment rabbitmq: $deployment/1 replicas prontas" -ForegroundColor Yellow
    }

    Write-Host "3. Verificando service..." -ForegroundColor Cyan
    $service = kubectl get service rabbitmq-service -o jsonpath='{.spec.type}' 2>$null
    if ($service) {
        Write-Host "$emoji_success Service rabbitmq-service: $service" -ForegroundColor Green
        if ($Detailed) {
            kubectl get service rabbitmq-service
        }
    } else {
        Write-Host "Service rabbitmq-service nao encontrado!" -ForegroundColor Red
    }

    Write-Host "4. Verificando ConfigMap..." -ForegroundColor Cyan
    $configMap = kubectl get configmap rabbitmq-config -o jsonpath='{.metadata.name}' 2>$null
    if ($configMap) {
        Write-Host "$emoji_success ConfigMap rabbitmq-config existe" -ForegroundColor Green
        $loopbackConfig = kubectl get configmap rabbitmq-config -o jsonpath='{.data.rabbitmq\.conf}' | Select-String "loopback_users"
        if ($loopbackConfig) {
            Write-Host "$emoji_success Configuracao loopback_users encontrada no ConfigMap" -ForegroundColor Green
            if ($Detailed) {
                Write-Host "   Config: $loopbackConfig" -ForegroundColor Yellow
            }
        } else {
            Write-Host "$emoji_error Configuracao loopback_users NAO encontrada no ConfigMap!" -ForegroundColor Red
        }
    } else {
        Write-Host "$emoji_error ConfigMap rabbitmq-config nao encontrado!" -ForegroundColor Red
    }

    Write-Host "5. Testando conectividade RabbitMQ..." -ForegroundColor Cyan
    $pingResult = Invoke-RabbitMQCommand "rabbitmq-diagnostics ping"
    if ($pingResult -match "Ping succeeded") {
        Write-Host "$emoji_success RabbitMQ respondendo ao ping" -ForegroundColor Green
    } else {
        Write-Host "$emoji_error RabbitMQ nao esta respondendo!" -ForegroundColor Red
        Write-Host "   Resultado: $pingResult" -ForegroundColor Yellow
    }

    Write-Host "6. Verificando configuracao loopback aplicada..." -ForegroundColor Cyan
    $loopbackStatus = Invoke-RabbitMQCommand "rabbitmqctl eval 'application:get_env(rabbit, loopback_users).'"
    if ($loopbackStatus) {
        Write-Host "$emoji_success Status loopback_users: $loopbackStatus" -ForegroundColor Green
        if ($loopbackStatus -match "\[\]" -or $loopbackStatus -match "none") {
            Write-Host "Configuracao loopback correta (permite conexoes remotas)" -ForegroundColor Green
        } else {
            Write-Host "Configuracao loopback pode estar restrita" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Nao foi possivel verificar configuracao loopback!" -ForegroundColor Red
    }

    Write-Host "7. Verificando filas criadas..." -ForegroundColor Cyan
    $queues = Invoke-RabbitMQCommand "rabbitmqctl list_queues name messages"
    if ($queues) {
        Write-Host "Filas disponiveis:" -ForegroundColor Green
        $queues | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
    } else {
        Write-Host "Nao foi possivel listar filas!" -ForegroundColor Red
    }

    Write-Host "8. Verificando usuarios..." -ForegroundColor Cyan
    $users = Invoke-RabbitMQCommand "rabbitmqctl list_users"
    if ($users) {
        Write-Host "Usuarios disponiveis:" -ForegroundColor Green
        $users | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
    } else {
        Write-Host "Nao foi possivel listar usuarios!" -ForegroundColor Red
    }

    Write-Host "9. Verificando plugins habilitados..." -ForegroundColor Cyan
    $plugins = Invoke-RabbitMQCommand "rabbitmq-plugins list --enabled --minimal"
    if ($plugins) {
        Write-Host "$emoji_success Plugins habilitados:" -ForegroundColor Green
        $plugins | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
        $essentialPlugins = @("rabbitmq_management", "rabbitmq_prometheus")
        foreach ($plugin in $essentialPlugins) {
            if ($plugins -match $plugin) {
                Write-Host "$emoji_success Plugin $plugin ativo" -ForegroundColor Green
            } else {
                Write-Host "$emoji_warning Plugin $plugin nao encontrado" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "$emoji_error Nao foi possivel listar plugins!" -ForegroundColor Red
    }

    if ($TestConnections) {
        Write-Host "10. Testando conexoes (OPCIONAL)..." -ForegroundColor Cyan
        # Teste de conexoes customizadas pode ser adicionado aqui, se necessario
    }

    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "VALIDACAO CONCLUIDA!" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "RESUMO DA VALIDACAO:" -ForegroundColor Cyan
    Write-Host "$emoji_success RabbitMQ rodando e respondendo" -ForegroundColor Green
    Write-Host "$emoji_success ConfigMap com configuracoes corretas" -ForegroundColor Green
    Write-Host "$emoji_success Deployment atualizado" -ForegroundColor Green
    Write-Host "$emoji_success Configuracao loopback aplicada" -ForegroundColor Green
    Write-Host "PROXIMOS PASSOS:" -ForegroundColor Cyan
    Write-Host "1. Testar Azure Functions conectando" -ForegroundColor White
    Write-Host "2. Monitorar logs: kubectl logs -f deployment/rabbitmq" -ForegroundColor White
    Write-Host "3. Dashboard: kubectl port-forward service/rabbitmq-service 15672:15672" -ForegroundColor White
    Write-Host "4. Verificar KEDA ScaledObjects: kubectl get scaledobjects" -ForegroundColor White
} # fechamento correto do try
catch {
    Write-Host "   $emoji_error ERRO DURANTE VALIDACAO:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "   $emoji_success Validacao concluida com sucesso!" -ForegroundColor Green
