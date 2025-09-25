# DEMO FRESH MACHINE SETUP

## 🚀 Setup para Máquina Nova - DevOps Minikube

**Como transformar uma máquina Windows nova em ambiente DevOps completo**

### ⚡ Opção 1: Bootstrap One-Line (Mais Fácil)

```powershell
# Uma linha para setup completo
curl -O https://raw.githubusercontent.com/YOUR_REPO/main/temp/Bootstrap-DevOps.ps1; .\Bootstrap-DevOps.ps1
```

**O que acontece:**
1. 📥 Download do script de bootstrap
2. 📁 Download/clone do projeto DevOps completo
3. 🔧 Instalação automática: Docker, Minikube, kubectl, Helm
4. ⚙️ Configuração completa do ambiente
5. 🚀 Inicialização automática do Minikube + KEDA
6. ✅ Validação final - pronto para usar!

### ⚙️ Opção 2: Setup Manual (Mais Controle)

```powershell
# 1. Download do projeto (escolha uma opção)
git clone https://github.com/YOUR_REPO/DevOps.git
# OU
curl -O https://github.com/YOUR_REPO/DevOps/archive/main.zip

# 2. Navegação
cd DevOps

# 3. Setup de dependências
.\temp\Setup-Fresh-Machine.ps1

# 4. Inicialização (opcional)
.\minikube\scripts\windows\init\init-minikube-fixed.ps1
```

### 🎯 Personalização Avançada

```powershell
# Custom: Localização específica
.\Bootstrap-DevOps.ps1 -ProjectPath "C:\MeusProjetos\DevOps"

# Custom: Repositório específico
.\Bootstrap-DevOps.ps1 -GitRepo "https://github.com/meu-usuario/meu-fork.git"

# Custom: Pular etapas específicas
.\Bootstrap-DevOps.ps1 -SkipGitClone -SkipSetup

# Custom: Usar ZIP em vez de Git
.\Bootstrap-DevOps.ps1 -UseDownload

# Setup: Pular instalações específicas
.\Setup-Fresh-Machine.ps1 -SkipDockerInstall -SkipValidation

# Setup: Com inicialização automática
.\Setup-Fresh-Machine.ps1 -RunInitialization
```

### 🧪 Cenários de Uso

#### 🆕 Desenvolvedor Novo na Equipe
```powershell
# Setup completo em uma linha
curl -O bootstrap.ps1; .\bootstrap.ps1
```

#### 🏢 Ambiente Corporativo
```powershell
# Docker já instalado corporativamente
.\Setup-Fresh-Machine.ps1 -SkipDockerInstall
```

#### 🔧 CI/CD Runner
```powershell
# Setup sem interação
.\Bootstrap-DevOps.ps1 -SkipValidation
```

#### 🧪 Ambiente Temporário
```powershell
# Setup rápido para testes
.\Setup-Fresh-Machine.ps1 -SkipInit
```

#### 💻 Desenvolvimento Local
```powershell
# Setup completo com inicialização
.\Bootstrap-DevOps.ps1
```

### ✅ Verificação Final

Após qualquer instalação, verificar:

```powershell
# Comandos disponíveis
docker --version
minikube version
kubectl version
helm version

# Status do ambiente
minikube status
kubectl cluster-info

# Teste rápido
.\minikube\scripts\windows\maintenance\quick-status.ps1

# Dashboard
.\minikube\scripts\windows\monitoring\open-dashboard.ps1
```

### 🛠️ Testes Completos

```powershell
# Teste completo da estrutura
.\minikube\windows-test-structure.ps1

# Teste KEDA
.\minikube\scripts\windows\keda\test-keda.ps1
```

### 📊 Resultado Esperado

**Antes:**
- ❌ Máquina Windows nova
- ❌ Nenhuma ferramenta DevOps
- ❌ Sem ambiente de desenvolvimento

**Depois:**
- ✅ Docker Desktop funcionando
- ✅ Minikube cluster rodando
- ✅ kubectl configurado
- ✅ Helm instalado
- ✅ KEDA operacional
- ✅ MongoDB e RabbitMQ prontos
- ✅ Dashboard acessível
- ✅ Autostart configurado
- ✅ Paths dinâmicos funcionando

### 🕐 Tempo Estimado

- **Bootstrap One-Line**: 15-30 minutos
- **Setup Manual**: 10-20 minutos
- **Reinicializações**: Possíveis para Hyper-V/WSL2

### 📞 Suporte Rápido

```powershell
# Logs de diagnóstico
minikube logs
docker system info

# Reset se necessário
minikube delete
.\minikube\scripts\windows\init\init-minikube-fixed.ps1

# Status detalhado
kubectl cluster-info dump
```

### 🎉 Success Indicators

Você sabe que deu certo quando:
- ✅ `minikube status` mostra "Running"
- ✅ `kubectl get pods -A` lista pods do sistema
- ✅ Dashboard abre no navegador
- ✅ `helm list` funciona sem erro
- ✅ MongoDB e RabbitMQ aparecem nos pods

---

**🚀 Pronto para desenvolvimento!**