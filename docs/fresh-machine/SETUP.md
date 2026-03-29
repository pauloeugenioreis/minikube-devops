# Fresh Machine Setup - DevOps Minikube Environment (Windows)

**Sistema de instalação completa para máquina nova Windows**  
*Zero to Running - Instalação automatizada do ambiente DevOps*

## 📣 Visão Geral

Este sistema permite configurar automaticamente um ambiente completo de desenvolvimento DevOps com Minikube em uma máquina Windows nova, instalando todas as dependências necessárias sem intervenção manual. **O projeto é transferido via pasta local (USB/rede/OneDrive) — não requer repositório online.**

### Componentes Principais

- **Setup-Fresh-Machine.ps1**: Script principal de instalação de dependências
- **Bootstrap-DevOps.ps1**: Script de bootstrap completo (download do projeto + setup)
- **Get-ProjectRoot.ps1**: Sistema de paths dinâmicos integrado
- **Scripts de inicialização**: Automação completa do ambiente

## 🚀 Uso Rápido

### Opção 1: Transferência de Projeto (Recomendado)

Para máquina completamente nova sem o projeto:

```powershell
# 1. Copiar toda a pasta do projeto via USB/rede para a nova máquina
# 2. Navegar para a pasta copiada (exemplo)
cd "C:\DevOps"  # ou onde você copiou o projeto

# 3. Executar bootstrap local
./scripts/windows/Bootstrap-DevOps.ps1

### Opção 2: Setup Local

Se já possui o projeto baixado:

```powershell
# Navegar para a pasta do projeto (onde estiver)
cd "C:\SeuCaminho\Para\DevOps"

# Executar setup
./temp/Setup-Fresh-Machine.ps1

# Ou com inicialização automática
./temp/Setup-Fresh-Machine.ps1 -RunInitialization

## 📦 Dependências Instaladas

### Automaticamente Instaladas

- **Docker Desktop**: Container runtime
- **Minikube**: Kubernetes local
- **kubectl**: Cliente Kubernetes
- **Helm**: Gerenciador de pacotes Kubernetes

### Pré-requisitos Verificados

- Windows 10/11 (verificação automática)
- Hyper-V (habilitação automática se necessário)
```text
```text
- WSL2 (habilitação automática se necessário)
- Privilégios administrativos (elevação automática)

## ⚙️ Parâmetros de Configuração

### Setup-Fresh-Machine.ps1

```powershell
# Pular instalações específicas
./Setup-Fresh-Machine.ps1 -SkipDockerInstall
./Setup-Fresh-Machine.ps1 -SkipMinikubeInstall
./Setup-Fresh-Machine.ps1 -SkipKubectlInstall
./Setup-Fresh-Machine.ps1 -SkipHelmInstall

# Pular validação final
./Setup-Fresh-Machine.ps1 -SkipValidation

# Executar inicialização automática após setup
./Setup-Fresh-Machine.ps1 -RunInitialization
*** End Patch

### Bootstrap-DevOps.ps1

```powershell
# Customizar localização do projeto (se necessário)
./Bootstrap-DevOps.ps1 -ProjectPath "C:\MeuProjeto\DevOps"

