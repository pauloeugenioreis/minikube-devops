# PROMPT P## 🃦 PROJETO ATUAL:
    │   ├── linux\ (placeholder - aguardando validação Ubuntu 24.04.3)
    │   └── windows\
    │       ├── Bootstrap-DevOps.ps1     # Bootstrap completo projeto
    │       ├── Get-ProjectRoot.ps1      # Sistema paths dinâmicos
    │       ├── autostart\
    │       ├── init\
    │       ├── maintenance\             # fix-dashboard-cronjob.ps1 (troubleshooting)
    │       └── monitoring\
└── windows-test-structure.ps1 💡 COMO TRABALHAR:
1. **SEMPRE** leia a documentação primeiro
2. **DETECTAR SO** automaticamente antes de qualquer ação
3. **ESCOLHER SCRIPTS** corretos (Windows: minikube/scripts/windows/ | Linux: temp/linux-scripts/)
4. **MANTENHA** padrões estabelecidos
5. **PRESERVE** soluções já implementadas
6. **USE temp/** para desenvolvimento/testes
7. **SÓ MOVA para minikube/** após validação 100%
8. **NÃO configure autostart** automaticamente
9. **DOCUMENTE** novas mudanças (Documentação + Histórico + Prompt)
10. **TESTE** antes de confirmar
11. **SIGA CHECKLIST-OBRIGATORIO.md** - PRIORIDADE MÁXIMA

## 🆕 CAPACIDADES ESTRUTURA LINUX (25/09/2025)
- Scripts Linux robustos, portáveis, com automação de dependências e preload de imagens KEDA
- Detecção dinâmica de paths, documentação e diagrama sempre atualizados
- Estrutura multiplataforma consolidada: onboarding facilitado e manutenção simplificada

**Reforço:** Sempre manter documentação e diagramas atualizados após qualquer alteração relevante.

## 🚨 CHECKLIST OBRIGATÓRIO (NUNCA ESQUECER)
**SEMPRE seguir**: temp/ → validação → migração → documentação → limpeza

**Arquivo**: CHECKLIST-OBRIGATORIO.md (prioridade máxima)
**Procedimentos**:
- 📁 Regra Arquitetural obrigatória
- 🧪 Atualizar windows-test-structure.ps1
- 📚 Atualizar 4 arquivos de documentação
- 🔄 Validação completa sempreional com RabbitMQ e MongoDB
- **Status**: ✅ CONCLUÍDO + OTIMIZADO - estrutura limpa e scripts Linux prontos
- **Local**: <CAMINHO-DO-PROJETO>\minikube\CONTINUAR CONVERSA EM NOVA MÁQUINA

## 🎯 Para GitHub Copilot na Nova Máquina:

**Cole este texto no novo chat:**

---

Olá! Sou o Paulo e preciso continuar nosso projeto Minikube de onde paramos. Aqui está o contexto completo:

## 📋 PROJETO ATUAL:
- **Objetivo**: Ambiente Minikube profissional com RabbitMQ e MongoDB
- **Status**: ✅ CONCLUÍDO - mas posso precisar de expansões/modificações
- **Local**: <CAMINHO-DO-PROJETO>\minikube\

## 📚 DOCUMENTAÇÃO DISPONÍVEL:
Por favor, LEIA estes arquivos para entender todo o contexto:
1. **HISTORICO-PROJETO-MINIKUBE.md** - Evolução técnica (8 fases)
2. **CONVERSAS-E-DECISOES.md** - Todas as 17 conversas
3. **PROMPT-BACKUP-COMPLETO.md** - Resumo consolidado

## 🎯 ESTRUTURA ATUAL:
```
DevOps\
├── minikube\                # Estrutura FINAL (codigo consolidado)
    ├── configs\ (Kubernetes YAML)
    ├── docs\ 
    │   ├── README.md
    │   ├── KEDA.md
    │   └── fresh-machine\       # Documentacao Fresh Machine Setup
    │       ├── SETUP.md
    │       ├── DEMO.md
    │       └── CHECKLIST.md
    ├── scripts\
    │   ├── linux\ (placeholder - aguardando validação Ubuntu 24.04.3)
    │   └── windows\
    │       ├── Setup-Fresh-Machine.ps1  # Fresh machine setup automatico
    │       ├── autostart\
    │       ├── init\
    │       ├── maintenance\
    │       └── monitoring\
    └── windows-test-structure.ps1
├── Bootstrap-DevOps.ps1      # Bootstrap completo do projeto (raiz)
```

## ⚙️ AMBIENTE CONFIGURADO:
- **Windows**: 12 scripts PowerShell funcionais (ambiente pronto)
- **Linux**: 12 scripts Bash equivalentes criados (temp/linux-scripts/ - aguarda validação Ubuntu 24.04.3)
- **Detecção SO**: Procedimento automático implementado para compatibilidade multiplataforma
- **Teste**: windows-test-structure.ps1 único e funcional (duplicações removidas)
- **RabbitMQ**: http://localhost:15672 (guest/guest) - Configuração genérica sem filas Azure
- **MongoDB**: mongodb://admin:admin@localhost:27017/admin
- **Dashboard K8s**: http://localhost:4666 (porta atualizada e funcional)
- **KEDA**: Autoscaling genérico para RabbitMQ
- **Autostart**: Windows configurado
- **Compatibilidade**: kubectl v1.34.0 + Kubernetes v1.34.0

## 🔑 DECISÕES IMPORTANTES:
- Sem caracteres especiais português
- Estrutura multiplataforma (Windows/Linux)
- OneDrive para backup automático
- Organização profissional por função
- Scripts robustos com verificações
- **REGRA ARQUITETURAL**: temp/ → validação → minikube/
- **AUTOSTART MANUAL**: Usuário configura conforme preferência
- **AMBIENTE GENÉRICO**: RabbitMQ + KEDA sem dependências Azure (remoção completa Azure Functions)

## 💡 COMO TRABALHAR:
1. **SEMPRE** leia a documentação primeiro
2. **MANTENHA** padrões estabelecidos
3. **PRESERVE** soluções já implementadas
4. **USE temp/** para desenvolvimento/testes
5. **SÓ MOVA para minikube/** após validação 100%
6. **NÃO configure autostart** automaticamente
7. **DOCUMENTE** novas mudanças
8. **TESTE** antes de confirmar

## 🎯 PRÓXIMOS PASSOS POSSÍVEIS:
- **Troubleshooting**: Scripts Dashboard CronJob implementados (fix-dashboard-cronjob.ps1)
- **Validação Linux**: Testar scripts Bash em Ubuntu 24.04.3
- **Migração Scripts**: Mover scripts validados de temp/ para minikube/
- **Novos Serviços**: Redis, PostgreSQL, Kafka, etc.
- **Monitoramento**: Prometheus + Grafana
- **CI/CD**: Jenkins, GitLab CI, GitHub Actions
[Paulo dirá o que precisar]

## 🆕 FRESH MACHINE SETUP (IMPLEMENTADO):
- **Bootstrap-DevOps.ps1**: Bootstrap completo do projeto (na raiz)
- **Setup-Fresh-Machine.ps1**: Instalação automática Docker, Minikube, kubectl, Helm (temp/)
- **One-line setup**: `curl bootstrap.ps1; .\bootstrap.ps1`
- **Zero-to-running**: Máquina nova → ambiente completo em 15-30 minutos
- **Documentação completa**: minikube/docs/fresh-machine/ com 3 arquivos MD

## 🔧 TROUBLESHOOTING DASHBOARD CRONJOB (IMPLEMENTADO):
- **Problema**: Dashboard v2.7.0 incompatível com Kubernetes v1.34.0 - erro 404 em CronJob details
- **Solução**: fix-dashboard-cronjob.ps1 com RBAC patches e diagnósticos completos
- **Limitação**: Problema arquitetural não resolvível por configuração
- **Alternativa**: Comandos kubectl funcionais documentados
- **Scripts**: Integrados em minikube/scripts/windows/maintenance/

## 🔧 CORREÇÃO DASHBOARD PORTA 4666 (IMPLEMENTADO):
- **Problema**: Dashboard não funcionando após restart + violação CHECKLIST-OBRIGATORIO.md
- **Investigação**: Porta 53954 bloqueada por permissões Windows
- **Solução**: Porta 4666 validada e definida como padrão
- **Melhorias Implementadas**:
  - Port-forward robusto com PID tracking
  - Limpeza automática de processos conflitantes
  - Lógica de recuperação automática se falhar
  - Testes aprimorados (8 tentativas, 20s wait)
- **Processo Corretivo**: Desenvolvimento em temp/ → validação → documentação obrigatória
- **Scripts Atualizados**: open-dashboard.ps1, fix-dashboard.ps1, init-minikube-fixed.ps1 (7 arquivos)
- **Nova URL**: http://localhost:4666

## 🚨 LIÇÃO CRÍTICA APRENDIDA:
**CHECKLIST-OBRIGATORIO.md é LEI ABSOLUTA**
- Nunca mais violar workflow temp/ → validação → migração → documentação
- Documentação obrigatória deve ser atualizada SEMPRE
- Regra arquitetural não pode ser quebrada independente da urgência

---

**Agora você tem contexto completo! Podemos continuar de onde paramos. O que precisa?**

---

## 📝 INSTRUÇÕES PARA PAULO:

1. **Copie todo o texto acima**
2. **Cole no novo chat da outra máquina**
3. **Aguarde IA ler a documentação**
4. **Continue normalmente!**

A IA terá acesso a TODA nossa história através dos arquivos de documentação!

*Última atualização: 22/09/2025 - Remoção Azure + Ambiente Genérico Completo*