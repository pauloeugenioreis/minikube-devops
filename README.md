# Minikube DevOps Environment

Ambiente profissional para desenvolvimento, testes e automação DevOps local usando Minikube, RabbitMQ, MongoDB, Redis e KEDA. Scripts prontos para **Windows**, **Linux** e **macOS**.

Professional environment for local DevOps automation, development, and testing with Minikube, RabbitMQ, MongoDB, Redis, and KEDA. Scripts provided for **Windows**, **Linux**, and **macOS**.

---

## Visão Geral | Overview

- Automação completa do setup Kubernetes local com Minikube
- Menu interativo unificado (Windows, Linux, macOS) para escolha de driver virtualizador, CPU e Memória
- RabbitMQ, MongoDB e Redis configurados automaticamente com persistência de dados
- KEDA para autoscaling baseado em eventos (RabbitMQ, CPU, memória, etc.)
- Scripts PowerShell e Bash para inicialização, manutenção e monitoramento
- Workloads entregues como Helm charts para instalações reproduzíveis

---

## Estrutura do Projeto | Project Structure

```
minikube-devops/
├── charts/                      # Helm charts (RabbitMQ, MongoDB, Redis)
├── configs/                     # Configurações KEDA e exemplos de escalonamento
├── docs/                        # Documentação completa e assets
├── scripts/
│   ├── windows/                 # Scripts PowerShell
│   │   ├── init/                # Rotinas de inicialização e autostart
│   │   ├── keda/                # Instaladores e validadores do KEDA
│   │   ├── maintenance/         # Ferramentas de correção (dashboard, lints)
│   │   ├── monitoring/          # Scripts para abrir métricas e dashboard
│   │   ├── utils/               # Bibliotecas globais DRy
│   │   ├── Bootstrap-DevOps.ps1 # Instalador all-in-one para Windows
│   │   ├── Setup-Fresh-Machine.ps1 # Executa o setup das ferramentas
│   │   ├── test-structure.ps1   # Valida integridade das pastas no Windows
│   │   └── README.md
│   ├── linux/                   # Scripts Bash (Ubuntu/Debian)
│   │   ├── drivers/             # Validadores de virtualização nativa
│   │   ├── init/                # Configurações interativas (Docker/KVM2) e start
│   │   ├── keda/                # Instaladores e validadores do KEDA
│   │   ├── maintenance/         # Fix de dashboard e logs de status
│   │   ├── utils/               # Bibliotecas globais DRy
│   │   ├── bootstrap-devops.sh  # Instalador all-in-one para Ubuntu/Debian
│   │   ├── setup-fresh-machine.sh # Dependencias via apt-get e curl
│   │   └── README.md
│   └── macOs/                   # Scripts Bash (macOS via Homebrew)
│       ├── drivers/             # Validadores de virtualização nativa
│       ├── init/                # Start focado em Docker nativo e QEMU2
│       ├── keda/                # Instaladores e validadores do KEDA
│       ├── maintenance/         # Verificações de portas vitais
│       ├── utils/               # Bibliotecas globais DRy
│       ├── bootstrap-devops.sh  # Instalador all-in-one para macOS via curl
│       ├── setup-fresh-machine.sh # Dependencias via Homebrew
│       └── README.md
├── init-minikube-windows.ps1    # Atalho root para Windows
├── init-minikube-linux.sh       # Atalho root para Linux
└── init-minikube-macos.sh       # Atalho root para macOS
```

---

## Como Usar | How to Use

### 1. Clonar o repositório | Clone the repository
```bash
git clone https://github.com/pauloeugenioreis/minikube-devops.git
cd minikube-devops
```

### 2. Escolher a plataforma | Choose your platform

#### 🪟 Windows
```powershell
# Bootstrap completo (recomendado)
.\scripts\windows\Bootstrap-DevOps.ps1

# Ou inicialização direta
.\scripts\windows\init\start.ps1
```

#### 🐧 Linux (Ubuntu/Debian)
```bash
# Inicialização direta
./init-minikube-linux.sh
```

#### 🍎 macOS
```bash
# Inicialização direta
./init-minikube-macos.sh
```

---

## Endpoints após inicialização | Endpoints after init

| Serviço | URL / Endereço | Credenciais |
|---|---|---|
| RabbitMQ Management | http://localhost:15672 | guest / guest |
| RabbitMQ AMQP | amqp://localhost:5672 | guest / guest |
| MongoDB | mongodb://localhost:27017/admin | admin / admin |
| Redis | redis://localhost:30679 | — |
| Kubernetes Dashboard | http://localhost:15671 | — |

> **Segurança:** As credenciais acima são padrões para desenvolvimento local. Consulte [docs/README.md](docs/README.md#segurança-e-credenciais) para instruções de como alterá-las antes de usar em ambientes compartilhados.

---

## Makefile (Linux / macOS)

Atalho para os comandos mais usados. Rode `make help` para ver tudo disponível.

```bash
make start-linux        # inicia o ambiente no Linux
make start-macos        # inicia o ambiente no macOS
make status             # status do cluster e pods
make stop               # para o Minikube
make clean              # deleta o cluster (irreversível)

make install-linux      # instala dependências no Linux
make install-macos      # instala dependências no macOS

make keda-linux         # instala KEDA (Linux)
make keda-macos         # instala KEDA (macOS)

make shellcheck         # roda ShellCheck em todos os scripts .sh
make pre-commit-install # instala hook de validação pré-commit
```

---

## Verificar estrutura | Validate structure
 *(Ferramenta diagnostica nativa do Windows)*

```powershell
# Windows
.\scripts\windows\test-structure.ps1
```

---

## Documentação | Documentation

| Arquivo | Conteúdo |
|---|---|
| [docs/README.md](docs/README.md) | Guia detalhado por plataforma |
| [docs/KEDA.md](docs/KEDA.md) | Autoscaling orientado a eventos |
| [scripts/windows/README.md](scripts/windows/README.md) | Referência dos scripts Windows |
| [scripts/linux/README.md](scripts/linux/README.md) | Referência dos scripts Linux |
| [scripts/macOs/README.md](scripts/macOs/README.md) | Referência dos scripts macOS |

---

## Licença | License

Este projeto é aberto para uso pessoal ou profissional.
This project is open for personal or commercial usage.

---

## Imagens do Projeto

<p align="center">
  <img src="docs/assets/1.png" alt="Imagem 1" width="600" />
  <img src="docs/assets/2.png" alt="Imagem 2" width="600" />
  <img src="docs/assets/3.png" alt="Imagem 3" width="600" />
  <img src="docs/assets/4.png" alt="Imagem 4" width="600" />
  <img src="docs/assets/5.png" alt="Imagem 5" width="600" />
  <img src="docs/assets/6.png" alt="Imagem 6" width="600" />
  <img src="docs/assets/7.png" alt="Imagem 7" width="600" />
  <img src="docs/assets/8.png" alt="Imagem 8" width="600" />
  <img src="docs/assets/9.png" alt="Imagem 9" width="600" />
</p>
