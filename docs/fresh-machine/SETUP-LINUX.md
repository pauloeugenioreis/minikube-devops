
# Fresh Machine Setup - DevOps Minikube Environment (Linux Ubuntu)

**Sistema de instalação completa para máquina nova Linux Ubuntu**  
*Zero to Running - Instalação automatizada do ambiente DevOps*

## 📣 Visão Geral

Este sistema permite configurar automaticamente um ambiente completo de desenvolvimento DevOps com Minikube em uma máquina Linux Ubuntu nova, instalando todas as dependências necessárias sem intervenção manual. **O projeto é transferido via pasta local (USB/rede/OneDrive) ou clone Git.**

### Componentes Principais

- **setup-fresh-machine.sh**: Script principal de instalação de dependências
- **bootstrap-devops.sh**: Script de bootstrap completo (download do projeto + setup)
- **Detecção automática**: Sistema de paths dinâmicos integrado
- **Scripts de inicialização**: Automação completa do ambiente

## 🚀 Uso Rápido

### Opção 1: Bootstrap Completo (Máquina Nova)

Para máquina completamente nova, sem o projeto:

```bash
# Download automático + instalação + inicialização
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/linux/bootstrap-devops.sh | bash

# Ou com customização de pasta
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/linux/bootstrap-devops.sh | bash -s -- --project-path /opt/devops
```

### OpÃ§Ã£o 2: Setup Local (Projeto Existente)
Se jÃ¡ possui o projeto baixado:

```bash
# Navegar para a pasta do projeto
cd "/caminho/para/projeto/DevOps"

# Executar setup com inicializaÃ§Ã£o
bash scripts/linux/setup-fresh-machine.sh --run-initialization

# Ou sem inicializaÃ§Ã£o automÃ¡tica
bash scripts/linux/setup-fresh-machine.sh
```

### OpÃ§Ã£o 3: TransferÃªncia Manual + Bootstrap
Para transferÃªncia via USB/rede:

```bash
# 1. Copiar pasta completa via USB/rede para a nova mÃ¡quina
# 2. Navegar para a pasta copiada
cd "/home/usuario/DevOps"  # ou onde vocÃª copiou o projeto

# 3. Executar setup local
bash scripts/linux/setup-fresh-machine.sh --run-initialization
```

## ðŸ“¦ DependÃªncias Instaladas

### Automaticamente Instaladas
- **Docker**: Container runtime (via repositÃ³rio oficial)
- **Minikube**: Kubernetes local (Ãºltima versÃ£o)
- **kubectl**: Cliente Kubernetes (versÃ£o compatÃ­vel)
- **Helm**: Gerenciador de pacotes Kubernetes (Ãºltima versÃ£o)

### PrÃ©-requisitos Verificados
- Ubuntu 18.04+ (verificaÃ§Ã£o automÃ¡tica, suporte a derivados)
- PrivilÃ©gios sudo (elevaÃ§Ã£o automÃ¡tica quando necessÃ¡rio)
- Conectividade com internet (para downloads)
- Grupo docker (configuraÃ§Ã£o automÃ¡tica)

## âš™ï¸ ParÃ¢metros de ConfiguraÃ§Ã£o

### setup-fresh-machine.sh

```bash
# Pular instalaÃ§Ãµes especÃ­ficas
bash setup-fresh-machine.sh --skip-docker
bash setup-fresh-machine.sh --skip-minikube
bash setup-fresh-machine.sh --skip-kubectl
bash setup-fresh-machine.sh --skip-helm

# Pular validaÃ§Ã£o final
bash setup-fresh-machine.sh --skip-validation

# Executar inicializaÃ§Ã£o automÃ¡tica apÃ³s setup
bash setup-fresh-machine.sh --run-initialization

# CombinaÃ§Ãµes
bash setup-fresh-machine.sh --skip-docker --run-initialization
```

### bootstrap-devops.sh

