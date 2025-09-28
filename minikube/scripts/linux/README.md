# Scripts Linux para Automação do Minikube

Este diretório contém todos os scripts necessários para provisionar, validar, manter e monitorar um ambiente DevOps local com Minikube, MongoDB, RabbitMQ, KEDA e Dashboard Kubernetes.

## Estrutura dos Diretórios

```
minikube/scripts/linux/
├── autostart/
│   └── minikube-autostart.sh
├── init/
│   └── init-minikube-fixed.sh
├── keda/
│   ├── install-helm-fixed.sh
│   ├── install-keda.sh
│   └── test-keda.sh
├── maintenance/
│   ├── fix-dashboard.sh
│   ├── validate-rabbitmq-config.sh
│   └── placeholder.sh
├── monitoring/
│   ├── open-dashboard.sh
│   ├── change-dashboard-port.sh
│   └── placeholder.sh
├── linux-test-structure.sh
```

## Scripts Principais

### autostart/
- **minikube-autostart.sh**
  - Encaminha para `init/init-minikube-fixed.sh` garantindo `--install-keda`.
  - Ideal para inicializações automatizadas (systemd, cron, login).
  - Caso deseje pular o KEDA execute o script `init/init-minikube-fixed.sh` manualmente com `--skip-keda`.

### init/
- **init-minikube-fixed.sh**
  - Inicialização completa do cluster usando os charts Helm locais (`minikube/charts`).
  - Habilita addons essenciais, cria port-forwards (Dashboard em `4666`).
  - Suporta `--install-keda`, `--skip-keda`, `--skip-addons` e `--skip-rabbitmq-config`.

### keda/
- **install-keda.sh**
  - Instala o KEDA via Helm.
  - Faz pull e carrega imagens do KEDA no Minikube (offline friendly).
  - Valida CRDs e pods.
  - Uso:
    ```bash
    bash keda/install-keda.sh
    ```

- **install-helm-fixed.sh**
  - Instala o Helm de forma robusta.

- **test-keda.sh**
  - Testa e valida a instalação do KEDA e seus CRDs.

### maintenance/
- **fix-dashboard.sh**
  - Corrige problemas comuns do dashboard do Kubernetes.

- **validate-rabbitmq-config.sh**
  - Valida se as configurações do RabbitMQ estão corretas.

- **placeholder.sh**
  - Script de placeholder para futuras manutenções.

### monitoring/
- **open-dashboard.sh**
  - Garante port-forward estável em `http://localhost:4666` e abre o navegador via `xdg-open` quando disponível.

- **change-dashboard-port.sh**
  - Altera a porta do dashboard para evitar conflitos.

- **placeholder.sh**
  - Script de placeholder para futuras automações de monitoramento.

### Outros
- **linux-test-structure.sh**
  - Valida toda a estrutura do ambiente, conferindo se todos os componentes essenciais estão presentes e funcionando.

---

## Recomendações de Uso
- Execute sempre o `minikube-autostart.sh` para inicializar e validar o ambiente.
- Use os scripts de manutenção e monitoramento conforme necessidade.
- Para ambientes offline, garanta que as imagens do KEDA estejam previamente carregadas (o script já faz isso automaticamente).

## Exemplos de Execução
```bash
# Inicializar ambiente completo
bash autostart/minikube-autostart.sh

# Instalar KEDA separadamente
bash keda/install-keda.sh

# Validar estrutura
bash linux-test-structure.sh
```

---

Para dúvidas ou automações adicionais, consulte os comentários em cada script ou peça suporte ao responsável pelo DevOps.
> Os logs gerados pelos scripts de inicializacao sao registrados em `minikube/log/` (com fallback para `${TMPDIR:-/tmp}/minikube-log`).
