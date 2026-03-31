# init-minikube-windows.ps1 - Atalho de Inicializacao (Windows)
# Verifica dependencias e chama o script consolidado de start.

function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

$root = $PSScriptRoot
$setupScript = Join-Path $root "scripts\windows\Setup-Fresh-Machine.ps1"
$startScript = Join-Path $root "scripts\windows\init\start.ps1"

# 1. Verificar dependencias criticas
if (-not (Test-Command "minikube") -or -not (Test-Command "kubectl")) {
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "DEPENDENCIAS FALTANDO - AMBIENTE DEVOPS" -ForegroundColor Yellow
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "Minikube ou kubectl nao encontrados no seu sistema." -ForegroundColor White
    
    if (Test-Path $setupScript) {
        Write-Host "`nDeseja realizar a instalacao automatica de dependencias?" -ForegroundColor Cyan
        Write-Host "(Serao instalados: Docker Desktop, Minikube, kubectl, Helm)" -ForegroundColor Gray
        $escolha = Read-Host "Continuar com o setup? [Y/N]"
        if ($escolha -match '^[yYsS]') {
            & $setupScript -RunInitialization
            # Se o setup rodar com sucesso e ja inicializar, podemos sair.
            # No entanto, se ele apenas instalou, o PATH pode precisar de refresh.
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`nSetup concluido. Tentando seguir com a inicializacao..." -ForegroundColor Green
                # Refresh PATH para a sessao atual
                $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")
            } else {
                Write-Host "`nSetup falhou ou foi interrompido. Verifique os erros acima." -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "Instalacao cancelada. O ambiente nao pode ser iniciado sem as dependencias." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Script de setup nao encontrado em: $setupScript" -ForegroundColor Red
        Write-Host "Instale as dependencias manualmente e tente novamente." -ForegroundColor Yellow
        exit 1
    }
}

# 2. Iniciar ambiente
if (Test-Path $startScript) {
    & $startScript @args
} else {
    Write-Host "[ERRO] Não foi possível encontrar: $startScript" -ForegroundColor Red
}
