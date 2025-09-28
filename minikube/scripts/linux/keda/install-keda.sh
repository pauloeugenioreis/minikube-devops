#!/bin/bash
# =====================================================
# Script de Instalacao KEDA no Minikube - Versao Linux
# KEDA - Kubernetes Event-driven Autoscaling
# =====================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Deployments KEDA para ajustes pós-instalação
KEDA_DEPLOYMENTS=(
    "keda-operator"
    "keda-admission-webhooks"
    "keda-operator-metrics-apiserver"
)

# Parametros
SKIP_HELM=false
UNINSTALL=false

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-helm)
            SKIP_HELM=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        -h|--help)
            echo "Uso: $0 [--skip-helm] [--uninstall]"
            echo "  --skip-helm  : Pular configuracao do repositorio Helm"
            echo "  --uninstall  : Desinstalar KEDA"
            exit 0
            ;;
        *)
            echo "Parametro desconhecido: $1"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}KEDA - Kubernetes Event-driven Autoscaling Setup${NC}"
echo -e "${GREEN}Versao: 2.15+ (Latest)${NC}"
echo -e "${CYAN}=====================================================${NC}"

# Funcao para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ajusta imagePullPolicy dos deployments KEDA para IfNotPresent
patch_keda_image_policy() {
    echo -e "${WHITE}   Ajustando imagePullPolicy dos componentes KEDA...${NC}"
    for deploy in "${KEDA_DEPLOYMENTS[@]}"; do
        if ! kubectl patch deployment "$deploy" -n keda --type='json' \
            -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]' >/dev/null 2>&1; then
            echo -e "${YELLOW}   ⚠️ Não foi possível ajustar imagePullPolicy de ${deploy}.${NC}"
        fi
    done
}

# Funcao para capturar versao do kubectl
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

# Funcao para verificar se Minikube esta rodando
test_minikube_running() {
    minikube status 2>/dev/null | grep -q "Running"
}

# Verificacoes iniciais
echo -e "\n${YELLOW}1. Verificando prerequisitos...${NC}"

if ! command_exists kubectl; then
    echo -e "${RED}   ❌ kubectl nao encontrado!${NC}"
    echo -e "${YELLOW}   Ubuntu: sudo snap install kubectl --classic${NC}"
    exit 1
fi

if ! command_exists helm; then
    echo -e "${RED}   ❌ Helm nao encontrado!${NC}"
    echo -e "${YELLOW}   Ubuntu: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash${NC}"
    exit 1
fi

if ! command_exists minikube; then
    echo -e "${RED}   ❌ Minikube nao encontrado!${NC}"
    exit 1
fi

echo -e "${GREEN}   ✅ kubectl: $(get_kubectl_version || echo "desconhecido")${NC}"
echo -e "${GREEN}   ✅ helm: $(helm version --short 2>/dev/null)${NC}"
echo -e "${GREEN}   ✅ minikube: $(minikube version --short 2>/dev/null)${NC}"

# Verificar se Minikube esta rodando
echo -e "\n${YELLOW}2. Verificando status do Minikube...${NC}"
if ! test_minikube_running; then
    echo -e "${RED}   ❌ Minikube nao esta rodando!${NC}"
    echo -e "${YELLOW}   Inicie o Minikube primeiro com o script principal${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Minikube esta rodando${NC}"

# Se uninstall foi solicitado
if [ "$UNINSTALL" = true ]; then
    echo -e "\n${YELLOW}🗑️ Desinstalando KEDA...${NC}"
    
    echo -e "${YELLOW}   Removendo KEDA via Helm...${NC}"
    helm uninstall keda --namespace keda 2>/dev/null
    
    echo -e "${YELLOW}   Removendo namespace keda...${NC}"
    kubectl delete namespace keda --ignore-not-found=true 2>/dev/null
    
    echo -e "${YELLOW}   Removendo CRDs do KEDA...${NC}"
    kubectl delete crd scaledobjects.keda.sh --ignore-not-found=true 2>/dev/null
    kubectl delete crd scaledjobs.keda.sh --ignore-not-found=true 2>/dev/null
    kubectl delete crd triggerauthentications.keda.sh --ignore-not-found=true 2>/dev/null
    kubectl delete crd clustertriggerauthentications.keda.sh --ignore-not-found=true 2>/dev/null
    kubectl delete crd cloudeventsources.eventing.keda.sh --ignore-not-found=true 2>/dev/null
    kubectl delete crd clustercloudeventsources.eventing.keda.sh --ignore-not-found=true 2>/dev/null
    
    echo -e "\n${GREEN}✅ KEDA removido com sucesso!${NC}"
    exit 0
fi

# Instalacao do KEDA

# Baixar e carregar imagens do KEDA no Minikube
echo -e "\n${YELLOW}3. Baixando e carregando imagens do KEDA no Minikube...${NC}"
KEDA_VERSION="2.17.2"
IMAGES=(
    "ghcr.io/kedacore/keda:${KEDA_VERSION}"
    "ghcr.io/kedacore/keda-admission-webhooks:${KEDA_VERSION}"
    "ghcr.io/kedacore/keda-metrics-apiserver:${KEDA_VERSION}"
)
for img in "${IMAGES[@]}"; do
    echo -e "${CYAN}   Baixando $img ...${NC}"
    docker pull "$img"
    echo -e "${CYAN}   Carregando $img no Minikube ...${NC}"
    minikube image load "$img"
