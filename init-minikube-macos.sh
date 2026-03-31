#!/usr/bin/env bash
# init-minikube-macos.sh
# Atalho para inicializacao do ambiente Minikube no macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/scripts/macOs/init/start.sh"

if [[ -f "$INIT_SCRIPT" ]]; then
    bash "$INIT_SCRIPT" "$@"
else
    echo "Erro: Script de inicializacao nao encontrado em $INIT_SCRIPT"
    exit 1
fi
