# Minikube DevOps Environment — Documentação

## Visão Geral

Ambiente Minikube com RabbitMQ, MongoDB, Redis e KEDA para desenvolvimento local. Os scripts validam dependências, aplicam charts Helm, configuram ingress e port-forwards e exibem endpoints de acesso. Suportado em **Windows**, **Linux** e **macOS**.

---

## Requisitos Mínimos

| Plataforma | Requisitos |
|---|---|
| **Windows** | Windows 10/11, PowerShell 5.1+, Docker Desktop, Minikube ≥ 1.38, kubectl ≥ 1.35 |
| **Linux** | Ubuntu 18.04+, Bash, Docker, Minikube ≥ 1.38, kubectl ≥ 1.35, Helm |
| **macOS** | macOS 12+, Homebrew, Docker Desktop, Minikube ≥ 1.38, kubectl ≥ 1.35, Helm |

- Mínimo 8 GB RAM e 30 GB livres recomendados
- Acesso administrativo para edição de `/etc/hosts` e instalação de dependências

---

## Estrutura Principal

- **[scripts/windows/](../scripts/windows/README.md)** — Bootstrap, inicialização, KEDA, manutenção e monitoramento (PowerShell)
- **[scripts/linux/](../scripts/linux/README.md)** — Equivalente em Bash com autostart, drivers interativos (Docker/KVM2) e validação
- **[scripts/macOs/](../scripts/macOs/README.md)** — Equivalente em Bash para macOS via Homebrew (Docker/QEMU2)
- **[charts/](../charts/)** — Helm charts para RabbitMQ, MongoDB e Redis (valores padrão versionados)
- **[configs/](../configs/)** — Exemplos KEDA: CPU, memória, RabbitMQ

---

## Iniciando no Windows

### Bootstrap Completo (Recomendado)
```powershell
cd <CAMINHO-DO-PROJETO>
.\scripts\windows\Bootstrap-DevOps.ps1
```
Instala Docker Desktop, Minikube, kubectl e Helm; inicializa o cluster com KEDA e aplica os charts.

### Inicialização Manual
```powershell
.\scripts\windows\init\start.ps1
# Para pular KEDA:
.\scripts\windows\init\start.ps1 -InstallKeda:$false
```

### Instalar Dependências Sem Subir o Cluster
```powershell
.\scripts\windows\Setup-Fresh-Machine.ps1
```

### Autostart no Windows
Copie `scripts\windows\autostart\minikube-autostart.bat` para:
```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
```

---

## Iniciando no Linux

### Bootstrap Completo (Máquina Nova)
```bash
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/linux/bootstrap-devops.sh | bash
```

### Com Projeto Clonado
```bash
./init-minikube-linux.sh
```
> O script apresentará um menu para escolha de driver (`docker` ou `kvm2`) e quantidade de `CPU / Memória`.
> Para executar sem pausas interativas, defina variáveis de ambiente antes da chamada, ex: `MINIKUBE_DRIVER=docker MINIKUBE_CPUS=4 MINIKUBE_MEMORY=8g ./init-minikube-linux.sh`

### Ferramentas Úteis
```bash
# Status do ambiente
bash scripts/linux/maintenance/status.sh

# Corrigir Dashboard
bash scripts/linux/maintenance/dashboard.sh
```

---

## Iniciando no macOS

### Bootstrap Completo (Máquina Nova)
```bash
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/macOs/bootstrap-devops.sh | bash
```

### Com Projeto Clonado
```bash
./init-minikube-macos.sh
```
> O script apresentará um menu interativo para recursos e driver oficial (`docker` ou `qemu2`).
> Para automação (fallback silencioso), proceda de forma injetada: `MINIKUBE_DRIVER=qemu2 ./init-minikube-macos.sh`

### Ferramentas Úteis
```bash
# Status do ambiente
bash scripts/macOs/maintenance/status.sh

# Corrigir Dashboard
bash scripts/macOs/maintenance/dashboard.sh
```

---

## Componentes Instalados

