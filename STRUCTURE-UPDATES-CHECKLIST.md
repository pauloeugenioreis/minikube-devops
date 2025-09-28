# 📋 CHECKLIST PARA ATUALIZAÇÕES NA ESTRUTURA MINIKUBE

## 🎯 ARQUIVOS QUE SEMPRE DEVEM SER VERIFICADOS

Sempre que adicionar novos serviços, componentes ou fazer mudanças na estrutura:

### 1. **windows-test-structure.ps1**
- ✅ Adicionar testes para novos componentes
- ✅ Verificar caminhos dos arquivos
- ✅ Testar execução sem erros

- **Autostart**: Script unico com KEDA disponivel
- ?o. Atualizar script com novos serviAos quando necessario
- ?o. Garantir que argumentos padrao habilitem KEDA
- ?o. Documentar localizacao/uso do script

### 3. **docs/README.md**
- ✅ Atualizar estrutura de diretórios
- ✅ Adicionar seção do novo serviço
- ✅ Atualizar comandos de uso
- ✅ Atualizar seção "Como Usar"

### 4. **Documentação Específica**
- ✅ Criar arquivo .md específico (ex: KEDA.md)
- ✅ Documentar instalação, configuração, uso
- ✅ Incluir exemplos práticos
- ✅ Adicionar troubleshooting

### 5. **init-minikube-fixed.ps1**
- ✅ Adicionar parâmetros para novos serviços
- ✅ Integrar scripts de instalação
- ✅ Manter compatibilidade com versão sem o serviço

### 6. **Scripts Linux (se aplicvel)**
- ✅ Converter scripts PowerShell para Bash
- ✅ Adaptar para sintaxe Linux (systemd, xdg-open, etc.)
- ✅ Criar equivalência funcional 100%
- ✅ Testar em ambiente Linux de destino
- ✅ Documentar dependências específicas Linux

### 7. **Manutenção Estrutural**
- ✅ Evitar duplicação de arquivos de teste
- ✅ Manter arquivo único principal (windows-test-structure.ps1)
- ✅ Remover backups/versões antigas após validação
- ✅ Verificar funcionamento após limpeza
- ✅ Atualizar documentação após mudanças estruturais

### 8. **Detecção Automática de SO**
- ✅ SEMPRE detectar SO antes de executar qualquer ação
- ✅ Windows: Usar scripts PowerShell (minikube/scripts/windows/)
- ✅ Linux: Usar scripts Bash (temp/linux-scripts/ ou minikube/scripts/linux/)
- ✅ Adaptar comandos para sintaxe específica do SO
- ✅ Documentar qual SO foi detectado e usado
- ✅ Garantir compatibilidade multiplataforma

## 📝 PROCEDIMENTO PADRÃO ESTABELECIDO

### Fase 1: Desenvolvimento
```
temp/nome-do-servico/
├── scripts/
├── configs/
├── examples/
└── README.md
```

### Fase 2: Validação
- ✅ Testar 100% na pasta temp/
- ✅ Validar todos os scripts
- ✅ Confirmar exemplos funcionais
- ✅ Documentar problemas e soluções

### Fase 3: Integração
```
minikube/
├── configs/nome-do-servico/
├── scripts/windows/nome-do-servico/
├── scripts/windows/init/install-nome-do-servico.ps1
└── docs/NOME-DO-SERVICO.md
```

### Fase 4: Atualização de Arquivos
1. **windows-test-structure.ps1** → Adicionar testes
2. **docs/README.md** → Atualizar documentação
- **Autostart**: Script unico com KEDA disponivel
4. **init script** → Integrar instalação
5. **values.yaml** → Garantir que as configurações padrão são seguras e funcionais

### Fase 5: Teste Final
- ✅ Testar inicialização completa
- ✅ Validar documentação
- ✅ Confirmar exemplos funcionais

## 🎯 EXEMPLO: INTEGRAÇÃO KEDA (REALIZADA)

### ✅ Arquivos Adicionados:
- `charts/rabbitmq/` e `charts/mongodb/` (Migração para Helm)

### ✅ Arquivos Atualizados:
- **Autostart**: Script unico com KEDA disponivel

### ✅ Resultado:
- Documentação completa
- Testes funcionais
- **Autostart**: Script unico com KEDA disponivel

## 🚨 PONTOS DE ATENÇÃO

### Sempre Verificar:
1. **Encoding de arquivos** - Usar UTF-8 sem BOM
2. **Caminhos absolutos** vs relativos
3. **Compatibilidade** com versões anteriores
4. **Permissões** de execução PowerShell
5. **Dependências** entre serviços (ex: um chart que depende de outro)
6. **Valores padrão** no `values.yaml`

### Nunca Fazer:
- ❌ Quebrar compatibilidade com scripts existentes
- ❌ Esquecer de atualizar documentação
- ❌ Deixar testes quebrados
- ❌ Hardcode caminhos desnecessariamente

## 📚 TEMPLATE PARA NOVOS SERVIÇOS

### Estrutura Mínima:
```
temp/novo-servico/
├── scripts/
│   ├── install-novo-servico.ps1
│   └── test-novo-servico.ps1
├── configs/
│   └── examples/
└── README.md
```

### Integração Mínima:
```
minikube/
├── configs/novo-servico/
├── scripts/windows/novo-servico/
├── scripts/windows/init/install-novo-servico.ps1
└── docs/NOVO-SERVICO.md
```

## ✅ STATUS ATUAL

- **KEDA**: ✅ 100% Integrado e Documentado
- **RabbitMQ**: ✅ Funcional
- **MongoDB**: ✅ Funcional  
- **Dashboard**: ✅ Funcional
- **Autostart**: Script unico com KEDA disponivel
- **Documentação**: ✅ Completa e atualizada
- **Testes**: ✅ Funcionais

---
**Última Atualização**: $(Get-Date -Format "dd/MM/yyyy HH:mm")  
**Responsável**: GitHub Copilot + Paulo  
**Versão**: 2.0 (com KEDA integrado)
