# Guia: Migração do K8s atual para Minikube Autostart

## ✅ **Sim, você pode remover as configurações do K8s e usar o autostart!**

### 🧹 **Passo 1: Limpeza do K8s Atual**

#### A. Verificar o que está rodando atualmente
```bash
# Verificar pods do RabbitMQ e MongoDB
kubectl get pods -l app=rabbitmq
kubectl get pods -l app=mongodb

# Verificar services
kubectl get svc

# Verificar releases do Helm (se usando Helm)
helm list
```

#### B. Fazer backup dos dados (se necessário)
```bash
# Backup do RabbitMQ (se tiver dados importantes)
kubectl exec -it $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}') -- rabbitmqctl export_definitions /tmp/definitions.json
kubectl cp $(kubectl get pods -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}'):/tmp/definitions.json ./rabbitmq-backup.json

# Backup do MongoDB (se tiver dados importantes)
kubectl exec -it $(kubectl get pods -l app=mongodb -o jsonpath='{.items[0].metadata.name}') -- mongodump --archive --gzip > mongodb-backup.gz
```

#### C. Remover instalações atuais
```bash
# Se instalado via Helm
helm uninstall rabbitmq 2>/dev/null || true
helm uninstall mongodb 2>/dev/null || true

# Se instalado via kubectl apply
kubectl delete all -l app=rabbitmq
kubectl delete all -l app=mongodb
kubectl delete pvc -l app=rabbitmq
kubectl delete pvc -l app=mongodb
kubectl delete configmap -l app=rabbitmq
kubectl delete configmap -l app=mongodb
kubectl delete secret -l app=rabbitmq
kubectl delete secret -l app=mongodb

# Remover PVs se necessário
kubectl get pv
# kubectl delete pv <nome-do-pv> (se quiser limpar completamente)
```

### 🚀 **Passo 2: Usar o Autostart do Minikube**

#### A. Verificar se o Minikube está rodando
```bash
minikube status
```

#### B. Se não estiver rodando, iniciar:
```bash
minikube start
```

#### C. Executar o autostart (vai instalar tudo automaticamente)
```bash
cd /home/paulo/Downloads/Globo/minikube-devops
chmod +x minikube/scripts/linux/autostart/minikube-autostart.sh
./minikube/scripts/linux/autostart/minikube-autostart.sh
```

### 📋 **O que o Autostart faz:**

1. **Inicializa o Minikube** (se não estiver rodando)
2. **Instala Helm** (se não estiver instalado)
3. **Deploy do RabbitMQ** via Helm chart (com suas configurações 4.1.3)
4. **Deploy do MongoDB** via Helm chart
5. **Instala KEDA** automaticamente
6. **Configura port-forwards**:
   - RabbitMQ Management: http://localhost:15672
   - RabbitMQ AMQP: localhost:5672
7. **Aguarda todos os recursos ficarem prontos**

### 🔍 **Verificação Pós-Instalação**

#### A. Verificar se tudo subiu corretamente
```bash
# Verificar pods
kubectl get pods

# Verificar services
kubectl get svc

# Verificar port-forwards ativos
ps aux | grep "port-forward"
```

#### B. Testar acesso
```bash
# RabbitMQ Management
curl -u guest:guest http://localhost:15672/api/overview

# Ou abrir no browser
xdg-open http://localhost:15672
```

### ⚡ **Vantagens do Autostart:**

- ✅ **Tudo automatizado** - instala e configura tudo de uma vez
- ✅ **Usa seus charts atualizados** - com RabbitMQ 4.1.3
- ✅ **KEDA incluído** - para autoscaling
- ✅ **Port-forwards automáticos** - acesso imediato
- ✅ **Aguarda recursos ficarem ready** - não precisa ficar verificando manualmente

### 🚨 **Pontos de Atenção:**

1. **Dados**: Se você tem dados importantes, faça backup antes
2. **Configurações customizadas**: O autostart usa as configurações dos charts
3. **Namespace**: Por padrão, instala no namespace `default`
4. **Recursos**: Certifique-se que o Minikube tem recursos suficientes

### 🔄 **Se quiser reinstalar/atualizar no futuro:**

```bash
# Parar o autostart atual
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Rodar novamente
./minikube/scripts/linux/autostart/minikube-autostart.sh
```

### 📝 **Comando Completo para Migração:**

```bash
# 1. Limpar atual (CUIDADO: remove tudo!)
helm uninstall rabbitmq mongodb 2>/dev/null || true
kubectl delete all,pvc,configmap,secret -l app=rabbitmq
kubectl delete all,pvc,configmap,secret -l app=mongodb

# 2. Rodar autostart
cd /home/paulo/Downloads/Globo/minikube-devops
./minikube/scripts/linux/autostart/minikube-autostart.sh

# 3. Verificar
kubectl get pods
curl -u guest:guest http://localhost:15672/api/overview
```

**Pronto! Sua infraestrutura estará limpa e funcionando com o autostart do Minikube! 🎉**
