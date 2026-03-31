#!/usr/bin/env bash
# test-rabbitmq.sh
# Valida a configuracao do RabbitMQ no cluster Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

NAMESPACE="default"
RABBITMQ_POD=$(kubectl get pods -n "$NAMESPACE" -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$RABBITMQ_POD" ]; then
    log_error "Pod do RabbitMQ não encontrado no namespace $NAMESPACE."
    exit 1
fi

log_info "Validando configuração do RabbitMQ ($RABBITMQ_POD)..."

echo "--- Filas Ativas ---"
kubectl exec -n "$NAMESPACE" "$RABBITMQ_POD" -- rabbitmqctl list_queues name messages

echo "--- Status do Cluster ---"
kubectl exec -n "$NAMESPACE" "$RABBITMQ_POD" -- rabbitmqctl cluster_status

log_success "Validacao concluida!"
