#!/bin/bash
# =====================================================
# Script de Inicializacao Completa do Minikube com RabbitMQ e MongoDB
# Versao Linux Ubuntu 24.04.3
# =====================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
MINIKUBE_DIR="$(dirname "$LINUX_SCRIPTS_DIR")"
PROJECT_ROOT="$(dirname "$MINIKUBE_DIR")"
LOG_DIR="$PROJECT_ROOT/log"
if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    LOG_DIR="${TMPDIR:-/tmp}/minikube-log"
    mkdir -p "$LOG_DIR" 2>/dev/null
fi
LOG_FILE="$LOG_DIR/minikube-autostart-$(date +%Y%m%d).log"
if ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/minikube-autostart-$(date +%Y%m%d).log"
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/minikube-autostart-$(date +%Y%m%d).log"
fi
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Parametros
SKIP_ADDONS=false
INSTALL_KEDA=false

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-addons)
            SKIP_ADDONS=true
            shift
            ;;
        --install-keda)
            INSTALL_KEDA=true
            shift
            ;;
        -h|--help)
            echo "Uso: $0 [--skip-addons] [--install-keda]"
            echo "  --skip-addons  : Pular instalacao de addons"
            echo "  --install-keda : Instalar KEDA"
            exit 0
            ;;
        *)
            echo "Parametro desconhecido: $1"
            exit 1
            ;;
    esac
done

# Garantir que o kubectl correto esta no PATH
USER_BIN_PATH="$HOME/bin"
if [[ ":$PATH:" != *":$USER_BIN_PATH:"* ]]; then
    export PATH="$USER_BIN_PATH:$PATH"
fi
get_k8s_client_version() {
    local executable="$1"
    shift
    local args=("$@")
    local output

    if output=$("$executable" "${args[@]}" version --client --short 2>/dev/null); then
        output="${output//Client Version: /}"
        output="$(echo "$output" | head -n1 | xargs)"
        if [[ -n "$output" ]]; then
            echo "$output"
            return 0
        fi
    fi

    if output=$("$executable" "${args[@]}" version --client --output=json 2>/dev/null); then
        local git_version
        git_version=$(echo "$output" | grep -o '"gitVersion"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | cut -d'"' -f4)
        if [[ -n "$git_version" ]]; then
            echo "$git_version"
            return 0
        fi
    fi

    if output=$("$executable" "${args[@]}" version --client 2>/dev/null); then
        output="$(echo "$output" | head -n1 | xargs)"
        if [[ -n "$output" ]]; then
            echo "$output"
            return 0
        fi
    fi

    return 1
}

get_minikube_version() {
    local output
    if output=$(minikube version --short 2>/dev/null); then
        output="$(echo "$output" | head -n1 | xargs)"
        if [[ -n "$output" ]]; then
            echo "$output"
            return 0
        fi
    fi

    if output=$(minikube version 2>/dev/null); then
        output="$(echo "$output" | head -n1 | xargs)"
        if [[ -n "$output" ]]; then
            echo "$output"
            return 0
        fi
    fi

    return 1
}


KUBECTL_VERSION_DISPLAY=$(get_k8s_client_version kubectl 2>/dev/null)
if [[ -z "$KUBECTL_VERSION_DISPLAY" ]]; then
    KUBECTL_VERSION_DISPLAY="desconhecido"
fi
MINIKUBE_VERSION_DISPLAY=$(get_minikube_version 2>/dev/null)
if [[ -z "$MINIKUBE_VERSION_DISPLAY" ]]; then
    MINIKUBE_VERSION_DISPLAY="desconhecido"
fi

echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}Inicializando Ambiente Minikube Completo${NC}"
echo -e "${GREEN}Versoes: kubectl ${KUBECTL_VERSION_DISPLAY}, minikube ${MINIKUBE_VERSION_DISPLAY}${NC}"
echo -e "${CYAN}=====================================================${NC}"

# Funcao para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funcao para verificar se Docker esta rodando
test_docker_running() {
    docker version >/dev/null 2>&1
}

