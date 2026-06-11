---
description: Desenvolve pipeline de dados completo (código + DQ + observabilidade)
argument-hint: "<descrição do pipeline: fontes, destino, frequência, volumetria>"
---
Demanda de pipeline de dados: $ARGUMENTS

Fluxo:
1. Use o subagente **data-engineer** para implementar o pipeline (Python/PySpark/SQL/Iceberg) com testes, incluindo jobs de manutenção Iceberg quando criar tabelas.
2. Use o subagente **data-quality-engineer** para definir e implementar a suite de DQ das tabelas envolvidas.
3. Use o subagente **observability-engineer** para instrumentar o pipeline e criar monitors de freshness, falha e volumetria.
4. Consolide: arquivos entregues, decisões de design, regras de DQ e monitoração criada.
Se faltarem informações críticas (schema das fontes, SLA, volumetria), pergunte antes de implementar.
