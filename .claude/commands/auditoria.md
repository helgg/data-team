---
description: Auditoria completa de um projeto/plataforma existente (arquitetura, segurança, qualidade, custo, observabilidade)
argument-hint: <diretório/repositório ou descrição do escopo>
---
Use o subagente **techleader** para coordenar uma auditoria completa de: $ARGUMENTS

O techleader deve delegar EM PARALELO:
- **aws-architect**: revisão da arquitetura atual, riscos e melhorias.
- **guardrails-engineer**: postura de segurança e compliance/LGPD.
- **data-quality-engineer**: cobertura atual de DQ e lacunas.
- **finops-analyst**: oportunidades de economia.
- **observability-engineer**: lacunas de monitoração e alertas.

Entrega final: relatório executivo com achados por área, priorizados por risco/ROI, e um roadmap de remediação em ondas (quick wins → médio prazo → estrutural).
