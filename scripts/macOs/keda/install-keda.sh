#!/usr/bin/env bash
# install-keda.sh
# Instalacao KEDA no macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/common.sh"

UNINSTALL=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --uninstall) UNINSTALL=true; shift ;;
        *) shift ;;
    esac
done

if [[ "$UNINSTALL" == "true" ]]; then
    log_info "Desinstalando KEDA..."
    helm uninstall keda -n keda || true
    kubectl delete ns keda || true
    exit 0
fi

log_info "Instalando KEDA via Helm..."
helm repo add kedacore https://kedacore.github.io/charts || true
helm repo update
helm upgrade --install keda kedacore/keda -n keda --create-namespace

log_success "KEDA instalado."
