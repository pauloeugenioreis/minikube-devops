# KEDA — Event-driven Autoscaling

## O que é o KEDA?

KEDA (Kubernetes Event-driven Autoscaling) permite escalar workloads Kubernetes com base em eventos externos, indo além das métricas padrão de CPU e memória.

### Principais recursos
- **Scale-to-zero**: reduz réplicas para zero quando não há demanda
- **Escalonamento orientado a eventos**: filas, tópicos, streams e muito mais
- **Mais de 50 scalers** oficialmente suportados
- **Integração nativa** com o Horizontal Pod Autoscaler do Kubernetes

---

## Instalação

### 🪟 Windows
```powershell
# Junto com a inicialização completa (padrão)
.\scripts\windows\init\init-minikube-fixed.ps1

# Apenas o KEDA em ambiente já configurado
.\scripts\windows\keda\install-keda.ps1
```

### 🐧 Linux
```bash
# Junto com a inicialização completa (padrão)
bash scripts/linux/autostart/minikube-autostart.sh

# Apenas o KEDA em ambiente já configurado
bash scripts/linux/keda/install-keda.sh
```

### 🍎 macOS
```bash
# Junto com a inicialização completa (padrão)
bash scripts/macOs/autostart/minikube-autostart.sh

# Apenas o KEDA em ambiente já configurado
bash scripts/macOs/keda/install-keda.sh
```

---

## Estrutura dos arquivos

```text
configs/keda/examples/
  ├── cpu-scaling-example.yaml
  ├── memory-scaling-example.yaml
  └── rabbitmq-scaling-example.yaml

scripts/
  ├── windows/keda/
  │   ├── install-helm-fixed.ps1
  │   ├── install-keda.ps1
  │   └── test-keda.ps1
  ├── linux/keda/
  │   ├── install-helm-fixed.sh
  │   ├── install-keda.sh
  │   └── test-keda.sh
  └── macOs/keda/
      ├── install-helm-fixed.sh
      ├── install-keda.sh
      └── test-keda.sh
```

---

## Comandos úteis

```bash
# Ver pods do KEDA
kubectl get pods -n keda

# Ver ScaledObjects ativos
kubectl get scaledobject -A

# Ver HPAs gerados pelo KEDA
kubectl get hpa -A

# Logs do operador
kubectl logs -n keda -l app.kubernetes.io/name=keda-operator
```

---

## Exemplos de ScaledObject

### 1. Escalonamento por CPU
```yaml
triggers:
- type: cpu
  metadata:
    type: Utilization
    value: "70"
```

### 2. Escalonamento por fila RabbitMQ
```yaml
triggers:
- type: rabbitmq
  metadata:
    host: amqp://guest:guest@rabbitmq-service:5672/
    queueName: task-queue
    queueLength: "10"
```

### 3. Escalonamento por memória
```yaml
triggers:
- type: memory
  metadata:
    type: Utilization
    value: "80"
```

### Aplicar exemplos
```bash
# Escalonamento por CPU
kubectl apply -f configs/keda/examples/cpu-scaling-example.yaml

# Verificar ScaledObject criado
kubectl describe scaledobject cpu-scaledobject

# Verificar HPA correspondente
kubectl get hpa keda-hpa-cpu-scaledobject
```

---

## Testar instalação

```bash
# Linux / macOS
bash scripts/linux/keda/test-keda.sh
bash scripts/macOs/keda/test-keda.sh
```
```powershell
# Windows
.\scripts\windows\keda\test-keda.ps1
```

---

## Desinstalar

```bash
# Linux / macOS
bash scripts/linux/keda/install-keda.sh --uninstall
bash scripts/macOs/keda/install-keda.sh --uninstall
```
```powershell
# Windows
.\scripts\windows\keda\install-keda.ps1 -Uninstall
```

---

## Mais referências

- Documentação oficial: https://keda.sh/
- Exemplos adicionais: `configs/keda/examples/`
