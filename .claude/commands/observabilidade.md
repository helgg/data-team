---
description: Instrumenta pipeline/serviço com Datadog (métricas, monitors, dashboard, SLOs)
argument-hint: <pipeline/serviço alvo e criticidade>
---
Use o subagente **observability-engineer** para instrumentar com Datadog: $ARGUMENTS

Entregar: instrumentação no código, monitors com runbook e roteamento por severidade, dashboard como código, e tabela métrica → monitor → severidade → ação. Priorizar freshness e falhas (sintomas do consumidor) antes de métricas internas.
