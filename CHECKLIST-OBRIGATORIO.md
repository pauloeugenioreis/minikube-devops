# CHECKLIST OBRIGATÓRIO - PROCEDIMENTOS FUNDAMENTAIS

## 🚨 PRIORIDADE MÁXIMA - NUNCA ESQUECER

Este checklist DEVE ser seguido SEMPRE que criar, modificar ou expandir qualquer funcionalidade do projeto.

---

## ✅ CHECKLIST OBRIGATÓRIO PARA QUALQUER MUDANÇA

### 1. 📁 REGRA ARQUITETURAL (SEMPRE)
- [ ] **DESENVOLVIMENTO**: Criar SEMPRE em `temp/` primeiro
- [ ] **VALIDAÇÃO**: Testar completamente em `temp/`
- [ ] **MIGRAÇÃO**: Só mover para estrutura principal após 100% funcional
- [ ] **LIMPEZA**: Remover arquivos de `temp/` após migração

### 2. 🧪 TESTE DE ESTRUTURA (OBRIGATÓRIO)
- [ ] **ATUALIZAR**: `minikube/windows-test-structure.ps1` com novos componentes
- [ ] **EXECUTAR**: Teste completo após qualquer mudança
- [ ] **VALIDAR**: Todos os testes devem PASSAR

### 3. 📚 DOCUMENTAÇÃO (SEMPRE ATUALIZAR)
- [ ] **CONVERSAS-E-DECISOES.md**: Adicionar nova entrada
- [ ] **HISTORICO-PROJETO-MINIKUBE.md**: Atualizar evolução técnica
- [ ] **PROMPT-CONTINUIDADE.md**: Atualizar estrutura e capacidades
- [ ] **PROMPT-BACKUP-COMPLETO.md**: Atualizar resumo consolidado

### 4. 📂 ESTRUTURA DE ARQUIVOS (VERIFICAR)
- [ ] **Autostart**: Verificar se novos serviços precisam de autostart
- [ ] **README.md**: Atualizar documentação técnica
- [ ] **Configs**: Adicionar novos YAMLs se necessário
- [ ] **Scripts**: Organizar por função (init/maintenance/monitoring)

### 5. 🔄 INTEGRAÇÃO (VALIDAR)
- [ ] **Get-ProjectRoot.ps1**: Verificar compatibilidade paths dinâmicos
- [ ] **Init scripts**: Integrar novos serviços com parâmetros opcionais
- [ ] **Fresh Machine**: Atualizar setup se necessário

---

## 🎯 QUANDO APLICAR ESTE CHECKLIST

### ✅ SEMPRE que:
- Criar novos scripts
- Adicionar novos serviços (Redis, PostgreSQL, etc.)
- Modificar estrutura de pastas
- Implementar novas funcionalidades
- Corrigir bugs ou problemas
- Expandir documentação
- Criar arquivos de configuração

### ✅ ESPECIALMENTE quando:
- Mover arquivos de `temp/` para estrutura principal
- Implementar sistemas complexos (como Fresh Machine Setup)
- Modificar scripts existentes
- Adicionar documentação técnica

---

## 🚨 CONSEQUÊNCIAS DE NÃO SEGUIR

- ❌ Estrutura principal fica bagunçada
- ❌ Testes ficam desatualizados
- ❌ Documentação fica inconsistente
- ❌ Futuras IAs não terão contexto completo
- ❌ Usuário perde rastreabilidade do projeto

---

## 🎯 ORDEM DE EXECUÇÃO OBRIGATÓRIA

### 1. DESENVOLVIMENTO (temp/)
```
1. Criar em temp/
2. Desenvolver e testar
3. Validar funcionamento 100%
```

### 2. MIGRAÇÃO (temp/ → estrutura principal)
```
1. Mover arquivos para locais corretos
2. Atualizar windows-test-structure.ps1
3. Executar teste completo
4. Validar todos os componentes
```

### 3. DOCUMENTAÇÃO (SEMPRE)
```
1. Atualizar CONVERSAS-E-DECISOES.md
2. Atualizar HISTORICO-PROJETO-MINIKUBE.md
3. Atualizar PROMPT-CONTINUIDADE.md
4. Atualizar PROMPT-BACKUP-COMPLETO.md
```

### 4. LIMPEZA
```
1. Remover arquivos de temp/ após migração
2. Verificar estrutura final
3. Teste final completo
```

---

## 📋 TEMPLATE PARA ATUALIZAÇÃO DOCUMENTAÇÃO

### CONVERSAS-E-DECISOES.md
```markdown
### X. NOVA FUNCIONALIDADE
**Usuario**: "[requisito do usuário]"
**Contexto**: [contexto técnico]
**Implementacao**: [o que foi feito]
**Resultado**: [resultado alcançado]
**Data**: [data]
```

### HISTORICO-PROJETO-MINIKUBE.md
```markdown
### Fase X: Nome da Funcionalidade
- **Requisito**: [descrição do requisito]
- **Implementação**: [como foi implementado]
- **Tecnologia**: [tecnologias utilizadas]
- **Resultado**: [resultado e benefícios]
- **Documentação**: [arquivos criados]
```

### PROMPT-CONTINUIDADE.md
```
- Atualizar estrutura de arquivos
- Adicionar novos próximos passos
- Incluir novas capacidades
```

### PROMPT-BACKUP-COMPLETO.md
```
- Adicionar nova fase
- Atualizar status final
- Incluir novos comandos/capacidades
```

---

## 🎯 ESTE CHECKLIST É LEI

**NUNCA MAIS ESQUECER ESTES PROCEDIMENTOS**

Todo desenvolvimento deve seguir:
**temp/ → validação → migração → documentação → limpeza**

**Status**: ✅ CHECKLIST CRIADO E ATIVO
**Prioridade**: 🚨 MÁXIMA
**Aplicação**: 🔄 SEMPRE

---

*Checklist criado em 21/09/2025 como PRIORIDADE MÁXIMA*
*Nunca mais esquecer os procedimentos fundamentais do projeto*