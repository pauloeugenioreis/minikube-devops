# Script para alterar porta do Dashboard (Windows)
# Use este script para mudar facilmente a porta do Dashboard em todos os scripts relevantes

param(
    [Parameter(Mandatory=$true)]
    [int]$NovaPorta
)

$portaAtual = 15671
$scripts = @(
    "..\init\start.ps1",
    "dashboard-open.ps1", 
    "..\maintenance\status.ps1"
)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "ALTERANDO PORTA DO DASHBOARD KUBERNETES" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Porta atual: $portaAtual" -ForegroundColor Yellow
Write-Host "Nova porta: $NovaPorta" -ForegroundColor Green

# Parar port-forwards existentes
Write-Host "`nParando port-forwards existentes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Atualizar scripts
Write-Host "Atualizando scripts..." -ForegroundColor Yellow

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($relativeScript in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $relativeScript
    if (Test-Path $scriptPath) {
        Write-Host "  Atualizando $scriptPath..." -ForegroundColor White
        $conteudo = Get-Content $scriptPath -Raw
        
        # Substituir porta antiga pela nova nos formatos comuns
        $conteudo = $conteudo -replace ":$portaAtual", ":$NovaPorta"
        $conteudo = $conteudo -replace "Port $portaAtual", "Port $NovaPorta"
        $conteudo = $conteudo -replace "localhost:$portaAtual", "localhost:$NovaPorta"
        
        Set-Content -Path $scriptPath -Value $conteudo -Encoding UTF8
        Write-Host "    Concluido!" -ForegroundColor Green
    }
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "PORTA ALTERADA COM SUCESSO!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan