# Fresh Machine Setup - DevOps Minikube Environment (Linux Ubuntu)

**Sistema de instalação completa para máquina nova Linux Ubuntu**  
*Zero to Running - Instalação automatizada do ambiente DevOps*

## 📋 Visão Geral

Este sistema permite configurar automaticamente um ambiente completo de desenvolvimento DevOps com Minikube em uma máquina Linux Ubuntu nova, instalando todas as dependências necessárias sem intervenção manual. **O projeto é transferido via pasta local (USB/rede/OneDrive) ou clone Git.**

### Componentes Principais

- **setup-fresh-machine.sh**: Script principal de instalação de dependências
- **bootstrap-devops.sh**: Script de bootstrap completo (download projeto + setup)
- **Detecção automática**: Sistema de paths dinâmicos integrado
- **Scripts de inicialização**: Automação completa do ambiente

## 🚀 Uso Rápido

### Opção 1: Bootstrap Completo (Máquina Nova)
Para máquina completamente nova sem o projeto:

```bash
# Download automático + instalação + inicialização
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/minikube/scripts/linux/bootstrap-devops.sh | bash

# Ou com customização de pasta
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/minikube/scripts/linux/bootstrap-devops.sh | bash -s -- --project-path /opt/devops
```

### Opção 2: Setup Local (Projeto Existente)
Se já possui o projeto baixado:

```bash
# Navegar para a pasta do projeto
cd "/caminho/para/projeto/DevOps"

# Executar setup com inicialização
bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization

# Ou sem inicialização automática
bash minikube/scripts/linux/setup-fresh-machine.sh
```

### Opção 3: Transferência Manual + Bootstrap
Para transferência via USB/rede:

```bash
# 1. Copiar pasta completa via USB/rede para a nova máquina
# 2. Navegar para a pasta copiada
cd "/home/usuario/DevOps"  # ou onde você copiou o projeto

# 3. Executar setup local
bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization
```

## 📦 Dependências Instaladas

### Automaticamente Instaladas
- **Docker**: Container runtime (via repositório oficial)
- **Minikube**: Kubernetes local (última versão)
- **kubectl**: Cliente Kubernetes (versão compatível)
- **Helm**: Gerenciador de pacotes Kubernetes (última versão)

### Pré-requisitos Verificados
- Ubuntu 18.04+ (verificação automática, suporte a derivados)
- Privilégios sudo (elevação automática quando necessário)
- Conectividade com internet (para downloads)
- Grupo docker (configuração automática)

## ⚙️ Parâmetros de Configuração

### setup-fresh-machine.sh

```bash
# Pular instalações específicas
bash setup-fresh-machine.sh --skip-docker
bash setup-fresh-machine.sh --skip-minikube
bash setup-fresh-machine.sh --skip-kubectl
bash setup-fresh-machine.sh --skip-helm

# Pular validação final
bash setup-fresh-machine.sh --skip-validation

# Executar inicialização automática após setup
bash setup-fresh-machine.sh --run-initialization

# Combinações
bash setup-fresh-machine.sh --skip-docker --run-initialization
```

### bootstrap-devops.sh

```bash
# Customizar localização do projeto
bash bootstrap-devops.sh --project-path "/opt/devops"

# Pular etapas específicas
bash bootstrap-devops.sh --skip-setup
bash bootstrap-devops.sh --skip-init
bash bootstrap-devops.sh --skip-setup --skip-init

# Ver ajuda
bash bootstrap-devops.sh --help
```

## 🔧 Processo de Instalação Detalhado

### 1. Verificação Inicial
- ✅ Versão do Ubuntu (18.04+ required, derivados aceitos com aviso)
- ✅ Privilégios sudo (solicitação automática quando necessário)
- ✅ Conectividade com internet (para downloads das dependências)
- ✅ Comandos base: curl, wget, apt-get

