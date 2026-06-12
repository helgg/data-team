# Ch09 — Disponibilizando Dados

## Core Idea

Disponibilização é a etapa em que dados se tornam valor real — BI, ML ou ETL reverso. Toda decisão técnica deve partir do caso de uso e do usuário. Confiança nos dados é o ativo mais frágil e crítico: construída ao longo do tempo, destruída instantaneamente. O engenheiro de dados é responsável pela qualidade dos dados entregues, não pelo uso que o consumidor faz deles.

---

## Frameworks Introduzidos

### 1. Triângulo de Casos de Uso da Disponibilização

```
              Análise (BI)
             /
Usuário → caso de uso
             \
              ML ──── ETL reverso (loop de feedback)
```

Sempre responder: "Que **ação** este dado acionará, **quem** vai realizá-la e pode ser **automatizada**?"

### 2. Tipos de Análise

| Tipo | Foco | Latência típica | Ferramentas |
|------|------|----------------|-------------|
| Análise de negócios | Insights acionáveis (tendências históricas) | Minutos a dias | Tableau, Looker, Power BI, Superset |
| Análise operacional | Ação imediata | Segundos a minutos | Dashboards em tempo real, alertas |
| Análise incorporada | Usuário externo da aplicação | Sub-segundo | Bancos OLAP com alta concorrência |

### 3. Hierarquia de Disponibilização de Dados

**Troca de arquivos** → **Banco de dados (OLAP)** → **Sistemas de streaming** → **Federação de consultas** → **Compartilhamento de dados**

### 4. Camada Semântica / Camada de Métricas

Centraliza lógica de negócio separada dos scripts ETL. "Grave uma vez, utilize em qualquer lugar."

| Ferramenta | Abordagem | Camada |
|-----------|-----------|--------|
| Looker (LookML) | Gera SQL a partir de lógica virtual; pushdown para DB | BI + semântica |
| dbt | Pipeline SQL com definições de métricas reutilizáveis | Transformação + semântica |
| Apache Superset | Camada semântica de código aberto | BI |

---

## Key Concepts

**Confiança (Trust)** — variável mais crítica na disponibilização. Perda de confiança é um "golpe fatal e silencioso" que pode levar à dissolução de equipes de dados. Validação contínua + observabilidade + comunicação ativa.

**SLA/SLO como contrato** — SLA = compromisso geral ("dados disponíveis com qualidade"). SLO = métrica verificável ("99% uptime, 95% dados sem defeitos"). Comunique antecipadamente qualquer desvio.

**Produto de dados** — produto que ajuda a alcançar um objetivo via dados (D. J. Patil). Aplique "jobs to be done": o usuário "contrata" o produto para uma tarefa. Construir sem conhecer o caso de uso = produto que ninguém usa.

**Autoatendimento (self-service)** — aspiracional, raramente bem-sucedido na prática. Funciona quando: público correto (executivos data-savvy), escopo limitado, treinamento adequado. Falha quando: usuário não quer criar — quer consumir.

**Definição e lógica de dados** — "cliente" pode ter definição diferente em cada departamento. Formalizar em catálogo de dados e camada semântica elimina inconsistências. Conhecimento institucional informal = risco.

**Query pushdown (Looker)** — lógica LookML compilada em SQL executada no banco de origem. Looker não armazena dados — é tradutor. Contraste com Tableau que extrai e armazena localmente.

**ETL reverso (Reverse ETL / BLT)** — dados processados no OLAP retornam aos sistemas de origem (CRM, plataformas de anúncios). Reduz atrito do usuário final (vendedor acessa pontuação de leads no CRM, não num dashboard separado). **Risco**: loops de feedback podem escalar sem controle (lances de anúncio infinitos). Necessita monitoramento e guardrails.

**Análise incorporada (embedded analytics)** — três desafios únicos: (1) latência de dados baixa, (2) desempenho de query rápido, (3) alta concorrência. Bancos de dados OLAP nova geração (Druid, ClickHouse, SingleStore) projetados para isso.

**Manipulação de credenciais em notebooks** — anti-pattern crítico: credenciais hardcoded em notebooks vazam para repositórios. Usar gerenciadores de credenciais ou variáveis de ambiente. DE deve auditar e estabelecer padrões.

**Notebooks em produção** — caminho rápido (Netflix usa). Trade-off: desenvolvimento ágil vs. qualidade inferior ao pipeline formal. Abordagem híbrida: notebooks para prod "leve"; pipeline completo para projetos de alto valor.

**Data Mesh na disponibilização** — cada equipe de domínio é responsável por disponibilizar dados para outras equipes (servir) E por consumir dados de outras equipes (autoatendimento interno). Altera radicalmente a estrutura da responsabilidade.

---

## Mental Models

**"Trabalhe de trás para frente."** — Comece pelo caso de uso e pelo usuário; construa a arquitetura depois. Ferramentas primeiro = produtos que ninguém usa.

