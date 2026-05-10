SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help start-linux start-macos stop status clean install-linux install-macos \
        keda-linux keda-macos dashboard-linux dashboard-macos \
        rabbitmq-test-linux rabbitmq-test-macos shellcheck pre-commit-install

help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

# ── Inicialização ────────────────────────────────────────────────────────────

start-linux: ## Inicia o ambiente Minikube no Linux
	@bash scripts/linux/init/start.sh

start-macos: ## Inicia o ambiente Minikube no macOS
	@bash scripts/macOs/init/start.sh

start-windows: ## Inicia o ambiente Minikube no Windows (abre PowerShell)
	@powershell.exe -ExecutionPolicy Bypass -File scripts/windows/init/start.ps1

# ── Dependências ─────────────────────────────────────────────────────────────

install-linux: ## Instala dependências (Docker, Minikube, kubectl, Helm) no Linux
	@bash scripts/linux/setup-fresh-machine.sh

install-macos: ## Instala dependências via Homebrew no macOS
	@bash scripts/macOs/setup-fresh-machine.sh

# ── Manutenção ───────────────────────────────────────────────────────────────

status: ## Exibe status do cluster e serviços
	@if command -v bash >/dev/null 2>&1; then \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			bash scripts/macOs/maintenance/status.sh; \
		else \
			bash scripts/linux/maintenance/status.sh; \
		fi \
	fi

stop: ## Para o cluster Minikube
	@minikube stop

clean: ## Deleta o cluster Minikube e limpa dados locais
	@echo "Deletando cluster Minikube..."
	@minikube delete --all --purge
	@echo "Pronto."

dashboard-linux: ## Corrige e abre o Kubernetes Dashboard no Linux
	@bash scripts/linux/maintenance/dashboard.sh

dashboard-macos: ## Corrige e abre o Kubernetes Dashboard no macOS
	@bash scripts/macOs/maintenance/dashboard.sh

# ── KEDA ─────────────────────────────────────────────────────────────────────

keda-linux: ## Instala o KEDA no Linux
	@bash scripts/linux/keda/install-keda.sh

keda-macos: ## Instala o KEDA no macOS
	@bash scripts/macOs/keda/install-keda.sh

keda-uninstall-linux: ## Desinstala o KEDA no Linux
	@bash scripts/linux/keda/install-keda.sh --uninstall

keda-uninstall-macos: ## Desinstala o KEDA no macOS
	@bash scripts/macOs/keda/install-keda.sh --uninstall

# ── Testes ───────────────────────────────────────────────────────────────────

rabbitmq-test-linux: ## Testa configuração do RabbitMQ no Linux
	@bash scripts/linux/maintenance/test-rabbitmq.sh

rabbitmq-test-macos: ## Testa configuração do RabbitMQ no macOS
	@bash scripts/macOs/maintenance/test-rabbitmq.sh

# ── Qualidade de Código ───────────────────────────────────────────────────────

shellcheck: ## Roda ShellCheck em todos os scripts bash
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck não encontrado. Instale: apt install shellcheck / brew install shellcheck"; exit 1; }
	@echo "Rodando ShellCheck..."
	@find scripts -name "*.sh" -print0 | xargs -0 shellcheck --severity=warning
	@shellcheck --severity=warning init-minikube-linux.sh init-minikube-macos.sh
	@echo "ShellCheck OK."

pre-commit-install: ## Instala o pre-commit hook de shellcheck
	@command -v pre-commit >/dev/null 2>&1 || { echo "pre-commit não encontrado. Instale: pip install pre-commit / brew install pre-commit"; exit 1; }
	@pre-commit install
	@echo "pre-commit instalado."
