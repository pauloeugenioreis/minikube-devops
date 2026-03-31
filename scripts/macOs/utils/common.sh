#!/bin/bash

# common.sh
# Utilidades compartilhadas para scripts macOS

# Emojis
export emoji_success=$(printf "\u2705")
export emoji_error=$(printf "\u274c")
export emoji_warning=$(printf "\u26a0\ufe0f")
export emoji_info=$(printf "\U1f4a1")
export emoji_gear=$(printf "\u2699\ufe0f")
export emoji_rocket=$(printf "\U1f680")
export emoji_package=$(printf "\U1f4e6")
export emoji_wrench=$(printf "\U1f527")
export emoji_chart=$(printf "\U1f4ca")
export emoji_clipboard=$(printf "\U1f4cb")
export emoji_scroll=$(printf "\U1f4dc")
export emoji_book=$(printf "\U1f4da")
export emoji_party=$(printf "\U1f389")
export emoji_globe=$(printf "\U1f310")

# Funções de Log
log_info() {
    echo -e "${emoji_info} \e[36m$1\e[0m"
}

log_success() {
    echo -e "${emoji_success} \e[32m$1\e[0m"
}

log_warning() {
    echo -e "${emoji_warning} \e[33m$1\e[0m"
}

log_error() {
    echo -e "${emoji_error} \e[31m$1\e[0m"
}

# Verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar raiz do projeto
detect_project_root() {
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
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
