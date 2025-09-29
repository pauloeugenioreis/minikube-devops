# PROMPT CONTINUIDADE – PROJETO MINIKUBE

## 📂 Estrutura Atual (28/09/2025)
- `<CAMINHO-DO-PROJETO>/minikube/`
  - `charts/` – Helm charts de RabbitMQ e MongoDB
  - `configs/` – Configurações ativas (Ingress, KEDA examples)
  - `docs/` – README, KEDA, Fresh Machine (SETUP/DEMO/CHECKLIST)
  - `scripts/linux/` – Scripts Bash oficiais (autostart, init, keda, maintenance, monitoring)
  - `scripts/windows/` – Scripts PowerShell oficiais (equivalentes e Fresh Machine)
  - `linux-test-structure.sh` / `windows-test-structure.ps1` – Validação completa da estrutura

## 🆕 Capacidades Recentes
- Charts Helm como fonte única: RabbitMQ/MongoDB sob `helm upgrade --install`.
- Scripts Linux/Windows pré-carregam a imagem `metrics-server:v0.8.0` (tag + digest) e patcham o deployment para evitar `ImagePullBackOff`.
- `wait_for_resource` (Linux) aguarda RabbitMQ/MongoDB até `Ready`; validação final prioriza `http://rabbitmq.local` com fallback para `localhost:15672`.
- Remoção do legado `apply-rabbitmq-config.sh`; documentação/validadores alinhados à arquitetura Helm.
- Detecção robusta da versão do `kubectl` (JSON ou saída padrão) em todos os scripts – sem uso do flag `--short`.

## 📌 Como Prosseguir
1. **Leia documentação atualizada** (`docs/README.md`, `docs/KEDA.md`, Fresh Machine).
2. **Respeite o workflow**: `temp/` → validação → migração → documentação → limpeza.
3. **Mantenha checklists**: siga `MANDATORY-CHECKLIST.md` a cada alteração.
4. **Testes**: execute `linux-test-structure.sh`/`windows-test-structure.ps1` após qualquer mudança estrutural.
5. **Documente sempre**: DECISIONS-HISTORY.md, MINIKUBE-PROJECT-HISTORY.md, CONTINUITY-PROMPT.md, BACKUP-PROMPT.md.

## 🧭 Relembrando Auto-start/Init
- Linux: `minikube/scripts/linux/autostart/minikube-autostart.sh` (inclui KEDA e metrics-server fix).
- Windows: `minikube/scripts/windows/autostart/minikube-autostart.bat` + `init-minikube-fixed.ps1`.

## 🪛 Próximos Passos (se necessários)
- Validar futuros serviços primeiro em `temp/`.
- Expandir charts Helm caso novos componentes sejam adicionados.
- Reexecutar scripts de teste após qualquer mudança em dependências.

**Status geral**: Ambiente Minikube + RabbitMQ + MongoDB + KEDA estável, com scripts multiplataforma totalmente alinhados.

## Atualizacao 29/09/2025
- Novo diretorio `minikube/scripts/windows/keda/` concentra instalacao e testes do KEDA
- Scripts dedicados (`install-helm-fixed.ps1`, `install-keda.ps1`, `test-keda.ps1`) substituem logica duplicada no init
- Instalador valida prerequisitos, ajusta imagePullPolicy e aguarda pods com feedback controlado
- Testes KEDA cobrem exemplos de CPU, memoria e RabbitMQ com flags `-SkipExamples` e `-CleanupOnly`
