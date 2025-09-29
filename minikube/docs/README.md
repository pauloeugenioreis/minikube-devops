# Minikube DevOps Environment
#
# Documentação para Windows e Linux


## Visao Geral
Ambiente Minikube profissional com RabbitMQ, MongoDB e KEDA configurados para inicialização automática no Windows e Linux.

---

## Uso no Linux

### Estrutura dos scripts Linux
Os scripts Bash estão em:
```
<CAMINHO-DO-PROJETO>/DevOps/minikube/scripts/linux/
```

### Inicialização completa do ambiente (Linux)
Execute sempre a partir da raiz do projeto:
```bash
cd <CAMINHO-DO-PROJETO>/DevOps
bash minikube/scripts/linux/autostart/minikube-autostart.sh
```
Esse script:
- Valida e instala dependências (Docker, Minikube, kubectl)
- Inicia Docker e Minikube
- Aplica configurações, ingress, port-forwards
- Instala e valida KEDA (via Helm local quando necessário)
- Mostra acessos úteis (RabbitMQ, MongoDB, Dashboard)

### Comandos úteis (Linux)
```bash
# Instalar KEDA separadamente
bash minikube/scripts/linux/keda/install-keda.sh

# Validar estrutura do ambiente
bash minikube/linux-test-structure.sh

# Abrir dashboard manualmente
bash minikube/scripts/linux/monitoring/open-dashboard.sh
```

### Acesso ao RabbitMQ Management via Ingress
- URL: http://rabbitmq.local
- Necessário: entrada no /etc/hosts apontando para o IP do Minikube (feito automaticamente pelo script)

### Acesso ao Dashboard
- URL: http://localhost:15671
- Port-forward configurado automaticamente

### Observações
- Todos os scripts usam paths dinâmicos, basta rodar a partir da raiz do projeto
- Não é necessário editar caminhos fixos
- Para ambientes offline, as imagens do KEDA são carregadas automaticamente

---

## Estrutura do Projeto
```
<CAMINHO-DO-PROJETO>\DevOps\
├── temp\                        # Area de desenvolvimento
│   ├── scripts-teste\          # Scripts experimentais em desenvolvimento
│   ├── configs-teste\          # Configuracoes em teste e validacao
│   └── validacoes\             # Scripts de teste e verificacao
├── Bootstrap-DevOps.ps1         # Bootstrap completo para maquina nova (RAIZ)
└── minikube\                   # Estrutura FINAL (codigo consolidado)
    ├── charts\                 # NOVOS Helm Charts
    │   ├── mongodb\            # Chart do MongoDB
    │   └── rabbitmq\           # Chart do RabbitMQ
    ├── scripts\
    │   ├── windows\            # Scripts Windows (PowerShell)
    │   │   ├── Setup-Fresh-Machine.ps1
    │   │   ├── Get-ProjectRoot.ps1
    │   │   ├── init\
    │   │   │   ├── init-minikube-fixed.ps1
    │   │   │   └── install-keda.ps1
    │   │   ├── keda\
    │   │   │   ├── install-helm-fixed.ps1
    │   │   │   ├── install-keda.ps1
    │   │   │   └── test-keda.ps1
    │   │   ├── maintenance\
    │   │   │   ├── fix-dashboard.ps1
    │   │   │   ├── quick-status.ps1
    │   │   │   └── fix-kubectl-final.ps1
    │   │   ├── monitoring\
    │   │   │   ├── open-dashboard.ps1
    │   │   │   └── change-dashboard-port.ps1
    │   │   └── autostart\
    │   │       └── minikube-autostart.bat
    │   └── linux\              # Scripts Linux (Bash)
    │       ├── autostart\
    │       │   └── minikube-autostart.sh
    │       ├── init\
    │       │   └── init-minikube-fixed.sh
    │       ├── keda\
    │       │   ├── install-helm-fixed.sh
    │       │   ├── install-keda.sh
    │       │   └── test-keda.sh
    │       ├── maintenance\
    │       │   ├── fix-dashboard.sh
    │       │   ├── validate-rabbitmq-config.sh
    │       │   └── placeholder.sh
    │       ├── monitoring\
    │       │   ├── open-dashboard.sh
    │       │   ├── change-dashboard-port.sh
    │       │   └── placeholder.sh
    │       └── linux-test-structure.sh
    ├── configs\
    │   ├── configs_backup\     # Backup dos YAMLs antigos
    │   └── keda\
    │       └── examples\
    │           ├── cpu-scaling-example.yaml
    │           ├── memory-scaling-example.yaml
    │           └── rabbitmq-scaling-example.yaml
    ├── docs\
    │   ├── fresh-machine\
    │   │   └── SETUP.md
    │   ├── KEDA.md
    │   └── README.md
    └── windows-test-structure.ps1
```