# Pular etapas específicas se necessário
./Bootstrap-DevOps.ps1 -SkipSetup -SkipInit
```

## ðŸ”§ Processo de InstalaÃ§Ã£o Detalhado

### 1. Verificação Inicial

- ✅ Versão do Windows (10/11 required)
- ✅ Privilégios administrativos (elevação automática)
- ✅ Hyper-V habilitado (ativação automática + reboot se necessário)
- ✅ WSL2 habilitado (ativação automática + reboot se necessário)

### 2. Preparação do Ambiente

- 📁 Criação do diretório `%USERPROFILE%\bin`
- 🛠️ Configuração automática do PATH do usuário
- 📂 Preparação de diretórios temporários

### 3. Instalação Docker Desktop

- 📥 Download da versão mais recente
- ⚡ Instalação silenciosa com aceitação automática da licença
- 🔧 Aguardo da inicialização (timeout 300s)
- ✅ Verificação de funcionamento

### 4. Instalação Minikube

- 📥 Download da versão mais recente do GitHub
- 📁 Instalação em `%USERPROFILE%\bin\minikube.exe`
- ✅ Verificação da versão instalada

### 5. Instalação kubectl

- 🔍 Detecção da versão estável via API Kubernetes
- 📥 Download da versão correspondente
- 📁 Instalação em `%USERPROFILE%\bin\kubectl.exe`
- ✅ Verificação da versão instalada

### 6. Instalação Helm

- 🔍 Detecção da versão mais recente via GitHub API
- 📥 Download do pacote ZIP
- 📂 Extração e instalação em `%USERPROFILE%\bin\helm.exe`
- ✅ Verificação da versão instalada

### 7. Validação Final

- ✅ Teste de todos os comandos instalados
- 🐳 Verificação do Docker em execução
- 📊 Relatório de status final
- 📣 Instruções para próximos passos

## ðŸ› ï¸ IntegraÃ§Ã£o com Sistema de Paths DinÃ¢micos

O sistema detecta automaticamente se estÃ¡ sendo executado dentro de um projeto DevOps existente e utiliza o sistema de paths dinÃ¢micos:

```powershell
# DetecÃ§Ã£o automÃ¡tica do projeto
$getProjectRootScript = Join-Path $PSScriptRoot "Get-ProjectRoot.ps1"
if (Test-Path $getProjectRootScript) {
    . $getProjectRootScript
    $projectPaths = Get-ProjectPaths
    # Usar paths dinÃ¢micos para execuÃ§Ã£o automÃ¡tica
}
```

### Benefícios da Integração

- 🎯 Execução automática da inicialização se projeto detectado
- 📂 Uso de paths corretos independente da localização
- 🔧 Integração perfeita com scripts existentes

## ðŸ”„ Fluxo Completo: Zero to Running

### Para Máquina Completamente Nova

1. **Transferir Projeto**

   ```powershell
   # Copiar pasta completa via USB/rede/OneDrive
   # Para: C:\Users\%USERNAME%\Documents\OneDrive\Projetos\DevOps
   ```

2. **Execução Automática**

   ```powershell
   cd "C:\DevOps"  # ou onde você copiou
   ./scripts/windows/Bootstrap-DevOps.ps1
   ```

3. **Resultado Final**

   - ✅ Projeto disponível localmente
   - ✅ Todas dependências instaladas e funcionando
   - ✅ Minikube inicializado e cluster rodando
   - ✅ KEDA instalado e configurado
   - ✅ Dashboard acessível

### Para Máquina com Projeto Existente

1. **Navegação**

   ```powershell
   cd "C:\Caminho\Para\Projeto\DevOps"
   ```

2. **Setup com Inicialização**

   ```powershell
   ./temp/Setup-Fresh-Machine.ps1 -RunInitialization
   ```

## ðŸ§ª ValidaÃ§Ã£o e Testes

### Verificação Automática Incluída

- 🐳 `docker version` - Docker funcionando
- 🎯 `minikube status` - Cluster rodando
- 🛠️ `kubectl cluster-info` - Conectividade
- 📦 `helm version` - Helm instalado

### Scripts de Teste Disponíveis

```powershell
# Teste completo da estrutura
./windows-test-structure.ps1

# Status rápido
./scripts/windows/maintenance/quick-status.ps1

