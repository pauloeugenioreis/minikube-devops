#!/bin/bash

# bootstrap-devops.sh
# Script de bootstrap completo para Linux Ubuntu
# Download/clone do projeto + setup automatico de dependencias + inicializacao
# Equivalente Linux do Bootstrap-DevOps.ps1

set -euo pipefail

# Definir variaveis de emoji para saida consistente
emoji_rocket=$(printf "\U1f680")
emoji_package=$(printf "\U1f4e6")
emoji_gear=$(printf "\u2699\ufe0f")
emoji_check=$(printf "\u2713")
emoji_cross=$(printf "\u274c")
emoji_arrow=$(printf "\u27a1\ufe0f")
emoji_warning=$(printf "\u26a0\ufe0f")
emoji_info=$(printf "\U1f4a1")
emoji_folder=$(printf "\U1f4c1")

# Parametros padrao
PROJECT_PATH=""
SKIP_SETUP=false
SKIP_INIT=false
GITHUB_REPO="https://github.com/pauloeugenioreis/minikube-devops.git"
DEFAULT_PROJECT_PATH="$HOME/DevOps"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        --skip-setup)
            SKIP_SETUP=true
            shift
            ;;
        --skip-init)
            SKIP_INIT=true
            shift
            ;;
        --help|-h)
            echo "Uso: $0 [opcoes]"
            echo ""
            echo "Opcoes:"
            echo "  --project-path PATH     Caminho customizado para o projeto (default: $DEFAULT_PROJECT_PATH)"
            echo "  --skip-setup            Pular instalacao de dependencias"
            echo "  --skip-init             Pular inicializacao do ambiente"
            echo "  --help, -h              Mostrar esta ajuda"
            echo ""
            echo "Exemplos:"
            echo "  $0                                    # Setup completo com defaults"
            echo "  $0 --project-path /opt/devops         # Setup em caminho customizado"
            echo "  $0 --skip-setup                       # So baixar projeto, sem instalar deps"
            exit 0
            ;;
        *)
            echo "Opcao desconhecida: $1"
            echo "Use --help para ver opcoes disponiveis"
            exit 1
            ;;
    esac
done

# Usar default se nao especificado
if [[ -z "$PROJECT_PATH" ]]; then
    PROJECT_PATH="$DEFAULT_PROJECT_PATH"
fi

# Cabecalho
echo "====================================================="
echo "$emoji_rocket BOOTSTRAP DEVOPS - LINUX UBUNTU"
echo "$emoji_package Zero to Running - Setup Automatizado Completo"
echo "====================================================="
echo ""
echo "$emoji_info Configuracao:"
echo "  Pasta do projeto: $PROJECT_PATH"
echo "  Skip setup: $SKIP_SETUP"
echo "  Skip init: $SKIP_INIT"
echo ""

# Funcoes utilitarias
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

download_project() {
    echo "$emoji_package Baixando projeto DevOps..."
    
    # Criar diretorio pai se necessario
    local parent_dir
    parent_dir="$(dirname "$PROJECT_PATH")"
    mkdir -p "$parent_dir"
    
    # Tentar clone Git primeiro
    if command_exists git; then
        echo "$emoji_arrow Tentando clone Git..."
        if git clone "$GITHUB_REPO" "$PROJECT_PATH"; then
            echo "$emoji_check Projeto clonado via Git"
            return 0
        else
            echo "$emoji_warning Clone Git falhou, tentando download ZIP..."
        fi
    else
        echo "$emoji_info Git nao encontrado, usando download ZIP..."
    fi
    
    # Fallback: download ZIP
    local temp_dir
    temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/project.zip"
    
    echo "$emoji_arrow Baixando ZIP do GitHub..."
    if curl -L -o "$zip_file" "https://github.com/pauloeugenioreis/minikube-devops/archive/refs/heads/main.zip"; then
        echo "$emoji_arrow Extraindo projeto..."
        unzip -q "$zip_file" -d "$temp_dir"
        mv "$temp_dir/minikube-devops-main" "$PROJECT_PATH"
        rm -rf "$temp_dir"
        echo "$emoji_check Projeto baixado via ZIP"
        return 0
    else
        echo "$emoji_cross Falha no download do projeto"
        rm -rf "$temp_dir"
        return 1
    fi
}

