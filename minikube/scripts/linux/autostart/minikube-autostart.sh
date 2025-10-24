#!/usr/bin/env bash
# =====================================================
# Autostart Linux (sempre instala KEDA)
# =====================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/../init/init-minikube-fixed.sh"
KVM_PREP_SCRIPT="$SCRIPT_DIR/../drivers/hypervisors/kvm-prep.sh"
DOCKER_PREP_SCRIPT="$SCRIPT_DIR/../drivers/containers/docker-prep.sh"

DEFAULT_CPUS="${DEFAULT_MINIKUBE_CPUS:-4}"
DEFAULT_MEMORY="${DEFAULT_MINIKUBE_MEMORY:-8g}"
MINIKUBE_CPUS="$DEFAULT_CPUS"
MINIKUBE_MEMORY="$DEFAULT_MEMORY"

prompt_driver() {
    echo "Escolha o driver do Minikube:" \
        && echo "  1) docker (padrão)" \
        && echo "  2) kvm2 (requere suporte VT e libvirt)"\
        && printf "Seleção [1/2]: "
    read -r choice
    case "$choice" in
        2)
            echo "Driver kvm2 selecionado."
            MINIKUBE_DRIVER="kvm2"
            ;;
        *)
            echo "Driver docker selecionado."
            MINIKUBE_DRIVER="docker"
            ;;
    esac
}

prepare_kvm() {
    if [[ "$MINIKUBE_DRIVER" != "kvm2" ]]; then
        return
    fi

    if [[ ! -x "$KVM_PREP_SCRIPT" ]]; then
        echo "Script de preparação KVM não encontrado em $KVM_PREP_SCRIPT" >&2
        exit 1
    fi

    echo "==> Preparando ambiente KVM..."
    "$KVM_PREP_SCRIPT"

    if ! command -v virsh >/dev/null 2>&1; then
        echo "falha: virsh não encontrado após preparação." >&2
        exit 1
    fi

    if ! virsh list >/dev/null 2>&1; then
        echo "falha: libvirt não respondeu. Verifique serviço libvirtd." >&2
        exit 1
    fi

    if ! groups "$USER" | grep -q '\blibvirt\b'; then
        echo "==> Atenção: seu usuário não está no grupo libvirt. Faça logout/login antes de continuar." >&2
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
echo "AUTOSTART MINIKUBE + KEDA (LINUX)"
echo "====================================================="
prompt_driver
prepare_kvm
prepare_docker
prompt_resources

echo "Encaminhando execução para: $INIT_SCRIPT"

if [[ "$MINIKUBE_DRIVER" == "kvm2" ]]; then
    MINIKUBE_CONTAINER_RUNTIME="containerd"
else
    MINIKUBE_CONTAINER_RUNTIME="containerd"
fi

export MINIKUBE_DRIVER
export MINIKUBE_CONTAINER_RUNTIME
export MINIKUBE_CPUS
export MINIKUBE_MEMORY

echo ""
exec bash "$INIT_SCRIPT" "$@" --install-keda
