#!/bin/bash

# setup-fresh-machine.sh
# Script de instalacao completa para maquina nova Linux Ubuntu
# Instala automaticamente: Docker, Minikube, kubectl, Helm
# Configurado para usar paths dinamicos e ambiente completo Minikube DevOps

set -euo pipefail

# Definir variaveis de emoji para saida consistente
emoji_gear=$(printf "\u2699\ufe0f")
emoji_check=$(printf "\u2713")
emoji_cross=$(printf "\u274c")
emoji_arrow=$(printf "\u27a1\ufe0f")
emoji_package=$(printf "\U1f4e6")
emoji_rocket=$(printf "\U1f680")
emoji_warning=$(printf "\u26a0\ufe0f")
emoji_info=$(printf "\U1f4a1")

# Parametros do script
SKIP_DOCKER_INSTALL=false
SKIP_MINIKUBE_INSTALL=false
SKIP_KUBECTL_INSTALL=false
SKIP_HELM_INSTALL=false
SKIP_VALIDATION=false
RUN_INITIALIZATION=false

# Parse argumentos de linha de comando
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-docker)
            SKIP_DOCKER_INSTALL=true
            shift
            ;;
        --skip-minikube)
            SKIP_MINIKUBE_INSTALL=true
            shift
            ;;
        --skip-kubectl)
            SKIP_KUBECTL_INSTALL=true
            shift
            ;;
        --skip-helm)
            SKIP_HELM_INSTALL=true
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --run-initialization)
            RUN_INITIALIZATION=true
            shift
            ;;
        --help|-h)
            echo "Uso: $0 [opcoes]"
            echo ""
            echo "Opcoes:"
            echo "  --skip-docker       Pular instalacao do Docker"
            echo "  --skip-minikube     Pular instalacao do Minikube"
            echo "  --skip-kubectl      Pular instalacao do kubectl"
            echo "  --skip-helm         Pular instalacao do Helm"
            echo "  --skip-validation   Pular validacao final"
            echo "  --run-initialization Executar inicializacao apos setup"
            echo "  --help, -h          Mostrar esta ajuda"
            exit 0
            ;;
        *)
            echo "Opcao desconhecida: $1"
            echo "Use --help para ver opcoes disponiveis"
            exit 1
            ;;
    esac
done

# Diretorio do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=""

# Tentar detectar pasta raiz do projeto
detect_project_root() {
    local current_dir="$SCRIPT_DIR"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/minikube/docs/README.md" && -d "$current_dir/minikube/scripts" ]]; then
            PROJECT_ROOT="$current_dir"
            echo "$emoji_check Pasta raiz do projeto detectada: $PROJECT_ROOT"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    echo "$emoji_warning Pasta raiz do projeto nao detectada. Setup independente."
    return 1
}

# Cabecalho
echo "====================================================="
echo "$emoji_rocket SETUP COMPLETO - MAQUINA NOVA LINUX UBUNTU"
echo "$emoji_gear Minikube DevOps Environment - Instalacao Automatica"
echo "====================================================="

# Funcoes utilitarias
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo "$emoji_warning Script sendo executado como root. Recomenda-se executar como usuario normal."
        echo "$emoji_info O script solicitara sudo quando necessario."
    fi
    
    if ! sudo -n true 2>/dev/null; then
        echo "$emoji_info Este script requer privilegios sudo para instalacao."
        echo "Por favor, digite sua senha quando solicitado."
        sudo true
    fi
}

check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        echo "$emoji_cross Sistema operacional nao identificado"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        echo "$emoji_warning Sistema detectado: $PRETTY_NAME"
        echo "$emoji_info Este script foi otimizado para Ubuntu, mas pode funcionar em derivados."
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "$emoji_check Sistema operacional: $PRETTY_NAME"
    fi
    
    # Verificar versao minima (18.04+)
    local version_id_numeric=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ $version_id_numeric -lt 18 ]]; then
        echo "$emoji_cross Ubuntu $VERSION_ID detectado. Versao minima requerida: 18.04"
        exit 1
    fi
}

update_system() {
    echo "$emoji_arrow Atualizando sistema..."
    sudo apt-get update -qq
    sudo apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release
    echo "$emoji_check Sistema atualizado"
}

install_docker() {
    if [[ "$SKIP_DOCKER_INSTALL" == "true" ]]; then
        echo "$emoji_arrow Pulando instalacao do Docker (--skip-docker)"
        return 0
    fi
    
    echo "$emoji_package Instalando Docker..."
    
    if command_exists docker; then
        echo "$emoji_check Docker ja instalado: $(docker --version)"
        return 0
    fi
    
    # Remover versoes antigas
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Adicionar repositorio oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Adicionar usuario ao grupo docker
    sudo usermod -aG docker "$USER"
    
    # Iniciar servico
    sudo systemctl enable docker
    sudo systemctl start docker
    
    echo "$emoji_check Docker instalado: $(docker --version)"
    echo "$emoji_info Voce precisa fazer logout/login para usar Docker sem sudo"
}

install_minikube() {
    if [[ "$SKIP_MINIKUBE_INSTALL" == "true" ]]; then
        echo "$emoji_arrow Pulando instalacao do Minikube (--skip-minikube)"
        return 0
    fi
    
    echo "$emoji_package Instalando Minikube..."
    
    if command_exists minikube; then
        echo "$emoji_check Minikube ja instalado: $(minikube version --short)"
        return 0
    fi
    
    # Download e instalacao
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    
    echo "$emoji_check Minikube instalado: $(minikube version --short)"
}

