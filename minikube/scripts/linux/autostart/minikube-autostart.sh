#!/bin/bash
# =====================================================
# Autostart Simples do Minikube - Versao Linux
# Inicia apenas o Minikube basico
# =====================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuracoes
AUTOSTART_LOG="$HOME/.minikube/autostart-simple.log"
MAX_RETRIES=3

echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}🚀 AUTOSTART MINIKUBE SIMPLES${NC}"
echo -e "${WHITE}Iniciando ambiente basico...${NC}"
echo -e "${CYAN}=====================================================${NC}"

# Criar diretorio de logs se nao existir
mkdir -p "$(dirname "$AUTOSTART_LOG")"

# Redirecionar saida para log
exec 1> >(tee -a "$AUTOSTART_LOG")
exec 2> >(tee -a "$AUTOSTART_LOG" >&2)

echo -e "${YELLOW}📅 $(date '+%Y-%m-%d %H:%M:%S') - Iniciando autostart simples${NC}"

# Funcao para log com timestamp
log_msg() {
    echo -e "${WHITE}[$(date '+%H:%M:%S')] $1${NC}"
}

# Funcao para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Verificar prerequisitos
log_msg "1️⃣ Verificando prerequisitos..."


# Instalação automática de dependências
install_docker() {
    log_msg "🔧 Instalando Docker..."
    sudo apt update && sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"
}

install_minikube() {
    log_msg "🔧 Instalando Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
}

install_kubectl() {
    log_msg "🔧 Instalando kubectl..."
    sudo snap install kubectl --classic || sudo apt install -y kubectl
}

if ! command_exists docker; then
    install_docker
    if ! command_exists docker; then
        log_msg "❌ Falha ao instalar Docker. Instale manualmente."
        exit 1
    fi
fi

if ! command_exists minikube; then
    install_minikube
    if ! command_exists minikube; then
        log_msg "❌ Falha ao instalar Minikube. Instale manualmente."
        exit 1
    fi
fi

if ! command_exists kubectl; then
    install_kubectl
    if ! command_exists kubectl; then
        log_msg "❌ Falha ao instalar kubectl. Instale manualmente."
        exit 1
    fi
fi

log_msg "✅ Prerequisitos OK"

# 2. Verificar Docker
log_msg "2️⃣ Verificando Docker..."

if ! systemctl is-active --quiet docker; then
    log_msg "🔧 Iniciando Docker..."
    sudo systemctl start docker
    sleep 5
    
    if ! systemctl is-active --quiet docker; then
        log_msg "❌ Falha ao iniciar Docker"
        exit 1
    fi
fi

if ! docker info >/dev/null 2>&1; then
    log_msg "❌ Docker nao esta funcionando"
    exit 1
fi

log_msg "✅ Docker funcionando"

# 3. Verificar/Iniciar Minikube
log_msg "3️⃣ Verificando Minikube..."

minikube_status=$(minikube status 2>/dev/null | grep "host:" | awk '{print $2}')

if [ "$minikube_status" != "Running" ]; then
    log_msg "🚀 Iniciando Minikube..."
    
    # Tentar iniciar com configuracoes basicas
    minikube start --driver=docker
    
    if [ $? -ne 0 ]; then
        log_msg "❌ Falha ao iniciar Minikube na primeira tentativa"
        
        # Tentar com configuracoes especificas
        log_msg "🔄 Tentando com configuracoes especificas..."
        minikube start \
            --driver=docker \
            --cpus=2 \
            --memory=4096 \
            --disk-size=20g
        
        if [ $? -ne 0 ]; then
            log_msg "❌ Falha ao iniciar Minikube"
            exit 1
        fi
    fi
    
    # Aguardar estabilizar
    sleep 10
else
    log_msg "✅ Minikube ja esta rodando"
fi

# 4. Verificar conectividade kubectl
log_msg "4️⃣ Verificando conectividade..."

for i in {1..5}; do
    if kubectl cluster-info >/dev/null 2>&1; then
        log_msg "✅ kubectl conectado ao cluster"
        break
    fi
    
    if [ $i -eq 5 ]; then
        log_msg "❌ kubectl nao consegue conectar ao cluster"
        exit 1
    fi
    
    log_msg "⏳ Aguardando cluster ficar pronto... ($i/5)"
    sleep 5
done

basic_addons=("dashboard" "metrics-server")

