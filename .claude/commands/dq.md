---
description: Define e implementa regras de data quality para uma tabela ou pipeline
argument-hint: <tabela/pipeline alvo e contexto de negócio>
---
Use o subagente **data-quality-engineer** para analisar e implementar qualidade de dados em: $ARGUMENTS

Exigências: cobrir as 6 dimensões (completude, unicidade, validade, consistência, atualidade, acurácia), toda regra com severidade + ação + threshold + dono, estratégia de quarentena para warnings e circuit breaker para blockers, e lista de métricas de DQ a expor para monitoração.