```bash
# Customizar localizaÃ§Ã£o do projeto
bash bootstrap-devops.sh --project-path "/opt/devops"

# Pular etapas especÃ­ficas
bash bootstrap-devops.sh --skip-setup
bash bootstrap-devops.sh --skip-init
bash bootstrap-devops.sh --skip-setup --skip-init

# Ver ajuda
bash bootstrap-devops.sh --help
```

## ðŸ”§ Processo de InstalaÃ§Ã£o Detalhado

### 1. VerificaÃ§Ã£o Inicial
- âœ… VersÃ£o do Ubuntu (18.04+ required, derivados aceitos com aviso)
- âœ… PrivilÃ©gios sudo (solicitaÃ§Ã£o automÃ¡tica quando necessÃ¡rio)
- âœ… Conectividade com internet (para downloads das dependÃªncias)
- âœ… Comandos base: curl, wget, apt-get

### 2. PreparaÃ§Ã£o do Ambiente
- ðŸ“ AtualizaÃ§Ã£o do sistema (`apt-get update`)
- ðŸ› ï¸ InstalaÃ§Ã£o de dependÃªncias base: curl, wget, apt-transport-https, ca-certificates, gnupg, lsb-release
- ðŸ”§ ConfiguraÃ§Ã£o de repositÃ³rios oficiais

### 3. InstalaÃ§Ã£o Docker
- ðŸ—‘ï¸ RemoÃ§Ã£o de versÃµes antigas (docker.io, docker-engine)
- ðŸ”‘ AdiÃ§Ã£o de chave GPG oficial do Docker
- ðŸ“¦ AdiÃ§Ã£o do repositÃ³rio oficial Docker para Ubuntu
- âš™ï¸ InstalaÃ§Ã£o do Docker CE + CLI + containerd + plugins
- ðŸ‘¥ AdiÃ§Ã£o do usuÃ¡rio ao grupo docker
- ðŸ”„ HabilitaÃ§Ã£o e inicializaÃ§Ã£o do serviÃ§o systemd

### 4. InstalaÃ§Ã£o Minikube
- ðŸ“¥ Download da versÃ£o mais recente do GitHub oficial
- ðŸ“ InstalaÃ§Ã£o em `/usr/local/bin/minikube`
- âœ… VerificaÃ§Ã£o da versÃ£o instalada

### 5. InstalaÃ§Ã£o kubectl
- ðŸ” DetecÃ§Ã£o da versÃ£o estÃ¡vel via API Kubernetes
- ðŸ“¥ Download da versÃ£o correspondente do repositÃ³rio oficial
- ðŸ“ InstalaÃ§Ã£o em `/usr/local/bin/kubectl`
- âœ… VerificaÃ§Ã£o da versÃ£o instalada

### 6. InstalaÃ§Ã£o Helm
- ðŸŒ Uso do script oficial de instalaÃ§Ã£o do Helm
- ðŸ“¥ Download e instalaÃ§Ã£o automÃ¡tica da versÃ£o mais recente
- âœ… VerificaÃ§Ã£o da versÃ£o instalada

### 7. ValidaÃ§Ã£o Final
- âœ… Teste de todos os comandos instalados
- ðŸ³ VerificaÃ§Ã£o do Docker em execuÃ§Ã£o
- ðŸ‘¥ VerificaÃ§Ã£o do grupo docker do usuÃ¡rio
- ðŸ“Š RelatÃ³rio de status final
- ðŸ“‹ InstruÃ§Ãµes para prÃ³ximos passos

## ðŸ› ï¸ IntegraÃ§Ã£o com Sistema de Paths DinÃ¢micos

O sistema detecta automaticamente se estÃ¡ sendo executado dentro de um projeto DevOps existente:

```bash
# DetecÃ§Ã£o automÃ¡tica do projeto
detect_project_root() {
    local current_dir="$SCRIPT_DIR"
    while [[ "$current_dir" != "/" ]]; do
        if [[ ( -f "$current_dir/minikube/docs/README.md" && -d "$current_dir/minikube/scripts" ) || ( -f "$current_dir/docs/README.md" && -d "$current_dir/scripts" ) ]]; then
            PROJECT_ROOT="$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}
```

