#!/usr/bin/env bash
# =====================================================
# Teste de Estrutura - Versão Linux
# Valida a organização principal do projeto Minikube
# =====================================================
set -u
IFS=$' \t\n'

# --- Cores ---
supports_color() {
    [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]
}

if supports_color; then
    GREEN=$'\033[0;32m'
    RED=$'\033[0;31m'
    YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'
    NC=$'\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    CYAN=''
    NC=''
fi

success_count=0
failure_count=0

print_divider() {
    echo -e "${CYAN}=====================================${NC}"
}

print_header() {
    print_divider
    echo -e "${GREEN}TESTANDO ESTRUTURA PROFISSIONAL MINIKUBE (LINUX)${NC}"
    print_divider
}

find_project_root() {
    local current_dir
    current_dir="$(dirname "$(readlink -f "$0")")"
    for _ in {1..10}; do
        if [[ -f "$current_dir/DECISIONS-HISTORY.md" && -d "$current_dir/minikube" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

PROJECT_ROOT=$(find_project_root || true)
if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "${RED}ERRO: Não foi possível detectar a pasta raiz do projeto.${NC}"
    exit 1
fi
MINIKUBE_PATH="$PROJECT_ROOT/minikube"

test_files() {
    local category="$1"
    local directory="$2"
    shift 2
    local files=("$@")

    echo -e "\n${YELLOW}Testando ${category}...${NC}"
    for file in "${files[@]}"; do
        local path
        if [[ -n "$directory" ]]; then
            path="$MINIKUBE_PATH/$directory/$file"
        else
            path="$MINIKUBE_PATH/$file"
        fi
        if [[ -e "$path" ]]; then
            echo -e "  ${GREEN}✅ $(basename "$file") encontrado${NC}"
            ((success_count++))
        else
            echo -e "  ${RED}❌ $(basename "$file") não encontrado em '$path'${NC}"
            ((failure_count++))
        fi
    done
}

test_root_files() {
    local category="$1"
    shift
    local files=("$@")

    echo -e "\n${YELLOW}Testando ${category}...${NC}"
    for file in "${files[@]}"; do
        local path="$PROJECT_ROOT/$file"
        if [[ -e "$path" ]]; then
            echo -e "  ${GREEN}✅ $(basename "$file") encontrado${NC}"
            ((success_count++))
        else
            echo -e "  ${RED}❌ $(basename "$file") não encontrado em '$path'${NC}"
            ((failure_count++))
        fi
    done
}

print_header

# Scripts Linux
test_files "Scripts de Inicialização (Linux)" "scripts/linux/init" \
    "init-minikube-fixed.sh" "apply-rabbitmq-config.sh"
test_files "Scripts de Manutenção (Linux)" "scripts/linux/maintenance" \
    "fix-dashboard.sh" "validate-rabbitmq-config.sh"
test_files "Scripts de Monitoramento (Linux)" "scripts/linux/monitoring" \
    "open-dashboard.sh" "change-dashboard-port.sh"
test_files "Scripts KEDA (Linux)" "scripts/linux/keda" \
    "install-helm-fixed.sh" "install-keda.sh" "test-keda.sh"
test_files "Scripts Autostart (Linux)" "scripts/linux/autostart" \
    "minikube-autostart.sh"
test_files "Script de Teste de Estrutura (Linux)" "" "linux-test-structure.sh"

# Estrutura comum
test_files "Configs KEDA" "configs/keda/examples" \
    "cpu-scaling-example.yaml" "memory-scaling-example.yaml" "rabbitmq-scaling-example.yaml"
test_files "Documentação" "docs" "README.md" "KEDA.md"
test_files "Documentação Fresh Machine" "docs/fresh-machine" \
    "SETUP.md" "DEMO.md" "CHECKLIST.md"

test_files "Scripts Windows essenciais" "scripts/windows" \
    "Setup-Fresh-Machine.ps1" "Bootstrap-DevOps.ps1"
test_files "Scripts Autostart (Windows)" "scripts/windows/autostart" \
    "minikube-autostart.bat"
test_files "Scripts Windows - Init" "scripts/windows/init" \
    "init-minikube-fixed.ps1" "apply-rabbitmq-config.ps1" "install-keda.ps1"
test_files "Scripts Windows - Manutenção" "scripts/windows/maintenance" \
    "fix-dashboard.ps1" "quick-status.ps1" "fix-kubectl-final.ps1" "validate-rabbitmq-config.ps1" "fix-dashboard-cronjob.ps1"
test_files "Scripts Windows - Monitoring" "scripts/windows/monitoring" \
    "open-dashboard.ps1" "change-dashboard-port.ps1"
test_files "Scripts Windows - KEDA" "scripts/windows/keda" \
    "install-helm-fixed.ps1" "install-helm.ps1" "install-keda.ps1" "test-keda.ps1"

# Helm Charts
echo -e "\n${YELLOW}Testando estrutura de Helm Charts...${NC}"
charts_path="$MINIKUBE_PATH/charts"
if [[ -d "$charts_path" ]]; then
    echo -e "  ${GREEN}✅ Pasta de charts encontrada${NC}"; ((success_count++))
    for chart in rabbitmq mongodb; do
        chart_path="$charts_path/$chart"
        if [[ -d "$chart_path" ]]; then
            echo -e "    ${GREEN}✅ Chart '${chart}' encontrado${NC}"; ((success_count++))
            if [[ -f "$chart_path/Chart.yaml" ]]; then
                echo -e "      ${GREEN}✅ Chart.yaml encontrado${NC}"; ((success_count++))
            else
                echo -e "      ${RED}❌ Chart.yaml ausente${NC}"; ((failure_count++))
            fi
            if [[ -f "$chart_path/values.yaml" ]]; then
                echo -e "      ${GREEN}✅ values.yaml encontrado${NC}"; ((success_count++))
            else
                echo -e "      ${RED}❌ values.yaml ausente${NC}"; ((failure_count++))
            fi
            if [[ -d "$chart_path/templates" ]]; then
                echo -e "      ${GREEN}✅ Pasta templates encontrada${NC}"; ((success_count++))
            else
                echo -e "      ${RED}❌ Pasta templates ausente${NC}"; ((failure_count++))
            fi
        else
            echo -e "    ${RED}❌ Chart '${chart}' não encontrado${NC}"; ((failure_count++))
        fi
    done
else
    echo -e "  ${RED}❌ Pasta de charts não encontrada${NC}"; ((failure_count++))
fi

# Arquivos na raiz
test_root_files "Checklists e Históricos" \
    "STRUCTURE-UPDATES-CHECKLIST.md" "MANDATORY-CHECKLIST.md" "DECISIONS-HISTORY.md" \
    "DYNAMIC-PATHS.md" "MINIKUBE-PROJECT-HISTORY.md" "CONTINUITY-PROMPT.md" "BACKUP-PROMPT.md"

print_divider

total_checks=$((success_count + failure_count))
if [[ $failure_count -eq 0 ]]; then
    echo -e "${GREEN}✅ SUCESSO! Estrutura completa e consistente.${NC}"
else
    echo -e "${RED}❌ FALHA! Foram encontrados ${failure_count} problemas na estrutura.${NC}"
fi

echo -e "${CYAN}Total de verificações: ${total_checks} | Sucessos: ${success_count} | Falhas: ${failure_count}${NC}"
print_divider

echo -e "\n${YELLOW}Próximos passos sugeridos:${NC}"
echo -e "1. ${GREEN}Inicializar ambiente:${NC} bash $MINIKUBE_PATH/scripts/linux/autostart/minikube-autostart.sh"
echo -e "2. ${GREEN}Abrir Dashboard:${NC}     bash $MINIKUBE_PATH/scripts/linux/monitoring/open-dashboard.sh"
echo -e "3. ${GREEN}Consultar docs:${NC}      cat $MINIKUBE_PATH/docs/README.md"

echo -e "\n${GREEN}Teste concluído!${NC}"
