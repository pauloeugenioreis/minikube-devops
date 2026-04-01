#!/usr/bin/env bash
# =====================================================
# Inicializacao completa do Minikube - macOS
# =====================================================
set -euo pipefail

# Sourcing common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_COMMON="$SCRIPT_DIR/../utils/common.sh"
if [[ -f "$UTILS_COMMON" ]]; then
    source "$UTILS_COMMON"
else
    log_info() { echo -e "\e[36m$1\e[0m"; }
    log_success() { echo -e "\e[32m$1\e[0m"; }
    log_warning() { echo -e "\e[33m$1\e[0m"; }
    log_error() { echo -e "\e[31m$1\e[0m"; }
    command_exists() { command -v "$1" >/dev/null 2>&1; }
fi

# Configurações do Cluster
MINIKUBE_CONTAINER_RUNTIME=${MINIKUBE_CONTAINER_RUNTIME:-containerd}
REQUIRED_KUBECTL_VERSION="1.35.0"

# --- Funcoes utilitarias locais ---
check_port() {
    local port="$1"
    lsof -i :"$port" >/dev/null 2>&1
}

ensure_hosts_entry() {
    local ip="$1"
    local host="$2"
    [[ -z "$ip" || -z "$host" ]] && return 1
    if grep -qE "^${ip}[[:space:]]+${host}(\\s|$)" /etc/hosts 2>/dev/null; then
        return 0
    fi
    log_warning "Garantindo entrada em /etc/hosts para ${host} (${ip})..."
    if sudo sh -c "echo '${ip} ${host}' >> /etc/hosts"; then
        log_success "Entrada '${ip} ${host}' adicionada."
    else
        log_warning "Não foi possível adicionar ${host} automaticamente."
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
    local timeout="${4:-100}"
    local interval=5
    local waited=0
    local ns_args=()
    local -a target_parts
    read -r -a target_parts <<< "$target"
    [[ -n "$namespace" ]] && ns_args=(-n "$namespace")

    log_info "Aguardando ${desc}..."
    while (( waited < timeout )); do
        if kubectl get "${target_parts[@]}" "${ns_args[@]}" >/dev/null 2>&1; then
            if kubectl wait "${ns_args[@]}" --for=condition=ready "${target_parts[@]}" --timeout="${interval}s" >/dev/null 2>&1; then
                log_success "${desc} pronto!"
                return 0
            fi
        fi
        sleep "$interval"
        waited=$((waited + interval))
        echo -e "   ...aguardando ${desc} (${waited}s/${timeout}s)"
    done
    return 0
}

deploy_chart() {
    local release="$1"
    local chart_path="$2"
    local namespace="$3"
    log_info "Instalando/atualizando ${release} (Helm)..."
    helm upgrade --install "$release" "$chart_path" --namespace "$namespace" --create-namespace
}

ensure_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        log_warning "Abrindo Docker Desktop..."
        open /Applications/Docker.app || true
        local elapsed=0
        while ! docker info >/dev/null 2>&1 && (( elapsed < 120 )); do
            sleep 5
            elapsed=$((elapsed + 5))
        done
    fi
}

# --- Main Logic ---

log_info "Verificando dependencias..."
log_versions() {
    local kv=$(kubectl version --client 2>/dev/null | head -1 || echo "0.0.0")
    local mv=$(minikube version --short 2>/dev/null || echo "v0.0.0")
    log_info "Versoes: kubectl $kv, minikube $mv"
}
log_versions

# Check required dependencies
MISSING_DEPS=false
SETUP_ARGS=()

CURRENT_KUBECTL=$(kubectl version --client 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0.0.0")
if [[ "$CURRENT_KUBECTL" < "$REQUIRED_KUBECTL_VERSION" ]]; then
    log_error "kubectl versao $CURRENT_KUBECTL detectada. Minimo requerido: $REQUIRED_KUBECTL_VERSION"
    MISSING_DEPS=true
else
    SETUP_ARGS+=("--skip-kubectl")
fi

if ! command_exists minikube; then
    log_error "minikube nao encontrado."
    MISSING_DEPS=true
else
    SETUP_ARGS+=("--skip-minikube")
fi

if ! command_exists helm; then
    log_error "helm nao encontrado."
    MISSING_DEPS=true
else
    SETUP_ARGS+=("--skip-helm")
fi

if ! command_exists docker; then
    log_error "docker nao encontrado."
    MISSING_DEPS=true
else
    SETUP_ARGS+=("--skip-docker")
fi

if [[ "$MISSING_DEPS" == "true" ]]; then
    log_warning "Dependencias ausentes ou desatualizadas detectadas."
    log_info "Iniciando instalacao automatica via setup-fresh-machine.sh..."
    
    SETUP_SCRIPT="$SCRIPT_DIR/../setup-fresh-machine.sh"
    if [[ -f "$SETUP_SCRIPT" ]]; then
        SETUP_ARGS+=("--force-update")
        bash "$SETUP_SCRIPT" "${SETUP_ARGS[@]}"
        
        # Reavaliar kubectl apos instalacao caso ainda nao esteja no PATH do script
        CURRENT_KUBECTL=$(kubectl version --client 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0.0.0")
    else
        log_error "Script de re-setup nao encontrado em: $SETUP_SCRIPT"
        exit 1
    fi
fi

# Menu interativo para configuracao do Minikube
if [[ -z "${MINIKUBE_DRIVER:-}" ]]; then
    echo -e "\e[36mEscolha o driver do Minikube:\e[0m"
    echo -e "  1) docker (padrao)"
    echo -e "  2) qemu2"
    read -p "Selecao [1/2]: " driver_choice
    case "$driver_choice" in
        2) MINIKUBE_DRIVER="qemu2" ;;
        *) MINIKUBE_DRIVER="docker" ;;
    esac
