#!/usr/bin/env bash
# =====================================================
# Inicialização completa do Minikube - Linux
# Mantém paridade com o fluxo do Windows (Helm + KEDA)
# =====================================================
set -euo pipefail

# --- Configuração de cores ---
supports_color() {
    [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]
}

if supports_color; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'
    WHITE=$'\033[1;37m'
    NC=$'\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    WHITE=''
    NC=''
fi

# --- Funções utilitárias ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_port() {
    local port="$1"
    if command_exists ss; then
        ss -tulwn 2>/dev/null | grep -q ":${port} "
    else
        netstat -tuln 2>/dev/null | grep -q ":${port} "
    fi
}

kill_port_forward() {
    local pattern="$1"
    pkill -f "kubectl.*port-forward.*${pattern}" 2>/dev/null || true
}

start_port_forward() {
    local namespace="$1"
    local resource="$2"
    local mapping="$3"
    kubectl port-forward -n "$namespace" "$resource" "$mapping" >/dev/null 2>&1 &
    sleep 3
}

wait_for_resource() {
    local desc="$1"
    local target="$2"
    local namespace="$3"
    local timeout="${4:-300}"
    local interval=5
    local waited=0
    local ns_args=()
    local -a target_parts

    read -r -a target_parts <<< "$target"
    [[ -n "$namespace" ]] && ns_args=(-n "$namespace")

    echo -e "${WHITE}   Aguardando ${desc}...${NC}"

    while (( waited < timeout )); do
        if kubectl get "${target_parts[@]}" "${ns_args[@]}" >/dev/null 2>&1; then
            if kubectl wait "${ns_args[@]}" --for=condition=ready "${target_parts[@]}" --timeout="${interval}s" >/dev/null 2>&1; then
                echo -e "${GREEN}   ${desc} pronto!${NC}"
                return 0
            fi
        fi

        sleep "$interval"
        waited=$((waited + interval))
        echo -e "${WHITE}   ...aguardando ${desc} (${waited}s/${timeout}s)${NC}"
    done

    echo -e "${YELLOW}   ⚠️ Timeout aguardando ${desc}. Verifique manualmente.${NC}"
    return 1
}

wait_for_job() {
    local job_name="$1"
    local namespace="$2"
    local waited=0
    local interval=10
    local timeout=300

    echo -e "${WHITE}   Aguardando job ${job_name} completar...${NC}"
    while (( waited < timeout )); do
        local status
        status=$(kubectl get job "$job_name" -n "$namespace" -o jsonpath='{.status.conditions[0].type}' 2>/dev/null || true)
        case "$status" in
            Complete)
                echo -e "${GREEN}   Job ${job_name} concluído com sucesso.${NC}"
                return 0
                ;;
            Failed)
                echo -e "${RED}   Job ${job_name} falhou.${NC}"
                kubectl logs job/"$job_name" -n "$namespace" || true
                return 1
                ;;
        esac
        sleep "$interval"
        waited=$((waited + interval))
    done
    echo -e "${YELLOW}   ⚠️ Timeout aguardando job ${job_name}.${NC}"
    kubectl logs job/"$job_name" -n "$namespace" || true
    return 1
}

