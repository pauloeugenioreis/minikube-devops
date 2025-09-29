# Diagnostico e Correcao do Dashboard K8s

$emoji_success = [char]::ConvertFromUtf32(0x2705)
$emoji_error = [char]::ConvertFromUtf32(0x274C)
$emoji_warning = [char]::ConvertFromUtf32(0x26A0)
$emoji_info = [char]::ConvertFromUtf32(0x1F4A1)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "DIAGNOSTICO DO DASHBOARD KUBERNETES" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Verificar pods do Dashboard
Write-Host "`n1. Verificando pods do Dashboard..." -ForegroundColor Yellow
$dashboardPods = kubectl get pods -n kubernetes-dashboard --no-headers 2>$null
if ($dashboardPods) {
    $dashboardPods | ForEach-Object {
        $parts = $_ -split '\s+'
        $name = $parts[0]
        $status = $parts[2]
        if ($status -eq "Running") {
            Write-Host "   $emoji_success $name - $status" -ForegroundColor Green
        } else {
            Write-Host "   $emoji_warning $name - $status" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   $emoji_error Nenhum pod encontrado" -ForegroundColor Red
}

# 2. Verificar servicos
Write-Host "`n2. Verificando servicos do Dashboard..." -ForegroundColor Yellow
$dashboardSvcs = kubectl get svc -n kubernetes-dashboard --no-headers 2>$null
if ($dashboardSvcs) {
    $dashboardSvcs | ForEach-Object {
        $parts = $_ -split '\s+'
        $name = $parts[0]
        Write-Host "   $emoji_success $name" -ForegroundColor Green
    }
} else {
    Write-Host "   $emoji_error Nenhum servico encontrado" -ForegroundColor Red
}

# 3. Verificar port-forwards ativos
Write-Host "`n3. Verificando port-forwards do Dashboard..." -ForegroundColor Yellow
$portForwards = Get-Process kubectl -ErrorAction SilentlyContinue
if ($portForwards) {
    Write-Host "   $emoji_info Processos kubectl encontrados: $($portForwards.Count)" -ForegroundColor Blue
} else {
    Write-Host "   $emoji_warning Nenhum processo kubectl ativo" -ForegroundColor Yellow
}

# 4. Testar conectividade
Write-Host "`n4. Testando conectividade porta 15671..." -ForegroundColor Yellow
$dashboardTest = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($dashboardTest) {
    Write-Host "   $emoji_success Porta 15671 ACESSIVEL" -ForegroundColor Green
} else {
    Write-Host "   $emoji_error Porta 15671 NAO ACESSIVEL" -ForegroundColor Red

    Write-Host "`n$emoji_warning TENTANDO CORRIGIR..." -ForegroundColor Yellow
    
    # Parar port-forwards existentes
    Write-Host "   Parando port-forwards antigos..." -ForegroundColor Yellow
    Get-Process kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Aguardar Dashboard estar pronto
    Write-Host "   Aguardando Dashboard estar pronto..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=60s 2>$null
    
    # Criar novo port-forward
    Write-Host "   Criando novo port-forward..." -ForegroundColor Yellow
    Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "15671:80" -WindowStyle Hidden
    
    # Aguardar e testar novamente
    Start-Sleep -Seconds 8
    $dashboardTest2 = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue
    
    if ($dashboardTest2) {
        Write-Host "   $emoji_success CORRIGIDO! Dashboard agora acessivel" -ForegroundColor Green
    } else {
        Write-Host "   $emoji_error Ainda com problemas" -ForegroundColor Red
    }
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "RESULTADO:" -ForegroundColor Yellow
if ($dashboardTest -or $dashboardTest2) {
    Write-Host "$emoji_success Dashboard acessivel em: http://localhost:15671" -ForegroundColor Green
    Write-Host "$emoji_info Use: .\open-dashboard.ps1 para abrir automaticamente" -ForegroundColor Blue
} else {
    Write-Host "$emoji_error Dashboard com problemas" -ForegroundColor Red
    Write-Host "$emoji_info Tente: minikube dashboard (abrira em porta aleatoria)" -ForegroundColor Blue
}
Write-Host "=====================================================" -ForegroundColor Cyan