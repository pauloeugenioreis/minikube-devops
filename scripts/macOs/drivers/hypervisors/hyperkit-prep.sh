#!/usr/bin/env bash
set -euo pipefail

log(){ printf '[info] %s\n' "$*"; }
warn(){ printf '[warn] %s\n' "$*" >&2; }
error(){ printf '[error] %s\n' "$*" >&2; exit 1; }

require_cmd(){ command -v "$1" >/dev/null 2>&1 || error "Comando obrigatório não encontrado: $1"; }

check_virtualization(){
    local vmx
    vmx=$(sysctl -a 2>/dev/null | grep -c "VMX\|vmx_excl_only" || true)
    if [[ "$vmx" -eq 0 ]]; then
        warn "Virtualização de hardware (VMX) não detectada. Hyperkit pode não funcionar."
        return 1
    fi
    return 0
}

install_hyperkit(){
    if command -v hyperkit >/dev/null 2>&1; then
        log "Hyperkit já instalado: $(hyperkit -version 2>/dev/null | head -1 || echo 'versao desconhecida')"
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then
        error "Homebrew não encontrado. Instale em https://brew.sh primeiro."
    fi

    log "Instalando hyperkit via Homebrew..."
    brew install hyperkit
}

install_minikube_hyperkit_driver(){
    # O driver hyperkit para Minikube é instalado junto com o minikube via brew
    if command -v minikube >/dev/null 2>&1; then
        log "Minikube encontrado. Driver hyperkit disponível via 'minikube --driver=hyperkit'."
    else
        warn "Minikube não encontrado. Instale via: brew install minikube"
    fi
}

main(){
    require_cmd brew
    check_virtualization || warn "Pode não funcionar sem suporte VT/VMX."
    install_hyperkit
    install_minikube_hyperkit_driver
    log "Ambiente Hyperkit pronto."
}

main "$@"
