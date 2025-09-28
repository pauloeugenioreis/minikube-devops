#!/bin/bash
# =====================================================
# Teste de Estrutura - Versao Linux
# Valida toda a estrutura do ambiente Minikube
# =====================================================

# Cores para output
# TESTE COMPLETO DA ESTRUTURA MINIKUBE - VERSÃO LINUX
# Validacao abrangente de todos os componentes do projeto.

# --- Funções de Cor e Status ---
GREEN='\033[0;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ...restante do script homologado (conteúdo completo já lido)...
success_count=0
failure_count=0

print_status() {
    echo -e "${CYAN}=====================================${NC}"
}

print_header() {
    print_status
    echo -e "${GREEN}TESTANDO ESTRUTURA PROFISSIONAL MINIKUBE (LINUX)${NC}"
    print_status
}

# --- Detecção da Raiz do Projeto ---
find_project_root() {
    local current_dir
    current_dir="$(dirname "$(readlink -f "$0")")"
    for i in {1..10}; do
        if [[ -f "$current_dir/DECISIONS-HISTORY.md" && -d "$current_dir/minikube" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    echo ""
    return 1
}

PROJECT_ROOT=$(find_project_root)

if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${RED}ERRO: Não foi possível detectar a pasta raiz do projeto.${NC}"
    echo -e "${YELLOW}Certifique-se de que os arquivos marcadores (ex: DECISIONS-HISTORY.md) existem na raiz.${NC}"
    exit 1
fi

echo -e "${YELLOW}Pasta raiz do projeto detectada: ${GREEN}$PROJECT_ROOT${NC}"
MINIKUBE_PATH="$PROJECT_ROOT/minikube"

# --- Função de Teste Centralizada ---
test_files() {
    local category="$1"
    local directory="$2"
    shift 2
    local files=("$@")

    echo -e "\n${YELLOW}Testando $category...${NC}"

    for file in "${files[@]}"; do
        local full_path="$MINIKUBE_PATH/$directory/$file"
        if [[ -e "$full_path" ]]; then
            echo -e "  ${GREEN}✅ $(basename "$file") encontrado${NC}"
            ((success_count++))
        else
            echo -e "  ${RED}❌ $(basename "$file") NAO encontrado em '$full_path'${NC}"
            ((failure_count++))
        fi
    done
}

test_root_files() {
    local category="$1"
    shift
    local files=("$@")

    echo -e "\n${YELLOW}Testando $category...${NC}"

    for file in "${files[@]}"; do
        local full_path="$PROJECT_ROOT/$file"
        if [[ -e "$full_path" ]]; then
            echo -e "  ${GREEN}✅ $(basename "$file") encontrado${NC}"
            ((success_count++))
        else
            echo -e "  ${RED}❌ $(basename "$file") NAO encontrado em '$full_path'${NC}"
            ((failure_count++))
        fi
    done
}


# --- Execução dos Testes ---
print_header

# Scripts Linux
test_files "Scripts de Inicialização (Linux)" "scripts/linux/init" "init-minikube-fixed.sh" "apply-rabbitmq-config.sh"
test_files "Scripts de Manutenção (Linux)" "scripts/linux/maintenance" "fix-dashboard.sh" "validate-rabbitmq-config.sh"
test_files "Scripts de Monitoramento (Linux)" "scripts/linux/monitoring" "open-dashboard.sh" "change-dashboard-port.sh"
test_files "Scripts KEDA (Linux)" "scripts/linux/keda" "install-helm-fixed.sh" "install-keda.sh" "test-keda.sh"
test_files "Scripts Autostart (Linux)" "scripts/linux/autostart" "minikube-autostart.sh" 
test_files "Script de Teste de Estrutura (Linux)" "" "linux-test-structure.sh"

# Estrutura Comum
test_files "Configs KEDA" "configs/keda/examples" "cpu-scaling-example.yaml" "memory-scaling-example.yaml" "rabbitmq-scaling-example.yaml"
test_files "Documentação" "docs" "README.md" "KEDA.md"
test_files "Documentação Fresh Machine" "docs/fresh-machine" "SETUP.md" "CHECKLIST.md"

# Helm Charts
echo -e "\n${YELLOW}Testando estrutura de Helm Charts...${NC}"
charts_path="$MINIKUBE_PATH/charts"
if [[ -d "$charts_path" ]]; then
    echo -e "  ${GREEN}✅ Pasta de charts encontrada${NC}"; ((success_count++))
    for chart in "rabbitmq" "mongodb"; do
        chart_path="$charts_path/$chart"
        if [[ -d "$chart_path" ]]; then
            echo -e "    ${GREEN}✅ Chart '$chart' encontrado${NC}"; ((success_count++))
            if [[ -f "$chart_path/Chart.yaml" && -f "$chart_path/values.yaml" && -d "$chart_path/templates" ]]; then
                echo -e "      ${GREEN}✅ Estrutura básica (Chart.yaml, values.yaml, templates) válida${NC}"; ((success_count++))
            else
                echo -e "      ${RED}❌ Estrutura básica do chart '$chart' inválida${NC}"; ((failure_count++))
            fi
        else
            echo -e "    ${RED}❌ Chart '$chart' NAO encontrado${NC}"; ((failure_count++))
        fi
    done
else
    echo -e "  ${RED}❌ Pasta de charts NAO encontrada${NC}"; ((failure_count++))
fi

# Arquivos na Raiz
test_root_files "Checklists e Históricos na Raiz" "MANDATORY-CHECKLIST.md" "DECISIONS-HISTORY.md" "MINIKUBE-PROJECT-HISTORY.md" "DYNAMIC-PATHS.md"

# --- Resumo Final ---
print_status
total_checks=$((success_count + failure_count))
if [[ $failure_count -eq 0 ]]; then
    echo -e "${GREEN}✅ SUCESSO! ESTRUTURA COMPLETA E CONSISTENTE!${NC}"
else
    echo -e "${RED}❌ FALHA! Foram encontrados $failure_count problemas na estrutura.${NC}"
fi
echo -e "${CYAN}Total de verificações: $total_checks | Sucessos: $success_count | Falhas: $failure_count${NC}"
print_status

echo -e "\n${YELLOW}PROXIMOS PASSOS:${NC}"
echo -e "1. ${GREEN}Inicializar (com KEDA):${NC} bash $MINIKUBE_PATH/scripts/linux/autostart/minikube-autostart.sh"
echo -e "2. ${GREEN}Verificar status:${NC}      bash $MINIKUBE_PATH/scripts/linux/maintenance/quick-status.sh"
echo -e "3. ${GREEN}Abrir Dashboard:${NC}       bash $MINIKUBE_PATH/scripts/linux/monitoring/open-dashboard.sh"
echo -e "4. ${GREEN}Consultar Docs:${NC}        cat $MINIKUBE_PATH/docs/README.md"

echo -e "\n${GREEN}TESTE CONCLUIDO!${NC}"
