# Capítulo 1: Descrição do que é Engenharia de Dados

## Core Idea
Engenharia de dados é o desenvolvimento, implementação e manutenção de sistemas e processos que recebem dados brutos e produzem informações consistentes e de alta qualidade para casos de uso downstream (análise, ML). O engenheiro gerencia o **ciclo de vida dos dados** — não apenas ferramentas.

## Frameworks Introduzidos

- **Ciclo de Vida da Engenharia de Dados**: Geração → Armazenamento → Ingestão → Transformação → Disponibilização, com elementos subjacentes transversais: Segurança, Gerenciamento de dados, DataOps, Arquitetura de dados, Orquestração, Engenharia de software.
  - Quando usar: como lente para qualquer decisão técnica — redireciona o foco de tecnologia para dados e objetivos.
  - Como: mapear cada iniciativa a uma ou mais etapas do ciclo; checar se os elementos subjacentes estão cobertos.

- **Modelo de Maturidade de Dados (3 estágios)**:
  - **Estágio 1 — Começando**: dados improvisados, equipe pequena, foco em base sólida antes de ML.
  - **Estágio 2 — Escalonando**: práticas formais, arquiteturas escaláveis, DevOps/DataOps, suporte a ML.
  - **Estágio 3 — Liderando**: cultura orientada a dados, automação, governança, ferramentas de descoberta (catálogos, linhagem).
  - Quando usar: para calibrar prioridades e evitar avançar etapas antes da fundação estar pronta.

- **Engenheiro Tipo A / Tipo B**:
  - **Tipo A (Abstraction)**: opera com ferramentas gerenciadas e SaaS; evita reinventar soluções; presente em todos os estágios.
  - **Tipo B (Building)**: constrói ferramentas e sistemas customizados; aparece nos estágios 2-3 ou quando o caso de uso é único e crítico.
  - Quando usar: ao definir escopo de contratação ou ao decidir build vs buy.

## Key Concepts

- **Engenharia de dados**: combinação de segurança, gerenciamento de dados, DataOps, arquitetura de dados, orquestração e engenharia de software.
- **Ciclo de vida da engenharia de dados**: framework central que redireciona foco de tecnologia para dados e objetivos.
- **Elementos subjacentes**: conceitos transversais a todas as etapas (segurança, gerenciamento, DataOps, arquitetura, orquestração, SW engineering).
- **Maturidade de dados**: avanço rumo a maior utilização, capacidade e integração de dados — não depende de tamanho ou idade da empresa.
- **Hierarquia de Necessidades da Ciência de Dados** (Rogati): coleta/limpeza/infraestrutura → análise → ML. 70-80% do tempo de cientistas vai para a base; engenharia de dados resolve essa base.
- **Tipo A / Tipo B**: distinção entre engenheiros que abstraem vs. constroem ferramentas customizadas.
- **Upstream / Downstream**: engenharia de dados está upstream da ciência de dados; consome de produtores de dados (engenheiros de SW, DevOps) e serve consumidores (cientistas, analistas, ML).

## Mental Models

- "Use o ciclo de vida como lente, não ferramentas específicas — o que não muda são as etapas; o que muda são as implementações."
- "Avance na maturidade de dados antes de avançar em ML — sem base sólida, modelos não chegam à produção."
- "Tipo A por padrão, Tipo B apenas quando oferece vantagem competitiva real."
- "Engenheiro de dados como intermediário: recebe dados brutos de upstream, entrega valor para downstream."

## Anti-patterns

- **Saltar para ML sem fundação de dados**: sem base sólida, não há dados para treinar modelos confiáveis nem infraestrutura para implantá-los em produção.
- **Trabalhar isolado**: equipes de dados sem comunicação com stakeholders de negócio constroem coisas de pouca utilidade.
- **Complexidade desnecessária**: usar Hadoop para gigabytes; adotar ferramentas de ponta sem valor entregue. "Todas as decisões de tecnologia devem ser guiadas pelo valor entregue aos clientes."
- **Complacência no estágio 3**: após atingir liderança com dados, organizações regridem se não mantiverem foco contínuo em manutenção e melhoria.

## Worked Example

**Maturidade de dados na prática — diagnóstico de estágio:**

| Sintoma observado | Estágio provável | Ação do engenheiro de dados |
|---|---|---|
| Solicitações de dados improvisadas, sem arquitetura definida | 1 | Conseguir adesão da liderança; definir arquitetura mínima; construir base antes de ML |
| Pipelines existem mas não escalam; cientistas de dados limpam dados manualmente | 2 | Adotar DataOps; automatizar ingestão e limpeza; construir suporte a ML |
| Cultura orientada a dados, mas novos dados não fluem bem | 3 | Criar automação de onboarding de fontes; implantar catálogo e linhagem; governança ativa |

**Regra prática**: "o gargalo no escalonamento não é hardware — é a equipe de engenharia. Priorize soluções simples de gerenciar."

## Key Takeaways

1. Engenharia de dados gerencia o **ciclo de vida dos dados** — não é apenas ETL ou pipelines.
2. O ciclo: Geração → Armazenamento → Ingestão → Transformação → Disponibilização, com 6 elementos subjacentes transversais.
3. Avalie a maturidade de dados antes de decidir o que construir — estágio define prioridades.
4. Tipo A (abstração/SaaS) é o ponto de partida; Tipo B (build) só quando há vantagem competitiva.
5. Engenharia de dados está **upstream** da ciência de dados — sua base determina o sucesso de ML em produção.
6. Linguagens essenciais: SQL (universal), Python (cola), Java/Scala (ecossistema Apache), bash (automação).

## Connects To

- **Ch2**: Expande o ciclo de vida e os elementos subjacentes em detalhe.
- **Ch3**: Arquitetura de dados — o que um engenheiro de dados faz no estágio 1 sem arquiteto disponível.
- **Ch4**: Escolha de tecnologias ao longo do ciclo — operacionaliza o framework Tipo A/B.
- **Hierarquia de Rogati**: referência externa que posiciona engenharia de dados como base obrigatória antes de IA/ML.