find_project_root() {
    local dir="$1"
    for _ in {1..10}; do
        if [[ -f "$dir/MINIKUBE-PROJECT-HISTORY.md" && -d "$dir/minikube/charts" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

deploy_chart() {
    local release="$1"
    local chart_path="$2"
    local namespace="$3"
    echo -e "${WHITE}   Instalando/atualizando ${release} (Helm)...${NC}"
    helm upgrade --install "$release" "$chart_path" --namespace "$namespace" --create-namespace
    echo -e "${GREEN}   ${release} pronto via Helm.${NC}"
}

ensure_log_file() {
    local preferred_dir="$1"
    local fallback_dir="$HOME/.minikube/logs"

    if mkdir -p "$preferred_dir" 2>/dev/null; then
        echo "$preferred_dir/init-linux-$(date '+%Y%m%d').log"
        return
    fi

    mkdir -p "$fallback_dir"
    echo "$fallback_dir/init-linux-$(date '+%Y%m%d').log"
}

log_versions() {
    local kubectl_ver
    local minikube_ver
    local helm_ver

    kubectl_ver=$(get_kubectl_version || echo "desconhecido")
    minikube_ver=$(minikube version --short 2>/dev/null || echo "desconhecido")
    helm_ver=$(helm version --short 2>/dev/null || echo "desconhecido")

    echo -e "${GREEN}Versões detectadas:${NC}"
    echo -e "${WHITE}   • kubectl:  ${kubectl_ver}${NC}"
    echo -e "${WHITE}   • minikube: ${minikube_ver}${NC}"
    echo -e "${WHITE}   • helm:     ${helm_ver}${NC}"
}

get_kubectl_version() {
    local output
    if output=$(kubectl version --client --output=json 2>/dev/null); then
        local version
        version=$(echo "$output" | sed -n 's/.*"gitVersion"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    if output=$(kubectl version --client 2>/dev/null); then
        local version
        version=$(echo "$output" | awk -F': ' '/Client Version/ {print $2}')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    return 1
}

ensure_docker_running() {
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}Docker já está em execução.${NC}"
        return
    fi

    echo -e "${YELLOW}Iniciando serviço Docker...${NC}"
    if sudo systemctl start docker; then
        local elapsed=0
        local timeout=120
        while ! docker info >/dev/null 2>&1 && (( elapsed < timeout )); do
            sleep 5
            elapsed=$((elapsed + 5))
            echo -e "${WHITE}   Aguardando Docker ($elapsed/${timeout}s)...${NC}"
        done
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}Docker pronto!${NC}"
        else
            echo -e "${RED}Docker não ficou pronto no tempo esperado.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Falha ao iniciar o serviço Docker.${NC}"
        exit 1
    fi
}

ensure_minikube_running() {
    if minikube status >/dev/null 2>&1; then
        echo -e "${GREEN}Minikube já está rodando.${NC}"
        return
    fi

    echo -e "${YELLOW}Iniciando Minikube (driver docker)...${NC}"
    if ! minikube start --driver=docker; then
        echo -e "${RED}Falha ao iniciar o Minikube.${NC}"
        echo -e "${YELLOW}Tente executar 'minikube delete --all --purge' e rodar o script novamente.${NC}"
        exit 1
    fi
}

METRICS_SERVER_IMAGES=(
    "registry.k8s.io/metrics-server/metrics-server:v0.8.0"
    "registry.k8s.io/metrics-server/metrics-server@sha256:89258156d0e9af60403eafd44da9676fd66f600c7934d468ccc17e42b199aee2"
)

ensure_metrics_server_image() {
    if ! command_exists docker; then
        echo -e "${YELLOW}   ⚠️ Docker não disponível para pré-carregar imagens do metrics-server.${NC}"
        return
    fi

    for image in "${METRICS_SERVER_IMAGES[@]}"; do
        if ! docker image inspect "$image" >/dev/null 2>&1; then
            echo -e "${WHITE}   Baixando imagem ${image}...${NC}"
            if ! docker pull "$image"; then
                echo -e "${YELLOW}   ⚠️ Falha ao baixar ${image}. O addon tentará puxar diretamente.${NC}"
                continue
            fi
        fi

        echo -e "${WHITE}   Carregando ${image} no Minikube...${NC}"
        if ! minikube image load "$image" >/dev/null 2>&1; then
            echo -e "${YELLOW}   ⚠️ Não foi possível carregar ${image} no Minikube. Verifique manualmente.${NC}"
        else
            echo -e "${GREEN}   ${image} disponível para o metrics-server.${NC}"
        fi
    done
}

patch_metrics_server_image() {
    echo -e "${WHITE}   Ajustando deployment do metrics-server para usar imagem local (tag)...${NC}"
    if ! kubectl patch deployment metrics-server -n kube-system \
        --type=json \
        -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"registry.k8s.io/metrics-server/metrics-server:v0.8.0"}]' >/dev/null 2>&1; then
        echo -e "${YELLOW}   ⚠️ Não foi possível ajustar a imagem do metrics-server. Verifique manualmente.${NC}"
    fi
}

KEDA_DEPLOYMENTS=(
    "keda-operator"
    "keda-admission-webhooks"
    "keda-operator-metrics-apiserver"
)

