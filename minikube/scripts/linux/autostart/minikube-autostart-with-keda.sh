#!/bin/bash
# =====================================================
# Autostart do Minikube com KEDA - Versao Linux
# Inicia ambiente completo automaticamente
# =====================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuracoes
AUTOSTART_LOG="$HOME/.minikube/autostart.log"
MAX_RETRIES=3
WAIT_TIMEOUT=300

echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}🚀 AUTOSTART MINIKUBE COM KEDA${NC}"
echo -e "${WHITE}Iniciando ambiente completo...${NC}"
echo -e "${CYAN}=====================================================${NC}"

# Criar diretorio de logs se nao existir
mkdir -p "$(dirname "$AUTOSTART_LOG")"

# Redirecionar saida para log
exec 1> >(tee -a "$AUTOSTART_LOG")
exec 2> >(tee -a "$AUTOSTART_LOG" >&2)

echo -e "${YELLOW}📅 $(date '+%Y-%m-%d %H:%M:%S') - Iniciando autostart${NC}"

# Funcao para log com timestamp
log_msg() {
    echo -e "${WHITE}[$(date '+%H:%M:%S')] $1${NC}"
}

# Funcao para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funcao para aguardar servico
wait_for_service() {
    local service_name="$1"
    local namespace="$2"
    local max_wait="$3"
    
    log_msg "Aguardando $service_name no namespace $namespace..."
    
    local waited=0
    while [ $waited -lt $max_wait ]; do
        if kubectl get pods -n "$namespace" 2>/dev/null | grep -q "$service_name.*Running"; then
            log_msg "✅ $service_name pronto"
            return 0
        fi
        
        sleep 5
        waited=$((waited + 5))
        
        if [ $((waited % 30)) -eq 0 ]; then
            log_msg "⏳ Aguardando $service_name... (${waited}s/${max_wait}s)"
        fi
    done
    
    log_msg "⚠️ Timeout aguardando $service_name"
    return 1
}

# 1. Verificar prerequisitos
log_msg "1️⃣ Verificando prerequisitos..."

if ! command_exists minikube; then
    log_msg "❌ Minikube nao encontrado!"
    exit 1
fi

if ! command_exists kubectl; then
    log_msg "❌ kubectl nao encontrado!"
    exit 1
fi

if ! command_exists docker; then
    log_msg "❌ Docker nao encontrado!"
    exit 1
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

if ! minikube status >/dev/null 2>&1; then
    log_msg "🚀 Iniciando Minikube..."
    
    # Configuracoes recomendadas
    minikube start \
        --driver=docker \
        --cpus=4 \
        --memory=8192 \
        --disk-size=20g \
        --kubernetes-version=stable
    
    if [ $? -ne 0 ]; then
        log_msg "❌ Falha ao iniciar Minikube"
        exit 1
    fi
    
    # Aguardar estabilizar
    sleep 10
else
    log_msg "✅ Minikube ja esta rodando"
fi

# Verificar conectividade kubectl
if ! kubectl cluster-info >/dev/null 2>&1; then
    log_msg "❌ Kubectl nao consegue conectar ao cluster"
    exit 1
fi

log_msg "✅ Minikube e kubectl OK"

# 4. Habilitar addons necessarios
log_msg "4️⃣ Habilitando addons..."

addons=("dashboard" "ingress")

for addon in "${addons[@]}"; do
    if ! minikube addons list | grep -q "$addon.*enabled"; then
        log_msg "🔧 Habilitando addon: $addon"
        minikube addons enable "$addon"
    else
        log_msg "✅ Addon $addon ja habilitado"
    fi
done

# 5. Verificar Helm
log_msg "5️⃣ Verificando Helm..."

if ! command_exists helm; then
    log_msg "📦 Instalando Helm..."
    
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    
    if ! command_exists helm; then
        log_msg "❌ Falha ao instalar Helm"
        exit 1
    fi
else
    log_msg "✅ Helm ja instalado"
