
# Scripts macOS para Automação do Minikube

Este diretório contém todos os scripts necessários para provisionar, validar, manter e monitorar um ambiente DevOps local com Minikube no macOS.

## 🍎 Pré-requisitos

- macOS 12 (Monterey) ou superior
- [Homebrew](https://brew.sh) (será instalado automaticamente pelo setup)

## 🚀 Setup para Máquina Nova (macOS)

### Opção 1: Bootstrap Completo (Recomendado)

```bash
# Download automático do projeto + instalação de dependências + inicialização
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/macOs/bootstrap-devops.sh | bash
```

### Opção 2: Setup Local (Se já tem o projeto)

```bash
# Navegar para a pasta do projeto
cd /caminho/para/projeto/DevOps

# Instalar dependências e inicializar
bash scripts/macOs/setup-fresh-machine.sh --run-initialization
```

### Opção 3: Só Dependências (Sem inicialização)

```bash
# Instalar Homebrew, Docker Desktop, Minikube, kubectl, Helm
bash scripts/macOs/setup-fresh-machine.sh
```


## Estrutura dos Diretórios

```text
scripts/macOs/
├── setup-fresh-machine.sh       # Setup completo para máquina nova
├── bootstrap-devops.sh          # Bootstrap com download do projeto
├── autostart/
│   └── minikube-autostart.sh    # Prompt driver + inicialização
├── drivers/
│   ├── containers/
│   │   └── docker-prep.sh       # Instala/verifica Docker Desktop
│   └── hypervisors/
│       └── hyperkit-prep.sh     # Instala/verifica Hyperkit
├── init/
│   └── init-minikube-fixed.sh   # Inicialização completa do cluster
├── keda/
│   ├── install-helm-fixed.sh    # Instalação robusta do Helm
│   ├── install-keda.sh          # Instalação do KEDA
│   └── test-keda.sh             # Validação do KEDA
├── maintenance/
│   ├── fix-dashboard.sh         # Corrige problemas do Dashboard
│   ├── validate-rabbitmq-config.sh
│   └── placeholder.sh
└── monitoring/
    ├── open-dashboard.sh         # Abre Dashboard no navegador
    ├── change-dashboard-port.sh
    └── placeholder.sh
```

## Diferenças em relação ao Linux

| Linux | macOS |
|-------|-------|
| `apt-get` | `brew` |
| `systemctl` (Docker) | Docker Desktop app |
| `kvm2` driver | `hyperkit` driver |
| `xdg-open` | `open` |
| `ss -tulwn` | `lsof -i :PORT` |
| `/etc/os-release` | `sw_vers` |

## Scripts Principais

### `setup-fresh-machine.sh`
- Instala Homebrew se ausente
- Instala Docker Desktop, Minikube, kubectl, Helm via `brew`
- Verifica macOS 12+
- Parâmetros: `--skip-docker`, `--skip-minikube`, `--skip-kubectl`, `--skip-helm`, `--run-initialization`

### `bootstrap-devops.sh`
- Bootstrap completo: download do projeto + setup + inicialização
- Clone via Git ou download ZIP como fallback
- Parâmetros: `--project-path`, `--skip-setup`, `--skip-init`

### `autostart/minikube-autostart.sh`
- Prompt para driver: **docker** (padrão) ou **hyperkit**
- Configura CPUs e memória para o Minikube
- Encaminha para `init/init-minikube-fixed.sh --install-keda`

### `init/init-minikube-fixed.sh`
- Inicialização completa do cluster com Helm charts locais
- Habilita addons essenciais, cria port-forwards
- Parâmetros: `--install-keda`, `--skip-keda`, `--skip-addons`, `--skip-rabbitmq-config`

## Exemplos de Execução

```bash
# Inicializar ambiente completo
bash autostart/minikube-autostart.sh

# Instalar KEDA separadamente
bash keda/install-keda.sh

# Abrir Dashboard
bash monitoring/open-dashboard.sh

# Validar estrutura
bash ../../macos-test-structure.sh
```

## Endpoints após Inicialização

- **RabbitMQ Management**: http://localhost:15672 (guest/guest)
- **RabbitMQ AMQP**: amqp://guest:guest@localhost:5672
- **MongoDB**: mongodb://admin:admin@localhost:27017/admin
- **Redis**: redis://localhost:30679
- **Kubernetes Dashboard**: http://localhost:15671

> Os logs gerados pelos scripts de inicializacao sao registrados em `log/` (com fallback para `${TMPDIR:-/tmp}/minikube-log`).