| Componente | Versão | Porta | Credenciais |
|---|---|---|---|
| RabbitMQ | 4.1 | 15672 (UI), 5672 (AMQP) | guest / guest |
| MongoDB | 8.0.15 | 27017 | admin / admin |
| Redis | 7.2 | 30679 | — |
| Kubernetes Dashboard | — | 15671 | — (acesso direto) |
| KEDA | 2.17+ | (namespace `keda`) | — |

> **Redis**: exposto na porta `30679` via port-forward (NodePort).

---

## Segurança e Credenciais

> **Atenção:** As credenciais abaixo são padrões para desenvolvimento local. **Nunca as use em ambientes compartilhados ou produção sem alterá-las.**

| Serviço | Usuário | Senha padrão | Arquivo de configuração |
|---|---|---|---|
| RabbitMQ | `guest` | `guest` | `charts/rabbitmq/values.yaml` → `credentials` |
| MongoDB | `admin` | `admin` | `charts/mongodb/values.yaml` → `credentials` |
| Redis | — | sem senha | `charts/redis/values.yaml` → `auth.enabled` |

### Como trocar as credenciais

**RabbitMQ:**
```bash
# Edite charts/rabbitmq/values.yaml e altere credentials.username / credentials.password
helm upgrade rabbitmq charts/rabbitmq
```

**MongoDB:**
```bash
# Edite charts/mongodb/values.yaml e altere credentials.username / credentials.password
helm upgrade mongodb charts/mongodb
```

**Redis (habilitar autenticação):**
```bash
# Edite charts/redis/values.yaml:
#   auth.enabled: true
#   auth.password: "sua-senha-forte"
helm upgrade redis charts/redis
```

> **Nota:** Alterar credenciais após o primeiro deploy requer deletar o PersistentVolumeClaim e recriar o serviço, pois os dados já foram inicializados com a senha antiga.

---

## Makefile — Comandos Rápidos

Para Linux e macOS, todos os fluxos principais estão disponíveis via `make`. Rode `make help` para ver a lista completa.

```bash
# Inicialização
make start-linux          # inicia o ambiente completo no Linux
make start-macos          # inicia o ambiente completo no macOS

# Manutenção
make status               # exibe status do cluster, pods e port-forwards
make stop                 # para o Minikube
make clean                # deleta o cluster e limpa dados (irreversível)
make dashboard-linux      # corrige RBAC e abre o Dashboard (Linux)
make dashboard-macos      # corrige RBAC e abre o Dashboard (macOS)

# Dependências
make install-linux        # instala Docker, Minikube, kubectl, Helm no Linux
make install-macos        # instala dependências via Homebrew no macOS

# KEDA
make keda-linux           # instala KEDA (Linux)
make keda-macos           # instala KEDA (macOS)
make keda-uninstall-linux # desinstala KEDA (Linux)
make keda-uninstall-macos # desinstala KEDA (macOS)

# Testes
make rabbitmq-test-linux  # valida configuração do RabbitMQ (Linux)
make rabbitmq-test-macos  # valida configuração do RabbitMQ (macOS)

# Qualidade de código
make shellcheck           # roda ShellCheck em todos os .sh
make pre-commit-install   # instala hook pré-commit de shellcheck
```

---

## Gerenciamento com Helm

Os serviços são instalados via `helm upgrade --install` a partir de `charts/`. Ajuste valores editando os `values.yaml` de cada chart. O script de inicialização (`start.sh` / `start.ps1`) garante que as versões declaradas sejam aplicadas a cada execução.

---

## Troubleshooting

| Problema | Solução |
|---|---|
| kubectl incompatível | `scripts/windows/maintenance/kubectl.ps1` |
| Dashboard não abre ou Erros 404 em Cronjobs | `scripts/windows/maintenance/dashboard.ps1` |
| Docker não responde | Scripts verificam e iniciam o serviço automaticamente |
| Minikube não inicia | `minikube delete --all --purge` e execute o init novamente |

Para Linux/macOS, use os scripts equivalentes em `scripts/linux/maintenance/` ou `scripts/macOs/maintenance/`.

---

## Comandos Úteis

