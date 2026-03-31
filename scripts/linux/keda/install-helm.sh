#!/usr/bin/env bash
# install-helm.sh - Instalação robusta do Helm no Linux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"

log_info "Verificando instalação do Helm..."

if command_exists helm; then
    log_success "Helm já instalado: $(helm version --short 2>/dev/null)"
    exit 0
fi

log_info "Baixando e instalando Helm através do script oficial..."

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

if command_exists helm; then
    log_success "Helm instalado com sucesso: $(helm version --short 2>/dev/null)"
else
    log_error "Falha ao instalar Helm."
    exit 1
fi
