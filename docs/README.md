# Minikube DevOps Environment — Documentação

## Visão Geral

Ambiente Minikube com RabbitMQ, MongoDB, Redis e KEDA para desenvolvimento local. Os scripts validam dependências, aplicam charts Helm, configuram ingress e port-forwards e exibem endpoints de acesso. Suportado em **Windows**, **Linux** e **macOS**.

---

## Requisitos Mínimos

| Plataforma | Requisitos |
|---|---|
| **Windows** | Windows 10/11, PowerShell 5.1+, Docker Desktop, Minikube ≥ 1.37, kubectl ≥ 1.34 |
| **Linux** | Ubuntu 18.04+, Bash, Docker, Minikube, kubectl, Helm |
| **macOS** | macOS 12+, Homebrew, Docker Desktop, Minikube, kubectl, Helm |

- Mínimo 8 GB RAM e 30 GB livres recomendados
- Acesso administrativo para edição de `/etc/hosts` e instalação de dependências

---

## Estrutura Principal

- **[scripts/windows/](../scripts/windows/README.md)** — Bootstrap, inicialização, KEDA, manutenção e monitoramento (PowerShell)
- **[scripts/linux/](../scripts/linux/README.md)** — Equivalente em Bash com autostart, drivers (Docker/KVM) e validação
- **[scripts/macOs/](../scripts/macOs/README.md)** — Equivalente em Bash para macOS via Homebrew (Docker Desktop, Hyperkit)
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
.\scripts\windows\init\init-minikube-fixed.ps1
# Para pular KEDA:
.\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda:$false
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
cd <CAMINHO-DO-PROJETO>
bash scripts/linux/autostart/minikube-autostart.sh
```

### Ferramentas Úteis
```bash
bash scripts/linux/keda/install-keda.sh
bash scripts/linux/monitoring/open-dashboard.sh
bash linux-test-structure.sh
```

---

## Iniciando no macOS

### Bootstrap Completo (Máquina Nova)
```bash
curl -fsSL https://raw.githubusercontent.com/pauloeugenioreis/minikube-devops/main/scripts/macOs/bootstrap-devops.sh | bash
```

### Com Projeto Clonado
```bash
cd <CAMINHO-DO-PROJETO>
bash scripts/macOs/autostart/minikube-autostart.sh
```

### Ferramentas Úteis
```bash
bash scripts/macOs/keda/install-keda.sh
bash scripts/macOs/monitoring/open-dashboard.sh
bash macos-test-structure.sh
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

## Gerenciamento com Helm

Os serviços são instalados via `helm upgrade --install` a partir de `charts/`. Ajuste valores editando os `values.yaml` de cada chart. O script `init-minikube-fixed` garante que as versões declaradas sejam aplicadas a cada execução.

---

## Troubleshooting

| Problema | Solução |
|---|---|
| kubectl incompatível | `scripts/windows/maintenance/fix-kubectl-final.ps1` |
| Dashboard não abre | `scripts/windows/maintenance/fix-dashboard.ps1` |
| Erro 404 em CronJobs | `scripts/windows/maintenance/fix-dashboard-cronjob.ps1` |
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

## Notas Finais

- Dados ficam em volumes persistentes, sobrevivendo a reinicializações do Minikube.
- O `/etc/hosts` e os port-forwards são configurados automaticamente durante a inicialização.
- Os scripts assumem permissão administrativa para instalar dependências quando necessário.
