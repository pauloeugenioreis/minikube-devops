#!/bin/bash

# common.sh
# Utilidades compartilhadas para scripts macOS

# Emojis
# Emojis
export EMOJI_SUCCESS="✅"
export EMOJI_CHECK="✅"
export EMOJI_ERROR="❌"
export EMOJI_CROSS="❌"
export EMOJI_WARNING="⚠️"
export EMOJI_INFO="💡"
export EMOJI_ARROW="➡️"
export EMOJI_GEAR="⚙️"
export EMOJI_ROCKET="🚀"
export EMOJI_PACKAGE="📦"
export EMOJI_WRENCH="🔧"
export EMOJI_CHART="📊"
export EMOJI_CLIPBOARD="📋"
export EMOJI_SCROLL="📜"
export EMOJI_BOOK="📚"
export EMOJI_PARTY="🎉"
export EMOJI_GLOBE="🌐"

# Funções de Log
log_info() {
    echo -e "${EMOJI_INFO} \033[36m$1\033[0m"
}

log_success() {
    echo -e "${EMOJI_SUCCESS} \033[32m$1\033[0m"
}

log_warning() {
    echo -e "${EMOJI_WARNING} \033[33m$1\033[0m"
}

log_error() {
    echo -e "${EMOJI_ERROR} \033[31m$1\033[0m"
}

# Verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Aguarda uma porta local estar ouvindo (para verificar port-forwards)
wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local elapsed=0
    while (( elapsed < timeout )); do
        if (echo >/dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}

# Detectar raiz do projeto
detect_project_root() {
    local current_dir
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/README.md" && -d "$current_dir/scripts" && -d "$current_dir/docs" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# Exportar caminhos úteis
PROJECT_ROOT_DETECTED=$(detect_project_root)
if [[ $? -ne 0 ]]; then
    PROJECT_ROOT_DETECTED=$(pwd)
fi

export PROJECT_ROOT="$PROJECT_ROOT_DETECTED"
export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
export SCRIPTS_MACOS_DIR="$PROJECT_ROOT/scripts/macOs"
export CHARTS_DIR="$PROJECT_ROOT/charts"
export CONFIGS_DIR="$PROJECT_ROOT/configs"