# 5. Habilitar apenas o dashboard via addon
log_msg "5️⃣ Habilitando addon do dashboard..."
if ! minikube addons list | grep -q "dashboard.*enabled"; then
    log_msg "🔧 Habilitando addon: dashboard"
    minikube addons enable dashboard
    if [ $? -eq 0 ]; then
        log_msg "✅ Addon dashboard habilitado"
    else
        log_msg "⚠️ Falha ao habilitar addon dashboard"
    fi
else
    log_msg "✅ Addon dashboard ja habilitado"
fi

# 5b. Remover deployment antigo do metrics-server, aplicar manifest oficial e garantir argumento --kubelet-insecure-tls

# Limpeza total do metrics-server antes de aplicar o manifest oficial
log_msg "5️⃣ Limpando qualquer resquício do metrics-server antigo..."
log_msg "⚙️ Desabilitando addon do metrics-server do Minikube, se estiver ativo..."
minikube addons disable metrics-server || true
log_msg "🧹 Removendo deployment antigo do metrics-server..."
kubectl -n kube-system delete deployment metrics-server --ignore-not-found
log_msg "🧹 Removendo ReplicaSets antigos do metrics-server..."
kubectl -n kube-system delete rs -l k8s-app=metrics-server --ignore-not-found
log_msg "🧹 Removendo pods antigos do metrics-server..."
kubectl -n kube-system delete pods -l k8s-app=metrics-server --ignore-not-found
sleep 3
log_msg "5️⃣ Aplicando manifest oficial do metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.3/components.yaml
sleep 5
# Editar deployment para garantir argumento --kubelet-insecure-tls
kubectl -n kube-system patch deployment metrics-server \
    --type='json' \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' || true
log_msg "✅ metrics-server configurado de forma persistente"

# 6. Aguardar pods ficarem prontos
log_msg "6️⃣ Aguardando pods ficarem prontos..."

sleep 10

# Verificar pods do sistema
system_ready=true
for namespace in kube-system kubernetes-dashboard; do
    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
        not_ready=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
        
        if [ "$not_ready" -gt 0 ]; then
            log_msg "⚠️ $not_ready pods nao prontos no namespace $namespace"
            system_ready=false
        else
            log_msg "✅ Todos os pods prontos no namespace $namespace"
        fi
    fi
done

# 7. Configurar port-forward basico do Dashboard
log_msg "7️⃣ Configurando acesso ao Dashboard..."

# Parar port-forwards existentes
pkill -f "kubectl.*port-forward.*dashboard" 2>/dev/null
sleep 2

# Configurar Dashboard port-forward
if ! netstat -tuln 2>/dev/null | grep -q ":53954 "; then
    log_msg "🌐 Configurando Dashboard port-forward..."
    kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 53954:80 >/dev/null 2>&1 &
    # Aguardar port-forward ficar ativo
    sleep 3
    if netstat -tuln 2>/dev/null | grep -q ":53954 "; then
        log_msg "✅ Dashboard port-forward configurado"
    else
        log_msg "⚠️ Falha ao configurar Dashboard port-forward"
    fi
else
    log_msg "✅ Dashboard port-forward ja ativo"
fi

# Configurar port-forward do RabbitMQ sempre após o Dashboard
log_msg "7️⃣ Configurando acesso ao RabbitMQ..."
# Parar port-forwards antigos do RabbitMQ
pkill -f "kubectl.*port-forward.*rabbitmq-service.*15672:15672" 2>/dev/null
sleep 2
# Aguardar pod do RabbitMQ ficar Running
for i in {1..12}; do
    pod_status=$(kubectl get pods -n default -l app=rabbitmq -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ "$pod_status" = "Running" ]; then
        log_msg "✅ Pod RabbitMQ está Running."
        break
    fi
    if [ $i -eq 12 ]; then
        log_msg "❌ Timeout aguardando RabbitMQ ficar Running."
        break
    fi
    log_msg "⏳ Aguardando RabbitMQ ficar Running... ($i/12)"
    sleep 5
