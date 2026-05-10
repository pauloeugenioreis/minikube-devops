#!/usr/bin/env bash

# bootstrap-devops.sh
# Script de bootstrap completo para macOS
# Download/clone do projeto + setup automatico de dependencias + inicializacao
# Equivalente macOS do bootstrap-devops.sh Linux

set -euo pipefail

# Definir variaveis de emoji para saida consistente
EMOJI_ROCKET=$(printf "\U1f680")
EMOJI_PACKAGE=$(printf "\U1f4e6")
EMOJI_GEAR=$(printf "\u2699\ufe0f")
EMOJI_CHECK=$(printf "\u2713")
EMOJI_CROSS=$(printf "\u274c")
EMOJI_ARROW=$(printf "\u27a1\ufe0f")
EMOJI_WARNING=$(printf "\u26a0\ufe0f")
EMOJI_INFO=$(printf "\U1f4a1")
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
echo "$EMOJI_ROCKET BOOTSTRAP DEVOPS - macOS"
echo "$EMOJI_PACKAGE Zero to Running - Setup Automatizado Completo"
echo "====================================================="
echo ""
echo "$EMOJI_INFO Configuracao:"
echo "  Pasta do projeto: $PROJECT_PATH"
echo "  Skip setup: $SKIP_SETUP"
echo "  Skip init: $SKIP_INIT"
echo ""

# Funcoes utilitarias
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_layout_prefix() {
    local root="$1"
    if [[ -d "$root/minikube/scripts" ]]; then
        echo "minikube/"
    else
        echo ""
    fi
}

download_project() {
    echo "$EMOJI_PACKAGE Baixando projeto DevOps..."

    # Criar diretorio pai se necessario
    local parent_dir
    parent_dir="$(dirname "$PROJECT_PATH")"
    mkdir -p "$parent_dir"

    # Tentar clone Git primeiro
    if command_exists git; then
        echo "$EMOJI_ARROW Tentando clone Git..."
        if git clone "$GITHUB_REPO" "$PROJECT_PATH"; then
            echo "$EMOJI_CHECK Projeto clonado via Git"
            return 0
        else
            echo "$EMOJI_WARNING Clone Git falhou, tentando download ZIP..."
        fi
    else
        echo "$EMOJI_INFO Git nao encontrado, usando download ZIP..."
    fi

    # Fallback: download ZIP
    local temp_dir
    temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/project.zip"

    echo "$EMOJI_ARROW Baixando ZIP do GitHub..."
    if curl -L -o "$zip_file" "https://github.com/pauloeugenioreis/minikube-devops/archive/refs/heads/main.zip"; then
        echo "$EMOJI_ARROW Extraindo projeto..."
        unzip -q "$zip_file" -d "$temp_dir"
        mv "$temp_dir/minikube-devops-main" "$PROJECT_PATH"
        rm -rf "$temp_dir"
        echo "$EMOJI_CHECK Projeto baixado via ZIP"
        return 0
    else
        echo "$EMOJI_CROSS Falha no download do projeto"
        rm -rf "$temp_dir"
        return 1
    fi
}

check_project_exists() {
    if [[ -d "$PROJECT_PATH" ]]; then
        if [[ -f "$PROJECT_PATH/minikube/docs/README.md" || -f "$PROJECT_PATH/docs/README.md" ]]; then
            echo "$EMOJI_CHECK Projeto ja existe e parece valido: $PROJECT_PATH"
            return 0
        else
            echo "$EMOJI_WARNING Pasta existe mas nao parece ser o projeto DevOps: $PROJECT_PATH"
            echo "$EMOJI_INFO Verificando conteudo..."
            if [[ -n "$(ls -A "$PROJECT_PATH")" ]]; then
                echo "$EMOJI_CROSS Pasta nao vazia e nao e o projeto esperado"
                return 1
            else
                echo "$EMOJI_INFO Pasta vazia, pode ser usada para download"
                return 2
            fi
        fi
    else
        echo "$EMOJI_INFO Projeto nao existe, sera baixado: $PROJECT_PATH"
        return 2
    fi
}