### BenefÃ­cios da IntegraÃ§Ã£o
- ðŸŽ¯ ExecuÃ§Ã£o automÃ¡tica da inicializaÃ§Ã£o se projeto detectado
- ðŸ“‚ Uso de paths corretos independente da localizaÃ§Ã£o
- ðŸ”„ IntegraÃ§Ã£o perfeita com scripts existentes

## ðŸ”„ Fluxos de Uso Completos

### Para MÃ¡quina Completamente Nova (Internet)

```bash
# Uma linha - download + setup + inicializaÃ§Ã£o
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/linux/bootstrap-devops.sh | bash
```

### Para MÃ¡quina Nova (TransferÃªncia Local)

```bash
# 1. Transferir projeto via USB/rede para mÃ¡quina
# 2. Navegar e executar
cd "/home/usuario/DevOps"  # ou onde vocÃª copiou
bash scripts/linux/setup-fresh-machine.sh --run-initialization
```

### Para MÃ¡quina com Projeto Existente

```bash
# NavegaÃ§Ã£o e setup
cd "/caminho/para/projeto/DevOps"
bash scripts/linux/setup-fresh-machine.sh --run-initialization
```

### Para Ambiente Corporativo/Restrito

```bash
# Instalar sÃ³ algumas dependÃªncias
bash setup-fresh-machine.sh --skip-docker  # Se Docker jÃ¡ gerenciado pelo TI
bash setup-fresh-machine.sh --skip-validation  # Para ambientes offline
```

## ðŸ§ª ValidaÃ§Ã£o e Testes

### VerificaÃ§Ã£o AutomÃ¡tica IncluÃ­da
- ðŸ³ `docker --version` - Docker instalado
- ðŸŽ¯ `minikube version` - Minikube funcionando  
- ðŸ”§ `kubectl version --client` - kubectl instalado
- ðŸ“¦ `helm version` - Helm funcionando
- ðŸ‘¥ VerificaÃ§Ã£o de grupo docker

### Scripts de Teste DisponÃ­veis
```bash
# Teste completo da estrutura apÃ³s inicializaÃ§Ã£o
bash linux-test-structure.sh

# Status rÃ¡pido do ambiente
minikube status
kubectl cluster-info

# Verificar pods dos serviÃ§os
kubectl get pods,svc,pv,pvc
```

## ðŸš¨ Troubleshooting Comum

### Problema: UsuÃ¡rio nÃ£o consegue usar Docker
**Causa**: UsuÃ¡rio nÃ£o estÃ¡ no grupo docker  
**SoluÃ§Ã£o**:
```bash
# O script jÃ¡ faz isso, mas se necessÃ¡rio:
sudo usermod -aG docker $USER
# Fazer logout/login ou:
newgrp docker
```

### Problema: Download falha
**Causa**: Conectividade ou URLs temporariamente indisponÃ­veis  
**SoluÃ§Ã£o**:
- Verificar conexÃ£o com internet
- Tentar novamente (downloads podem falhar temporariamente)
- Usar parÃ¢metros --skip-* para pular downloads problemÃ¡ticos

### Problema: Minikube nÃ£o consegue iniciar
**SoluÃ§Ã£o**:
```bash
# Limpar configuraÃ§Ã£o e tentar novamente
minikube delete
minikube start --driver=docker --force

# Se problema persistir, verificar Docker
docker version
sudo systemctl status docker
```

### Problema: PermissÃµes insuficientes
**Causa**: sudo nÃ£o configurado ou usuÃ¡rio sem privilÃ©gios  
**SoluÃ§Ã£o**:
- Executar script como usuÃ¡rio normal (ele solicitarÃ¡ sudo quando necessÃ¡rio)
- Verificar se usuÃ¡rio estÃ¡ no grupo sudo: `groups $USER`
- Configurar sudo se necessÃ¡rio: `sudo usermod -aG sudo $USER`