**"Confiança é tudo. Fácil perder, difícil reconquistar."** — Um pipeline que entrega dados errados uma vez planta uma dúvida que persiste por anos.

**"Dados em tempo real sem ação = distração implacável."** — Streaming sem clareza sobre que ação vai disparar é custo sem benefício.

**"O futuro é streaming substituindo lote."** — Streaming captura em tempo real; lote pode ser consumido como caso especial downstream. Arquitetura deve evoluir nessa direção.

**"Disponibilização = superfície de segurança máxima."** — É o ponto onde mais pessoas e sistemas tocam os dados. Privilégio mínimo não é opcional.

**"Produto de dados com loops de feedback positivos."** — Mais uso gera mais dados, que aprimoram o produto. Monitore adoção; produto ignorado é custo, não valor.

---

## Anti-patterns

- **Construir sem conhecer o caso de uso** — investimento técnico sem retorno; "build for the sake of building".
- **Autoatendimento para o público errado** — executivos não querem criar visualizações; analistas já usam SQL. Entender quem é o usuário real.
- **Definições de dados implícitas** — métricas calculadas de forma inconsistente em diferentes squads. Usar camada semântica para centralizar.
- **Credenciais hardcoded em notebooks** — vaza para git; compromete segurança. Nunca inserir credentials no código.
- **Permissões totais por conveniência** — "acesso de admin para todos" viola LGPD/GDPR e aumenta blast radius de vazamentos.
- **ETL reverso sem guardrails** — loop de feedback sem limite pode causar gastos/ações catastróficas em escala. Monitoramento e limitações são obrigatórios.
- **Relatórios sem adoção continuando ativos** — vulnerabilidade de segurança sem valor. Audite uso; desative produtos não utilizados.
- **Notebook local como produção permanente** — sem versionamento, sem CI/CD, sem escala. Migrar para cloud-based assim que viável.

---

## Worked Example

**Cenário:** E-commerce quer (a) dashboard de vendas para executivos, (b) modelo de recomendação para engenheiros de ML e (c) devolver leads pontuados ao CRM.

**Estratégia de disponibilização:**

```
Fontes → [Data Warehouse (Snowflake)]
                   │
        ┌──────────┼────────────┐
        ▼          ▼            ▼
   [LookML/dbt]  [Notebook   [ETL Reverso]
   métricas       Jupyter]    → CRM (Salesforce)
        │          │
   [Tableau/    [Feature
    Looker]      Store]
   (executivos) (modelo ML)
```

**SLA definido:** dados de vendas disponíveis às 06h (batch noturno), 95% sem defeitos, uptime 99%.

**Segurança:**
- Executivos: acesso somente leitura ao schema `analytics.vendas_agg`
- Cientistas de dados: acesso somente leitura a `analytics.features` (anonimizado)
- Pipeline de ETL reverso: conta de serviço com permissão de escrita apenas na tabela `crm_leads_scored`

**Guardrail ETL reverso:** se `lead_score_delta > 50%` em uma execução, pausar e alertar. Limite máximo de 10.000 registros por run.

---

## Key Takeaways

1. Comece pelo caso de uso e usuário, não pela ferramenta. "Que ação esses dados vão disparar?"
2. Confiança nos dados é o ativo mais crítico — validação, observabilidade e comunicação ativa são a base.
3. Análise de negócios (insights) ≠ análise operacional (ação imediata) ≠ análise incorporada (alta concorrência + baixa latência). Cada uma exige arquitetura diferente.
4. Camada semântica (dbt, LookML) = "grave uma vez, use em qualquer lugar". Resolve inconsistências de métricas em toda a organização.
5. ETL reverso fecha o ciclo: dados processados voltam aos sistemas de origem onde o usuário já trabalha. Requer guardrails obrigatórios.
6. Segurança na disponibilização = maior superfície de risco. Princípio do privilégio mínimo, somente leitura como padrão.
7. Autoatendimento funciona com o público certo (executivos data-savvy, escopo limitado) — falha na maioria dos casos sem esse alinhamento.
8. DataOps na disponibilização: monitorar uptime, latência, qualidade, versões e acesso continuamente.

---

## Connects To

- [ch02] Ciclo de vida DE — disponibilização é a etapa final, mas o ciclo é contínuo com loops de feedback
- [ch03] Arquitetura — data mesh reorganiza a responsabilidade de disponibilização por domínio
- [ch05] Sistemas de origem — ETL reverso envia dados de volta; SLAs e contratos de dados definidos aqui
- [ch06] Armazenamento — OLAP (data warehouse) é o backend principal; separação compute/storage habilita múltiplos warehouses por carga de trabalho
- [ch08] Transformações — camada semântica/métricas (dbt, LookML) conecta transformação e disponibilização
- [ch11] Pilha em tempo real — streaming substituirá lote na disponibilização; análise operacional é o caso de uso líder