# Abrir dashboard
./scripts/windows/monitoring/open-dashboard.ps1
```

## ðŸš¨ Troubleshooting Comum

### Problema: Hyper-V não pode ser habilitado

**Solução**: Verificar se:

- BIOS tem virtualização habilitada
- Windows é Pro/Enterprise (Home não suporta Hyper-V nativo)
- Usar WSL2 como alternativa

### Problema: Docker não inicia

**Solução**:

- Aguardar mais tempo (pode demorar até 5 minutos)
- Reiniciar máquina após instalação
- Verificar se Hyper-V/WSL2 estão funcionando

### Problema: Download falha

**Solução**:

- Verificar conexão com internet para downloads automáticos
- Tentar novamente (downloads podem falhar temporariamente)
- Verificar se dependências estão acessíveis (Docker, Minikube, etc.)

### Problema: Minikube não consegue iniciar

**Solução**:

```powershell
# Limpar configuração e tentar novamente
minikube delete
minikube start --driver=docker --force
```

### Problema: Permissões insuficientes

**Solução**: Script solicita elevação automática, mas pode ser necessário:

- Executar PowerShell "Como Administrador" manualmente
- Verificar política de execução: `Set-ExecutionPolicy RemoteSigned`

## ðŸ“Š Logs e DiagnÃ³stico

### Localizações de Log

- **Docker**: `%USERPROFILE%\.docker\`
- **Minikube**: `%USERPROFILE%\.minikube\logs\`
- **Kubectl**: Configuração em `%USERPROFILE%\.kube\`

### Comandos de Diagnóstico

```powershell
# Status geral
docker version; minikube status; kubectl version; helm version

# Logs do Minikube
minikube logs

# Informações do cluster
kubectl cluster-info dump
```

## ðŸ”„ AtualizaÃ§Ãµes e ManutenÃ§Ã£o

### Atualizar Dependências

```powershell
# Re-executar setup pulando validação
./temp/Setup-Fresh-Machine.ps1 -SkipValidation

# Atualizar apenas componentes específicos
./temp/Setup-Fresh-Machine.ps1 -SkipDockerInstall -SkipMinikubeInstall
```

### Limpeza e Reset

```powershell
# Reset completo do Minikube
minikube delete --all
./scripts/windows/init/init-minikube-fixed.ps1

# Limpar Docker
docker system prune -a
```

## ðŸ“ Estrutura de Arquivos

```
temp/
â”œâ”€â”€ Setup-Fresh-Machine.ps1     # Script principal de setup
â”œâ”€â”€ Bootstrap-DevOps.ps1        # Bootstrap completo
â””â”€â”€ FRESH-MACHINE-SETUP.md      # Esta documentaÃ§Ã£o

scripts/windows/
â”œâ”€â”€ Get-ProjectRoot.ps1          # Sistema de paths dinÃ¢micos
â”œâ”€â”€ init/
â”‚   â””â”€â”€ init-minikube-fixed.ps1  # InicializaÃ§Ã£o do ambiente
â”œâ”€â”€ maintenance/
â”‚   â””â”€â”€ quick-status.ps1         # VerificaÃ§Ã£o rÃ¡pida
â””â”€â”€ monitoring/
   â””â”€â”€ open-dashboard.ps1       # Abrir dashboard
``` 

## ðŸŽ¯ Casos de Uso

### Desenvolvedor Novo na Equipe

```powershell
# 1. Receber projeto via transferência (USB/rede/OneDrive)
# 2. Uma linha, configuração completa
cd "C:\DevOps"  # navegar para onde copiou o projeto
./scripts/windows/Bootstrap-DevOps.ps1
```

### Configuração de CI/CD

```powershell
# Setup automatizado em runner
./temp/Setup-Fresh-Machine.ps1 -SkipValidation -RunInitialization
```

### Ambiente de Desenvolvimento Temporário

```powershell
# Setup rápido sem inicialização
./temp/Setup-Fresh-Machine.ps1 -SkipInit
```

### Máquina Corporativa com Restrições

```powershell
# Pular Docker, usar instalação manual
.\temp\Setup-Fresh-Machine.ps1 -SkipDockerInstall
```

---

## ðŸ“ž Suporte

Para problemas específicos:

1. Verificar logs nas localizações indicadas
2. Executar scripts de diagnÃ³stico
3. Consultar troubleshooting comum
4. Re-executar setup com parÃ¢metros especÃ­ficos

**Sistema testado em**: Windows 10 Pro/Enterprise, Windows 11  
**Ãšltima atualizaÃ§Ã£o**: Dezembro 2024  
**Compatibilidade**: PowerShell 5.1+, .NET Framework 4.7.2+
