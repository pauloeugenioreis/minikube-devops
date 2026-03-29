#!/usr/bin/env bash
set -euo pipefail

log(){ printf '[info] %s\n' "$*"; }
warn(){ printf '[warn] %s\n' "$*" >&2; }
error(){ printf '[error] %s\n' "$*" >&2; exit 1; }

require_cmd(){ command -v "$1" >/dev/null 2>&1 || error "Comando obrigatório não encontrado: $1"; }

check_virtualization(){
    if ! egrep -q '(vmx|svm)' /proc/cpuinfo; then
        warn "CPU sem suporte a virtualização (VMX/SVM)."
        return 1
    fi
    return 0
}

is_pkg_installed(){
    local pkg="$1"
    case "$pkg" in
        qemu-kvm)
            dpkg -s qemu-kvm >/dev/null 2>&1 || dpkg -s qemu-system-x86 >/dev/null 2>&1
            ;;
        *)
            dpkg -s "$pkg" >/dev/null 2>&1
            ;;
    esac
}

install_packages(){
    local pkgs=(qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils)
    local missing=()
    local pkg

    for pkg in "${pkgs[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if (( ${#missing[@]} )); then
        log "Instalando pacotes ausentes: ${missing[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${missing[@]}"
    else
        log "Pacotes KVM/Libvirt já instalados."
    fi
}

ensure_service(){
    if ! systemctl is-enabled --quiet libvirtd; then
        sudo systemctl enable libvirtd
    fi
    if ! systemctl is-active --quiet libvirtd; then
        sudo systemctl start libvirtd
    fi
}

configure_user(){
    local user="$1"
    if ! id -nG "$user" | grep -qw libvirt; then
        sudo usermod -aG libvirt "$user"
        warn "Usuário $user adicionado ao grupo libvirt. Por favor, relogue para aplicar."
    fi
}

main(){
    require_cmd egrep
    require_cmd sudo
    check_virtualization || warn "Pode não funcionar sem suporte VT/SVM."
    install_packages
    ensure_service
    configure_user "${SUDO_USER:-$USER}"
    log "Ambiente KVM pronto."
}

main "$@"
