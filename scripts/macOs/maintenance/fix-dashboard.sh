#!/usr/bin/env bash
# fix-dashboard.sh - Corrige problemas comuns do Dashboard do Kubernetes (macOS)
set -euo pipefail

NAMESPACE="kubernetes-dashboard"
PORT="${1:-15671}"

echo "🔧 Verificando Dashboard Kubernetes..."

# Verificar se o namespace existe
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ Namespace '$NAMESPACE' nao encontrado."
    echo "   Execute o script de inicializacao primeiro."
    exit 1
fi

# Matar port-forwards existentes
echo "🔄 Limpando port-forwards existentes na porta $PORT..."
pkill -f "kubectl.*port-forward.*${PORT}" 2>/dev/null || true
sleep 2

# Aguardar pod do dashboard ficar pronto
echo "⏳ Aguardando pod do Dashboard..."
kubectl wait -n "$NAMESPACE" \
    --for=condition=ready pod \
    -l k8s-app=kubernetes-dashboard \
    --timeout=120s 2>/dev/null || {
    echo "⚠️ Dashboard pod nao ficou pronto no tempo esperado."
    kubectl get pods -n "$NAMESPACE" || true
}

# Reiniciar port-forward
echo "🔌 Iniciando port-forward na porta $PORT..."
kubectl port-forward -n "$NAMESPACE" service/kubernetes-dashboard "${PORT}:80" >/dev/null 2>&1 &
sleep 4

# Verificar porta via lsof (macOS)
if lsof -i :"$PORT" >/dev/null 2>&1; then
    echo "✅ Dashboard acessivel em http://localhost:${PORT}"
    open "http://localhost:${PORT}" 2>/dev/null || true
else
    echo "❌ Port-forward nao iniciou corretamente."
    echo "   Tente manualmente: kubectl port-forward -n $NAMESPACE service/kubernetes-dashboard ${PORT}:80"
fi
