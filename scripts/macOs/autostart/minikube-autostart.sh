#!/usr/bin/env bash
# =====================================================
# Autostart macOS (sempre instala KEDA)
# =====================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/../init/init-minikube-fixed.sh"
HYPERKIT_PREP_SCRIPT="$SCRIPT_DIR/../drivers/hypervisors/hyperkit-prep.sh"
DOCKER_PREP_SCRIPT="$SCRIPT_DIR/../drivers/containers/docker-prep.sh"

DEFAULT_CPUS="${DEFAULT_MINIKUBE_CPUS:-4}"
DEFAULT_MEMORY="${DEFAULT_MINIKUBE_MEMORY:-8g}"
MINIKUBE_CPUS="$DEFAULT_CPUS"
MINIKUBE_MEMORY="$DEFAULT_MEMORY"

prompt_driver() {
    echo "Escolha o driver do Minikube:" \
        && echo "  1) docker (padrão)" \
        && echo "  2) hyperkit (requer Hyperkit instalado)" \
        && printf "Seleção [1/2]: "
    read -r choice
    case "$choice" in
        2)
            echo "Driver hyperkit selecionado."
            MINIKUBE_DRIVER="hyperkit"
            ;;
        *)
            echo "Driver docker selecionado."
            MINIKUBE_DRIVER="docker"
            ;;
    esac
}

prepare_hyperkit() {
    if [[ "$MINIKUBE_DRIVER" != "hyperkit" ]]; then
        return
    fi

    if [[ ! -x "$HYPERKIT_PREP_SCRIPT" ]]; then
        echo "Script de preparação Hyperkit não encontrado em $HYPERKIT_PREP_SCRIPT" >&2
        exit 1
    fi

    echo "==> Preparando ambiente Hyperkit..."
    "$HYPERKIT_PREP_SCRIPT"

    if ! command -v hyperkit >/dev/null 2>&1; then
        echo "falha: hyperkit não encontrado após preparação." >&2
        exit 1
    fi
}

prepare_docker() {
    if [[ "$MINIKUBE_DRIVER" != "docker" ]]; then
        return
    fi

    if [[ ! -x "$DOCKER_PREP_SCRIPT" ]]; then
        echo "Script de preparação Docker não encontrado em $DOCKER_PREP_SCRIPT" >&2
        exit 1
    fi

    echo "==> Preparando ambiente Docker..."
    "$DOCKER_PREP_SCRIPT"
}

prompt_resources() {
    echo "Configuração de recursos para o Minikube:" \
        && echo "  CPUs padrão : $DEFAULT_CPUS" \
        && echo "  Memória padrão: $DEFAULT_MEMORY" \
        && printf "Deseja alterar? [1=Sim / 2=Não]: "
    read -r choice
    case "$choice" in
        1|s|S)
            read -rp "Informe o número de CPUs [$DEFAULT_CPUS]: " cpus_input
            if [[ -n "$cpus_input" ]]; then
                MINIKUBE_CPUS="$cpus_input"
            fi
            read -rp "Informe a memória (ex.: 8g) [$DEFAULT_MEMORY]: " mem_input
            if [[ -n "$mem_input" ]]; then
                MINIKUBE_MEMORY="$mem_input"
            fi
            ;;
        *)
            echo "Mantendo valores padrão." ;;
    esac

    echo "Recursos definidos: CPUs=$MINIKUBE_CPUS, Memória=$MINIKUBE_MEMORY"
}

if [[ ! -f "$INIT_SCRIPT" ]]; then
    echo "init-minikube-fixed.sh não encontrado em $INIT_SCRIPT" >&2
    exit 1
fi

echo "====================================================="
echo "AUTOSTART MINIKUBE + KEDA (macOS)"
echo "====================================================="
prompt_driver
prepare_hyperkit
prepare_docker
prompt_resources

echo "Encaminhando execução para: $INIT_SCRIPT"

MINIKUBE_CONTAINER_RUNTIME="containerd"

export MINIKUBE_DRIVER
export MINIKUBE_CONTAINER_RUNTIME
export MINIKUBE_CPUS
export MINIKUBE_MEMORY

echo ""
exec bash "$INIT_SCRIPT" "$@" --install-keda
