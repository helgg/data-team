# Arquitetura do Time de Agentes

## Racional das decisões

### Por que orquestrador + especialistas?
Um único agente generalista acumula contexto de todas as frentes (Terraform, Spark, custos, segurança) e degrada conforme a conversa cresce. O padrão orquestrador-trabalhadores (recomendado pela Anthropic em "Building Effective Agents") mantém cada especialista com contexto limpo e focado, e concentra a memória do projeto no techleader.

### Por que o techleader não implementa?
Separar decisão de execução evita que o orquestrador "polua" seu contexto com detalhes de implementação e perca a visão do todo. Ele recebe apenas resumos dos subagentes — exatamente o nível certo para validar critérios de aceite.

### Distribuição de ferramentas (princípio do menor privilégio)

| Agente | Write/Edit/Bash | WebSearch | Racional |
|---|---|---|---|
| techleader | ❌ (só Task/TodoWrite) | ❌ | Orquestra, não executa |
| terraform-engineer | ✅ | ❌ | Implementa e valida IaC |
| aws-architect | ❌ | ✅ | Desenha e verifica features/limites atuais |
| data-engineer | ✅ | ❌ | Implementa e testa pipelines |
| data-quality-engineer | ✅ | ❌ | Implementa suites de DQ |
| guardrails-engineer | ❌ | ✅ | Revisor — não deve alterar código que audita |
| finops-analyst | ❌ | ✅ | Analista — precisa de preços atuais |
| observability-engineer | ✅ | ✅ | Instrumenta código e consulta docs Datadog |

### Modelos
- **techleader → opus**: coordenação, julgamento de trade-offs e decomposição valem o custo extra.
- **especialistas → sonnet**: melhor custo-benefício para implementação. Ajuste para `inherit` se quiser que sigam o modelo da sessão principal.

## Fluxos típicos

### /projeto (orquestração completa)
```
usuário → techleader
  ├── valida premissas com o usuário
  ├── plano (TodoWrite) → aprovação do usuário
  ├── aws-architect (desenho)            ─┐
  ├── finops-analyst (estimativa)        ─┤ paralelo
  ├── terraform-engineer (IaC)            │ (após desenho)
  ├── data-engineer (pipeline + testes)   │
  ├── data-quality-engineer (regras DQ)  ─┤ paralelo
  ├── observability-engineer (monitors)  ─┘
  ├── guardrails-engineer (revisão final)
  └── quality gates + resumo consolidado
```

### /revisar (revisão paralela)
Três revisores independentes (segurança, técnica, custo) rodam em paralelo sobre o mesmo diff e o resultado é consolidado por severidade — padrão de "parallelization/voting" das best practices da Anthropic.

## Evoluções sugeridas
- **Hooks**: bloquear `terraform apply` via PreToolUse hook como guardrail técnico (não só instrucional).
- **MCP servers**: Datadog MCP para o observability-engineer consultar monitors reais; AWS Knowledge MCP para o aws-architect.
- **Agente extra**: `docs-writer` para gerar documentação/ADRs das decisões do techleader.
- **Skills**: extrair padrões repetitivos (ex.: template de módulo Terraform, template de contrato de dados) para Skills reutilizáveis.
