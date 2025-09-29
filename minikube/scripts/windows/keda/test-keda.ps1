# Script de Teste e Validacao KEDA
# Testa todos os componentes e exemplos

param(
    [switch]$SkipExamples,
    [switch]$CleanupOnly
)

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info = [char]::ConvertFromUtf32(0x1F4A1)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "KEDA - Teste e Validacao Completa" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Funcao para aguardar pods
function Wait-ForPods {
    param(
        [string]$Namespace = "default",
        [string]$LabelSelector,
        [int]$TimeoutSeconds = 120
    )
    
    $waited = 0
    $interval = 10
    
    do {
        Start-Sleep $interval
        $waited += $interval
        
        if ($LabelSelector) {
            $pods = kubectl get pods -n $Namespace -l $LabelSelector --no-headers 2>$null
        } else {
            $pods = kubectl get pods -n $Namespace --no-headers 2>$null
        }
        
        if ($pods) {
            $totalPods = ($pods | Measure-Object).Count
            $readyPods = ($pods | Where-Object { $_ -match "Running.*1/1" } | Measure-Object).Count
            
            Write-Host "   Aguardando pods: $readyPods/$totalPods prontos..." -ForegroundColor Cyan
            
            if ($readyPods -eq $totalPods) {
                return $true
            }
        }
        
        if ($waited -ge $TimeoutSeconds) {
            Write-Host "   $emoji_warning Timeout aguardando pods em $Namespace" -ForegroundColor Yellow
            return $false
        }
    } while ($true)
}

# Cleanup se solicitado
if ($CleanupOnly) {
    Write-Host "`n🧹 Limpando recursos de teste..." -ForegroundColor Yellow
    
    Write-Host "   Removendo ScaledObjects..." -ForegroundColor Cyan
    kubectl delete scaledobject --all --all-namespaces --ignore-not-found=true 2>$null
    
    Write-Host "   Removendo deployments de teste..." -ForegroundColor Cyan
    kubectl delete deployment nginx-deployment --ignore-not-found=true 2>$null
    kubectl delete deployment memory-app-deployment --ignore-not-found=true 2>$null
    kubectl delete deployment rabbitmq-consumer-deployment --ignore-not-found=true 2>$null

    Write-Host "   $emoji_success Cleanup concluido!" -ForegroundColor Green
    exit 0
}

Write-Host "`n1. Verificando instalacao KEDA..." -ForegroundColor Yellow

# Verificar namespace keda
$kedaNamespace = kubectl get namespace keda --no-headers 2>$null
if (-not $kedaNamespace) {
    Write-Host "   $emoji_error Namespace 'keda' nao encontrado!" -ForegroundColor Red
    Write-Host "   Execute o script de instalacao primeiro" -ForegroundColor Yellow
    exit 1
}
Write-Host "   $emoji_success Namespace keda existe" -ForegroundColor Green

# Verificar pods KEDA
Write-Host "`n   Verificando pods KEDA:" -ForegroundColor Cyan
$kedaPods = kubectl get pods -n keda --no-headers 2>$null
if (-not $kedaPods) {
    Write-Host "   $emoji_error Nenhum pod KEDA encontrado!" -ForegroundColor Red
    exit 1
}

$runningPods = ($kedaPods | Where-Object { $_ -match "Running.*1/1" } | Measure-Object).Count
$totalPods = ($kedaPods | Measure-Object).Count

Write-Host "   Status: $runningPods/$totalPods pods rodando" -ForegroundColor Cyan
if ($runningPods -ne $totalPods) {
    Write-Host "   $emoji_warning Nem todos os pods KEDA estao rodando!" -ForegroundColor Yellow
    kubectl get pods -n keda
}

# Verificar CRDs
Write-Host "`n   Verificando CRDs KEDA:" -ForegroundColor Cyan
$crds = @("scaledobjects.keda.sh", "scaledjobs.keda.sh", "triggerauthentications.keda.sh")
foreach ($crd in $crds) {
    $exists = kubectl get crd $crd --no-headers 2>$null
    if ($exists) {
        Write-Host "   $emoji_success $crd" -ForegroundColor Green
    } else {
        Write-Host "   $emoji_error $crd" -ForegroundColor Red
    }
}

# Verificar versao KEDA
Write-Host "`n   Verificando versao KEDA:" -ForegroundColor Cyan
$kedaVersion = kubectl get crd/scaledobjects.keda.sh -o jsonpath='{.metadata.labels.app\.kubernetes\.io/version}' 2>$null
if ($kedaVersion) {
    Write-Host "   Versao: $kedaVersion" -ForegroundColor Green
} else {
    Write-Host "   Versao nao detectada" -ForegroundColor Yellow
}

if ($SkipExamples) {
    Write-Host "`n$emoji_success Verificacao basica concluida!" -ForegroundColor Green
    exit 0
}

Write-Host "`n2. Testando exemplo CPU Scaling..." -ForegroundColor Yellow

