# Script para Aplicar Configurações Completas do RabbitMQ
# Implementa OPÇÃO 1 + Job de Configuração

# Forcar a codificacao UTF-8 para exibir icones corretamente
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

param(
    [switch]$SkipBackup,
    [switch]$ForceApply
)

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "🔧 APLICANDO CONFIGURAÇÕES RABBITMQ ATUALIZADAS" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

# Função para aguardar deployment
function Wait-ForDeployment {
    param(
        [string]$DeploymentName,
        [int]$TimeoutSeconds = 300
    )
    
    Write-Host "⏳ Aguardando deployment $DeploymentName..." -ForegroundColor Cyan
    
    $waited = 0
    $interval = 10
    
    do {
        Start-Sleep $interval
        $waited += $interval
        
        $status = kubectl get deployment $DeploymentName -o jsonpath='{.status.readyReplicas}' 2>$null
        if ($status -eq "1") {
            Write-Host " $emoji_success Deployment $DeploymentName está pronto!" -ForegroundColor Green
            return $true
        }
        
        Write-Host "   ⏳ Aguardando... ($waited/$TimeoutSeconds segundos)" -ForegroundColor Yellow
        
        if ($waited -ge $TimeoutSeconds) {
            Write-Host "   $emoji_warning Timeout aguardando deployment $DeploymentName" -ForegroundColor Red
            return $false
        }
    } while ($true)
}

# Função para aguardar job
function Wait-ForJob {
    param(
        [string]$JobName,
        [int]$TimeoutSeconds = 600
    )
    
    Write-Host "⏳ Aguardando job $JobName..." -ForegroundColor Cyan
    
    $waited = 0
    $interval = 15
    
    do {
        Start-Sleep $interval
        $waited += $interval
        
        $status = kubectl get job $JobName -o jsonpath='{.status.conditions[0].type}' 2>$null
        if ($status -eq "Complete") {
            Write-Host " $emoji_success Job $JobName completado com sucesso!" -ForegroundColor Green
            return $true
        } elseif ($status -eq "Failed") {
            Write-Host " $emoji_error Job $JobName falhou!" -ForegroundColor Red
            Write-Host "📋 Logs do job:" -ForegroundColor Yellow
            kubectl logs job/$JobName
            return $false
        }
        
        Write-Host "   ⏳ Job em andamento... ($waited/$TimeoutSeconds segundos)" -ForegroundColor Yellow
        
        if ($waited -ge $TimeoutSeconds) {
            Write-Host "   $emoji_warning Timeout aguardando job $JobName" -ForegroundColor Red
            Write-Host "📋 Logs do job:" -ForegroundColor Yellow
            kubectl logs job/$JobName
            return $false
        }
    } while ($true)
}