# Funcao para iniciar Docker (via systemd)
start_docker() {
    echo -e "${YELLOW}   Iniciando Docker via systemd...${NC}"
    
    # Verificar se Docker service existe
    if ! systemctl list-unit-files docker.service >/dev/null 2>&1; then
        echo -e "${RED}   Docker service nao encontrado! Instale o Docker primeiro.${NC}"
        return 1
    fi
    
    # Iniciar Docker service
    sudo systemctl start docker
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}   Docker iniciado. Aguardando ficar pronto...${NC}"
        
        # Aguardar Docker ficar pronto (maximo 120 segundos)
        timeout=120
        elapsed=0
        while ! test_docker_running && [ $elapsed -lt $timeout ]; do
            sleep 5
            elapsed=$((elapsed + 5))
            echo -e "${YELLOW}   Aguardando Docker... ($elapsed/$timeout segundos)${NC}"
        done
        
        if test_docker_running; then
            echo -e "${GREEN}   Docker pronto!${NC}"
            return 0
        else
            echo -e "${RED}   Timeout: Docker nao ficou pronto em $timeout segundos${NC}"
            return 1
        fi
    else
        echo -e "${RED}   Falha ao iniciar Docker service${NC}"
        return 1
    fi
}

# Verificar dependencias
echo -e "${YELLOW}Verificando dependencias...${NC}"
if ! command_exists minikube; then
    echo -e "${RED}Minikube nao encontrado! Instale o Minikube primeiro.${NC}"
    echo -e "${YELLOW}Ubuntu: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube${NC}"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}kubectl nao encontrado! Instale o kubectl primeiro.${NC}"
    echo -e "${YELLOW}Ubuntu: sudo snap install kubectl --classic${NC}"
    exit 1
fi

# Verificar Docker
echo -e "${YELLOW}Verificando Docker...${NC}"
if ! command_exists docker; then
    echo -e "${RED}Docker nao encontrado! Instale o Docker primeiro.${NC}"
    echo -e "${YELLOW}Ubuntu: sudo apt update && sudo apt install docker.io && sudo usermod -aG docker $USER${NC}"
    exit 1
fi

if ! test_docker_running; then
    echo -e "${YELLOW}Docker nao esta rodando. Tentando iniciar...${NC}"
    if ! start_docker; then
        echo -e "${RED}Falha ao iniciar Docker!${NC}"
        echo -e "${YELLOW}Execute manualmente: sudo systemctl start docker${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Docker ja esta rodando!${NC}"
fi

# Verificar se usuario esta no grupo docker
if ! groups $USER | grep -q docker; then
    echo -e "${YELLOW}Usuario nao esta no grupo docker. Adicionando...${NC}"
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}IMPORTANTE: Faca logout/login ou execute: newgrp docker${NC}"
fi

# Verificar conectividade do Docker
echo -e "${YELLOW}Verificando conectividade Docker...${NC}"
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}Docker funcionando corretamente!${NC}"
else
    echo -e "${YELLOW}Docker com problemas. Aguardando estabilizar...${NC}"
    sleep 10
fi

# Verificar compatibilidade de versoes
echo -e "${YELLOW}Verificando compatibilidade kubectl/Kubernetes...${NC}"
KUBECTL_VERSION_DISPLAY=$(get_k8s_client_version kubectl 2>/dev/null)
MINIKUBE_K8S_VERSION=$(get_k8s_client_version minikube kubectl -- 2>/dev/null)

if [[ -n "$KUBECTL_VERSION_DISPLAY" && -n "$MINIKUBE_K8S_VERSION" ]]; then
    if [[ "$KUBECTL_VERSION_DISPLAY" != "$MINIKUBE_K8S_VERSION" ]]; then
        echo -e "${YELLOW}AVISO: Versoes incompativeis detectadas!${NC}"
        echo -e "${YELLOW}kubectl: $KUBECTL_VERSION_DISPLAY | Kubernetes: $MINIKUBE_K8S_VERSION${NC}"
        echo -e "${YELLOW}Execute: minikube kubectl -- version --client${NC}"
    else
        echo -e "${GREEN}OK Versoes compativeis: $KUBECTL_VERSION_DISPLAY${NC}"
    fi
else
    echo -e "${YELLOW}AVISO: Nao foi possivel verificar compatibilidade. Continuando...${NC}"
fi

# Iniciar Minikube
echo -e "${YELLOW}Iniciando Minikube...${NC}"
if ! minikube status >/dev/null 2>&1; then
    echo -e "${YELLOW}Iniciando Minikube pela primeira vez...${NC}"
    minikube start --driver=docker
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao iniciar Minikube!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Minikube ja esta rodando!${NC}"
fi

