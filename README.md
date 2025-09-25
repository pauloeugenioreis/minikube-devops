# Minikube DevOps Environment

Ambiente profissional para desenvolvimento, testes e automação DevOps local usando Minikube, RabbitMQ, MongoDB e KEDA, com scripts prontos para Windows e Linux.

Professional environment for local DevOps automation, development and testing using Minikube, RabbitMQ, MongoDB and KEDA, with ready-to-use scripts for Windows and Linux.

---

## 🇧🇷 Visão Geral
- **Automação completa** do setup de ambiente Kubernetes local com Minikube
- **RabbitMQ** e **MongoDB** configurados automaticamente com persistência de dados
- **KEDA** para autoscaling de workloads baseado em eventos (RabbitMQ, CPU, memória, etc.)
- **Scripts PowerShell e Bash** para inicialização, manutenção, monitoramento e troubleshooting
- **Estrutura profissional**: separação entre desenvolvimento (`temp/`) e produção (`minikube/`)
- **Versionamento obrigatório**: integração contínua com GitHub

## 🇺🇸 Overview
- **Full automation** of local Kubernetes environment setup with Minikube
- **RabbitMQ** and **MongoDB** automatically configured with data persistence
- **KEDA** for event-driven autoscaling (RabbitMQ, CPU, memory, etc.)
- **PowerShell and Bash scripts** for initialization, maintenance, monitoring and troubleshooting
- **Professional structure**: separation between development (`temp/`) and production (`minikube/`)
- **Mandatory versioning**: continuous integration with GitHub

---

## 🇧🇷 Estrutura do Projeto | 🇺🇸 Project Structure
```
DevOps/
├── temp/                  # Área de desenvolvimento | Development area
├── minikube/              # Estrutura principal     | Main structure
│   ├── configs/           # Configurações Kubernetes (YAML)
│   ├── docs/              # Documentação detalhada  | Documentation
│   ├── scripts/           # Scripts Windows e Linux | Scripts
│   └── windows-test-structure.ps1 # Teste de estrutura | Structure test
├── CHECKLIST-OBRIGATORIO.md # Checklist obrigatório | Mandatory checklist
├── CONVERSAS-E-DECISOES.md   # Histórico de decisões | Decisions history
└── ...
```

---

## 🇧🇷 Como Usar | 🇺🇸 How to Use
1. **Clone o repositório | Clone the repository:**
   ```
   git clone https://github.com/pauloeugenioreis/minikube-devops.git
   ```
2. **Siga o `CHECKLIST-OBRIGATORIO.md` para qualquer alteração**
   **Follow `CHECKLIST-OBRIGATORIO.md` for any change**
3. **Inicialize o ambiente | Initialize the environment:**
   - Windows: execute os scripts em | run scripts in `minikube/scripts/windows/init/`
   - Linux: utilize os scripts em | use scripts in `minikube/scripts/linux/`
4. **Configure autostart (opcional) | (Optional) Set up autostart:**
   - Copie o `.bat` desejado para a pasta de inicialização do Windows
   - Copy the desired `.bat` to Windows startup folder
5. **Consulte a documentação | See documentation** em/in `minikube/docs/` para detalhes, troubleshooting e exemplos | for details, troubleshooting and examples

---


## 🇧🇷 Principais Comandos | 🇺🇸 Main Commands

### 🪟 Windows
- Inicialização completa (Windows) | Full initialization (Windows):
  ```powershell
  .\minikube\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda
  ```
- Teste de estrutura | Structure test:
  ```powershell
  .\minikube\windows-test-structure.ps1
  ```
- Verificar status | Check status:
  ```powershell
  .\minikube\scripts\windows\maintenance\quick-status.ps1
  ```

### 🐧 Linux
- Inicialização completa (Linux) | Full initialization (Linux):
  ```bash
  bash minikube/scripts/linux/init-minikube.sh
  ```
- Teste de estrutura | Structure test:
  ```bash
  bash minikube/scripts/linux/linux-test-structure.sh
  ```
- Verificar status | Check status:
  ```bash
  bash minikube/scripts/linux/quick-status.sh
  ```

---

## 🇧🇷 Documentação | 🇺🇸 Documentation
- [CHECKLIST-OBRIGATORIO.md](CHECKLIST-OBRIGATORIO.md): Checklist obrigatório | Mandatory checklist
- [minikube/docs/README.md](minikube/docs/README.md): Documentação detalhada | Detailed documentation
- [CONVERSAS-E-DECISOES.md](CONVERSAS-E-DECISOES.md): Histórico de decisões | Decisions history

---

## 🇧🇷 Versionamento | 🇺🇸 Versioning
- Todo o projeto é versionado no GitHub | All project is versioned on GitHub
- Sempre use | Always use:
  ```
  git add .
  git commit -m "mensagem | message"
  git push
  ```
  após qualquer alteração | after any change

---

## 🇧🇷 Licença | 🇺🇸 License
Este projeto é aberto e pode ser utilizado por qualquer pessoa, para fins pessoais ou profissionais.
This project is open and can be used by anyone, for personal or professional purposes.