```bash
kubectl get pods,svc,pv,pvc
kubectl logs -l app=rabbitmq
kubectl logs -l app=mongodb
minikube stop
minikube delete
```

---

## Documentação Adicional

| Arquivo | Conteúdo |
|---|---|
| [KEDA.md](KEDA.md) | Autoscaling orientado a eventos |
| [scripts/windows/README.md](../scripts/windows/README.md) | Referência dos scripts Windows |
| [scripts/linux/README.md](../scripts/linux/README.md) | Referência dos scripts Linux |
| [scripts/macOs/README.md](../scripts/macOs/README.md) | Referência dos scripts macOS |

---

## Backup e Restore dos Volumes

Os dados persistem em volumes dentro do nó minikube. Use os comandos abaixo para fazer backup e restauração.

### Backup

```bash
# MongoDB — dump completo
kubectl exec -n default deploy/mongodb -- \
  mongodump --uri="mongodb://admin:admin@localhost:27017/admin" \
  --out=/tmp/mongodump
kubectl cp default/$(kubectl get pod -l app=mongodb -o jsonpath='{.items[0].metadata.name}'):/tmp/mongodump ./backup-mongodb

# RabbitMQ — exportar definições (filas, exchanges, bindings)
kubectl port-forward svc/rabbitmq 15672:15672 &
curl -s -u guest:guest http://localhost:15672/api/definitions > backup-rabbitmq-definitions.json
kill %1

# Redis — dump RDB (precisa do redis-cli)
kubectl exec -n default deploy/redis -- redis-cli BGSAVE
kubectl cp default/$(kubectl get pod -l app=redis -o jsonpath='{.items[0].metadata.name}'):/data/dump.rdb ./backup-redis.rdb
```

### Restore

```bash
# MongoDB
kubectl cp ./backup-mongodb \
  default/$(kubectl get pod -l app=mongodb -o jsonpath='{.items[0].metadata.name}'):/tmp/mongodump
kubectl exec -n default deploy/mongodb -- \
  mongorestore --uri="mongodb://admin:admin@localhost:27017/admin" /tmp/mongodump

# RabbitMQ — importar definições
kubectl port-forward svc/rabbitmq 15672:15672 &
curl -s -u guest:guest -X POST -H "Content-Type: application/json" \
  -d @backup-rabbitmq-definitions.json \
  http://localhost:15672/api/definitions
kill %1

# Redis — restaurar RDB
kubectl cp ./backup-redis.rdb \
  default/$(kubectl get pod -l app=redis -o jsonpath='{.items[0].metadata.name}'):/data/dump.rdb
kubectl rollout restart deployment/redis
```

> **Atenção:** Troque as credenciais nos comandos acima se você as alterou em `values.yaml`.

---

## Upgrade e Downgrade de Charts

Os serviços são gerenciados com Helm, o que torna upgrades e downgrades simples e reproduzíveis.

### Upgrade de versão de imagem

1. Edite o campo `image.tag` no `values.yaml` do chart desejado:
   ```yaml
   # charts/rabbitmq/values.yaml
   image:
     tag: "4.2-management"   # era "4.1-management"
   ```

2. Aplique com Helm:
   ```bash
   helm upgrade rabbitmq charts/rabbitmq
   # ou via Makefile:
   # helm upgrade mongodb charts/mongodb
   # helm upgrade redis charts/redis
   ```

3. Acompanhe o rollout:
   ```bash
   kubectl rollout status deployment/rabbitmq
   ```

### Downgrade (rollback)

```bash
# Ver histórico de releases
helm history rabbitmq

# Voltar para a revisão anterior
helm rollback rabbitmq

# Ou voltar para uma revisão específica
helm rollback rabbitmq 2
```

### Upgrade de recursos (CPU/memória)

Edite a seção `resources` no `values.yaml` e rode `helm upgrade`. Não há perda de dados, pois os PVCs são mantidos.

---

## Notas Finais

- Dados ficam em volumes persistentes, sobrevivendo a reinicializações do Minikube.
- O `/etc/hosts` e os port-forwards são configurados automaticamente durante a inicialização.
- Os scripts assumem permissão administrativa para instalar dependências quando necessário.
