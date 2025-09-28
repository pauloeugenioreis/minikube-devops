# Script para alterar porta do Dashboard
# Use este script para mudar facilmente a porta do Dashboard

param(
    [Parameter(Mandatory=$true)]
    [int]$NovaPorta
)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "ALTERANDO PORTA DO DASHBOARD KUBERNETES" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan

$portaAtual = 4666
Write-Host "Porta atual: $portaAtual" -ForegroundColor Yellow
Write-Host "Nova porta: $NovaPorta" -ForegroundColor Green

# Verificar se a nova porta esta disponivel
Write-Host "`nVerificando disponibilidade da porta $NovaPorta..." -ForegroundColor Yellow
$portaTest = Test-NetConnection -ComputerName localhost -Port $NovaPorta -InformationLevel Quiet -WarningAction SilentlyContinue

if ($portaTest) {
    Write-Host "AVISO: Porta $NovaPorta ja esta em uso!" -ForegroundColor Red
    $confirmar = Read-Host "Deseja continuar mesmo assim? (s/n)"
    if ($confirmar -ne "s") {
        Write-Host "Operacao cancelada." -ForegroundColor Yellow
        exit
    }
}

# Parar port-forwards existentes
Write-Host "`nParando port-forwards existentes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Atualizar scripts
Write-Host "Atualizando scripts..." -ForegroundColor Yellow

$scripts = @(
    "init-minikube-fixed.ps1",
    "open-dashboard.ps1", 
    "quick-status.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "  Atualizando $script..." -ForegroundColor White
        
        # Ler conteudo
        $conteudo = Get-Content $script -Raw
        
        # Substituir porta antiga pela nova
        $conteudo = $conteudo -replace ":$portaAtual", ":$NovaPorta"
        $conteudo = $conteudo -replace "Port $portaAtual", "Port $NovaPorta"
        $conteudo = $conteudo -replace "localhost:$portaAtual", "localhost:$NovaPorta"
        
        # Salvar
        Set-Content -Path $script -Value $conteudo -Encoding UTF8
        Write-Host "    $script atualizado!" -ForegroundColor Green
    }
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "PORTA ALTERADA COM SUCESSO!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nova configuracao:" -ForegroundColor Yellow
Write-Host "  Dashboard K8s: http://localhost:$NovaPorta" -ForegroundColor White
Write-Host ""
Write-Host "Para testar: .\open-dashboard.ps1" -ForegroundColor Blue