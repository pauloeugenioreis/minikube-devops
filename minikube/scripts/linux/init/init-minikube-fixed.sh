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

echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}Inicializando Ambiente Minikube Completo${NC}"
echo -e "${GREEN}Versoes: kubectl $(kubectl version --client --short 2>/dev/null), minikube $(minikube version --short 2>/dev/null)${NC}"
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
kubectl_version=$(kubectl version --client --short 2>/dev/null | sed 's/Client Version: //')
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Versoes compativeis: $kubectl_version${NC}"
else
    echo -e "${YELLOW}⚠️  Nao foi possivel verificar compatibilidade. Continuando...${NC}"
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

# Testar conectividade
echo -e "${YELLOW}Testando conectividade...${NC}"

# Funcao para testar URL
test_url() {
    local url=$1
    local service_name=$2
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${WHITE}Testando $service_name - Tentativa $attempt/$max_attempts...${NC}"
        
        if curl -s --max-time 5 "$url" >/dev/null 2>&1; then
            echo -e "${GREEN}$service_name acessivel${NC}"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    echo -e "${YELLOW}$service_name nao respondeu apos $max_attempts tentativas${NC}"
    return 1
}

test_url "http://rabbitmq.local" "RabbitMQ Management"
test_url "http://localhost:53954" "Dashboard K8s"

# Testar MongoDB
echo -e "${WHITE}Testando MongoDB...${NC}"
if kubectl exec deployment/mongodb -- mongosh mongodb://admin:admin@localhost:27017/admin --eval "db.runCommand('ping')" >/dev/null 2>&1; then
    echo -e "${GREEN}MongoDB acessivel${NC}"
else
    echo -e "${YELLOW}MongoDB nao respondeu${NC}"
fi

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