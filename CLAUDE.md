# Data Platform Team — Time de Agentes Especialistas

Este repositório define um time de agentes para desenvolvimento de infraestrutura e produtos de dados profissionais, orquestrado pelo agente **techleader**.

## Regra central de orquestração

- Demandas que cruzam mais de uma especialidade → SEMPRE comece pelo subagente **techleader**.
- Demandas pontuais de uma especialidade → delegue direto ao especialista (ou use o slash command correspondente).
- O techleader nunca implementa: ele planeja, delega, valida quality gates e consolida.
- Subagentes não compartilham contexto entre si: toda delegação deve incluir contexto, tarefa, critério de aceite, restrições e formato de saída.

## Estrutura de pastas (OBRIGATÓRIO)

- **Todo código gerado por agentes vai dentro de `infra/`** — Terraform, módulos, ASL, SQL, Python libs, docs técnicos.
- A raiz do repositório deve conter apenas: `CLAUDE.md`, `README.md`, `.gitignore` e a pasta `infra/`.
- Comandos `terraform` são sempre executados a partir de `infra/` (ex: `cd infra && terraform validate`).
- Ao criar novos projetos ou expandir infra existente, criar subpastas dentro de `infra/` se necessário.

## Padrões globais do projeto (valem para TODOS os agentes)

- **Idioma**: respostas e documentação em português (pt-BR); código, nomes de recursos e comentários técnicos em inglês.
- **Segurança**: nunca commitar credenciais; menor privilégio em IAM; PII sempre classificada e protegida.
- **Terraform**: nunca executar `apply` sem aprovação explícita do usuário. `plan` é o limite da autonomia.
- **Tags obrigatórias** em todo recurso AWS: `Project`, `Environment`, `ManagedBy`, `Owner`, `CostCenter`.
- **Toda tabela nova** nasce com: regras de DQ, job de manutenção Iceberg e monitor de freshness.
- **Custo**: infra nova só é considerada pronta com estimativa mensal do finops-analyst.
- **Commits**: conventional commits (`feat:`, `fix:`, `infra:`, `dq:`, `docs:`).

## Quality gates (checklist do techleader antes de declarar entrega pronta)

1. `terraform validate` + `plan` limpos (infra)
2. Testes passando + lint limpo (código)
3. Regras de DQ definidas (tabelas novas)
4. Revisão de segurança do guardrails-engineer (mudanças sensíveis)
5. Estimativa de custo (infra nova)
6. Monitoração definida (pipelines/serviços críticos)

## Slash commands disponíveis

| Comando | O que faz |
|---|---|
| `/projeto <descrição>` | Orquestração completa via techleader |
| `/infra <demanda>` | Arquitetura + Terraform + custo + segurança |
| `/pipeline <descrição>` | Pipeline + DQ + observabilidade |
| `/dq <tabela>` | Suite de data quality |
| `/custos <escopo>` | Estimativa ou otimização de custos |
| `/observabilidade <alvo>` | Instrumentação Datadog |
| `/revisar [escopo]` | Review multidisciplinar paralelo |
| `/auditoria <escopo>` | Auditoria completa da plataforma |

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