done
# Port-forward robusto usando nohup (igual ao comando manual)
if ! netstat -tuln 2>/dev/null | grep -q ":15672 "; then
    log_msg "🌐 Iniciando RabbitMQ port-forward com nohup (comando manual)..."
    nohup kubectl port-forward -n default service/rabbitmq-service 15672:15672 > ~/nohup-rabbitmq.log 2>&1 &
    sleep 4
    if netstat -tuln 2>/dev/null | grep -q ":15672 "; then
        log_msg "✅ RabbitMQ port-forward configurado (nohup/manual)"
    else
        log_msg "❌ Falha ao configurar RabbitMQ port-forward. Veja o log em ~/nohup-rabbitmq.log"
    fi
else
    log_msg "✅ RabbitMQ port-forward ja ativo"
fi

# 8. Verificacao final
log_msg "8️⃣ Verificacao final..."

echo -e "\n${CYAN}=====================================================${NC}"
echo -e "${GREEN}🎉 AUTOSTART SIMPLES CONCLUIDO!${NC}"
echo -e "${CYAN}=====================================================${NC}"

echo -e "\n${YELLOW}📊 STATUS DO AMBIENTE:${NC}"

# Status do Minikube
minikube_status=$(minikube status 2>/dev/null | grep "host:" | awk '{print $2}')
if [ "$minikube_status" = "Running" ]; then
    echo -e "${GREEN}   ✅ Minikube: $minikube_status${NC}"
else
    echo -e "${RED}   ❌ Minikube: $minikube_status${NC}"
fi

# Status do kubectl
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ kubectl: Conectado${NC}"
else
    echo -e "${RED}   ❌ kubectl: Desconectado${NC}"
fi

# Status do Dashboard
if kubectl get pods -n kubernetes-dashboard >/dev/null 2>&1; then
    dashboard_pods=$(kubectl get pods -n kubernetes-dashboard --no-headers 2>/dev/null | grep -c "Running")
    if [ "$dashboard_pods" -gt 0 ]; then
        echo -e "${GREEN}   ✅ Dashboard: $dashboard_pods pods rodando${NC}"
    else
        echo -e "${YELLOW}   ⚠️ Dashboard: Pods iniciando${NC}"
    fi
else
    echo -e "${RED}   ❌ Dashboard: Nao encontrado${NC}"
fi

# Status do port-forward
if netstat -tuln 2>/dev/null | grep -q ":53954 "; then
    echo -e "${GREEN}   ✅ Port-forward: Ativo na porta 53954${NC}"
else
    echo -e "${RED}   ❌ Port-forward: Inativo${NC}"
fi

echo -e "\n${YELLOW}🌐 ACESSOS DISPONIVEIS:${NC}"
echo -e "${WHITE}   • Dashboard: http://localhost:53954${NC}"

# Configurar domínio rabbitmq.local no /etc/hosts para acesso via Ingress
MINIKUBE_IP=$(minikube ip 2>/dev/null)
RABBIT_DOMAIN="rabbitmq.local"
INGRESS_YAML="$PWD/minikube/configs/rabbitmq-management-ingress.yaml"
INGRESS_ENABLED=$(kubectl get pods -A | grep ingress-nginx-controller | wc -l)
if [ -n "$MINIKUBE_IP" ]; then
    # Habilitar o Ingress Controller se não estiver rodando
    if [ "$INGRESS_ENABLED" -eq 0 ]; then
        echo -e "${YELLOW}🔧 Habilitando o Ingress Controller do Minikube...${NC}"
        minikube addons enable ingress
        # Aguarda o pod do ingress-nginx-controller ficar Running
        echo -e "${WHITE}⏳ Aguardando o Ingress Controller iniciar...${NC}"
        while [[ $(kubectl get pods -A | grep ingress-nginx-controller | grep -c Running) -eq 0 ]]; do
            sleep 2
            echo -n "."
        done
        echo -e "\n${GREEN}   ✅ Ingress Controller pronto!${NC}"
    fi
    # Verifica sem sudo
    if ! grep -q "$RABBIT_DOMAIN" /etc/hosts; then
        echo -e "${YELLOW}🔧 Adicionando $RABBIT_DOMAIN ao /etc/hosts apontando para $MINIKUBE_IP...${NC}"
        echo "$MINIKUBE_IP $RABBIT_DOMAIN" | sudo tee -a /etc/hosts >/dev/null
    else
        # Só atualiza se o IP estiver diferente
        CURRENT_IP=$(grep "$RABBIT_DOMAIN" /etc/hosts | awk '{print $1}')
        if [ "$CURRENT_IP" != "$MINIKUBE_IP" ]; then
            echo -e "${YELLOW}🔄 Atualizando $RABBIT_DOMAIN para $MINIKUBE_IP em /etc/hosts...${NC}"
            sudo sed -i "/$RABBIT_DOMAIN/d" /etc/hosts
            echo "$MINIKUBE_IP $RABBIT_DOMAIN" | sudo tee -a /etc/hosts >/dev/null
            echo -e "${YELLOW}🔄 Atualizado $RABBIT_DOMAIN para $MINIKUBE_IP em /etc/hosts${NC}"
        else
            echo -e "${GREEN}   ✅ $RABBIT_DOMAIN já está configurado corretamente em /etc/hosts${NC}"
        fi
    fi
    echo -e "${GREEN}   ✅ rabbitmq.local configurado em /etc/hosts${NC}"
    echo -e "${WHITE}   • RabbitMQ (Ingress): http://rabbitmq.local${NC}"
    # Aplicar o Ingress automaticamente
    if [ -f "$INGRESS_YAML" ]; then
        echo -e "${YELLOW}🔧 Aplicando Ingress do RabbitMQ...${NC}"
        kubectl apply -f "$INGRESS_YAML"
    else
        echo -e "${RED}   ❌ Arquivo do Ingress não encontrado: $INGRESS_YAML${NC}"
    fi