install_kubectl() {
    if [[ "$SKIP_KUBECTL_INSTALL" == "true" ]]; then
        echo "$emoji_arrow Pulando instalacao do kubectl (--skip-kubectl)"
        return 0
    fi
    
    echo "$emoji_package Instalando kubectl..."
    
    if command_exists kubectl; then
        echo "$emoji_check kubectl ja instalado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
        return 0
    fi
    
    # Detectar versao estavel
    local kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    
    # Download e instalacao
    curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    echo "$emoji_check kubectl instalado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
}

install_helm() {
    if [[ "$SKIP_HELM_INSTALL" == "true" ]]; then
        echo "$emoji_arrow Pulando instalacao do Helm (--skip-helm)"
        return 0
    fi
    
    echo "$emoji_package Instalando Helm..."
    
    if command_exists helm; then
        echo "$emoji_check Helm ja instalado: $(helm version --short)"
        return 0
    fi
    
    # Usar script oficial de instalacao
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    echo "$emoji_check Helm instalado: $(helm version --short)"
}

validate_installation() {
    if [[ "$SKIP_VALIDATION" == "true" ]]; then
        echo "$emoji_arrow Pulando validacao final (--skip-validation)"
        return 0
    fi
    
    echo "$emoji_gear Validando instalacao..."
    
    local errors=0
    
    # Validar Docker
    if command_exists docker; then
        if docker version >/dev/null 2>&1 || groups | grep -q docker; then
            echo "$emoji_check Docker: $(docker --version)"
        else
            echo "$emoji_cross Docker instalado mas nao acessivel (precisa logout/login)"
            ((errors++))
        fi
    else
        echo "$emoji_cross Docker nao encontrado"
        ((errors++))
    fi
    
    # Validar Minikube
    if command_exists minikube; then
        echo "$emoji_check Minikube: $(minikube version --short)"
    else
        echo "$emoji_cross Minikube nao encontrado"
        ((errors++))
    fi
    
    # Validar kubectl
    if command_exists kubectl; then
        echo "$emoji_check kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    else
        echo "$emoji_cross kubectl nao encontrado"
        ((errors++))
    fi
    
    # Validar Helm
    if command_exists helm; then
        echo "$emoji_check Helm: $(helm version --short)"
    else
        echo "$emoji_cross Helm nao encontrado"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo "$emoji_check Todas as dependencias instaladas com sucesso!"
        return 0
    else
        echo "$emoji_cross $errors erro(s) encontrado(s) na validacao"
        return 1
    fi
}

run_initialization() {
    if [[ "$RUN_INITIALIZATION" != "true" ]]; then
        return 0
    fi
    
    echo "$emoji_rocket Executando inicializacao do ambiente..."
    
    if [[ -n "$PROJECT_ROOT" ]]; then
        local init_script="$PROJECT_ROOT/minikube/scripts/linux/init/init-minikube-fixed.sh"
        if [[ -f "$init_script" ]]; then
            echo "$emoji_arrow Executando: $init_script"
            bash "$init_script" --install-keda
        else
            echo "$emoji_warning Script de inicializacao nao encontrado: $init_script"
        fi
    else
        echo "$emoji_warning Pasta raiz do projeto nao detectada. Nao e possivel executar inicializacao automatica."
        echo "$emoji_info Para inicializar manualmente:"
        echo "  cd /caminho/para/projeto"
        echo "  bash minikube/scripts/linux/init/init-minikube-fixed.sh --install-keda"
    fi
}

print_final_instructions() {
    echo ""
    echo "====================================================="
    echo "$emoji_rocket INSTALACAO COMPLETA!"
    echo "====================================================="
    echo ""
    echo "$emoji_info Proximos passos:"
    echo ""
    
    if groups | grep -q docker; then
        echo "$emoji_check Voce ja pode usar Docker"
    else
        echo "$emoji_warning Para usar Docker sem sudo:"
        echo "  1. Faca logout e login novamente"
        echo "  2. Ou execute: newgrp docker"
        echo ""
    fi
    
    echo "$emoji_gear Para iniciar o ambiente Minikube:"
    if [[ -n "$PROJECT_ROOT" ]]; then
        echo "  cd $PROJECT_ROOT"
        echo "  bash minikube/scripts/linux/init/init-minikube-fixed.sh --install-keda"
    else
        echo "  cd /caminho/para/projeto/DevOps"
        echo "  bash minikube/scripts/linux/init/init-minikube-fixed.sh --install-keda"
    fi
    echo ""
    
    echo "$emoji_info Comandos disponiveis apos inicializacao:"
    echo "  - RabbitMQ Management: http://localhost:15672 (guest/guest)"
    echo "  - Kubernetes Dashboard: http://localhost:15671"
    echo "  - MongoDB: localhost:27017 (admin/admin)"
    echo ""
    
    echo "$emoji_info Comandos uteis:"
    echo "  minikube status          # Status do cluster"
    echo "  kubectl get pods         # Listar pods"
    echo "  minikube dashboard       # Abrir dashboard"
    echo "  docker version           # Verificar Docker"
    echo ""
}

# Execucao principal
main() {
    detect_project_root
    check_sudo
    check_ubuntu_version
    update_system
    
    install_docker
    install_minikube
    install_kubectl
    install_helm
    
    if validate_installation; then
        run_initialization
        print_final_instructions
        echo "$emoji_check Setup completo! Sistema pronto para uso."
    else
        echo "$emoji_cross Setup completado com erros. Verifique as mensagens acima."
        exit 1
    fi
}

# Executar funcao principal
main "$@"