## Gerenciamento de Aplicações com Helm

A partir da Fase 18, as aplicações base (RabbitMQ e MongoDB) não são mais instaladas via `kubectl apply` com arquivos YAML estáticos. Agora, elas são gerenciadas como pacotes pelo **Helm**.

- **Onde estão os Charts?**
  - A configuração de cada serviço se encontra em `minikube/charts/`.
  - `minikube/charts/rabbitmq/`
  - `minikube/charts/mongodb/`

- **Como customizar?**
  - Para alterar configurações (versão, portas, senhas, limites de recursos), edite o arquivo `values.yaml` dentro da pasta do respectivo chart.

- **Como funciona?**
  - O script `init-minikube-fixed.ps1` agora executa `helm upgrade --install` para garantir que os serviços sejam instalados ou atualizados para a versão definida nos charts, de forma automática.

Essa abordagem torna o gerenciamento dos serviços muito mais robusto, versionável e fácil de manter.

## Processo de Desenvolvimento

### Regra Arquitetural:
1. **Desenvolvimento**: Todos os scripts experimentais devem ser criados na pasta `temp/`
2. **Teste e Validacao**: Testes completos na area temporaria
3. **Integracao**: Apenas codigo 100% funcional e validado vai para `minikube/`
4. **Manutencao**: Estrutura principal sempre estavel e profissional

### Workflow:
```
temp/scripts-teste/     →    Desenvolvimento
temp/validacoes/        →    Testes completos  
                        →    Validacao 100%
minikube/scripts/       →    Integracao final
```

### Vantagens:
- ✅ Estrutura principal sempre estavel
- ✅ Experimentos isolados sem risco
- ✅ Validacao completa antes da integracao
- ✅ Zero chance de "baguncar" ambiente funcional

## Componentes Instalados

### Minikube

### RabbitMQ
- **Versao**: 3.12-management
- **Credenciais**: guest/guest
- **Portas**: 15672 (Management), 5672 (AMQP)
- **Storage**: 1Gi persistente

### MongoDB
- **Versao**: 7.0
- **Credenciais**: admin/admin
- **Porta**: 27017
- **Storage**: 2Gi persistente
- **Memoria**: 1Gi

### Kubernetes Dashboard
- **Porta**: 15671
- **Acesso**: http://127.0.0.1:15671

### KEDA (Event-driven Autoscaling)
- **Versao**: 2.17+
- **Namespace**: keda
- **Funcionalidade**: Scale-to-zero, auto-scaling baseado em eventos
- **Triggers Suportados**: CPU, Memory, RabbitMQ, MongoDB, Prometheus, etc.
- **Documentacao**: [KEDA.md](KEDA.md)

## Como Usar

### ⚡ Sistema de Paths Dinâmicos

O projeto detecta automaticamente sua localização. Execute de qualquer pasta dentro do projeto:

```powershell
# Bootstrap completo (de qualquer lugar do projeto)
.\minikube\scripts\windows\Bootstrap-DevOps.ps1

# Inicialização (scripts detectam paths automaticamente)
.\minikube\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda

# Teste de estrutura
.\minikube\windows-test-structure.ps1
```

### Inicializacao Completa (com KEDA)
```powershell
.\minikube\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda
```

### Inicializacao Completa (sem KEDA)
```powershell
.\minikube\scripts\windows\init\init-minikube-fixed.ps1
```

### Instalar apenas KEDA
```powershell
.\minikube\scripts\windows\init\install-keda.ps1
```

### Verificar Status
```powershell
.\minikube\scripts\windows\maintenance\quick-status.ps1
```

### Abrir Dashboard
```powershell
.\minikube\scripts\windows\monitoring\open-dashboard.ps1
```

### Corrigir Dashboard
```powershell
.\minikube\scripts\windows\maintenance\fix-dashboard.ps1
```