else
    echo -e "${RED}   ❌ Não foi possível obter o IP do Minikube para configurar rabbitmq.local${NC}"
fi

echo -e "\n${YELLOW}📋 INFORMACOES UTEIS:${NC}"
echo -e "${WHITE}   • Log do autostart: $AUTOSTART_LOG${NC}"
echo -e "${WHITE}   • Status completo: minikube status${NC}"
echo -e "${WHITE}   • Parar Minikube: minikube stop${NC}"
echo -e "${WHITE}   • Excluir cluster: minikube delete${NC}"
echo -e "${WHITE}   • Ver todos os pods: kubectl get pods --all-namespaces${NC}"

echo -e "\n${YELLOW}⚠️  Para acessar o RabbitMQ Management, execute manualmente em outro terminal:${NC}"
echo -e "${WHITE}   nohup kubectl port-forward -n default service/rabbitmq-service 15672:15672 > ~/nohup-rabbitmq.log 2>&1 &"
echo -e "${WHITE}   Depois acesse: http://localhost:15672${NC}"
echo -e "${YELLOW}⚠️  Se preferir via Ingress, acesse: http://rabbitmq.local${NC} (certifique-se que o Ingress está criado)"

echo -e "\n${YELLOW}🔧 COMANDOS PARA EXPANSAO:${NC}"
echo -e "${WHITE}   • Habilitar Ingress: minikube addons enable ingress${NC}"
echo -e "${WHITE}   • Instalar Helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash${NC}"
echo -e "${WHITE}   • Ver addons: minikube addons list${NC}"

# Determinar status geral
if [ "$minikube_status" = "Running" ] && kubectl cluster-info >/dev/null 2>&1; then
    echo -e "\n${GREEN}🎯 Ambiente basico funcionando!${NC}"
    exit_code=0
else
    echo -e "\n${YELLOW}⚠️ Ambiente pode precisar de atencao${NC}"
    exit_code=1
fi

log_msg "📅 $(date '+%Y-%m-%d %H:%M:%S') - Autostart simples finalizado (exit: $exit_code)"

echo -e "\n${GREEN}✅ Autostart simples concluido!${NC}"


# Chamar init-minikube-fixed.sh para garantir KEDA instalado (igual Windows)
INIT_MINIKUBE_SH="$PWD/minikube/scripts/linux/init/init-minikube-fixed.sh"
if [ -f "$INIT_MINIKUBE_SH" ]; then
    echo -e "\n${YELLOW}🔄 Executando inicialização completa com KEDA...${NC}"
    bash "$INIT_MINIKUBE_SH" --install-keda
else
    echo -e "${RED}⚠️  init-minikube-fixed.sh não encontrado em minikube/scripts/linux/init/${NC}"
fi

# Chamar bootstrap-devops.sh para setup e instruções finais
if [ -f "$PWD/minikube/scripts/linux/bootstrap-devops.sh" ]; then
    bash "$PWD/minikube/scripts/linux/bootstrap-devops.sh"
else
    echo "⚠️  bootstrap-devops.sh não encontrado em minikube/scripts/linux/"
fi

exit $exit_code