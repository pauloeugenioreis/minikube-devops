#!/bin/bash

# common.sh
# Utilidades compartilhadas para scripts Linux

# Emojis
EMOJI_SUCCESS=$(printf "\u2705");    export EMOJI_SUCCESS
EMOJI_CHECK=$(printf "\u2705");      export EMOJI_CHECK
EMOJI_ERROR=$(printf "\u274c");      export EMOJI_ERROR
EMOJI_CROSS=$(printf "\u274c");      export EMOJI_CROSS
EMOJI_WARNING=$(printf "\u26a0\ufe0f"); export EMOJI_WARNING
EMOJI_INFO=$(printf "\U1f4a1");      export EMOJI_INFO
EMOJI_ARROW=$(printf "\u27a1\ufe0f"); export EMOJI_ARROW
EMOJI_GEAR=$(printf "\u2699\ufe0f"); export EMOJI_GEAR
EMOJI_ROCKET=$(printf "\U1f680");    export EMOJI_ROCKET
EMOJI_PACKAGE=$(printf "\U1f4e6");   export EMOJI_PACKAGE
EMOJI_WRENCH=$(printf "\U1f527");    export EMOJI_WRENCH
EMOJI_CHART=$(printf "\U1f4ca");     export EMOJI_CHART
EMOJI_CLIPBOARD=$(printf "\U1f4cb"); export EMOJI_CLIPBOARD
EMOJI_SCROLL=$(printf "\U1f4dc");    export EMOJI_SCROLL
EMOJI_BOOK=$(printf "\U1f4da");      export EMOJI_BOOK
EMOJI_PARTY=$(printf "\U1f389");     export EMOJI_PARTY
EMOJI_GLOBE=$(printf "\U1f310");     export EMOJI_GLOBE

# Funções de Log
log_info() {
    echo -e "${EMOJI_INFO} \e[36m$1\e[0m"
}

log_success() {
    echo -e "${EMOJI_SUCCESS} \e[32m$1\e[0m"
}

log_warning() {
    echo -e "${EMOJI_WARNING} \e[33m$1\e[0m"
}

log_error() {
    echo -e "${EMOJI_ERROR} \e[31m$1\e[0m"
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
# Sobe níveis a partir do script atual até achar o README.md e a pasta scripts
detect_project_root() {
    # Pegar o diretório do script common.sh (esta na scripts/linux/utils)
    local current_dir
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Subir ate achar a raiz
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
    # Se falhar, tentar o diretório atual como fallback desesperado
    PROJECT_ROOT_DETECTED=$(pwd)
fi

export PROJECT_ROOT="$PROJECT_ROOT_DETECTED"
export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
export SCRIPTS_LINUX_DIR="$PROJECT_ROOT/scripts/linux"
export CHARTS_DIR="$PROJECT_ROOT/charts"
export CONFIGS_DIR="$PROJECT_ROOT/configs"