### 2. Preparação do Ambiente
- 📁 Atualização do sistema (`apt-get update`)
- 🛠️ Instalação de dependências base: curl, wget, apt-transport-https, ca-certificates, gnupg, lsb-release
- 🔧 Configuração de repositórios oficiais

### 3. Instalação Docker
- 🗑️ Remoção de versões antigas (docker.io, docker-engine)
- 🔑 Adição de chave GPG oficial do Docker
- 📦 Adição do repositório oficial Docker para Ubuntu
- ⚙️ Instalação do Docker CE + CLI + containerd + plugins
- 👥 Adição do usuário ao grupo docker
- 🔄 Habilitação e inicialização do serviço systemd

### 4. Instalação Minikube
- 📥 Download da versão mais recente do GitHub oficial
- 📁 Instalação em `/usr/local/bin/minikube`
- ✅ Verificação da versão instalada

### 5. Instalação kubectl
- 🔍 Detecção da versão estável via API Kubernetes
- 📥 Download da versão correspondente do repositório oficial
- 📁 Instalação em `/usr/local/bin/kubectl`
- ✅ Verificação da versão instalada

### 6. Instalação Helm
- 🌐 Uso do script oficial de instalação do Helm
- 📥 Download e instalação automática da versão mais recente
- ✅ Verificação da versão instalada

### 7. Validação Final
- ✅ Teste de todos os comandos instalados
- 🐳 Verificação do Docker em execução
- 👥 Verificação do grupo docker do usuário
- 📊 Relatório de status final
- 📋 Instruções para próximos passos

## 🛠️ Integração com Sistema de Paths Dinâmicos

O sistema detecta automaticamente se está sendo executado dentro de um projeto DevOps existente:

```bash
# Detecção automática do projeto
detect_project_root() {
    local current_dir="$SCRIPT_DIR"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/minikube/docs/README.md" && -d "$current_dir/minikube/scripts" ]]; then
            PROJECT_ROOT="$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}
```

### Benefícios da Integração
- 🎯 Execução automática da inicialização se projeto detectado
- 📂 Uso de paths corretos independente da localização
- 🔄 Integração perfeita com scripts existentes

## 🔄 Fluxos de Uso Completos

### Para Máquina Completamente Nova (Internet)

```bash
# Uma linha - download + setup + inicialização
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/minikube/scripts/linux/bootstrap-devops.sh | bash
```

### Para Máquina Nova (Transferência Local)

```bash
# 1. Transferir projeto via USB/rede para máquina
# 2. Navegar e executar
cd "/home/usuario/DevOps"  # ou onde você copiou
bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization
```

### Para Máquina com Projeto Existente

```bash
# Navegação e setup
cd "/caminho/para/projeto/DevOps"
bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization
```

### Para Ambiente Corporativo/Restrito

```bash
# Instalar só algumas dependências
bash setup-fresh-machine.sh --skip-docker  # Se Docker já gerenciado pelo TI
bash setup-fresh-machine.sh --skip-validation  # Para ambientes offline
```

## 🧪 Validação e Testes

### Verificação Automática Incluída
- 🐳 `docker --version` - Docker instalado
- 🎯 `minikube version` - Minikube funcionando  
- 🔧 `kubectl version --client` - kubectl instalado
- 📦 `helm version` - Helm funcionando
- 👥 Verificação de grupo docker

### Scripts de Teste Disponíveis
```bash
# Teste completo da estrutura após inicialização
bash linux-test-structure.sh

# Status rápido do ambiente
minikube status
kubectl cluster-info

# Verificar pods dos serviços
kubectl get pods,svc,pv,pvc
```

## 🚨 Troubleshooting Comum

### Problema: Usuário não consegue usar Docker
**Causa**: Usuário não está no grupo docker  
**Solução**:
```bash
# O script já faz isso, mas se necessário:
sudo usermod -aG docker $USER
# Fazer logout/login ou:
newgrp docker
```

### Problema: Download falha
**Causa**: Conectividade ou URLs temporariamente indisponíveis  
**Solução**:
- Verificar conexão com internet
- Tentar novamente (downloads podem falhar temporariamente)
- Usar parâmetros --skip-* para pular downloads problemáticos

