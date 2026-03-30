#!/usr/bin/env bash
set -euo pipefail

log(){ printf '[info] %s\n' "$*"; }
warn(){ printf '[warn] %s\n' "$*" >&2; }
error(){ printf '[error] %s\n' "$*" >&2; exit 1; }

require_cmd(){ command -v "$1" >/dev/null 2>&1 || error "Comando obrigatório não encontrado: $1"; }

install_docker_desktop(){
    log "Instalando Docker Desktop via Homebrew Cask..."
    if ! command -v brew >/dev/null 2>&1; then
        error "Homebrew não encontrado. Instale em https://brew.sh primeiro."
    fi
    brew install --cask docker
}

wait_for_docker(){
    log "Aguardando Docker Desktop inicializar..."
    local elapsed=0
    local timeout=120
    while ! docker info >/dev/null 2>&1 && (( elapsed < timeout )); do
        sleep 5
        elapsed=$((elapsed + 5))
        log "  ...aguardando Docker ($elapsed/${timeout}s)..."
    done
    if docker info >/dev/null 2>&1; then
        log "Docker rodando corretamente."
    else
        warn "Docker Desktop instalado mas daemon ainda não respondeu. Abra o Docker Desktop manualmente."
    fi
}

main(){
    require_cmd curl

    if ! command -v docker >/dev/null 2>&1; then
        install_docker_desktop
    else
        log "Docker já instalado."
    fi

    # Abrir Docker Desktop se não estiver rodando
    if ! docker info >/dev/null 2>&1; then
        log "Abrindo Docker Desktop..."
        open /Applications/Docker.app 2>/dev/null || true
        wait_for_docker
    else
        log "Docker já está rodando."
    fi
}

main "$@"