fi

# 6. Instalar KEDA
log_msg "6️⃣ Instalando/Verificando KEDA..."

# Verificar se KEDA ja esta instalado
if kubectl get namespace keda-system >/dev/null 2>&1; then
    log_msg "✅ KEDA namespace existe"
    
    # Verificar se pods estao rodando
    if kubectl get pods -n keda-system | grep -q "Running"; then
        log_msg "✅ KEDA ja esta funcionando"
    else
        log_msg "🔧 KEDA instalado mas pods nao estao prontos"
    fi
else
    log_msg "📦 Instalando KEDA..."
    
    # Adicionar repositorio Helm do KEDA
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    
    # Instalar KEDA
    helm install keda kedacore/keda --namespace keda-system --create-namespace
    
    if [ $? -ne 0 ]; then
        log_msg "❌ Falha ao instalar KEDA"
        exit 1
    fi
fi

# Aguardar KEDA ficar pronto
wait_for_service "keda" "keda-system" $WAIT_TIMEOUT

# 7. Configurar volumes persistentes
log_msg "7️⃣ Configurando volumes persistentes..."

# Criar configuracao de PV se nao existir
pv_config="minikube/configs/persistent-volumes.yaml"
cat > "$pv_config" << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /data/mongodb
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: rabbitmq-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /data/rabbitmq
EOF

kubectl apply -f "$pv_config"
log_msg "✅ Volumes persistentes configurados"

# 8. Instalar MongoDB
log_msg "8️⃣ Instalando MongoDB..."

if ! kubectl get pods | grep -q "mongodb.*Running"; then
  mongodb_config="minikube/configs/mongodb.yaml"
    cat > "$mongodb_config" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: "admin"
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: "admin123"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
      volumes:
      - name: mongodb-storage
        persistentVolumeClaim:
          claimName: mongodb-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
EOF

    kubectl apply -f "$mongodb_config"
    wait_for_service "mongodb" "default" $WAIT_TIMEOUT
else
    log_msg "✅ MongoDB ja esta rodando"
fi

# 9. Instalar RabbitMQ
log_msg "9️⃣ Instalando RabbitMQ..."

if ! kubectl get pods | grep -q "rabbitmq.*Running"; then
  rabbitmq_config="minikube/configs/rabbitmq.yaml"
    cat > "$rabbitmq_config" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3-management
        ports:
        - containerPort: 5672
        - containerPort: 15672
        env:
        - name: RABBITMQ_DEFAULT_USER
          value: "admin"
        - name: RABBITMQ_DEFAULT_PASS
          value: "admin123"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        volumeMounts:
        - name: rabbitmq-storage
          mountPath: /var/lib/rabbitmq
      volumes:
      - name: rabbitmq-storage
        persistentVolumeClaim:
          claimName: rabbitmq-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rabbitmq-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-service
spec:
  selector:
    app: rabbitmq
  ports:
  - name: amqp
    port: 5672
    targetPort: 5672
  - name: management
    port: 15672
    targetPort: 15672
  type: ClusterIP
EOF

    kubectl apply -f "$rabbitmq_config"
    wait_for_service "rabbitmq" "default" $WAIT_TIMEOUT
else
    log_msg "✅ RabbitMQ ja esta rodando"
fi

# 10. Configurar port-forwards
log_msg "🔟 Configurando port-forwards..."

# Parar port-forwards existentes
pkill -f "kubectl.*port-forward" 2>/dev/null
sleep 2

# Dashboard
if ! netstat -tuln 2>/dev/null | grep -q ":53954 "; then
    log_msg "🌐 Configurando Dashboard port-forward..."
    kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 53954:80 >/dev/null 2>&1 &
    sleep 2
fi

# MongoDB
if ! netstat -tuln 2>/dev/null | grep -q ":27017 "; then
    log_msg "🍃 Configurando MongoDB port-forward..."
    kubectl port-forward service/mongodb-service 27017:27017 >/dev/null 2>&1 &
    sleep 2