### Problema: Minikube não consegue iniciar
**Solução**:
```bash
# Limpar configuração e tentar novamente
minikube delete
minikube start --driver=docker --force

# Se problema persistir, verificar Docker
docker version
sudo systemctl status docker
```

### Problema: Permissões insuficientes
**Causa**: sudo não configurado ou usuário sem privilégios  
**Solução**:
- Executar script como usuário normal (ele solicitará sudo quando necessário)
- Verificar se usuário está no grupo sudo: `groups $USER`
- Configurar sudo se necessário: `sudo usermod -aG sudo $USER`

### Problema: Versão Ubuntu não suportada
**Causa**: Versão muito antiga (< 18.04)  
**Solução**:
- Atualizar Ubuntu para versão suportada
- Ou instalar dependências manualmente para versões antigas

## 📊 Logs e Diagnóstico

### Comandos de Diagnóstico
```bash
# Status geral de todas as ferramentas
docker version && minikube version && kubectl version --client && helm version

# Logs do Docker
sudo journalctl -u docker

# Logs do Minikube
minikube logs

# Informações do cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

### Verificar Grupos e Permissões
```bash
# Verificar grupos do usuário
groups $USER

# Verificar status do Docker
sudo systemctl status docker

# Testar Docker sem sudo
docker run hello-world
```

## 🔄 Atualizações e Manutenção

### Atualizar Dependências
```bash
# Re-executar setup para atualizar para versões mais recentes
bash setup-fresh-machine.sh --skip-validation

# Atualizar apenas componentes específicos
bash setup-fresh-machine.sh --skip-docker --skip-minikube
```

### Limpeza e Reset
```bash
# Reset completo do Minikube
minikube delete --all

# Limpar Docker (cuidado em produção)
docker system prune -a

# Reinstalar tudo
bash setup-fresh-machine.sh --run-initialization
```

## 📁 Estrutura de Arquivos

```
minikube/scripts/linux/
├── setup-fresh-machine.sh          # Script principal de setup
├── bootstrap-devops.sh              # Bootstrap completo
├── init/
│   └── init-minikube-fixed.sh      # Inicialização do ambiente
├── maintenance/
│   └── quick-status.sh             # Scripts de manutenção
└── monitoring/
    └── open-dashboard.sh           # Scripts de monitoramento
```

## 🎯 Casos de Uso

### Desenvolvedor Novo na Equipe
```bash
# Uma linha - ambiente completo
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/minikube/scripts/linux/bootstrap-devops.sh | bash
```

### Configuração de CI/CD (Ubuntu Runner)
```bash
# Setup automatizado sem interação
bash setup-fresh-machine.sh --run-initialization 2>&1 | tee setup.log
```

### Ambiente de Desenvolvimento Temporário
```bash
# Setup rápido sem inicialização
bash setup-fresh-machine.sh
# Inicializar depois manualmente quando necessário
```

### Máquina Corporativa com Docker Gerenciado
```bash
# Pular Docker, instalar só Kubernetes tools
bash setup-fresh-machine.sh --skip-docker --run-initialization
```

### Ambiente Offline (Dependências Pré-baixadas)
```bash
# Usar parâmetros para pular downloads problemáticos
bash setup-fresh-machine.sh --skip-validation
```

---

## 📞 Suporte

Para problemas específicos:
1. Verificar logs do sistema: `journalctl -u docker`, `minikube logs`
2. Executar comandos de diagnóstico listados acima
3. Consultar troubleshooting comum neste documento
4. Re-executar setup com parâmetros específicos

**Sistema testado em**: Ubuntu 18.04 LTS, 20.04 LTS, 22.04 LTS, 24.04 LTS  
**Compatibilidade**: Derivados Ubuntu (Linux Mint, Elementary, etc.) com aviso  
**Última atualização**: Outubro 2025  
**Dependências**: bash 4.0+, curl, wget, sudo