done
echo -e "${GREEN}   ✅ Imagens do KEDA carregadas no Minikube${NC}"

echo -e "\n${YELLOW}4. Configurando repositorio Helm do KEDA...${NC}"

if [ "$SKIP_HELM" = false ]; then
    echo -e "${CYAN}   Adicionando repositorio kedacore...${NC}"
    helm repo add kedacore https://kedacore.github.io/charts
    
    echo -e "${CYAN}   Atualizando repositorios Helm...${NC}"
    helm repo update
    
    echo -e "${GREEN}   ✅ Repositorio KEDA configurado${NC}"
fi

echo -e "\n${YELLOW}4. Criando namespace keda...${NC}"
kubectl create namespace keda --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}   ✅ Namespace 'keda' criado/verificado${NC}"

echo -e "\n${YELLOW}5. Instalando KEDA via Helm...${NC}"
echo -e "${CYAN}   Isso pode levar alguns minutos...${NC}"

helm upgrade --install keda kedacore/keda --namespace keda --create-namespace
if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ KEDA instalado com sucesso!${NC}"
    patch_keda_image_policy
else
    echo -e "${RED}   ❌ Erro na instalacao do KEDA${NC}"
    exit 1
fi

# Aguardar pods ficarem prontos
echo -e "\n${YELLOW}6. Aguardando pods KEDA ficarem prontos...${NC}"
max_wait=120
elapsed=0
interval=5

while [ $elapsed -lt $max_wait ]; do
    sleep $interval
    elapsed=$((elapsed + interval))
    
    # Contar pods prontos
    ready_pods=$(kubectl get pods -n keda --no-headers 2>/dev/null | grep -c "1/1.*Running")
    total_pods=$(kubectl get pods -n keda --no-headers 2>/dev/null | wc -l)
    
    echo -e "${WHITE}   ⏱️ ${elapsed}s - Pods prontos: $ready_pods/$total_pods${NC}"
    
    if [ "$ready_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
        echo -e "${GREEN}   ✅ Todos os pods KEDA estao prontos!${NC}"
        break
    fi
    
    if [ $elapsed -ge $max_wait ]; then
        echo -e "${YELLOW}   ⚠️ Timeout aguardando pods. Continuando...${NC}"
        break
    fi
done

# Validacao
echo -e "\n${YELLOW}7. Validando instalacao...${NC}"

# Verificar namespace
if kubectl get namespace keda >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Namespace keda existe${NC}"
else
    echo -e "${RED}   ❌ Namespace keda nao encontrado!${NC}"
fi

# Verificar CRDs
crds=("scaledobjects.keda.sh" "scaledjobs.keda.sh" "triggerauthentications.keda.sh" "clustertriggerauthentications.keda.sh")
for crd in "${crds[@]}"; do
    if kubectl get crd "$crd" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ CRD $crd existe${NC}"
    else
        echo -e "${RED}   ❌ CRD $crd nao encontrado!${NC}"
    fi
done

# Verificar versao
keda_version=$(kubectl get deployment -n keda keda-operator -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ -n "$keda_version" ]; then
    echo -e "${GREEN}   ✅ KEDA versao: $keda_version${NC}"
else
    echo -e "${YELLOW}   ⚠️ Nao foi possivel verificar versao KEDA${NC}"
fi

# Verificar pods
echo -e "\n${WHITE}Status dos pods KEDA:${NC}"
kubectl get pods -n keda

echo -e "\n${CYAN}=====================================================${NC}"
echo -e "${GREEN}🎉 INSTALACAO KEDA CONCLUIDA!${NC}"
echo -e "${CYAN}=====================================================${NC}"

echo -e "\n${YELLOW}📋 COMANDOS UTEIS:${NC}"
echo -e "${WHITE}   • Ver pods KEDA: kubectl get pods -n keda${NC}"
echo -e "${WHITE}   • Ver ScaledObjects: kubectl get scaledobject -A${NC}"
echo -e "${WHITE}   • Ver HPAs: kubectl get hpa -A${NC}"
echo -e "${WHITE}   • Logs KEDA: kubectl logs -n keda -l app.kubernetes.io/name=keda-operator${NC}"

# Definir caminhos para exemplos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIKUBE_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
CONFIGS_PATH="$MINIKUBE_ROOT/configs"

echo -e "\n${YELLOW}📁 EXEMPLOS DISPONIVEIS:${NC}"
echo -e "${WHITE}   • Localizacao: $CONFIGS_PATH/keda/examples/${NC}"
echo -e "${WHITE}   • Script de teste: $SCRIPT_DIR/test-keda.sh${NC}"

echo -e "\n${GREEN}✅ KEDA pronto para uso!${NC}"
