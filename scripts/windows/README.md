# Scripts Windows para Automação do Minikube

Este diretório contém todos os scripts PowerShell para provisionar, validar, manter e monitorar um ambiente DevOps local com Minikube no Windows.

## 🪟 Pré-requisitos

- Windows 10/11
- PowerShell 5.1+
- Docker Desktop instalado e em execução
- Privilégios de administrador (para edição de hosts e instalação de dependências)

---

## 🚀 Setup para Máquina Nova (Windows)

### Opção 1: Bootstrap Completo (Recomendado)

```powershell
# Na pasta raiz do projeto
.\scripts\windows\Bootstrap-DevOps.ps1
```

### Opção 2: Só Dependências (Sem inicialização)

```powershell
.\scripts\windows\Setup-Fresh-Machine.ps1
```

### Opção 3: Inicialização Direta

```powershell
.\scripts\windows\init\start.ps1
```

---

## Estrutura dos Diretórios

```text
scripts/windows/
├── Bootstrap-DevOps.ps1          # Bootstrap: download + setup + init
├── Setup-Fresh-Machine.ps1       # Instala Docker, Minikube, kubectl, Helm
├── test-structure.ps1            # Valida estrutura no Windows
├── init/
│   ├── start.ps1                 # Inicialização completa do cluster
│   └── set-rabbitmq.ps1          # Aplica configurações RabbitMQ
├── keda/
│   ├── install-helm.ps1          # Instalação robusta do Helm
│   ├── install-keda.ps1          # Instalação standalone do KEDA
│   └── test-keda.ps1             # Testa e valida o KEDA
├── maintenance/
│   ├── dashboard.ps1             # Corrige problemas do Dashboard e Erros 404
│   ├── kubectl.ps1               # Corrige incompatibilidades do kubectl
│   ├── status.ps1                # Status rápido do ambiente
│   └── test-rabbitmq.ps1         # Valida configuração do RabbitMQ
├── monitoring/
│   ├── dashboard-open.ps1        # Abre o Kubernetes Dashboard
│   └── dashboard-port.ps1        # Altera a porta do Dashboard
└── utils/
    └── common.ps1                # Sistema de paths e logs dinâmicos
```

---

## Scripts Principais

### `Bootstrap-DevOps.ps1`
Bootstrap completo: valida/instala dependências + inicializa o ambiente.
```powershell
.\scripts\windows\Bootstrap-DevOps.ps1

# Pular etapas
.\scripts\windows\Bootstrap-DevOps.ps1 -SkipSetup
.\scripts\windows\Bootstrap-DevOps.ps1 -SkipInit
```

### `Setup-Fresh-Machine.ps1`
Instala todas as dependências (Docker Desktop, Minikube, kubectl, Helm).
```powershell
.\scripts\windows\Setup-Fresh-Machine.ps1

# Com inicialização automática após setup
.\scripts\windows\Setup-Fresh-Machine.ps1 -RunInitialization

# Pular etapas específicas
.\scripts\windows\Setup-Fresh-Machine.ps1 -SkipDockerInstall
.\scripts\windows\Setup-Fresh-Machine.ps1 -SkipMinikubeInstall -SkipHelm
```

### `init/start.ps1`
Inicialização completa do cluster: addons, charts Helm, port-forwards, KEDA.
```powershell
# Com KEDA (padrão)
.\scripts\windows\init\start.ps1

# Sem KEDA
.\scripts\windows\init\start.ps1 -InstallKeda:$false

# Com driver personalizado
.\scripts\windows\init\start.ps1 -Driver hyperv -Cpus 6 -Memory 12g
```



---

## Ferramentas de Manutenção e Monitoramento

```powershell
# Status rápido do ambiente
.\scripts\windows\maintenance\status.ps1

# Abrir Dashboard Kubernetes
.\scripts\windows\monitoring\dashboard-open.ps1

# Corrigir Dashboard que não abre e erros 404
.\scripts\windows\maintenance\dashboard.ps1

# Corrigir incompatibilidade do kubectl
.\scripts\windows\maintenance\kubectl.ps1

# Validar configuração RabbitMQ
.\scripts\windows\maintenance\test-rabbitmq.ps1
```

---

## Endpoints após Inicialização

| Serviço | URL / Endereço | Credenciais |
|---|---|---|
| RabbitMQ Management | http://localhost:15672 | guest / guest |
| RabbitMQ AMQP | amqp://localhost:5672 | guest / guest |
| MongoDB | mongodb://localhost:27017/admin | admin / admin |
| Redis | redis://localhost:30679 | — |
| Kubernetes Dashboard | http://localhost:15671 | — |

---

## Troubleshooting

- **Docker não inicia?** Os scripts verificam e aguardam o daemon automaticamente.
- **Dashboard não abre ou CronJob não carrega?** Use `dashboard.ps1`.
- **kubectl com versão incompatível?** Use `kubectl.ps1`.
- **KEDA com erro?** Verifique com `.\scripts\windows\keda\test-keda.ps1`.
- **Reset completo?** `minikube delete --all --purge` e execute `start.ps1` novamente.

> Consulte [`docs/README.md`](../../docs/README.md) para guias mais detalhados.
