# Teste de Validação RabbitMQ 4.1.3

## Pré-requisitos
```bash
# Verificar se o Minikube está rodando
minikube status

# Verificar se o Helm está instalado
helm version
```

## Passos de Teste

### 1. Fazer Backup (se já existir instalação anterior)
```bash
# Se já tiver uma instalação do RabbitMQ
kubectl get configmap rabbitmq-config -o yaml > rabbitmq-backup.yaml
kubectl get secret -l app=rabbitmq -o yaml > rabbitmq-secrets-backup.yaml
```

### 2. Instalar/Atualizar o Chart
```bash
# Para nova instalação
helm install rabbitmq ./minikube/charts/rabbitmq

# Para atualização
helm upgrade rabbitmq ./minikube/charts/rabbitmq

# Verificar status
helm status rabbitmq
```

### 3. Verificar Deployments
```bash
# Verificar se os pods estão rodando
kubectl get pods -l app=rabbitmq

# Verificar logs
kubectl logs -l app=rabbitmq

# Verificar se os services estão ativos
kubectl get svc rabbitmq
```

### 4. Testar Conectividade

#### A. Teste AMQP (Porta 5672)
```bash
# Port-forward para teste local
kubectl port-forward svc/rabbitmq 5672:5672 &

# Testar conexão (se tiver ferramenta de teste AMQP)
# telnet localhost 5672
```

#### B. Teste Management Interface (Porta 15672)
```bash
# Port-forward para management
kubectl port-forward svc/rabbitmq 15672:15672 &

# Abrir no browser: http://localhost:15672
# Login: guest / guest
```

### 5. Validar Configurações RabbitMQ 4.x

#### A. Verificar Plugins Ativos
```bash
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmq-plugins list
```

#### B. Verificar Configurações
```bash
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl environment
```

#### C. Verificar Status do Cluster
```bash
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl cluster_status
```

#### D. Verificar Queue Types (Quorum como padrão)
```bash
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl list_queues name type
```

### 6. Teste de Performance Básico

#### A. Criar Queue de Teste
```bash
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl eval 'rabbit_amqqueue:declare({resource, <<"/">>, queue, <<"test_queue">>}, true, false, [], none).'
```

#### B. Verificar Métricas
```bash
# Acessar Prometheus metrics (se habilitado)
kubectl port-forward svc/rabbitmq 15692:15692 &
curl http://localhost:15692/metrics
```

## Pontos de Atenção RabbitMQ 4.x

1. **Quorum Queues**: Por padrão, novas queues serão quorum queues
2. **Peer Discovery**: Usando discovery do Kubernetes
3. **Recursos**: Memoria aumentada para melhor performance
4. **Plugins**: Sintaxe atualizada para v4.x

## Rollback (se necessário)
```bash
# Voltar para versão anterior
helm rollback rabbitmq

# Ou reinstalar com versão 3.x
# Editar values.yaml tag para "3.12-management"
# helm upgrade rabbitmq ./minikube/charts/rabbitmq
```

## Troubleshooting

### Pod não inicia
```bash
kubectl describe pod -l app=rabbitmq
kubectl logs -l app=rabbitmq --previous
```

### Problemas de RBAC
```bash
kubectl get serviceaccount rabbitmq
kubectl get role rabbitmq-peer-discovery
kubectl get rolebinding rabbitmq-peer-discovery
```

### Problemas de Configuração
```bash
kubectl get configmap rabbitmq-config -o yaml
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- cat /etc/rabbitmq/rabbitmq.conf
```
