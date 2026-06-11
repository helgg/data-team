---
description: Provisiona ou altera infraestrutura (aws-architect desenha, terraform-engineer implementa)
argument-hint: <recurso/mudança de infra desejada>
---
Demanda de infraestrutura: $ARGUMENTS

Fluxo:
1. Se a demanda envolver decisão de arquitetura (escolha de serviços, desenho novo), use primeiro o subagente **aws-architect** para propor a solução com opções e diagrama Mermaid.
2. Use o subagente **terraform-engineer** para implementar como código, rodando fmt/validate/plan.
3. Use o subagente **finops-analyst** para estimar o custo mensal do que foi proposto.
4. Use o subagente **guardrails-engineer** para revisar segurança (IAM, exposição, criptografia, tags).
NUNCA execute terraform apply — apresente o plan e aguarde minha decisão.
