# KEDA - Event-driven Autoscaling

## O que é KEDA?

KEDA (Kubernetes Event-driven Autoscaling) é uma ferramenta que permite escalar aplicações Kubernetes baseado em eventos externos, não apenas métricas de CPU/Memory.

## Características Principais

- **Scale-to-Zero**: Pode escalar aplicações para 0 replicas quando não há demanda
- **Event-driven**: Escalamento baseado em filas, tópicos, streams, etc.
- **Múltiplos Scalers**: Suporte para 50+ fontes de dados diferentes
- **HPA Integration**: Funciona com Horizontal Pod Autoscaler nativo do Kubernetes

## Instalação

### Instalação Automática (Recomendada)
```powershell
# Instalar junto com inicialização do Minikube
.\minikube\scripts\windows\init\init-minikube-fixed.ps1 -InstallKeda

# Ou instalar apenas KEDA em ambiente já configurado
.\minikube\scripts\windows\init\install-keda.ps1
```

### Instalação Manual
```powershell
# 1. Instalar Helm (se necessário)
.\minikube\scripts\windows\keda\install-helm-fixed.ps1

# 2. Instalar KEDA
.\minikube\scripts\windows\keda\install-keda.ps1
```

## Estrutura dos Arquivos

```
minikube/
├── configs/keda/
│   └── examples/           # Exemplos de configuração
│       ├── cpu-scaling-example.yaml
│       ├── memory-scaling-example.yaml
│       └── rabbitmq-scaling-example.yaml
└── scripts/windows/
    ├── init/
    │   ├── install-keda.ps1     # Instalação integrada
    │   └── init-minikube-fixed.ps1  # Script principal com suporte KEDA
    └── keda/               # Scripts KEDA específicos
        ├── install-helm-fixed.ps1
        ├── install-keda.ps1
        └── test-keda.ps1
```

## Comandos Úteis

### Verificação do Status
```bash
# Ver pods KEDA
kubectl get pods -n keda

# Ver ScaledObjects ativos
kubectl get scaledobject -A

# Ver HPAs criados pelo KEDA
kubectl get hpa -A

# Logs do KEDA operator
kubectl logs -n keda -l app.kubernetes.io/name=keda-operator
```

### Deployment de Exemplo
```bash
# Aplicar exemplo de CPU scaling
kubectl apply -f configs/keda/examples/cpu-scaling-example.yaml

# Verificar ScaledObject criado
kubectl describe scaledobject cpu-scaledobject

# Verificar HPA gerado automaticamente
kubectl get hpa keda-hpa-cpu-scaledobject
```

## Tipos de Scaling Suportados

### 1. CPU/Memory Scaling
```yaml
triggers:
- type: cpu
  metadata:
    type: Utilization
    value: "70"  # 70% CPU
```

### 2. RabbitMQ Queue Scaling
```yaml
triggers:
- type: rabbitmq
  metadata:
    host: amqp://guest:guest@rabbitmq-service:5672/
    queueName: task-queue
    queueLength: "10"
```

### 3. Memory Scaling
```yaml
triggers:
- type: memory
  metadata:
    type: Utilization
    value: "80"  # 80% Memory
```

## Integração com RabbitMQ/MongoDB

O KEDA pode escalar aplicações baseado em:

- **RabbitMQ**: Tamanho de filas, rate de mensagens
- **MongoDB**: Tamanho de collections, operações pendentes
- **Metrics**: Métricas customizadas via Prometheus

## Exemplos Práticos

### Exemplo 1: Worker que Processa Fila RabbitMQ
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: rabbitmq-worker-scaler
spec:
  scaleTargetRef:
    name: worker-deployment
  minReplicaCount: 0    # Scale-to-zero
  maxReplicaCount: 10
  triggers:
  - type: rabbitmq
    metadata:
      host: amqp://guest:guest@rabbitmq-service:5672/
      queueName: work-queue
      queueLength: "5"   # Escala quando > 5 mensagens
```

### Exemplo 2: API com Auto-scaling por CPU
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: api-cpu-scaler
spec:
  scaleTargetRef:
    name: api-deployment
  minReplicaCount: 1
  maxReplicaCount: 20
  triggers:
  - type: cpu
    metadata:
      type: Utilization
      value: "60"        # Escala quando CPU > 60%
```

## Monitoramento

### Verificar Status de Escalamento
```bash
# Ver todas as métricas KEDA
kubectl get scaledobject -o wide

# Detalhar escalador específico
kubectl describe scaledobject <nome>

# Ver eventos de escalamento
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Logs e Debugging
```bash
# Logs detalhados do KEDA
kubectl logs -n keda deployment/keda-operator -f

# Ver configuração do HPA gerado
kubectl describe hpa keda-hpa-<scaledobject-name>
```

## Troubleshooting

### Problemas Comuns

1. **ScaledObject não fica "Ready"**
   - Verificar se o deployment target existe
   - Verificar configuração dos triggers
   - Ver logs do KEDA operator

2. **HPA não é criado**
   - Verificar se metrics-server está rodando
   - Verificar sintaxe dos triggers
   - Verificar permissões RBAC

3. **Scale-to-zero não funciona**
   - Verificar se minReplicaCount está definido como 0
   - Verificar se há atividade na fonte de dados
   - Aguardar cooldown period

### Comandos de Diagnóstico
```bash
# Verificar CRDs KEDA
kubectl get crd | grep keda

# Verificar RBAC
kubectl get clusterrole | grep keda

# Verificar webhooks
kubectl get validatingwebhookconfiguration | grep keda
```

## Performance e Tuning

### Configurações Recomendadas

- **Cooldown Period**: 300s (5min) para scale-down
- **Scale-up Period**: 30s para scale-up
- **Min Replicas**: 1 para apps críticas, 0 para workers
- **Max Replicas**: Baseado na capacidade do cluster

### Exemplo com Configurações Avançadas
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: advanced-scaler
spec:
  scaleTargetRef:
    name: my-deployment
  minReplicaCount: 0
  maxReplicaCount: 50
  cooldownPeriod: 300      # 5min cooldown
  pollingInterval: 30      # Verificar a cada 30s
  triggers:
  - type: rabbitmq
    metadata:
      host: amqp://guest:guest@rabbitmq:5672/
      queueName: priority-queue
      queueLength: "3"
      vhostName: "/"
```

## Referências

- [Documentação Oficial KEDA](https://keda.sh/)
- [Lista de Scalers Suportados](https://keda.sh/docs/scalers/)
- [Exemplos KEDA](https://github.com/kedacore/samples)
- [KEDA no GitHub](https://github.com/kedacore/keda)