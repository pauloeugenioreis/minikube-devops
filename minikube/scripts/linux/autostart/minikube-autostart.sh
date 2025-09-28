#!/bin/bash
# =====================================================
# Autostart do Minikube (Linux) - Ambiente completo com KEDA
# =====================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/../init/init-minikube-fixed.sh"

if [ ! -f "$INIT_SCRIPT" ]; then
    echo "Erro: init-minikube-fixed.sh nao encontrado em $INIT_SCRIPT"
    exit 1
fi

echo "====================================================="
echo "AUTOSTART MINIKUBE (LINUX)"
echo "Chamando script de inicializacao completo com KEDA"
echo "====================================================="

exec bash "$INIT_SCRIPT" --install-keda "$@"
