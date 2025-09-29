# Script para abrir Dashboard do Kubernetes
# Execute este script para acessar o Dashboard diretamente

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "ABRINDO DASHBOARD DO KUBERNETES" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

# Verificar se o Minikube esta rodando
Write-Host "Verificando status do Minikube..." -ForegroundColor Yellow
minikube status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Minikube nao esta rodando. Iniciando..." -ForegroundColor Yellow
    minikube start
}

# Verificar se o port-forward ja existe
Write-Host "Verificando port-forward do Dashboard..." -ForegroundColor Yellow
$dashboardTest = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue

if (-not $dashboardTest) {
    Write-Host "Criando port-forward para Dashboard..." -ForegroundColor Yellow
    
    # Parar qualquer port-forward antigo
    Get-Process kubectl -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Aguardar Dashboard estar pronto
    Write-Host "Aguardando Dashboard estar pronto..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=60s 2>$null
    
    Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "kubernetes-dashboard", "service/kubernetes-dashboard", "15671:80" -WindowStyle Hidden
    
    # Aguardar port-forward iniciar (tempo maior)
    Write-Host "Aguardando port-forward iniciar..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Verificar conectividade
$dashboardTest2 = Test-NetConnection -ComputerName localhost -Port 15671 -InformationLevel Quiet -WarningAction SilentlyContinue

if ($dashboardTest2) {
    Write-Host "Dashboard acessivel! Abrindo no navegador..." -ForegroundColor Green
    
    # Abrir no navegador padrao
    Start-Process "http://localhost:15671"
    
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "DASHBOARD ABERTO COM SUCESSO!" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "URL: http://localhost:15671" -ForegroundColor White
    Write-Host ""
    Write-Host "Nota: Mantenha este terminal aberto para manter" -ForegroundColor Yellow
    Write-Host "      o port-forward ativo." -ForegroundColor Yellow
    
} else {
    Write-Host "Nao foi possivel conectar ao Dashboard." -ForegroundColor Red
    Write-Host "Tente executar manualmente:" -ForegroundColor Yellow
    Write-Host "   minikube dashboard" -ForegroundColor White
}

Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Blue
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")