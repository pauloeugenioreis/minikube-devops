#!/usr/bin/env bash
# =====================================================
# Script de Instalacao KEDA no Minikube - Versao Linux
# KEDA - Kubernetes Event-driven Autoscaling
# =====================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

# Parametros
SKIP_HELM=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-helm) SKIP_HELM=true; shift ;;
        --uninstall) UNINSTALL=true; shift ;;
        -h|--help)
            echo "Uso: $0 [--skip-helm] [--uninstall]"
            exit 0
            ;;
        *) shift ;;
    esac
done

log_info "Instalacao do KEDA iniciada..."

if [[ "$UNINSTALL" == "true" ]]; then
    log_info "Desinstalando KEDA..."
    helm uninstall keda --namespace keda 2>/dev/null || true
    kubectl delete namespace keda --ignore-not-found=true
    log_success "KEDA removido."
    exit 0
fi

# Adicionar Helm Repo
if [[ "$SKIP_HELM" == "false" ]]; then
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
fi

# Instalar
log_info "Executando Helm Upgrade..."
helm upgrade --install keda kedacore/keda --namespace keda --create-namespace

log_success "KEDA instalado com sucesso!"
echo ""
log_success "KEDA pronto para uso!"
