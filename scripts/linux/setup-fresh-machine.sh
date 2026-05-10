#!/bin/bash

# setup-fresh-machine.sh
# Script de instalacao completa para maquina nova Linux Ubuntu
# Instala automaticamente: Docker, Minikube, kubectl, Helm
# Configurado para usar paths dinamicos e ambiente completo Minikube DevOps

set -euo pipefail

# Sourcing common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_COMMON="$SCRIPT_DIR/utils/common.sh"
# shellcheck source=utils/common.sh
source "$UTILS_COMMON"

# Parametros do script
SKIP_DOCKER_INSTALL=false
SKIP_MINIKUBE_INSTALL=false
SKIP_KUBECTL_INSTALL=false
SKIP_HELM_INSTALL=false
SKIP_VALIDATION=false
RUN_INITIALIZATION=false
FORCE_UPDATE=false

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
        --force-update)
            FORCE_UPDATE=true
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
            echo "  --force-update      Forcar atualizacao das ferramentas ja instaladas"
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
        if [[ ( -f "$current_dir/minikube/docs/README.md" && -d "$current_dir/minikube/scripts" ) || ( -f "$current_dir/docs/README.md" && -d "$current_dir/scripts" ) ]]; then
            PROJECT_ROOT="$current_dir"
            echo "$EMOJI_CHECK Pasta raiz do projeto detectada: $PROJECT_ROOT"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    echo "$EMOJI_WARNING Pasta raiz do projeto nao detectada. Setup independente."
    return 1
}

# Cabecalho
echo "====================================================="
echo "$EMOJI_ROCKET SETUP COMPLETO - MAQUINA NOVA LINUX UBUNTU"
echo "$EMOJI_GEAR Minikube DevOps Environment - Instalacao Automatica"
echo "====================================================="

# Funcoes utilitarias
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_layout_prefix() {
    local root="$1"
    if [[ -n "$root" && -d "$root/minikube/scripts" ]]; then
        echo "minikube/"
    else
        echo ""
    fi
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo "$EMOJI_WARNING Script sendo executado como root. Recomenda-se executar como usuario normal."
        echo "$EMOJI_INFO O script solicitara sudo quando necessario."
    fi
    
    if ! sudo -n true 2>/dev/null; then
        echo "$EMOJI_INFO Este script requer privilegios sudo para instalacao."
        echo "Por favor, digite sua senha quando solicitado."
        sudo true
    fi
}

check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        echo "$EMOJI_CROSS Sistema operacional nao identificado"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        echo "$EMOJI_WARNING Sistema detectado: $PRETTY_NAME"
        echo "$EMOJI_INFO Este script foi otimizado para Ubuntu, mas pode funcionar em derivados."
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "$EMOJI_CHECK Sistema operacional: $PRETTY_NAME"
    fi
    
    # Verificar versao minima (18.04+)
    local version_id_numeric
    version_id_numeric=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ $version_id_numeric -lt 18 ]]; then
        echo "$EMOJI_CROSS Ubuntu $VERSION_ID detectado. Versao minima requerida: 18.04"
        exit 1
    fi
}

update_system() {
    echo "$EMOJI_ARROW Atualizando sistema..."
    sudo apt-get update -qq
    sudo apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release
    echo "$EMOJI_CHECK Sistema atualizado"
}

