#!/usr/bin/env bash
# test-keda.sh - Testa e valida a instalacao do KEDA no macOS
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}=====================================================${NC}"
echo -e "${GREEN}Teste de Instalacao KEDA - macOS${NC}"
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
check "kubectl disponivel" "command -v kubectl"
check "helm disponivel" "command -v helm"
check "minikube disponivel" "command -v minikube"
check "Minikube rodando" "minikube status 2>/dev/null | grep -q Running"

echo -e "\n${YELLOW}2. Verificando KEDA...${NC}"
check "Namespace keda existe" "kubectl get namespace keda"
check "CRD scaledobjects.keda.sh" "kubectl get crd scaledobjects.keda.sh"
check "CRD scaledjobs.keda.sh" "kubectl get crd scaledjobs.keda.sh"
check "CRD triggerauthentications.keda.sh" "kubectl get crd triggerauthentications.keda.sh"
check "CRD clustertriggerauthentications.keda.sh" "kubectl get crd clustertriggerauthentications.keda.sh"

echo -e "\n${YELLOW}3. Verificando pods KEDA...${NC}"
check "Deployment keda-operator existe" "kubectl get deployment keda-operator -n keda"
check "Deployment keda-admission-webhooks existe" "kubectl get deployment keda-admission-webhooks -n keda"
check "Deployment keda-operator-metrics-apiserver existe" "kubectl get deployment keda-operator-metrics-apiserver -n keda"

echo -e "\n${WHITE}Status dos pods KEDA:${NC}"
kubectl get pods -n keda 2>/dev/null || echo -e "${YELLOW}   Nao foi possivel listar pods KEDA${NC}"

echo -e "\n${CYAN}=====================================================${NC}"
echo -e "Resultado: ${GREEN}${pass} ok${NC} / ${RED}${fail} falha(s)${NC}"
echo -e "${CYAN}=====================================================${NC}"

if [[ $fail -eq 0 ]]; then
    echo -e "${GREEN}✅ KEDA validado com sucesso!${NC}"
    exit 0
else
    echo -e "${RED}❌ Falhas detectadas na validacao do KEDA.${NC}"
    exit 1
fi
