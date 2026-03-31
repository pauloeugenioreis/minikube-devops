#!/usr/bin/env bash
# dashboard.sh
# Corrige problemas comuns com o Kubernetes Dashboard no Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

log_info "Corrigindo problemas do Dashboard..."

# 1. Garantir RBAC para CronJobs (Erro 404 comum no Dashboard novo)
log_info "1. Aplicando correcao de RBAC para visualizacao de CronJobs..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-cronjobs-fix
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
EOF

# 2. Resetar Port-Forward se necessário
log_info "2. Reiniciando port-forward do Dashboard na porta 15671..."
pkill -f "kubectl.*port-forward.*kubernetes-dashboard" || true
sleep 1
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 15671:80 >/dev/null 2>&1 &

sleep 2
if lsof -i :15671 >/dev/null; then
    log_success "Dashboard corrigido e disponivel em http://localhost:15671"
else
    log_error "Nao foi possivel iniciar o port-forward na porta 15671."
fi