fi

# RabbitMQ Management
if ! netstat -tuln 2>/dev/null | grep -q ":15672 "; then
    log_msg "🐰 Configurando RabbitMQ Management port-forward..."
    kubectl port-forward service/rabbitmq-service 15672:15672 >/dev/null 2>&1 &
    sleep 2
fi

# 11. Verificacao final
log_msg "🔍 Verificacao final do ambiente..."

echo -e "\n${CYAN}=====================================================${NC}"
echo -e "${GREEN}🎉 AUTOSTART CONCLUIDO!${NC}"
echo -e "${CYAN}=====================================================${NC}"

echo -e "\n${YELLOW}📊 STATUS DOS SERVICOS:${NC}"

# Verificar cada servico
services_status=()

# Kubernetes
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Kubernetes Cluster${NC}"
    services_status+=("k8s:ok")
else
    echo -e "${RED}   ❌ Kubernetes Cluster${NC}"
    services_status+=("k8s:fail")
fi

# KEDA
if kubectl get pods -n keda-system | grep -q "Running"; then
    echo -e "${GREEN}   ✅ KEDA${NC}"
    services_status+=("keda:ok")
else
    echo -e "${RED}   ❌ KEDA${NC}"
    services_status+=("keda:fail")
fi

# MongoDB
if kubectl get pods | grep -q "mongodb.*Running"; then
    echo -e "${GREEN}   ✅ MongoDB${NC}"
    services_status+=("mongodb:ok")
else
    echo -e "${RED}   ❌ MongoDB${NC}"
    services_status+=("mongodb:fail")
fi

# RabbitMQ
if kubectl get pods | grep -q "rabbitmq.*Running"; then
    echo -e "${GREEN}   ✅ RabbitMQ${NC}"
    services_status+=("rabbitmq:ok")
else
    echo -e "${RED}   ❌ RabbitMQ${NC}"
    services_status+=("rabbitmq:fail")
fi

# Dashboard
if kubectl get pods -n kubernetes-dashboard | grep -q "Running"; then
    echo -e "${GREEN}   ✅ Dashboard${NC}"
    services_status+=("dashboard:ok")
else
    echo -e "${RED}   ❌ Dashboard${NC}"
    services_status+=("dashboard:fail")
fi

echo -e "\n${YELLOW}🌐 ACESSOS DISPONIVEIS:${NC}"
echo -e "${WHITE}   • Dashboard: http://localhost:53954${NC}"
echo -e "${WHITE}   • MongoDB: mongodb://admin:admin123@localhost:27017${NC}"
echo -e "${WHITE}   • RabbitMQ Management: http://admin:admin123@localhost:15672${NC}"

echo -e "\n${YELLOW}📋 INFORMACOES UTEIS:${NC}"
echo -e "${WHITE}   • Log do autostart: $AUTOSTART_LOG${NC}"
echo -e "${WHITE}   • Parar port-forwards: pkill -f 'kubectl.*port-forward'${NC}"
echo -e "${WHITE}   • Status do cluster: kubectl cluster-info${NC}"
echo -e "${WHITE}   • Pods em execucao: kubectl get pods --all-namespaces${NC}"

# Contar sucessos
success_count=$(echo "${services_status[@]}" | tr ' ' '\n' | grep -c ":ok")
total_count=${#services_status[@]}

echo -e "\n${YELLOW}📈 RESUMO:${NC}"
echo -e "${WHITE}   Servicos funcionando: $success_count/$total_count${NC}"

if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}   🎯 Ambiente 100% funcional!${NC}"
    exit_code=0
else
    echo -e "${YELLOW}   ⚠️ Alguns servicos podem precisar de atencao${NC}"
    exit_code=1
fi

log_msg "📅 $(date '+%Y-%m-%d %H:%M:%S') - Autostart finalizado (exit: $exit_code)"

echo -e "\n${GREEN}✅ Autostart concluido!${NC}"
exit $exit_code