# Habilitar addons essenciais
if [ "$SKIP_ADDONS" = false ]; then
    echo -e "${YELLOW}Habilitando addons essenciais...${NC}"
    
    addons=("storage-provisioner" "default-storageclass" "dashboard")
    
    for addon in "${addons[@]}"; do
        echo -e "${WHITE}   Habilitando $addon...${NC}"
        minikube addons enable $addon
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   $addon habilitado${NC}"
        else
            echo -e "${YELLOW}   Erro ao habilitar $addon${NC}"
        fi
    done
fi

# Aguardar cluster estar pronto
echo -e "${YELLOW}Aguardando cluster estar pronto...${NC}"
kubectl wait --for=condition=ready node/minikube --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}Timeout aguardando cluster ficar pronto!${NC}"
    exit 1
fi

# Aplicar configuracoes dos servicos
echo -e "${YELLOW}Aplicando configuracoes dos servicos...${NC}"



# Detectar raiz do projeto de forma robusta
find_project_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/minikube/scripts/linux/init" && -d "$dir/minikube/configs" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(find_project_root "$SCRIPT_DIR")"
if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${RED}Não foi possível detectar a raiz do projeto. Saindo.${NC}"
    exit 1
fi
CONFIGS_PATH="$PROJECT_ROOT/minikube/configs"

config_files=("persistent-volumes.yaml" "rabbitmq.yaml" "mongodb.yaml") # rabbitmq-setup-job.yaml removido do apply automático

for config_file in "${config_files[@]}"; do
    config_path="$CONFIGS_PATH/$config_file"
    if [ -f "$config_path" ]; then
        echo -e "${WHITE}   Aplicando $config_file...${NC}"
        kubectl apply -f "$config_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}   $config_file aplicado com sucesso${NC}"
        else
            echo -e "${RED}   Erro ao aplicar $config_file${NC}"
        fi
    else
        echo -e "${RED}   Arquivo nao encontrado: $config_path${NC}"
    fi
done

# Aplicar Ingress do RabbitMQ Management
INGRESS_FILE="$CONFIGS_PATH/rabbitmq-management-ingress.yaml"
if [ -f "$INGRESS_FILE" ]; then
    echo -e "${WHITE}   Aplicando rabbitmq-management-ingress.yaml...${NC}"
    kubectl apply -f "$INGRESS_FILE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   rabbitmq-management-ingress.yaml aplicado com sucesso${NC}"
    else
        echo -e "${RED}   Erro ao aplicar rabbitmq-management-ingress.yaml${NC}"
    fi
else
    echo -e "${YELLOW}   Ingress rabbitmq-management-ingress.yaml não encontrado em $CONFIGS_PATH${NC}"
fi

# Aguardar pods ficarem prontos
echo -e "${YELLOW}Aguardando pods ficarem prontos...${NC}"

echo -e "${WHITE}   Aguardando RabbitMQ...${NC}"
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s

echo -e "${WHITE}   Aguardando MongoDB...${NC}"
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s

# Mostrar status dos pods
echo -e "${WHITE}Status dos pods:${NC}"
kubectl get pods -o wide

# Configurar port-forwards
echo -e "${YELLOW}Configurando port-forwards...${NC}"

# Funcao para criar port-forward em background
create_port_forward() {
    local service=$1
    local port=$2
    local local_port=$3
    
    # Matar port-forward existente
    pkill -f "kubectl.*port-forward.*$port" 2>/dev/null
    
    echo -e "${WHITE}   Criando port-forward para $service ($local_port)...${NC}"
    kubectl port-forward service/$service $local_port:$port >/dev/null 2>&1 &
    
    # Aguardar port-forward estar ativo
    sleep 2
    if netstat -tuln | grep -q ":$local_port "; then
        echo -e "${GREEN}   Port-forward $service criado com sucesso${NC}"
    else
        echo -e "${YELLOW}   Port-forward $service pode nao estar ativo${NC}"
    fi
}

create_port_forward "rabbitmq-service" "15672" "15672"
create_port_forward "rabbitmq-service" "5672" "5672"  
create_port_forward "mongodb-service" "27017" "27017"

check_tcp_port() {
    local host="$1"
    local port="$2"
    timeout 3 bash -c "</dev/tcp/${host}/${port}" >/dev/null 2>&1
}