install_docker() {
    if [[ "$SKIP_DOCKER_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do Docker (--skip-docker)"
        return 0
    fi
    
    log_info "Instalando Docker..."
    
    if [[ "$FORCE_UPDATE" == "false" ]] && command_exists docker; then
        log_success "Docker ja instalado: $(docker --version)"
        return 0
    fi
    
    # Remover versoes antigas
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Adicionar repositorio oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Adicionar usuario ao grupo docker
    sudo usermod -aG docker "$USER"
    
    # Iniciar servico
    sudo systemctl enable docker
    sudo systemctl start docker
    
    echo "$EMOJI_CHECK Docker instalado: $(docker --version)"
    echo "$EMOJI_INFO Voce precisa fazer logout/login para usar Docker sem sudo"
}

install_minikube() {
    if [[ "$SKIP_MINIKUBE_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do Minikube (--skip-minikube)"
        return 0
    fi
    
    log_info "Instalando/Atualizando Minikube..."
    
    if [[ "$FORCE_UPDATE" == "false" ]] && command_exists minikube; then
        log_success "Minikube ja instalado: $(minikube version --short)"
        return 0
    fi
    
    # Download e instalacao
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    
    echo "$EMOJI_CHECK Minikube instalado: $(minikube version --short)"
}

install_kubectl() {
    if [[ "$SKIP_KUBECTL_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do kubectl (--skip-kubectl)"
        return 0
    fi
    
    log_info "Instalando/Atualizando kubectl..."
    
    if [[ "$FORCE_UPDATE" == "false" ]] && command_exists kubectl; then
        log_success "kubectl ja instalado: $(kubectl version --client 2>/dev/null | head -1 || echo 'ok')"
        return 0
    fi
    
    # Detectar versao estavel
    local kubectl_version
    kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    
    # Download e instalacao
    curl -LO "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    
    echo "$EMOJI_CHECK kubectl instalado: $(kubectl version --client 2>/dev/null | head -1 || echo 'ok')"
}

install_helm() {
    if [[ "$SKIP_HELM_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do Helm (--skip-helm)"
        return 0
    fi
    
    log_info "Instalando/Atualizando Helm..."
    
    if [[ "$FORCE_UPDATE" == "false" ]] && command_exists helm; then
        log_success "Helm ja instalado: $(helm version --short)"
        return 0
    fi
    
    # Usar script oficial de instalacao
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    echo "$EMOJI_CHECK Helm instalado: $(helm version --short)"
}

validate_installation() {
    if [[ "$SKIP_VALIDATION" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando validacao final (--skip-validation)"
        return 0
    fi
    
    echo "$EMOJI_GEAR Validando instalacao..."
    
    local errors=0
    
    # Validar Docker
    if command_exists docker; then
        if docker version >/dev/null 2>&1 || groups | grep -q docker; then
            echo "$EMOJI_CHECK Docker: $(docker --version)"
        else
            echo "$EMOJI_CROSS Docker instalado mas nao acessivel (precisa logout/login)"
            ((errors++))
        fi
    else
        echo "$EMOJI_CROSS Docker nao encontrado"
        ((errors++))
    fi
    
    # Validar Minikube
    if command_exists minikube; then
        echo "$EMOJI_CHECK Minikube: $(minikube version --short)"
    else
        echo "$EMOJI_CROSS Minikube nao encontrado"
        ((errors++))
    fi
    
    # Validar kubectl
    if command_exists kubectl; then
        echo "$EMOJI_CHECK kubectl: $(kubectl version --client 2>/dev/null | head -1 || echo 'ok')"
    else
        echo "$EMOJI_CROSS kubectl nao encontrado"
        ((errors++))
    fi
    
    # Validar Helm
    if command_exists helm; then
        echo "$EMOJI_CHECK Helm: $(helm version --short)"
    else
        echo "$EMOJI_CROSS Helm nao encontrado"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo "$EMOJI_CHECK Todas as dependencias instaladas com sucesso!"
        return 0
    else
        echo "$EMOJI_CROSS $errors erro(s) encontrado(s) na validacao"
        return 1
    fi
}

run_initialization() {
    if [[ "$RUN_INITIALIZATION" != "true" ]]; then
        return 0
    fi
    
    echo "$EMOJI_ROCKET Executando inicializacao do ambiente..."
    
    if [[ -n "$PROJECT_ROOT" ]]; then
        local init_script="$PROJECT_ROOT/scripts/linux/init/start.sh"
        if [[ ! -f "$init_script" ]]; then
            init_script="$PROJECT_ROOT/minikube/scripts/linux/init/start.sh"
        fi
        if [[ -f "$init_script" ]]; then
            echo "$EMOJI_ARROW Executando: $init_script"
            bash "$init_script" --install-keda
        else
            echo "$EMOJI_WARNING Script de inicializacao nao encontrado: $init_script"
        fi
    else
        local cmd_prefix
        cmd_prefix=$(get_layout_prefix "$PROJECT_ROOT")
        echo "$EMOJI_WARNING Pasta raiz do projeto nao detectada. Nao e possivel executar inicializacao automatica."
        echo "$EMOJI_INFO Para inicializar manualmente:"
        echo "  cd /caminho/para/projeto"
        echo "  bash ${cmd_prefix}scripts/linux/init/start.sh --install-keda"
    fi
}

print_final_instructions() {
    local cmd_prefix
    cmd_prefix=$(get_layout_prefix "$PROJECT_ROOT")

    echo ""
    echo "====================================================="
    echo "$EMOJI_ROCKET INSTALACAO COMPLETA!"
    echo "====================================================="
    echo ""
    echo "$EMOJI_INFO Proximos passos:"
    echo ""
    
    if groups | grep -q docker; then
        echo "$EMOJI_CHECK Voce ja pode usar Docker"
    else
        echo "$EMOJI_WARNING Para usar Docker sem sudo:"
        echo "  1. Faca logout e login novamente"
        echo "  2. Ou execute: newgrp docker"
        echo ""
    fi
    
    echo "$EMOJI_GEAR Para iniciar o ambiente Minikube:"
    if [[ -n "$PROJECT_ROOT" ]]; then
        echo "  cd $PROJECT_ROOT"
        echo "  bash ${cmd_prefix}scripts/linux/init/start.sh --install-keda"
    else
        echo "  cd /caminho/para/projeto/DevOps"
        echo "  bash ${cmd_prefix}scripts/linux/init/start.sh --install-keda"
    fi
    echo ""
    
    echo "$EMOJI_INFO Comandos disponiveis apos inicializacao:"
    echo "  - RabbitMQ Management: http://localhost:15672 (guest/guest)"
    echo "  - Kubernetes Dashboard: http://localhost:15671"
    echo "  - MongoDB: localhost:27017 (admin/admin)"
    echo ""
    
    echo "$EMOJI_INFO Comandos uteis:"
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
        echo "$EMOJI_CHECK Setup completo! Sistema pronto para uso."
    else
        echo "$EMOJI_CROSS Setup completado com erros. Verifique as mensagens acima."
        exit 1
    fi
}

# Executar funcao principal
main "$@"