try {
    Write-Host "1. Verificando namespace..." -ForegroundColor Cyan
    $namespace = kubectl get namespace default -o name 2>$null
    if (-not $namespace) {
        Write-Host " $emoji_error Namespace default não encontrado!" -ForegroundColor Red
        exit 1
    }
    Write-Host " $emoji_success Namespace default OK" -ForegroundColor Green

    # Backup dos recursos existentes (se não skipped)
    if (-not $SkipBackup) {
        Write-Host "2. Fazendo backup dos recursos existentes..." -ForegroundColor Cyan
        
        $backupDir = "backup-rabbitmq-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        kubectl get configmap rabbitmq-config -o yaml > "$backupDir\rabbitmq-config-backup.yaml" 2>$null
        kubectl get deployment rabbitmq -o yaml > "$backupDir\rabbitmq-deployment-backup.yaml" 2>$null
        kubectl get service rabbitmq-service -o yaml > "$backupDir\rabbitmq-service-backup.yaml" 2>$null

        Write-Host " $emoji_success Backup salvo em: $backupDir" -ForegroundColor Green
    }

    Write-Host "3. Removendo job de configuração anterior (se existir)..." -ForegroundColor Cyan
    kubectl delete job rabbitmq-setup --ignore-not-found=true
    Write-Host " $emoji_success Cleanup job anterior OK" -ForegroundColor Green

    Write-Host "4. Aplicando ConfigMap atualizado..." -ForegroundColor Cyan
    $configResult = kubectl apply -f "rabbitmq.yaml"
    if ($LASTEXITCODE -ne 0) {
        Write-Host " $emoji_error Falha ao aplicar ConfigMap!" -ForegroundColor Red
        exit 1
    }
    Write-Host " $emoji_success ConfigMap aplicado: $configResult" -ForegroundColor Green

    Write-Host "5. Reiniciando deployment RabbitMQ..." -ForegroundColor Cyan
    kubectl rollout restart deployment/rabbitmq
    if ($LASTEXITCODE -ne 0) {
        Write-Host " $emoji_error Falha ao reiniciar deployment!" -ForegroundColor Red
        exit 1
    }

    Write-Host "6. Aguardando deployment estar pronto..." -ForegroundColor Cyan
    if (-not (Wait-ForDeployment -DeploymentName "rabbitmq" -TimeoutSeconds 300)) {
        Write-Host " $emoji_error Deployment não ficou pronto no tempo esperado!" -ForegroundColor Red
        Write-Host "📋 Status do deployment:" -ForegroundColor Yellow
        kubectl describe deployment rabbitmq
        exit 1
    }

    Write-Host "7. Aplicando job de configuração..." -ForegroundColor Cyan
    $jobResult = kubectl apply -f "rabbitmq-setup-job.yaml"
    if ($LASTEXITCODE -ne 0) {
        Write-Host " $emoji_error Falha ao aplicar job de configuração!" -ForegroundColor Red
        exit 1
    }
    Write-Host " $emoji_success Job aplicado: $jobResult" -ForegroundColor Green

    Write-Host "8. Aguardando job de configuração..." -ForegroundColor Cyan
    if (-not (Wait-ForJob -JobName "rabbitmq-setup" -TimeoutSeconds 600)) {
        Write-Host " $emoji_error Job de configuração falhou!" -ForegroundColor Red
        exit 1
    }

    Write-Host "9. Verificação final..." -ForegroundColor Cyan
    
    # Verificar pods
    Write-Host "📋 Status dos pods:" -ForegroundColor Yellow
    kubectl get pods -l app=rabbitmq
    
    # Verificar filas
    Write-Host "📋 Verificando filas criadas:" -ForegroundColor Yellow
    $rabbitPod = kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($rabbitPod) {
        kubectl exec $rabbitPod -- rabbitmqctl list_queues name messages 2>$null
    }
    
    # Verificar configuração loopback
    Write-Host "📋 Verificando configuração loopback:" -ForegroundColor Yellow
    if ($rabbitPod) {
        kubectl exec $rabbitPod -- rabbitmqctl environment | Select-String loopback 2>$null
    }

    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "🎉 CONFIGURAÇÃO RABBITMQ CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Cyan
    
    Write-Host "📊 RECURSOS APLICADOS:" -ForegroundColor Cyan
    Write-Host "$emoji_success ConfigMap atualizado com loopback_users = none" -ForegroundColor Green
    Write-Host "$emoji_success Deployment com healthchecks e recursos otimizados" -ForegroundColor Green
    Write-Host "$emoji_success Job de configuração executado com sucesso" -ForegroundColor Green
    Write-Host "$emoji_success Filas criadas: pne-email, pne-integracao-rota, pne-integracao-arquivo" -ForegroundColor Green

    Write-Host "🔗 CONEXÕES:" -ForegroundColor Cyan
    Write-Host "  - AMQP: rabbitmq-service:5672" -ForegroundColor White
    Write-Host "  - Management: http://localhost:15672 (port-forward)" -ForegroundColor White
    Write-Host "  - Usuário: guest / Senha: guest" -ForegroundColor White
    
    Write-Host "🧪 TESTES RECOMENDADOS:" -ForegroundColor Cyan
    Write-Host "  - Verificar Azure Functions conectando" -ForegroundColor White
    Write-Host "  - Testar envio de mensagens" -ForegroundColor White
    Write-Host "  - Monitorar logs das functions" -ForegroundColor White

} catch {
    Write-Host " $emoji_error ERRO DURANTE APLICAÇÃO:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host " $emoji_success Script concluído com sucesso!" -ForegroundColor Green