## Setup para Maquina Nova (Sistema Offline)

### Para Desenvolvedores ou Novas Maquinas
O projeto inclui sistema completo de setup para maquinas novas sem necessidade de repositorio online:

#### 1. Transferir Projeto
- Copie toda a pasta do projeto via USB/rede/OneDrive
- Destino: qualquer local desejado (ex: `C:\DevOps`)

#### 2. Bootstrap Completo
```powershell
# Navegar para pasta do projeto (onde copiou)
cd "C:\DevOps"

# Executar bootstrap (instala dependencias + inicializa ambiente)
.\minikube\scripts\windows\Bootstrap-DevOps.ps1
```

#### 3. Setup Manual (Opcional)
Se preferir instalar apenas dependencias sem inicializar:
```powershell
# Apenas instalar Docker, Minikube, kubectl, Helm
.\temp\Setup-Fresh-Machine.ps1

# Inicializar depois manualmente
.\minikube\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda
```

**Documentacao Completa**: Ver `minikube\docs\fresh-machine\SETUP.md`

## Autostart no Windows (Configuracao Manual)
O arquivo `minikube-autostart.bat` esta disponivel em `scripts\windows\autostart\` como modelo.

**Para configurar autostart:**
1. Copie o arquivo para: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`
2. Ou configure da forma que preferir (Task Scheduler, etc.)

O script executa automaticamente na inicializacao do sistema quando configurado.

`minikube-autostart.bat` executa a inicializacao completa com KEDA por padrao.


**Nova Funcionalidade:** A janela permanece aberta durante a execução para acompanhar o progresso e só fecha após pressionar qualquer tecla.

## Troubleshooting

### Problema: kubectl versao incompativel
**Solucao**: Execute o script de correcao
```powershell
.\minikube\scripts\windows\maintenance\fix-kubectl-final.ps1
```

### Problema: Dashboard nao abre
**Solucao**: Execute o script de correcao do Dashboard
```powershell
.\minikube\scripts\windows\maintenance\fix-dashboard.ps1
```

### Problema: Dashboard erro 404 em CronJobs
**Limitação Conhecida**: Dashboard v2.7.0 incompatível com Kubernetes v1.34.0
**Detalhes**: Dashboard usa URLs de API internas incorretas para CronJobs
**Solução**: Use kubectl para gerenciar CronJobs:
```powershell
# Ver CronJobs
kubectl get cronjobs --all-namespaces

# Ver detalhes
kubectl describe cronjob cronjob-service -n cronjob-service

# Ver Jobs gerados
kubectl get jobs -n cronjob-service -l job-name
```
**Script de diagnóstico**:
```powershell
.\minikube\scripts\windows\maintenance\fix-dashboard-cronjob.ps1
```

### Problema: Docker nao esta rodando
**Solucao**: O script de inicializacao verifica e inicia o Docker automaticamente

### Problema: MongoDB com erro de memoria
**Solucao**: MongoDB ja esta configurado com 1Gi de memoria

## Credenciais de Acesso

### RabbitMQ Management
- **URL**: http://localhost:15672
- **Usuario**: guest
- **Senha**: guest

### MongoDB
- **Host**: localhost:27017
- **Usuario**: admin
- **Senha**: admin
- **Database**: admin

### Kubernetes Dashboard
- **URL**: http://127.0.0.1:15671
- **Token**: Não requerido (acesso direto via port-forward)

## Comandos Uteis

### Verificar servicos
```powershell
kubectl get pods,svc,pv,pvc
```

### Logs do RabbitMQ
```powershell
kubectl logs -l app=rabbitmq
```

### Logs do MongoDB
```powershell
kubectl logs -l app=mongodb
```

### Parar tudo
```powershell
minikube stop
```

### Limpar completamente
```powershell
minikube delete
```

## Requisitos do Sistema
- Windows 10/11
- Docker Desktop
- Minikube v1.37.0+
- kubectl v1.34.0+
- PowerShell 5.1+

## Notas Importantes
- Todos os dados sao persistentes (sobrevivem a reinicializacoes)
- O ambiente inicia automaticamente com o Windows
- Verificacao automatica do Docker antes da inicializacao
- Compatibilidade automatica entre kubectl e Kubernetes
