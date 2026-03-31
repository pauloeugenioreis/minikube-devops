# Scripts macOS para Automação do Minikube

Este diretório contém a suíte de automação para macOS (v12 Monterey ou superior).

## 🚀 Como Iniciar

### 1. Preparar a Máquina (Novos usuários)
Usa Homebrew para instalar Docker Desktop, Minikube, kubectl e Helm.
```bash
# Setup inicial
bash scripts/macOs/setup-fresh-machine.sh --run-initialization

# Forçar atualização das ferramentas (brew upgrade)
bash scripts/macOs/setup-fresh-machine.sh --force-update
```

### 2. Inicializar o Ambiente
Use o atalho na raiz do projeto ou o script de inicialização.
```bash
# Atalho na raiz
./init-minikube-macos.sh

# Script direto
bash scripts/macOs/init/start.sh
```

## 🛠️ Manutenção e Diagnóstico

- **Status Rápido**: `bash scripts/macOs/maintenance/status.sh`
- **Corrigir Dashboard**: `bash scripts/macOs/maintenance/dashboard.sh`
- **Testar RabbitMQ**: `bash scripts/macOs/maintenance/test-rabbitmq.sh`

---

## Estrutura de Arquivos

```text
scripts/macOs/
├── setup-fresh-machine.sh   # Instalador via Homebrew
├── utils/
│   └── common.sh            # Lógica compartilhada (LOGS, Emojis, Paths)
├── init/
│   └── start.sh             # Orquestrador de inicialização do cluster
├── maintenance/
│   ├── status.sh            # Verificação de saúde do ambiente
│   ├── dashboard.sh         # Correção de problemas do Dashboard
│   └── test-rabbitmq.sh     # Validação do RabbitMQ
└── keda/
    └── install-keda.sh      # Instalador automatizado do KEDA
```

## Requisitos Mínimos
- **macOS**: v12+ (Monterey)
- **Homebrew**: Instalado (o script tenta instalar se estiver ausente)
- **Minikube**: v1.38+
- **kubectl**: v1.35+

---
> [!IMPORTANT]
> Garanta que o **Docker Desktop** esteja aberto e o ícone na barra de tarefas esteja verde antes de rodar os scripts de inicialização.