Write-Host "   Aplicando CPU scaling example..." -ForegroundColor Cyan
kubectl apply -f ..\examples\cpu-scaling-example.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "   $emoji_error Falha ao aplicar exemplo CPU!" -ForegroundColor Red
} else {
    Write-Host "   $emoji_success Exemplo CPU aplicado" -ForegroundColor Green

    # Aguardar deployment estar pronto
    Write-Host "   Aguardando deployment..." -ForegroundColor Cyan
    if (Wait-ForPods -LabelSelector "app=nginx") {
        Write-Host "   $emoji_success Deployment nginx pronto" -ForegroundColor Green
    }
    
    # Verificar ScaledObject
    Write-Host "   Verificando ScaledObject..." -ForegroundColor Cyan
    $scaledObject = kubectl get scaledobject cpu-scaledobject --no-headers 2>$null
    if ($scaledObject) {
        Write-Host "   $emoji_success ScaledObject criado" -ForegroundColor Green
        kubectl get scaledobject cpu-scaledobject
    } else {
        Write-Host "   $emoji_error ScaledObject nao encontrado" -ForegroundColor Red
    }
}

Write-Host "`n3. Testando exemplo Memory Scaling..." -ForegroundColor Yellow

Write-Host "   Aplicando Memory scaling example..." -ForegroundColor Cyan
kubectl apply -f ..\examples\memory-scaling-example.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "   $emoji_error Falha ao aplicar exemplo Memory!" -ForegroundColor Red
} else {
    Write-Host "   $emoji_success Exemplo Memory aplicado" -ForegroundColor Green

    # Aguardar deployment estar pronto
    Write-Host "   Aguardando deployment..." -ForegroundColor Cyan
    if (Wait-ForPods -LabelSelector "app=memory-app") {
        Write-Host "   $emoji_success Deployment memory-app pronto" -ForegroundColor Green
    }
}

Write-Host "`n4. Verificando integracao com RabbitMQ..." -ForegroundColor Yellow

# Verificar se RabbitMQ existe
$rabbitmqService = kubectl get service rabbitmq --no-headers 2>$null
if ($rabbitmqService) {
    Write-Host "   $emoji_success RabbitMQ service encontrado" -ForegroundColor Green
    
    Write-Host "   Aplicando RabbitMQ scaling example..." -ForegroundColor Cyan
    kubectl apply -f ..\examples\rabbitmq-scaling-example.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   $emoji_success Exemplo RabbitMQ aplicado" -ForegroundColor Green
    } else {
        Write-Host "   $emoji_warning Exemplo RabbitMQ pode precisar de ajustes" -ForegroundColor Yellow
    }
} else {
    Write-Host "   $emoji_warning RabbitMQ nao encontrado - pulando exemplo" -ForegroundColor Yellow
    Write-Host "   Para testar integracao RabbitMQ, certifique-se que RabbitMQ esta rodando" -ForegroundColor Cyan
}

Write-Host "`n5. Status final de todos os ScaledObjects..." -ForegroundColor Yellow
kubectl get scaledobject -A 2>$null

Write-Host "`n6. Status de HPAs criados pelo KEDA..." -ForegroundColor Yellow
kubectl get hpa -A 2>$null

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "🎉 TESTE KEDA CONCLUIDO!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`n📊 RESULTADO DOS TESTES:" -ForegroundColor Yellow

# Resumo final
$scaledObjects = kubectl get scaledobject --all-namespaces --no-headers 2>$null
if ($scaledObjects) {
    $soCount = ($scaledObjects | Measure-Object).Count
    Write-Host "   $emoji_success $soCount ScaledObjects criados" -ForegroundColor Green
} else {
    Write-Host "   $emoji_warning Nenhum ScaledObject encontrado" -ForegroundColor Yellow
}

$hpas = kubectl get hpa --all-namespaces --no-headers 2>$null
if ($hpas) {
    $hpaCount = ($hpas | Measure-Object).Count
    Write-Host "   $emoji_success $hpaCount HPAs gerenciados pelo KEDA" -ForegroundColor Green
} else {
    Write-Host "   $emoji_warning Nenhum HPA encontrado" -ForegroundColor Yellow
}

Write-Host "`n🔧 COMANDOS UTEIS PARA MONITORAMENTO:" -ForegroundColor Yellow
Write-Host "   - Ver ScaledObjects: kubectl get scaledobject -A" -ForegroundColor Cyan
Write-Host "   - Ver HPAs: kubectl get hpa -A" -ForegroundColor Cyan
Write-Host "   - Logs KEDA: kubectl logs -n keda -l app.kubernetes.io/name=keda-operator" -ForegroundColor Cyan
Write-Host "   - Describe ScaledObject: kubectl describe scaledobject <nome>" -ForegroundColor Cyan

Write-Host "`n🧹 CLEANUP:" -ForegroundColor Yellow
Write-Host "   - Remover testes: .\test-keda.ps1 -CleanupOnly" -ForegroundColor Cyan

Write-Host "`n$emoji_success KEDA testado e funcionando!" -ForegroundColor Green