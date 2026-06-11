---
description: Code review multidisciplinar das mudanças atuais (segurança + qualidade + custo)
argument-hint: [escopo opcional: arquivos, diretório ou branch]
---
Faça uma revisão multidisciplinar das mudanças em: $ARGUMENTS (se vazio, use git diff da branch atual contra a main).

Execute EM PARALELO:
1. Subagente **guardrails-engineer**: revisão de segurança com o checklist completo e veredito (APROVADO/RESSALVAS/REPROVADO).
2. Subagente **data-engineer**: revisão técnica de código Python/Spark/SQL/Iceberg (corretude, performance, testes, idempotência).
3. Subagente **finops-analyst**: impacto de custo das mudanças, se houver infra ou mudanças de processamento relevantes.

Consolide os três pareceres em um único relatório por severidade, com veredito final.
