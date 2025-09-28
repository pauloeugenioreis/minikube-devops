# Verificacao Rapida do Ambiente
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "VERIFICACAO DO AMBIENTE MINIKUBE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan

# Versoes
Write-Host "`nVERSOES:" -ForegroundColor Yellow
Write-Host "kubectl: " -NoNewline -ForegroundColor White
kubectl version --client --short 2>$null
Write-Host "Minikube: " -NoNewline -ForegroundColor White  
minikube version --short 2>$null

# Status
Write-Host "`nSTATUS:" -ForegroundColor Yellow
Write-Host "Minikube: " -NoNewline -ForegroundColor White
minikube status 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "ATIVO" -ForegroundColor Green
} else {
    Write-Host "INATIVO" -ForegroundColor Red
}

# Pods
Write-Host "`nPODS:" -ForegroundColor Yellow
kubectl get pods 2>$null

# Servicos
Write-Host "`nSERVICOS:" -ForegroundColor Yellow
kubectl get svc 2>$null

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "VERIFICACAO CONCLUIDA" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "ACESSO RAPIDO:" -ForegroundColor Yellow
Write-Host "RabbitMQ Management: http://localhost:15672" -ForegroundColor White
Write-Host "MongoDB: localhost:27017" -ForegroundColor White  
Write-Host "Dashboard K8s: http://localhost:4666 (via .\open-dashboard.ps1)" -ForegroundColor White