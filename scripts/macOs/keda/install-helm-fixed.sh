#!/usr/bin/env bash
# install-helm-fixed.sh - Instalacao robusta do Helm no macOS
set -euo pipefail

log(){ printf '[info] %s\n' "$*"; }
warn(){ printf '[warn] %s\n' "$*" >&2; }
error(){ printf '[error] %s\n' "$*" >&2; exit 1; }

if command -v helm >/dev/null 2>&1; then
    log "Helm já instalado: $(helm version --short 2>/dev/null)"
    exit 0
fi

log "Instalando Helm via Homebrew..."

if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew não encontrado. Tentando método alternativo (script oficial)..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    brew install helm
fi

if command -v helm >/dev/null 2>&1; then
    log "Helm instalado com sucesso: $(helm version --short 2>/dev/null)"
else
    error "Falha ao instalar Helm."
fi
