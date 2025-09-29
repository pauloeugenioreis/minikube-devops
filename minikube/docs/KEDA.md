# KEDA - Event-driven Autoscaling

## O que e o KEDA?
KEDA (Kubernetes Event-driven Autoscaling) permite escalar workloads Kubernetes com base em eventos externos, indo alem das metricas padrao de CPU e memoria.

## Principais recursos
- Scale-to-zero: reduz replicas para zero quando nao ha demanda
- Escalonamento orientado a eventos: filas, topicos, streams e muito mais
- Mais de 50 scalers suportados oficialmente
- Integracao com o Horizontal Pod Autoscaler nativo do Kubernetes

## Instalacao

### Opcao automatica (recomendada)
```powershell
# Instalar junto com a inicializacao completa do Minikube
.\minikube\scripts\windows\init\init-minikube-fixed.ps1

# Instalar apenas o KEDA em um ambiente ja configurado
.\minikube\scripts\windows\init\install-keda.ps1
```

### Opcao manual
```powershell
# 1. Garantir que o Helm esteja instalado
.\minikube\scripts\windows\keda\install-helm-fixed.ps1

# 2. Instalar o KEDA via Helm
.\minikube\scripts\windows\keda\install-keda.ps1
```

## Estrutura dos arquivos
```
minikube/
  configs/keda/
    examples/
      cpu-scaling-example.yaml
      memory-scaling-example.yaml
      rabbitmq-scaling-example.yaml
  scripts/windows/
    init/
      install-keda.ps1
      init-minikube-fixed.ps1
    keda/
      install-helm-fixed.ps1
      install-keda.ps1
      test-keda.ps1
```

## Comandos uteis
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

## Deployment de exemplo
```bash
# Aplicar o exemplo de escalonamento por CPU
kubectl apply -f configs/keda/examples/cpu-scaling-example.yaml

# Conferir o ScaledObject criado
kubectl describe scaledobject cpu-scaledobject

# Conferir o HPA correspondente
kubectl get hpa keda-hpa-cpu-scaledobject
```

## Triggers mais comuns
```yaml
# 1. Escalonamento por CPU
triggers:
- type: cpu
  metadata:
    type: Utilization
    value: "70"

# 2. Escalonamento por fila RabbitMQ
triggers:
- type: rabbitmq
  metadata:
    host: amqp://guest:guest@rabbitmq-service:5672/
    queueName: task-queue
    queueLength: "10"

# 3. Escalonamento por memoria
triggers:
- type: memory
  metadata:
    type: Utilization
    value: "80"
```

## Integracao com RabbitMQ e MongoDB
- **RabbitMQ**: escala com base em tamanho de filas e taxa de mensagens
- **MongoDB**: escala considerando tamanho de colecoes ou operacoes pendentes
- **Metrics personalizadas**: suporta Prometheus ou fontes customizadas

## Mais referencias
- Documentacao oficial: https://keda.sh/
- Exemplos adicionais neste repositorio: `minikube/configs/keda/examples/`
