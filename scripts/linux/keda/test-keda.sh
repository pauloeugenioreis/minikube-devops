#!/usr/bin/env bash
# test-keda.sh - Testa e valida a instalacao do KEDA no Linux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/common.sh"

echo -e "\n${CYAN}=====================================================${NC}"
echo -e "${GREEN}Teste de Instalacao KEDA - Linux${NC}"
echo -e "${CYAN}=====================================================${NC}"

pass=0
fail=0

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ ${desc}${NC}"
        ((pass++))
    else
        echo -e "${RED}   ❌ ${desc}${NC}"
        ((fail++))
    fi
}

echo -e "\n${YELLOW}1. Verificando prerequisitos...${NC}"
check "kubectl disponivel" "command_exists kubectl"
check "helm disponivel" "command_exists helm"
check "minikube disponivel" "command_exists minikube"
check "Minikube rodando" "minikube status | grep -q Running"

echo -e "\n${YELLOW}2. Verificando KEDA...${NC}"
check "Namespace keda existe" "kubectl get namespace keda"
check "CRD scaledobjects.keda.sh" "kubectl get crd scaledobjects.keda.sh"
check "CRD scaledjobs.keda.sh" "kubectl get crd scaledjobs.keda.sh"
check "CRD triggerauthentications.keda.sh" "kubectl get crd triggerauthentications.keda.sh"

echo -e "\n${YELLOW}3. Verificando pods KEDA...${NC}"
check "Deployment keda-operator existe" "kubectl get deployment keda-operator -n keda"
check "Deployment keda-admission-webhooks existe" "kubectl get deployment keda-admission-webhooks -n keda"
check "Deployment keda-operator-metrics-apiserver existe" "kubectl get deployment keda-operator-metrics-apiserver -n keda"

echo -e "\n${WHITE}Status dos pods KEDA:${NC}"
kubectl get pods -n keda --no-headers | awk '{printf "  %-40s %s\n", $1, $3}'

echo -e "\n${CYAN}=====================================================${NC}"
echo -e "Resultado: ${GREEN}${pass} ok${NC} / ${RED}${fail} falha(s)${NC}"
echo -e "${CYAN}=====================================================${NC}"

if [[ $fail -eq 0 ]]; then
    log_success "KEDA validado com sucesso!"
    exit 0
else
    log_error "Falhas detectadas na validacao do KEDA."
    exit 1
fi