run_setup() {
    if [[ "$SKIP_SETUP" == "true" ]]; then
        echo "$EMOJI_ARROW Pulando instalacao de dependencias (--skip-setup)"
        return 0
    fi

    echo "$EMOJI_GEAR Executando setup de dependencias..."

    local setup_script="$PROJECT_PATH/scripts/macOs/setup-fresh-machine.sh"
    if [[ ! -f "$setup_script" ]]; then
        setup_script="$PROJECT_PATH/minikube/scripts/macOs/setup-fresh-machine.sh"
    fi
    if [[ -f "$setup_script" ]]; then
        echo "$EMOJI_ARROW Executando: $setup_script"
        chmod +x "$setup_script"

        local setup_args=""
        if [[ "$SKIP_INIT" != "true" ]]; then
            setup_args="$setup_args --run-initialization"
        fi

        bash "$setup_script" $setup_args
    else
        echo "$EMOJI_CROSS Script de setup nao encontrado: $setup_script"
        echo "$EMOJI_INFO Execute manualmente:"
        echo "  cd $PROJECT_PATH"
        echo "  bash scripts/macOs/setup-fresh-machine.sh --run-initialization"
        return 1
    fi
}

print_final_status() {
    local cmd_prefix
    cmd_prefix=$(get_layout_prefix "$PROJECT_PATH")

    echo ""
    echo "====================================================="
    echo "$EMOJI_ROCKET BOOTSTRAP COMPLETO!"
    echo "====================================================="
    echo ""
    echo "$emoji_folder Projeto localizado em: $PROJECT_PATH"
    echo ""

    if [[ "$SKIP_SETUP" == "true" ]]; then
        echo "$EMOJI_INFO Dependencias nao instaladas (--skip-setup usado)"
        echo "$EMOJI_GEAR Para instalar dependencias:"
        echo "  cd $PROJECT_PATH"
        echo "  bash ${cmd_prefix}scripts/macOs/setup-fresh-machine.sh --run-initialization"
        echo ""
    fi

    if [[ "$SKIP_INIT" == "true" ]]; then
        echo "$EMOJI_INFO Ambiente nao inicializado (--skip-init usado)"
        echo "$EMOJI_GEAR Para inicializar ambiente:"
        echo "  cd $PROJECT_PATH"
        echo "  bash ${cmd_prefix}scripts/macOs/init/start.sh --install-keda"
        echo ""
    fi

    echo "$EMOJI_INFO Proximos passos:"
    echo "  cd $PROJECT_PATH"
    echo "  # Ver documentacao:"
    echo "  cat ${cmd_prefix}docs/README.md"
    echo "  # Verificar status:"
    echo "  minikube status"
    echo "  kubectl get pods"
    echo ""

    echo "$EMOJI_INFO Endpoints apos inicializacao:"
    echo "  - RabbitMQ Management: http://localhost:15672 (guest/guest)"
    echo "  - Kubernetes Dashboard: http://localhost:15671"
    echo "  - MongoDB: localhost:27017 (admin/admin)"
    echo ""
}

# Execucao principal
main() {
    local project_status
    check_project_exists
    project_status=$?

    case $project_status in
        0)
            echo "$EMOJI_CHECK Usando projeto existente"
            ;;
        1)
            echo "$EMOJI_CROSS Nao e possivel continuar. Pasta existe mas nao e o projeto DevOps."
            echo "$EMOJI_INFO Solucoes:"
            echo "  1. Use --project-path para especificar outra pasta"
            echo "  2. Remova ou mova a pasta existente: $PROJECT_PATH"
            exit 1
            ;;
        2)
            if ! download_project; then
                echo "$EMOJI_CROSS Falha no download do projeto"
                exit 1
            fi
            ;;
    esac

    if ! run_setup; then
        echo "$EMOJI_WARNING Setup completado com avisos. Verifique mensagens acima."
    fi

    print_final_status
    echo "$EMOJI_CHECK Bootstrap completo! Projeto pronto para uso."
}

# Executar funcao principal
main "$@"
