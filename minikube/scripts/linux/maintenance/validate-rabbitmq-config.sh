#!/bin/bash
# Valida a configuração do RabbitMQ no cluster Kubernetes

set -e

NAMESPACE="default"
RABBITMQ_POD=$(kubectl get pods -n "$NAMESPACE" -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}')

if [ -z "$RABBITMQ_POD" ]; then
  echo "❌ Pod do RabbitMQ não encontrado no namespace $NAMESPACE."
  exit 1
fi

echo "🔍 Validando configuração do RabbitMQ ($RABBITMQ_POD)..."

# Exemplo: listar filas
kubectl exec -n "$NAMESPACE" "$RABBITMQ_POD" -- rabbitmqctl list_queues name messages

# Exemplo: verificar configuração loopback_users
kubectl exec -n "$NAMESPACE" "$RABBITMQ_POD" -- rabbitmqctl eval 'application:get_env(rabbit, loopback_users).'

echo "✅ Validação concluída!"