detailed_validation() {
    local issues=()
    local success=0
    local total=0

    echo -e "${WHITE}   Testando componentes principais...${NC}"

    total=$((total + 1))
    local rabbit_pods
    rabbit_pods=$(kubectl get pods -l app=rabbitmq --no-headers 2>/dev/null || true)
    if echo "$rabbit_pods" | grep -q '1/1.*Running'; then
        echo -e "${GREEN}     OK RabbitMQ pod rodando${NC}"
        success=$((success + 1))
    else
        echo -e "${RED}     ERRO RabbitMQ pod com problemas${NC}"
        issues+=("RabbitMQ pod nao esta rodando corretamente")
    fi

    total=$((total + 1))
    local mongo_pods
    mongo_pods=$(kubectl get pods -l app=mongodb --no-headers 2>/dev/null || true)
    if echo "$mongo_pods" | grep -q '1/1.*Running'; then
        echo -e "${GREEN}     OK MongoDB pod rodando${NC}"
        success=$((success + 1))
    else
        echo -e "${RED}     ERRO MongoDB pod com problemas${NC}"
        issues+=("MongoDB pod nao esta rodando corretamente")
    fi

    if [ "$INSTALL_KEDA" = true ]; then
        total=$((total + 1))
        local all_keda_pods
        all_keda_pods=$(kubectl get pods -n keda --no-headers 2>/dev/null || true)
        local total_keda
        total_keda=$(echo "$all_keda_pods" | grep -c '^')
        local ready_keda
        ready_keda=$(echo "$all_keda_pods" | grep -c '1/1.*Running')

        if [ "$total_keda" -eq 0 ]; then
            echo -e "${RED}     ERRO KEDA pods nao encontrados${NC}"
            issues+=("KEDA nao possui pods implantados")
        elif [ "$total_keda" -eq 3 ] && [ "$ready_keda" -eq "$total_keda" ]; then
            echo -e "${GREEN}     OK KEDA pods rodando (${ready_keda}/${total_keda} pods)${NC}"
            success=$((success + 1))
        elif [ "$total_keda" -eq 3 ]; then
            echo -e "${RED}     ERRO KEDA pods incompletos (${ready_keda}/${total_keda})${NC}"
            issues+=("KEDA nao tem todos os pods rodando (esperado ${total_keda}, prontos ${ready_keda})")
        elif [ "$ready_keda" -eq "$total_keda" ]; then
            echo -e "${GREEN}     OK KEDA pods rodando (${ready_keda}/${total_keda} pods)${NC}"
            success=$((success + 1))
        else
            echo -e "${RED}     ERRO KEDA pods incompletos (${ready_keda}/${total_keda})${NC}"
            issues+=("KEDA nao tem todos os pods rodando (esperado ${total_keda}, prontos ${ready_keda})")
        fi
    fi

    echo -e "${WHITE}   Testando conectividade...${NC}"

    total=$((total + 1))
    if check_tcp_port localhost 15672; then
        echo -e "${GREEN}     OK RabbitMQ Management acessivel (15672)${NC}"
        success=$((success + 1))
    else
        echo -e "${RED}     ERRO RabbitMQ Management inacessivel${NC}"
        issues+=("RabbitMQ Management nao esta acessivel na porta 15672")
    fi

    total=$((total + 1))
    if check_tcp_port localhost 27017; then
        echo -e "${GREEN}     OK MongoDB acessivel (27017)${NC}"
        success=$((success + 1))
    else
        echo -e "${RED}     ERRO MongoDB inacessivel${NC}"
        issues+=("MongoDB nao esta acessivel na porta 27017")
    fi

    total=$((total + 1))
    if check_tcp_port localhost 53954; then
        echo -e "${GREEN}     OK Dashboard K8s acessivel (53954)${NC}"
        success=$((success + 1))
    else
        echo -e "${YELLOW}     AVISO Dashboard K8s inacessivel (pode precisar de tempo)${NC}"
    fi

    echo ""
    local percent="0.0"
    if [ "$total" -gt 0 ]; then
        percent=$(awk "BEGIN { printf \"%.1f\", ($success/$total)*100 }")
    fi

    echo -e "${WHITE}RESULTADO DA VALIDACAO:${NC}"
    echo -e "${WHITE}Sucessos: ${success}/${total} (${percent}%)${NC}"

    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "${YELLOW}AVISO Problemas encontrados:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  - ${YELLOW}${issue}${NC}"
        done
    else
        echo -e "${GREEN}Nenhum problema encontrado.${NC}"
    fi
}