patch_keda_image_policy() {
    echo -e "${WHITE}   Ajustando imagePullPolicy dos componentes KEDA para IfNotPresent...${NC}"
    for deploy in "${KEDA_DEPLOYMENTS[@]}"; do
        if ! kubectl patch deployment "$deploy" -n keda --type='json' \
            -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]' >/dev/null 2>&1; then
            echo -e "${YELLOW}   ⚠️ Não foi possível ajustar imagePullPolicy de ${deploy}.${NC}"
        fi
    done
}


# --- Parâmetros ---
INSTALL_KEDA=true
SKIP_ADDONS=false
SKIP_RABBITMQ_CONFIG=false

usage() {
    cat <<USAGE
Uso: $0 [opções]
  --skip-addons          Não habilitar addons essenciais do Minikube
  --skip-keda            Pular instalação/validação do KEDA
  --install-keda         Forçar instalação do KEDA (padrão)
  --skip-rabbitmq-config Pular job de configuração do RabbitMQ
  -h, --help             Mostrar esta ajuda
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-addons)
            SKIP_ADDONS=true
            shift
            ;;
        --skip-keda)
            INSTALL_KEDA=false
            shift
            ;;
        --install-keda)
            INSTALL_KEDA=true
            shift
            ;;
        --skip-rabbitmq-config)
            SKIP_RABBITMQ_CONFIG=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Parâmetro desconhecido: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(find_project_root "$SCRIPT_DIR")"
if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${RED}Não foi possível detectar a raiz do projeto. Verifique a estrutura.${NC}"
    exit 1
fi
MINIKUBE_DIR="$PROJECT_ROOT/minikube"
CHARTS_DIR="$MINIKUBE_DIR/charts"
CONFIGS_DIR="$MINIKUBE_DIR/configs"
KEDA_INSTALLER="$MINIKUBE_DIR/scripts/linux/keda/install-keda.sh"
LOG_FILE=$(ensure_log_file "$PROJECT_ROOT/log")

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

cat <<INFO
${CYAN}=====================================================${NC}
${GREEN}Inicializando ambiente Minikube completo (Linux)${NC}
${CYAN}=====================================================${NC}
Projeto detectado em: ${WHITE}${PROJECT_ROOT}${NC}
Log: ${WHITE}${LOG_FILE}${NC}
INFO

REQUIRED_CMDS=(minikube kubectl helm docker)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command_exists "$cmd"; then
        echo -e "${RED}Dependência ausente: $cmd${NC}"
        case "$cmd" in
            minikube)
                echo -e "${YELLOW}Instale com: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube${NC}"
                ;;
            kubectl)
                echo -e "${YELLOW}Instale com: sudo snap install kubectl --classic${NC}"
                ;;
            helm)
                echo -e "${YELLOW}Instale com: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash${NC}"
                ;;
            docker)
                echo -e "${YELLOW}Instale com: sudo apt install -y docker.io && sudo usermod -aG docker $USER${NC}"
                ;;
        esac
        exit 1
    fi
done

log_versions
ensure_docker_running
ensure_minikube_running

if [[ "$SKIP_ADDONS" == false ]]; then
    echo -e "${YELLOW}Habilitando addons essenciais...${NC}"
    ensure_metrics_server_image
    for addon in storage-provisioner metrics-server default-storageclass dashboard; do
        echo -e "${WHITE}   Habilitando $addon...${NC}"
        minikube addons enable "$addon" >/dev/null 2>&1 || echo -e "${YELLOW}   ⚠️ Falha ao habilitar $addon. Verifique manualmente.${NC}"
    done
    patch_metrics_server_image
fi

wait_for_resource "nó Minikube" "node/minikube" ""

if [[ ! -d "$CHARTS_DIR/rabbitmq" || ! -d "$CHARTS_DIR/mongodb" ]]; then
    echo -e "${RED}Charts Helm não encontrados em $CHARTS_DIR. Verifique a estrutura.${NC}"
    exit 1
fi

deploy_chart rabbitmq "$CHARTS_DIR/rabbitmq" default
deploy_chart mongodb "$CHARTS_DIR/mongodb" default