fi

if [[ -z "${MINIKUBE_CPUS:-}" || -z "${MINIKUBE_MEMORY:-}" ]]; then
    echo -e "\e[36mConfiguracao de recursos para o Minikube:\e[0m"
    echo -e "  CPUs padrao : 4"
    echo -e "  Memoria padrao: 8g"
    read -p "Deseja alterar? [y/N]: " res_choice
    if [[ "$res_choice" =~ ^[YySs]$ ]]; then
        read -p "Informe o numero de CPUs [4]: " cpu_input
        MINIKUBE_CPUS=${cpu_input:-4}
        read -p "Informe a memoria (em GB, ex.: 8) [8g]: " mem_input
        if [[ "$mem_input" =~ ^[0-9]+$ ]]; then
            MINIKUBE_MEMORY="${mem_input}g"
        else
            MINIKUBE_MEMORY=${mem_input:-8g}
        fi
    else
        MINIKUBE_CPUS=${MINIKUBE_CPUS:-4}
        MINIKUBE_MEMORY=${MINIKUBE_MEMORY:-8g}
    fi
else
    MINIKUBE_CPUS=${MINIKUBE_CPUS:-4}
    MINIKUBE_MEMORY=${MINIKUBE_MEMORY:-8g}
fi

log_success "Configuracao: driver=${MINIKUBE_DRIVER}, cpus=${MINIKUBE_CPUS}, memory=${MINIKUBE_MEMORY}"

if [[ "$MINIKUBE_DRIVER" == "docker" ]]; then
    ensure_docker_running

    # Resolve conflicting stale network issue after reboot
    if docker network ls --format '{{.Name}}' 2>/dev/null | grep -q '^minikube$'; then
        if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^minikube$'; then
            log_warning "Limpando rede docker 'minikube' orfa para evitar erro na inicializacao..."
            docker network rm minikube >/dev/null 2>&1 || true
        fi
    fi
fi

log_info "Iniciando Minikube cluster..."
minikube start --driver="${MINIKUBE_DRIVER}" --container-runtime="${MINIKUBE_CONTAINER_RUNTIME}" --cpus="${MINIKUBE_CPUS}" --memory="${MINIKUBE_MEMORY}"

log_info "Habilitando addons..."
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress

wait_for_resource "Ingress controller" "pod -l app.kubernetes.io/component=controller" "ingress-nginx"
wait_for_resource "Metrics Server" "pod -l k8s-app=metrics-server" "kube-system"

log_info "Instalando Services..."
deploy_chart rabbitmq "$CHARTS_DIR/rabbitmq" default
deploy_chart mongodb "$CHARTS_DIR/mongodb" default
deploy_chart redis "$CHARTS_DIR/redis" default

wait_for_resource "RabbitMQ" "pod -l app=rabbitmq" "default"
wait_for_resource "MongoDB" "pod -l app=mongodb" "default"
wait_for_resource "Redis" "pod -l app=redis" "default"

log_info "Configurando port-forwards..."
kill_port_forward "rabbitmq.*15672"
start_port_forward "default" "service/rabbitmq" "15672:15672"
kill_port_forward "mongodb.*27017"
start_port_forward "default" "service/mongodb" "27017:27017"
kill_port_forward "kubernetes-dashboard"
start_port_forward "kubernetes-dashboard" "service/kubernetes-dashboard" "15671:80"

log_info "Instalando KEDA..."
KEDA_INSTALLER="$SCRIPTS_MACOS_DIR/keda/install-keda.sh"
if [[ -f "$KEDA_INSTALLER" ]]; then
    bash "$KEDA_INSTALLER" --skip-helm
fi

RABBITMQ_IP=$(kubectl get svc rabbitmq -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "10.106.8.239")

echo ""
echo -e "\e[36m=====================================================\e[0m"
echo -e "\e[32mAMBIENTE CONFIGURADO AUTOMATICAMENTE!\e[0m"
echo -e "\e[36m=====================================================\e[0m"
echo ""
echo -e "\e[33mInformacoes de Acesso:\e[0m"
echo ""
echo -e "\e[36mDashboard do Kubernetes:\e[0m"
echo -e "   Web UI: http://localhost:15671"
echo -e "   Alternativo: minikube dashboard"
echo ""
echo -e "\e[36mRabbitMQ:\e[0m"
echo -e "   Management UI: http://localhost:15672"
echo -e "   Usuario/Senha: guest/guest"
echo -e "   AMQP: localhost:5672"
echo -e "   Connection String: amqp://guest:guest@${RABBITMQ_IP}:5672"
echo ""
echo -e "\e[36mMongoDB:\e[0m"
echo -e "   Connection String: mongodb://admin:admin@localhost:27017/admin"
echo -e "   Host: localhost:27017"
echo -e "   Usuario/Senha: admin/admin"
echo ""
echo -e "\e[36mRedis:\e[0m"
echo -e "   Connection String: redis://localhost:30679"
echo -e "   Host: localhost:30679"
echo -e "   CLI: redis-cli -h localhost -p 30679"
echo ""
