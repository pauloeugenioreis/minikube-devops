@echo off
echo Iniciando Minikube automaticamente com KEDA...
REM Detectar dinamicamente o caminho do script de inicializacao
set "SCRIPT_DIR=%~dp0"
set "INIT_SCRIPT=%SCRIPT_DIR%..\init\init-minikube-fixed.ps1"
echo.
echo Executando script de inicializacao com KEDA...
echo Janela ficara aberta para acompanhar o progresso.
echo.
powershell -ExecutionPolicy Bypass -File "%INIT_SCRIPT%" -InstallKeda
echo.
echo Script concluido! Pressione qualquer tecla para fechar.
pause >nul