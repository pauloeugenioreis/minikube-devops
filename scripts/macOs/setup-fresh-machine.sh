#!/usr/bin/env bash

# setup-fresh-machine.sh
# Script de instalacao completa para maquina nova macOS
# Instala automaticamente: Homebrew, Docker Desktop, Minikube, kubectl, Helm
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
            echo "  --skip-docker       Pular instalacao do Docker Desktop"
            echo "  --skip-minikube     Pular instalacao do Minikube"
            echo "  --skip-kubectl      Pular instalacao do kubectl"
            echo "  --skip-helm         Pular instalacao do Helm"
            echo "  --skip-validation   Pular validacao final
  --run-initialization Executar inicializacao apos setup
  --force-update      Forcar atualizacao das ferramentas ja instaladas
"
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
echo "$EMOJI_ROCKET SETUP COMPLETO - MAQUINA NOVA macOS"
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

check_macos_version() {
    local version
    version=$(sw_vers -productVersion)
    local major
    major=$(echo "$version" | cut -d. -f1)

    echo "$EMOJI_CHECK Sistema operacional: macOS $version"

    if [[ "$major" -lt 12 ]]; then
        echo "$EMOJI_CROSS macOS $version detectado. Versao minima requerida: 12 (Monterey)"
        exit 1
    fi
}

install_homebrew() {
    if command_exists brew; then
        echo "$EMOJI_CHECK Homebrew ja instalado: $(brew --version | head -1)"
        return 0
    fi

    echo "$EMOJI_PACKAGE Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Adicionar brew ao PATH para Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    echo "$EMOJI_CHECK Homebrew instalado: $(brew --version | head -1)"
}

install_docker() {
    if [[ "$SKIP_DOCKER_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do Docker (--skip-docker)"
        return 0
    fi

    local version major
    version=$(sw_vers -productVersion)
    major=$(echo "$version" | cut -d. -f1)

    if [[ "$major" -lt 14 ]]; then
        echo "$EMOJI_WARNING macOS < 14 detectado. Instalando Colima + Docker CLI (Alternativa ao Docker Desktop)..."
        if [[ "$FORCE_UPDATE" == "true" ]] && command_exists colima; then
            brew upgrade colima docker
        else
            brew install colima docker
        fi
        echo "$EMOJI_ROCKET Iniciando Colima no modo QEMU (Compatibilidade)..."
        colima start --cpu 2 --memory 4 --vm-type qemu
    else
        if [[ "$FORCE_UPDATE" == "true" ]] && command_exists docker; then
            log_info "Atualizando Docker Desktop via Homebrew..."
            brew upgrade --cask docker
        else
            log_info "Instalando Docker Desktop via Homebrew..."
            brew install --cask docker
        fi

        echo "$EMOJI_ARROW Abrindo Docker Desktop para primeira inicializacao..."
        open /Applications/Docker.app
    fi

    echo "$EMOJI_INFO Aguardando Docker daemon inicializar..."
    local elapsed=0
    local timeout=60
    while ! docker info >/dev/null 2>&1 && (( elapsed < timeout )); do
        sleep 5
        elapsed=$((elapsed + 5))
        echo "$EMOJI_INFO   ...aguardando Docker ($elapsed/${timeout}s)..."
    done

    if docker info >/dev/null 2>&1; then
        echo "$EMOJI_CHECK Docker instalado e rodando: $(docker --version)"
    else
        echo "$EMOJI_WARNING Docker instalado mas daemon ainda nao respondeu."
        if [[ "$major" -lt 14 ]]; then
            echo "$EMOJI_INFO Tente rodar 'colima start' manualmente."
        else
            echo "$EMOJI_INFO Abra Docker Desktop manualmente e aguarde o icone ficar verde."
        fi
    fi
}

install_minikube() {
    if [[ "$SKIP_MINIKUBE_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do Minikube (--skip-minikube)"
        return 0
    fi

    # Instalar Minikube individualmente
    if command_exists minikube; then
        if [[ "$FORCE_UPDATE" == "true" ]]; then
            log_info "Atualizando Minikube via Homebrew..."
            brew upgrade minikube || true
        fi
    else
        log_info "Instalando Minikube via Homebrew..."
        brew install minikube
    fi

    # Instalar QEMU individualmente
    if command_exists qemu-system-x86_64; then
        if [[ "$FORCE_UPDATE" == "true" ]]; then
            log_info "Atualizando QEMU via Homebrew..."
            brew upgrade qemu || true
        fi
    else
        log_info "Instalando QEMU (Necessario para driver qemu2)..."
        brew install qemu
    fi

    echo "$EMOJI_CHECK Minikube e QEMU verificados."
}

install_kubectl() {
    if [[ "$SKIP_KUBECTL_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do kubectl (--skip-kubectl)"
        return 0
    fi

    if [[ "$FORCE_UPDATE" == "true" ]] && command_exists kubectl; then
        log_info "Atualizando kubectl via Homebrew..."
        brew upgrade kubectl
    else
        log_info "Instalando kubectl via Homebrew..."
        brew install kubectl
    fi

    echo "$EMOJI_CHECK kubectl instalado: $(kubectl version --client 2>/dev/null | head -1 || echo 'ok')"
}

install_helm() {
    if [[ "$SKIP_HELM_INSTALL" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao do Helm (--skip-helm)"
        return 0
    fi

    if [[ "$FORCE_UPDATE" == "true" ]] && command_exists helm; then
        log_info "Atualizando Helm via Homebrew..."
        brew upgrade helm
    else
        log_info "Instalando Helm via Homebrew..."
        brew install helm
    fi

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
        if docker info >/dev/null 2>&1; then
            echo "$EMOJI_CHECK Docker: $(docker --version)"
        else
            echo "$EMOJI_WARNING Docker instalado mas daemon nao acessivel (abra o Docker Desktop)"
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
        local init_script="$PROJECT_ROOT/scripts/macOs/init/start.sh"
        if [[ ! -f "$init_script" ]]; then
            init_script="$PROJECT_ROOT/minikube/scripts/macOs/init/start.sh"
        fi
        if [[ -f "$init_script" ]]; then
            echo "$EMOJI_ARROW Executando: $init_script"
            chmod +x "$init_script"
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
        echo "  bash ${cmd_prefix}scripts/macOs/init/start.sh --install-keda"
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
    echo "$EMOJI_GEAR Para iniciar o ambiente Minikube:"
    if [[ -n "$PROJECT_ROOT" ]]; then
        echo "  cd $PROJECT_ROOT"
        echo "  bash ${cmd_prefix}scripts/macOs/init/start.sh --install-keda"
    else
        echo "  cd /caminho/para/projeto/DevOps"
        echo "  bash ${cmd_prefix}scripts/macOs/init/start.sh --install-keda"
    fi
    echo ""

    echo "$EMOJI_INFO Comandos uteis apos inicializacao:"
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
    detect_project_root || true
    check_macos_version
    install_homebrew

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
