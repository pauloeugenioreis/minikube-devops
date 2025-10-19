# Minikube DevOps Environment

## Visao Geral
Ambiente Minikube opinado com RabbitMQ, MongoDB, Redis e KEDA, preparado para iniciar automaticamente em Windows e Linux. Os scripts validam dependencias, aplicam charts Helm, configuram ingress e exibem endpoints uteis.

## Requisitos Minimos
- Windows 10/11 com PowerShell 5.1+, Docker Desktop, Minikube >= 1.37.0, kubectl >= 1.34.0.
- Linux com Bash, Docker, Minikube, kubectl e Helm instalados (os scripts verificam e instalam quando possivel).
- Pelo menos 8 GB de RAM e 30 GB livres recomendados para rodar os servicos de forma confortavel.
- Acesso administrativo para permitir alteracoes em hosts e instalacao de dependencias.

## Estrutura Principal
- **Scripts Windows** (`minikube/scripts/windows`): bootstrap completo, inicializacao, automacoes de KEDA, manutencao e monitoramento.
- **Scripts Linux** (`minikube/scripts/linux`): equivalente em Bash com autostart, instalacao de dependencias e ferramentas de validacao.
- **Charts Helm** (`minikube/charts`): pacotes Helm para RabbitMQ, MongoDB e Redis com valores padrao versionados.
- **Documentacao** (`minikube/docs`): guias complementares como `fresh-machine/SETUP.md` e `KEDA.md`.
- **Area de testes** (`temp/`): espaco isolado para prototipos antes de promover scripts para `minikube/`.

## Iniciando no Linux
### 🚀 Setup para Máquina Nova Ubuntu
```bash
# Bootstrap completo - download + instalação + inicialização
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/minikube/scripts/linux/bootstrap-devops.sh | bash

# Ou se já tem o projeto:
cd <CAMINHO-DO-PROJETO>/DevOps
bash minikube/scripts/linux/setup-fresh-machine.sh --run-initialization
```

### Passo a passo rapido (projeto existente)
```
cd <CAMINHO-DO-PROJETO>/DevOps
bash minikube/scripts/linux/autostart/minikube-autostart.sh
```
O script valida Docker, Minikube e kubectl, inicia o cluster, aplica charts, configura ingress/port-forward e exibe URLs de acesso. Tambem atualiza automaticamente o arquivo `/etc/hosts` com o IP do Minikube.

### Comandos uteis
```
bash minikube/scripts/linux/keda/install-keda.sh
bash minikube/linux-test-structure.sh
bash minikube/scripts/linux/monitoring/open-dashboard.sh
```

### Endpoints principais
- RabbitMQ Management: `http://rabbitmq.local` (requer entrada em `/etc/hosts`, adicionada pelo autostart).
- Redis: `redis://localhost:6379` via port-forward configurado automaticamente.
- Kubernetes Dashboard: `http://localhost:15671` via port-forward configurado automaticamente.

## Iniciando no Windows
### Opcao recomendada (bootstrap completo)
```
.\minikube\scripts\windows\Bootstrap-DevOps.ps1
```
Executa validacao/instalacao de Docker, Minikube, kubectl e Helm, inicializa o cluster com KEDA e aplica os charts.

### Inicializacao manual
```
.\minikube\scripts\windows\init\init-minikube-fixed.ps1
```
O script instala e valida o KEDA por padrao; para pular essa etapa execute com `-InstallKeda:$false`.

### Instalar dependencias sem subir o cluster
```
.\temp\Setup-Fresh-Machine.ps1
```
Ideal para preparar maquinas offline antes de iniciar o ambiente.

### Ferramentas adicionais
```
.\minikube\scripts\windows\maintenance\quick-status.ps1
.\minikube\scripts\windows\monitoring\open-dashboard.ps1
.\minikube\scripts\windows\maintenance\fix-dashboard.ps1
.\minikube\scripts\windows\maintenance\fix-kubectl-final.ps1
```

### Autostart no Windows
Copie `minikube\scripts\windows\autostart\minikube-autostart.bat` para `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`. A janela permanece aberta ate o usuario confirmar com uma tecla, facilitando acompanhar o progresso.

## Gerenciamento com Helm
Os servicos principais sao instalados via `helm upgrade --install` a partir de `minikube/charts`. Ajuste configuracoes editando os arquivos `values.yaml` de cada chart. O script `init-minikube-fixed` garante que as versoes declaradas sejam aplicadas em cada execucao.

## Fluxo de Desenvolvimento
Scripts novos devem nascer em `temp/`, passar por validacoes e so entao serem promovidos para `minikube/`. Assim a base consolidada permanece estavel, enquanto experimentos ficam isolados.

## Componentes Instalados

- RabbitMQ 4.1 com painel em `http://localhost:15672`, usuario `guest/guest`, storage persistente de 1Gi.
- MongoDB 8.0.15 com `admin/admin`, exposto em `localhost:27017`, limite de memoria em 1Gi e storage de 2Gi.
- Redis 7.2 com cache otimizado, exposto em `localhost:6379`, limite de memoria em 256Mi e storage de 1Gi.
- Kubernetes Dashboard publicado em `http://127.0.0.1:15671`.
- KEDA 2.17+ no namespace `keda`, com triggers para CPU, memoria, RabbitMQ e outros.

## Troubleshooting

- `.\minikube\scripts\windows\maintenance\fix-kubectl-final.ps1`: corrige incompatibilidade de `kubectl`.
- `.\minikube\scripts\windows\maintenance\fix-dashboard.ps1`: reconfigura o dashboard quando nao abre.
- `.\minikube\scripts\windows\maintenance\fix-dashboard-cronjob.ps1`: contorna erro 404 ao listar CronJobs na versao 2.7.0 do dashboard.
- Docker parou? Os scripts verificam e iniciam o servico automaticamente.
- MongoDB com alerta de memoria? Os charts ja definem 1Gi reservado.

## Credenciais de Acesso

- Kubernetes Dashboard: `http://127.0.0.1:15671` (token nao requerido, acesso direto).
- RabbitMQ Management: `http://localhost:15672` com `guest/guest`.
- MongoDB: `admin/admin` em `localhost:27017`, banco `admin`.
- Redis: `redis://localhost:6379` (sem senha).

## Comandos Uteis

```bash
kubectl get pods,svc,pv,pvc
kubectl logs -l app=rabbitmq
kubectl logs -l app=mongodb
kubectl logs -l app=redis
minikube stop
minikube delete
```

## Documentacao Adicional

- `minikube/docs/fresh-machine/SETUP.md`: guia completo para preparar maquinas novas e ambientes offline.
- `minikube/docs/KEDA.md`: detalhes sobre escalonamento orientado a eventos.
- `minikube/scripts/linux/README.md`: referencia especifica dos scripts Bash.

## Notas Finais

- Dados ficam em volumes persistentes, sobrevivendo a reinicializacoes do Minikube.
- O host recebe ajustes e port-forward automaticamente durante a inicializacao.
- Os scripts assumem permissao administrativa para instalar dependencias e editar hosts quando necessario.

