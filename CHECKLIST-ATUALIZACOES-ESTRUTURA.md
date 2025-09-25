# 📋 CHECKLIST PARA ATUALIZAÇÕES NA ESTRUTURA MINIKUBE

## 🎯 ARQUIVOS QUE SEMPRE DEVEM SER VERIFICADOS

Sempre que adicionar novos serviços, componentes ou fazer mudanças na estrutura:

### 1. **windows-test-structure.ps1**
- ✅ Adicionar testes para novos componentes
- ✅ Verificar caminhos dos arquivos
- ✅ Testar execução sem erros

### 2. **minikube-autostart.bat**
- ✅ Criar versões com novos serviços se necessário
- ✅ Exemplo: `minikube-autostart-with-keda.bat`
- ✅ Manter versão original para compatibilidade

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
3. **autostart files** → Criar versões se necessário
4. **init script** → Integrar instalação

### Fase 5: Teste Final
- ✅ Executar `windows-test-structure.ps1`
- ✅ Testar inicialização completa
- ✅ Validar documentação
- ✅ Confirmar exemplos funcionais

## 🎯 EXEMPLO: INTEGRAÇÃO KEDA (REALIZADA)

### ✅ Arquivos Adicionados:
- `configs/keda/examples/` (3 arquivos YAML)
- `scripts/windows/keda/` (4 scripts PowerShell)
- `scripts/windows/init/install-keda.ps1`
- `docs/KEDA.md`

### ✅ Arquivos Atualizados:
- `docs/README.md` → Seção KEDA, estrutura, comandos
- `scripts/windows/init/init-minikube-fixed.ps1` → Parâmetro `-InstallKeda`
- `windows-test-structure.ps1` → Testes KEDA
- `scripts/windows/autostart/minikube-autostart-with-keda.bat` → Versão com KEDA

### ✅ Resultado:
- 100% integrado à estrutura principal
- Documentação completa
- Testes funcionais
- Opções de autostart disponíveis

## 🚨 PONTOS DE ATENÇÃO

### Sempre Verificar:
1. **Encoding de arquivos** - Usar UTF-8 sem BOM
2. **Caminhos absolutos** vs relativos
3. **Compatibilidade** com versões anteriores
4. **Permissões** de execução PowerShell
5. **Dependencies** entre serviços

### Nunca Fazer:
- ❌ Modificar estrutura principal sem testar em temp/
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
- **Autostart**: ✅ Versões com/sem KEDA disponíveis
- **Documentação**: ✅ Completa e atualizada
- **Testes**: ✅ Funcionais

---
**Última Atualização**: $(Get-Date -Format "dd/MM/yyyy HH:mm")  
**Responsável**: GitHub Copilot + Paulo  
**Versão**: 2.0 (com KEDA integrado)