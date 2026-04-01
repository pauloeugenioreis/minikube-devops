#!/bin/bash

# common.sh
# Utilidades compartilhadas para scripts macOS

# Emojis
# Emojis
export emoji_success="✅"
export emoji_check="✅"
export emoji_error="❌"
export emoji_cross="❌"
export emoji_warning="⚠️"
export emoji_info="💡"
export emoji_arrow="➡️"
export emoji_gear="⚙️"
export emoji_rocket="🚀"
export emoji_package="📦"
export emoji_wrench="🔧"
export emoji_chart="📊"
export emoji_clipboard="📋"
export emoji_scroll="📜"
export emoji_book="📚"
export emoji_party="🎉"
export emoji_globe="🌐"

# Funções de Log
log_info() {
    echo -e "${emoji_info} \033[36m$1\033[0m"
}

log_success() {
    echo -e "${emoji_success} \033[32m$1\033[0m"
}

log_warning() {
    echo -e "${emoji_warning} \033[33m$1\033[0m"
}

log_error() {
    echo -e "${emoji_error} \033[31m$1\033[0m"
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
