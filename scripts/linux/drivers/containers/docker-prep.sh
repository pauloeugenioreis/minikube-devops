#!/usr/bin/env bash
set -euo pipefail

log(){ printf '[info] %s\n' "$*"; }
warn(){ printf '[warn] %s\n' "$*" >&2; }
error(){ printf '[error] %s\n' "$*" >&2; exit 1; }

require_cmd(){ command -v "$1" >/dev/null 2>&1 || error "Comando obrigatório não encontrado: $1"; }

install_docker(){
    log "Instalando Docker (repositório oficial)..."
    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

group_setup(){
    local user="$1"
    if ! id -nG "$user" | grep -qw docker; then
        sudo usermod -aG docker "$user"
        warn "Usuário $user adicionado ao grupo docker. Faça logout/login para aplicar."
    fi
}

ensure_service(){
    sudo systemctl enable docker
    sudo systemctl start docker
}

main(){
    require_cmd curl
    require_cmd sudo

    if ! command -v docker >/dev/null 2>&1; then
        install_docker
    else
        log "Docker já instalado."
    fi

    group_setup "${SUDO_USER:-$USER}"
    ensure_service

    if ! docker info >/dev/null 2>&1; then
        warn "Docker ainda não responde. Verifique se o usuário relogou ou se o daemon está rodando."
    else
        log "Docker rodando corretamente."
    fi
}

main "$@"
