# Scripts Linux para Automação do Minikube

Este diretório contém a suíte de automação para sistemas Linux (Ubuntu 18.04+). A estrutura foi refatorada para seguir padrões consistentes de nomenclatura e modularidade.

## 🚀 Como Iniciar

### 1. Preparar a Máquina (Novos usuários)
Instala Docker, Minikube, kubectl e Helm automaticamente.
```bash
# Setup inicial
bash scripts/linux/setup-fresh-machine.sh --run-initialization

# Forçar atualização das ferramentas para as versões mais recentes
bash scripts/linux/setup-fresh-machine.sh --force-update
```

### 2. Inicializar o Ambiente
Use o atalho na raiz do projeto ou o script de inicialização.
```bash
# Atalho na raiz
./init-minikube-linux.sh

# Script direto
bash scripts/linux/init/start.sh
```

## 🛠️ Manutenção e Diagnóstico

Temos scripts dedicados para verificar a saúde do ambiente:

- **Status Rápido**: `bash scripts/linux/maintenance/status.sh`
- **Corrigir Dashboard**: `bash scripts/linux/maintenance/dashboard.sh`
- **Testar RabbitMQ**: `bash scripts/linux/maintenance/test-rabbitmq.sh`

---

## Estrutura de Arquivos

```text
scripts/linux/
├── setup-fresh-machine.sh   # Instalador de dependências e setup inicial
├── utils/
│   └── common.sh            # Lógica compartilhada (LOGS, Emojis, Paths)
├── init/
│   └── start.sh             # Orquestrador de inicialização do cluster
├── maintenance/
│   ├── status.sh            # Verificação de saúde do ambiente
│   ├── dashboard.sh         # Correção de RBAC e Port-Forward do Dashboard
│   └── test-rabbitmq.sh     # Validação de filas e status do RabbitMQ
└── keda/
    └── install-keda.sh      # Instalador automatizado do KEDA
```

## Requisitos Mínimos
- **Ubuntu**: 18.04+
- **Minikube**: v1.38+
- **kubectl**: v1.35+
- **Docker**: Engine mais recente disponível

---
> [!TIP]
> Os logs de inicialização são salvos em `log/` na raiz do projeto para facilitar a depuração.
