#!/usr/bin/env bash
# =====================================================
# Autostart Linux (sempre instala KEDA)
# =====================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/../init/init-minikube-fixed.sh"

if [[ ! -f "$INIT_SCRIPT" ]]; then
    echo "init-minikube-fixed.sh não encontrado em $INIT_SCRIPT" >&2
    exit 1
fi

echo "====================================================="
echo "AUTOSTART MINIKUBE + KEDA (LINUX)"
echo "====================================================="
echo "Encaminhando execução para: $INIT_SCRIPT"

echo ""
exec bash "$INIT_SCRIPT" "$@" --install-keda
