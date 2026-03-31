#!/usr/bin/env bash
# status.sh
# Verificação rápida do estado do ambiente Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

log_info "Verificando status do ambiente Minikube..."

echo "-----------------------------------------------------"
log_info "VERSOES:"
log_info "kubectl:  $(kubectl version --client --short 2>/dev/null || kubectl version --client | head -1)"
log_info "minikube: $(minikube version --short)"
log_info "helm:     $(helm version --short)"
echo "-----------------------------------------------------"

log_info "MINIKUBE STATUS:"
minikube status || log_error "Minikube não está rodando."
echo "-----------------------------------------------------"

log_info "PODS EM EXECUCAO (default):"
kubectl get pods -n default --no-headers 2>/dev/null | awk '{printf "  %-40s %s\n", $1, $3}'
echo "-----------------------------------------------------"

log_info "PORT-FORWARDS ATIVOS:"
PF_COUNT=$(ps aux | grep "kubectl.*port-forward" | grep -v grep | wc -l)
if [[ $PF_COUNT -gt 0 ]]; then
    ps aux | grep "kubectl.*port-forward" | grep -v grep | awk '{print "  [OK] " $NF, "(PID: " $2 ")"}'
else
    log_warning "Nenhum port-forward detectado."
fi
echo "-----------------------------------------------------"

log_info "ENDPOINTS LOCAIS:"
log_info "  RabbitMQ:  http://localhost:15672"
log_info "  Dashboard: http://localhost:15671"
log_info "  MongoDB:   localhost:27017"
echo "-----------------------------------------------------"

log_info "RECURSOS DO CLUSTER:"
kubectl top nodes 2>/dev/null || log_warning "Metrics Server ainda não respondeu ao comando 'top'."