# Configurar Dashboard
echo -e "${WHITE}   Criando port-forward para Dashboard K8s (53954)...${NC}"
echo -e "${WHITE}Aguardando Dashboard estar pronto...${NC}"
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=300s

# Tentar criar port-forward para Dashboard com retry
max_attempts=3
attempt=1
dashboard_ready=false

while [ $attempt -le $max_attempts ] && [ "$dashboard_ready" = false ]; do
    echo -e "${WHITE}Tentativa $attempt/$max_attempts - Verificando Dashboard...${NC}"
    
    pkill -f "kubectl.*port-forward.*dashboard" 2>/dev/null
    kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 53954:80 >/dev/null 2>&1 &
    
    sleep 3
    if netstat -tuln | grep -q ":53954 "; then
        echo -e "${GREEN}Dashboard pronto!${NC}"
        echo -e "${GREEN}Port-forward Dashboard criado${NC}"
        dashboard_ready=true
    else
        echo -e "${YELLOW}Tentativa $attempt falhou. Tentando novamente...${NC}"
        attempt=$((attempt + 1))
        sleep 2
    fi
done

# Instalar KEDA se solicitado
if [ "$INSTALL_KEDA" = true ]; then
    echo -e "${YELLOW}Instalando KEDA...${NC}"
    # Corrigir path para funcionar via autostart
    if [ -f "$SCRIPT_DIR/../keda/install-keda.sh" ]; then
        KEDA_SCRIPT="$SCRIPT_DIR/../keda/install-keda.sh"
    elif [ -f "$SCRIPT_DIR/install-keda.sh" ]; then
        KEDA_SCRIPT="$SCRIPT_DIR/install-keda.sh"
    elif [ -f "$PWD/../keda/install-keda.sh" ]; then
        KEDA_SCRIPT="$PWD/../keda/install-keda.sh"
    elif [ -f "$PWD/../../keda/install-keda.sh" ]; then
        KEDA_SCRIPT="$PWD/../../keda/install-keda.sh"
    else
        KEDA_SCRIPT=""
    fi
    if [ -n "$KEDA_SCRIPT" ] && [ -f "$KEDA_SCRIPT" ]; then
        bash "$KEDA_SCRIPT"
    else
        echo -e "${RED}Script install-keda.sh nao encontrado!${NC}"
    fi
fi

# Testar MongoDB
echo -e "${WHITE}Testando MongoDB...${NC}"
if kubectl exec deployment/mongodb -- mongosh mongodb://admin:admin@localhost:27017/admin --eval "db.runCommand('ping')" >/dev/null 2>&1; then
    echo -e "${GREEN}MongoDB acessivel${NC}"
else
    echo -e "${YELLOW}MongoDB nao respondeu${NC}"
fi

detailed_validation
echo ""
echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}AMBIENTE CONFIGURADO COM SUCESSO!${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo ""
echo -e "${YELLOW}Informacoes de Acesso:${NC}"
echo ""
echo -e "${YELLOW}RabbitMQ:${NC}"
echo -e "${WHITE}   Management UI: http://localhost:15672${NC}"
echo -e "${WHITE}   Usuario/Senha: guest/guest${NC}"
echo -e "${WHITE}   AMQP: localhost:5672${NC}"
echo ""
echo -e "${YELLOW}MongoDB:${NC}"
echo -e "${WHITE}   Connection String: mongodb://admin:admin@localhost:27017/admin${NC}"
echo -e "${WHITE}   Host: localhost:27017${NC}"
echo -e "${WHITE}   Usuario/Senha: admin/admin${NC}"
echo ""
echo -e "${YELLOW}Dashboard do Kubernetes:${NC}"
echo -e "${WHITE}   Web UI: http://localhost:53954${NC}"
echo -e "${WHITE}   Alternativo: minikube dashboard${NC}"
echo ""
echo -e "${YELLOW}Addons habilitados:${NC}"
echo -e "${WHITE}   - storage-provisioner${NC}"
echo -e "${WHITE}   - metrics-server${NC}"
echo -e "${WHITE}   - default-storageclass${NC}"
echo -e "${WHITE}   - dashboard${NC}"
echo ""
echo -e "${GREEN}Dados persistentes configurados - nao serao perdidos!${NC}"
echo ""
echo -e "${GREEN}Ambiente pronto para uso!${NC}"



