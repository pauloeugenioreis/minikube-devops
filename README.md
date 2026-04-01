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
├── configs/                     # Configurações KEDA e exemplos
├── docs/                        # Documentação completa
│   ├── README.md                # Este guia principal
│   └── KEDA.md                  # KEDA: autoscaling orientado a eventos
├── scripts/
│   ├── windows/                 # Scripts PowerShell
│   │   ├── init/                # Rotinas de inicialização e autostart
│   │   ├── maintenance/         # Ferramentas de correção (dashboard, lints)
│   │   ├── Setup-Fresh-Machine.ps1 # Download e setup inicial de ambiente
│   │   ├── test-structure.ps1   # Valida integridade das pastas no Windows
│   │   └── README.md
│   ├── linux/                   # Scripts Bash (Ubuntu/Debian)
│   │   ├── init/                # Configurações interativas (Docker/KVM2) e start
│   │   ├── maintenance/         # Fix de dashboard e logs de status
│   │   ├── setup-fresh-machine.sh # Dependencias via apt-get e curl
│   │   └── README.md
│   └── macOs/                   # Scripts Bash (macOS via Homebrew)
│       ├── init/                # Start focado em Docker nativo e QEMU2
│       ├── maintenance/         # Verificações de portas vitais
│       ├── setup-fresh-machine.sh # Dependencias via Homebrew
│       └── README.md
├── init-minikube-windows.ps1    # Atalho root para Windows
├── init-minikube-linux.sh       # Atalho root para Linux
├── init-minikube-macos.sh       # Atalho root para macOS
└── . (demais arquivos e pastas)
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
