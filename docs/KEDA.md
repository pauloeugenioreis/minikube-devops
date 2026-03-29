# KEDA - Event-driven Autoscaling


## O que é o KEDA?
KEDA (Kubernetes Event-driven Autoscaling) permite escalar workloads Kubernetes com base em eventos externos, indo além das métricas padrão de CPU e memória.


## Principais recursos
- Scale-to-zero: reduz réplicas para zero quando não há demanda
- Escalonamento orientado a eventos: filas, tópicos, streams e muito mais
- Mais de 50 scalers suportados oficialmente
- Integração com o Horizontal Pod Autoscaler nativo do Kubernetes


## Instalação

### Opção automática (recomendada)
```powershell
# Instalar junto com a inicialização completa do Minikube
./scripts/windows/init/init-minikube-fixed.ps1

# Instalar apenas o KEDA em um ambiente já configurado
./scripts/windows/init/install-keda.ps1
```

### Opção manual
```powershell
# 1. Garantir que o Helm esteja instalado
./scripts/windows/keda/install-helm-fixed.ps1

# 2. Instalar o KEDA via Helm
./scripts/windows/keda/install-keda.ps1
```


## Estrutura dos arquivos

```text
configs/
  keda/
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

# 3. Escalonamento por memória
triggers:
- type: memory
  metadata:
    type: Utilization
    value: "80"
```


## Integração com RabbitMQ e MongoDB
- **RabbitMQ**: escala com base em tamanho de filas e taxa de mensagens
- **MongoDB**: escala considerando tamanho de coleções ou operações pendentes
- **Métricas personalizadas**: suporta Prometheus ou fontes customizadas


## Mais referências
- Documentação oficial: https://keda.sh/
- Exemplos adicionais neste repositório: `configs/keda/examples/`
