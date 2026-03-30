#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-15671}"
NAMESPACE="kubernetes-dashboard"
SERVICE="service/kubernetes-dashboard"

# macOS: usa lsof em vez de ss
check_port() {
    local port="$1"
    lsof -i :"${port}" >/dev/null 2>&1
}

ensure_minikube() {
    if ! minikube status >/dev/null 2>&1; then
        echo "Minikube não está rodando. Iniciando..."
        minikube start --driver=docker
    fi
}

port_forward_dashboard() {
    pkill -f "kubectl.*port-forward.*${PORT}" 2>/dev/null || true
    kubectl wait -n "$NAMESPACE" --for=condition=ready pod -l k8s-app=kubernetes-dashboard --timeout=120s >/dev/null 2>&1 || true
    kubectl port-forward -n "$NAMESPACE" "$SERVICE" "${PORT}:80" >/dev/null 2>&1 &
    sleep 4
}

ensure_minikube

if ! check_port "$PORT"; then
    echo "Configurando port-forward do Dashboard na porta $PORT..."
    port_forward_dashboard
fi

if check_port "$PORT"; then
    echo "Dashboard acessível em http://localhost:${PORT}"
    # macOS: usa 'open' em vez de 'xdg-open'
    open "http://localhost:${PORT}" 2>/dev/null || true
    echo "Mantenha este terminal aberto para manter o port-forward ativo."
else
    echo "Não foi possível iniciar o port-forward. Utilize 'kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard ${PORT}:80' manualmente."
fi