wait_for_resource "RabbitMQ" "pod -l app=rabbitmq" "default"
wait_for_resource "MongoDB" "pod -l app=mongodb" "default"

echo -e "${YELLOW}Configurando port-forwards locais...${NC}"
kill_port_forward "rabbitmq-service.*15672"
start_port_forward "default" "service/rabbitmq-service" "15672:15672"
check_port 15672 && echo -e "${GREEN}   RabbitMQ Management em http://localhost:15672${NC}" || echo -e "${YELLOW}   ⚠️ RabbitMQ Management não respondeu (porta 15672).${NC}"

kill_port_forward "rabbitmq-service.*5672"
start_port_forward "default" "service/rabbitmq-service" "5672:5672"
check_port 5672 && echo -e "${GREEN}   RabbitMQ AMQP disponível em localhost:5672${NC}" || echo -e "${YELLOW}   ⚠️ RabbitMQ AMQP não respondeu (porta 5672).${NC}"

kill_port_forward "mongodb-service.*27017"
start_port_forward "default" "service/mongodb-service" "27017:27017"
check_port 27017 && echo -e "${GREEN}   MongoDB disponível em mongodb://localhost:27017${NC}" || echo -e "${YELLOW}   ⚠️ MongoDB não respondeu (porta 27017).${NC}"

kill_port_forward "kubernetes-dashboard"
start_port_forward "kubernetes-dashboard" "service/kubernetes-dashboard" "4666:80"
check_port 4666 && echo -e "${GREEN}   Dashboard em http://localhost:4666${NC}" || echo -e "${YELLOW}   ⚠️ Dashboard não respondeu (porta 4666).${NC}"

if [[ "$INSTALL_KEDA" == true ]]; then
    echo -e "${YELLOW}Instalando/validando KEDA...${NC}"
    if [[ -f "$KEDA_INSTALLER" ]]; then
        if bash "$KEDA_INSTALLER" --skip-helm; then
            patch_keda_image_policy
        else
            echo -e "${YELLOW}   ⚠️ Verifique os logs da instalação do KEDA.${NC}"
        fi
    else
        echo -e "${YELLOW}   ⚠️ Script do KEDA não encontrado em $KEDA_INSTALLER.${NC}"
    fi
fi

echo -e "${YELLOW}Executando validações rápidas...${NC}"
if curl -s --max-time 5 http://rabbitmq.local >/dev/null; then
    echo -e "${GREEN}   RabbitMQ via Ingress respondeu (http://rabbitmq.local).${NC}"
else
    echo -e "${YELLOW}   ⚠️ RabbitMQ via Ingress ainda não respondeu (rabbitmq.local).${NC}"
    if curl -s --max-time 5 http://localhost:15672 >/dev/null; then
        echo -e "${GREEN}   RabbitMQ Management respondeu em http://localhost:15672.${NC}"
    fi
fi

if kubectl exec deployment/mongodb -- mongosh mongodb://admin:admin@localhost:27017/admin --eval "db.runCommand('ping')" >/dev/null 2>&1; then
    echo -e "${GREEN}   MongoDB respondeu ao ping.${NC}"
else
    echo -e "${YELLOW}   ⚠️ MongoDB ainda não respondeu ao ping.${NC}"
fi

cat <<SUMMARY
${CYAN}=====================================================${NC}
${GREEN}AMBIENTE CONFIGURADO COM SUCESSO!${NC}
${CYAN}=====================================================${NC}
${YELLOW}Informações de acesso:${NC}
${WHITE}   • RabbitMQ UI:   http://rabbitmq.local  (guest/guest)${NC}
${WHITE}   • RabbitMQ AMQP: amqp://guest:guest@localhost:5672${NC}
${WHITE}   • MongoDB URI:   mongodb://admin:admin@localhost:27017/admin${NC}
${WHITE}   • Dashboard:     http://localhost:4666${NC}
SUMMARY

if [[ "$INSTALL_KEDA" == true ]]; then
    echo -e "${WHITE}   • KEDA:         kubectl get pods -n keda${NC}"
fi

echo -e "${YELLOW}Log completo:${NC} ${WHITE}$LOG_FILE${NC}"
echo -e "${GREEN}Ambiente pronto para uso!${NC}"