check_project_exists() {
    if [[ -d "$PROJECT_PATH" ]]; then
        if [[ -f "$PROJECT_PATH/minikube/docs/README.md" ]]; then
            echo "$emoji_check Projeto ja existe e parece valido: $PROJECT_PATH"
            return 0
        else
            echo "$emoji_warning Pasta existe mas nao parece ser o projeto DevOps: $PROJECT_PATH"
            echo "$emoji_info Verificando conteudo..."
            if [[ -n "$(ls -A "$PROJECT_PATH")" ]]; then
                echo "$emoji_cross Pasta nao vazia e nao e o projeto esperado"
                return 1
            else
                echo "$emoji_info Pasta vazia, pode ser usada para download"
                return 2
            fi
        fi
    else
        echo "$emoji_info Projeto nao existe, sera baixado: $PROJECT_PATH"
        return 2
    fi
}

run_setup() {
    if [[ "$SKIP_SETUP" == "true" ]]; then
        echo "$emoji_arrow Pulando instalacao de dependencias (--skip-setup)"
        return 0
    fi
    
    echo "$emoji_gear Executando setup de dependencias..."
    
    local setup_script="$PROJECT_PATH/minikube/scripts/linux/setup-fresh-machine.sh"
    if [[ -f "$setup_script" ]]; then
        echo "$emoji_arrow Executando: $setup_script"
        chmod +x "$setup_script"
        
        local setup_args=""
        if [[ "$SKIP_INIT" == "true" ]]; then
            setup_args="$setup_args"  # Sem --run-initialization
        else
            setup_args="$setup_args --run-initialization"
        fi
        
        bash "$setup_script" $setup_args
    else
        echo "$emoji_cross Script de setup nao encontrado: $setup_script"
        echo "$emoji_info Execute manualmente:"
        echo "  cd $PROJECT_PATH"
        echo "  bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization"
        return 1
    fi
}

print_final_status() {
    echo ""
    echo "====================================================="
    echo "$emoji_rocket BOOTSTRAP COMPLETO!"
    echo "====================================================="
    echo ""
    echo "$emoji_folder Projeto localizado em: $PROJECT_PATH"
    echo ""
    
    if [[ "$SKIP_SETUP" == "true" ]]; then
        echo "$emoji_info Dependencias nao instaladas (--skip-setup usado)"
        echo "$emoji_gear Para instalar dependencias:"
        echo "  cd $PROJECT_PATH"
        echo "  bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization"
        echo ""
    fi
    
    if [[ "$SKIP_INIT" == "true" ]]; then
        echo "$emoji_info Ambiente nao inicializado (--skip-init usado)"
        echo "$emoji_gear Para inicializar ambiente:"
        echo "  cd $PROJECT_PATH"
        echo "  bash minikube/scripts/linux/init/init-minikube-fixed.sh --install-keda"
        echo ""
    fi
    
    echo "$emoji_info Proximos passos:"
    echo "  cd $PROJECT_PATH"
    echo "  # Ver documentacao:"
    echo "  cat minikube/docs/README.md"
    echo "  # Verificar status:"
    echo "  minikube status"
    echo "  kubectl get pods"
    echo ""
    
    echo "$emoji_info Endpoints apos inicializacao:"
    echo "  - RabbitMQ Management: http://localhost:15672 (guest/guest)"
    echo "  - Kubernetes Dashboard: http://localhost:15671"
    echo "  - MongoDB: localhost:27017 (admin/admin)"
    echo ""
}

# Execucao principal
main() {
    # Verificar se projeto ja existe
    local project_status
    check_project_exists
    project_status=$?
    
    case $project_status in
        0)
            # Projeto ja existe e e valido
            echo "$emoji_check Usando projeto existente"
            ;;
        1)
            # Pasta existe mas nao e o projeto
            echo "$emoji_cross Nao e possivel continuar. Pasta existe mas nao e o projeto DevOps."
            echo "$emoji_info Solucoes:"
            echo "  1. Use --project-path para especificar outra pasta"
            echo "  2. Remova ou mova a pasta existente: $PROJECT_PATH"
            exit 1
            ;;
        2)
            # Projeto nao existe, precisa baixar
            if ! download_project; then
                echo "$emoji_cross Falha no download do projeto"
                exit 1
            fi
            ;;
    esac
    
    # Executar setup se solicitado
    if ! run_setup; then
        echo "$emoji_warning Setup completado com avisos. Verifique mensagens acima."
    fi
    
    print_final_status
    echo "$emoji_check Bootstrap completo! Projeto pronto para uso."
}

# Executar funcao principal
main "$@"