### Problema: VersÃ£o Ubuntu nÃ£o suportada
**Causa**: VersÃ£o muito antiga (< 18.04)  
**SoluÃ§Ã£o**:
- Atualizar Ubuntu para versÃ£o suportada
- Ou instalar dependÃªncias manualmente para versÃµes antigas

## ðŸ“Š Logs e DiagnÃ³stico

### Comandos de DiagnÃ³stico
```bash
# Status geral de todas as ferramentas
docker version && minikube version && kubectl version --client && helm version

# Logs do Docker
sudo journalctl -u docker

# Logs do Minikube
minikube logs

# InformaÃ§Ãµes do cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

### Verificar Grupos e PermissÃµes
```bash
# Verificar grupos do usuÃ¡rio
groups $USER

# Verificar status do Docker
sudo systemctl status docker

# Testar Docker sem sudo
docker run hello-world
```

## ðŸ”„ AtualizaÃ§Ãµes e ManutenÃ§Ã£o

### Atualizar DependÃªncias
```bash
# Re-executar setup para atualizar para versÃµes mais recentes
bash setup-fresh-machine.sh --skip-validation

# Atualizar apenas componentes especÃ­ficos
bash setup-fresh-machine.sh --skip-docker --skip-minikube
```

### Limpeza e Reset
```bash
# Reset completo do Minikube
minikube delete --all

# Limpar Docker (cuidado em produÃ§Ã£o)
docker system prune -a

# Reinstalar tudo
bash setup-fresh-machine.sh --run-initialization
```

## ðŸ“ Estrutura de Arquivos

```
scripts/linux/
â”œâ”€â”€ setup-fresh-machine.sh          # Script principal de setup
â”œâ”€â”€ bootstrap-devops.sh              # Bootstrap completo
â”œâ”€â”€ init/
â”‚   â””â”€â”€ init-minikube-fixed.sh      # InicializaÃ§Ã£o do ambiente
â”œâ”€â”€ maintenance/
â”‚   â””â”€â”€ quick-status.sh             # Scripts de manutenÃ§Ã£o
â””â”€â”€ monitoring/
    â””â”€â”€ open-dashboard.sh           # Scripts de monitoramento
```

## ðŸŽ¯ Casos de Uso

### Desenvolvedor Novo na Equipe
```bash
# Uma linha - ambiente completo
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/linux/bootstrap-devops.sh | bash
```

### ConfiguraÃ§Ã£o de CI/CD (Ubuntu Runner)
```bash
# Setup automatizado sem interaÃ§Ã£o
bash setup-fresh-machine.sh --run-initialization 2>&1 | tee setup.log
```

### Ambiente de Desenvolvimento TemporÃ¡rio
```bash
# Setup rÃ¡pido sem inicializaÃ§Ã£o
bash setup-fresh-machine.sh
# Inicializar depois manualmente quando necessÃ¡rio
```

### MÃ¡quina Corporativa com Docker Gerenciado
```bash
# Pular Docker, instalar sÃ³ Kubernetes tools
bash setup-fresh-machine.sh --skip-docker --run-initialization
```

### Ambiente Offline (DependÃªncias PrÃ©-baixadas)
```bash
# Usar parÃ¢metros para pular downloads problemÃ¡ticos
bash setup-fresh-machine.sh --skip-validation
```

---

## ðŸ“ž Suporte

Para problemas especÃ­ficos:
1. Verificar logs do sistema: `journalctl -u docker`, `minikube logs`
2. Executar comandos de diagnÃ³stico listados acima
3. Consultar troubleshooting comum neste documento
4. Re-executar setup com parÃ¢metros especÃ­ficos

**Sistema testado em**: Ubuntu 18.04 LTS, 20.04 LTS, 22.04 LTS, 24.04 LTS  
**Compatibilidade**: Derivados Ubuntu (Linux Mint, Elementary, etc.) com aviso  
**Ãšltima atualizaÃ§Ã£o**: Outubro 2025  
**DependÃªncias**: bash 4.0+, curl, wget, sudo
