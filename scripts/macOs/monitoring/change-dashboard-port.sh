#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="kubernetes-dashboard"
SERVICE="service/kubernetes-dashboard"
NEW_PORT="${1:-15672}"

# macOS: usa lsof em vez de ss
check_port() {
    local port="$1"
    lsof -i :"${port}" >/dev/null 2>&1
}

echo "Alterando porta do Dashboard para: $NEW_PORT"

# Matar port-forward existente
pkill -f "kubectl.*port-forward.*kubernetes-dashboard" 2>/dev/null || true
sleep 2

# Iniciar com nova porta
kubectl port-forward -n "$NAMESPACE" "$SERVICE" "${NEW_PORT}:80" >/dev/null 2>&1 &
sleep 4

if check_port "$NEW_PORT"; then
    echo "✅ Dashboard disponivel na nova porta: http://localhost:${NEW_PORT}"
    open "http://localhost:${NEW_PORT}" 2>/dev/null || true
else
    echo "❌ Nao foi possivel iniciar o Dashboard na porta $NEW_PORT."
fi
