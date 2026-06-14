# Chapter 12: Visualizing Data with Amazon QuickSight

## Core Idea
Dado bruto em tabelas não comunica; dado visual em segundos revela trends, outliers e correlações que levariam horas de análise SQL. O data engineer não apenas abastece o BI tool com dados — define a estrutura (datasets, SPICE refresh, sources) e a governança (quem acessa o quê) que permite ao business user explorar sem intermediário. QuickSight é o BI serverless AWS-native que fecha o ciclo do data lake até o dashboard executivo.

## Frameworks Introduced

- **SPICE vs Direct Query Decision**
  - **Direct Query**: cada acesso ao dashboard faz query na fonte; dado sempre atual; paga por query (Athena on-demand) ou usa recurso da fonte (RDS, Redshift)
  - **SPICE**: importa dado em memória; dashboards leem SPICE sem custo de query; reduz carga na fonte; dado pode ficar stale
  - Quando usar SPICE: dados de alta concorrência (1.000 readers consultando mesma tabela = 1.000 queries vs 1); dados com frequência de atualização previsível (diária, horária); custo de query alto (Athena on-demand)
  - Quando usar Direct Query: dado muda constantemente; equipe pequena; tempo de query < 2 minutos (timeout do QuickSight)
  - Regra: SPICE + refresh agendado = padrão para relatórios de negócio; Direct Query = exceção para dados em tempo real de equipes pequenas

- **ETL in QuickSight vs ETL outside QuickSight**
  - **Dentro do QuickSight**: join, filter, rename, calculated fields — via interface visual; não requer code review; mais ágil para analistas
  - **Fora do QuickSight (Glue, DataBrew)**: dataset disponível para múltiplos consumers (Athena, Redshift, outros); governado por pipeline formal; código em source control
  - Regra de decisão: se dataset será consumido apenas em QuickSight e transformações são simples → dentro; se dataset é reutilizado ou governa decisões críticas → fora, com pipeline formal

## Key Concepts

- **Amazon QuickSight**: BI serverless AWS; análises (authoring) + dashboards (publicados para readers); pricing por usuário (authors: fixo; readers: por sessão $0.30, máx $5/mês); Standard e Enterprise editions; sem infraestrutura para gerenciar
- **SPICE (Super-fast, Parallel, In-memory, Calculation Engine)**: engine in-memory do QuickSight; 10 GB por author no account; refresh: Standard = diário/semanal/mensal; Enterprise = incremental a cada 15 min, full a cada hora; API call para trigger event-driven; timeout de 2 min em direct query → migrar para SPICE se ultrapassar
- **SPICE limits**: Enterprise: 1 bilhão de rows ou 1 TB por dataset; Standard: 25 milhões de rows ou 25 GB; capacidade adicional: $0.38/GB/mês
- **Standard vs Enterprise edition**: Standard → todos users têm full author + reader, $12/user/mês; Enterprise → authors (fixo) + readers por sessão; AD/SAML, embedded dashboards, ML Insights, paginated reports, encryption at rest, fine-grained access control (somente Enterprise)
- **Analysis**: workspace de authoring onde authors criam visuals; max 50 datasets, 20 sheets (tabs), 30 visuals por sheet; publicado como dashboard
- **Dashboard**: análise publicada; readers podem filtrar, drill-down, sort, download CSV (se autor permitir); não podem editar
- **AutoGraph**: seleção automática de tipo de visual baseada em campos e tipos de dados selecionados; ponto de partida para exploração
- **Visual types**: line chart (trends over time), geospatial/points on map (dados geográficos), heat map (intersecção de dimensões por cor), bar chart (simples/stacked/clustered/horizontal), KPI (progresso vs meta com progress bar), tabela (dados raw, max 200 cols), pie/donut, box plot, gauge, histogram, pivot table, sankey, treemap, waterfall, word cloud, custom (imagem/vídeo/formulário/página web embutida)
- **ML Insights** (Enterprise only): autonarratives (texto em linguagem natural descrevendo o visual), anomaly detection (outlier detection em milhões de métricas, agendável de 1h a 1 mês), forecasting (predição de valores futuros via ML; mínimo 38 data points diários para forecast diário)
- **QuickSight Q**: NLQ (Natural Language Query); user digita "show me top 3 categories by revenue 2023" → QuickSight gera visual; requer configuração de Topics por author; +$250/account/mês + $10/author + reader cap $10; Generative BI (via Amazon Bedrock): criar visuals, cálculos e refinamentos por prompt (preview set/2023)
- **Q Topics**: coleção de datasets representando subject area de negócio; Automated Data Preparation: seleção automática de campos, renomeação (DOB → Date of Birth), synonyms (SALES_REP → salesperson, account representative), formato (revenue → currency); fine-tune via feedback de queries dos usuários
- **Embedded Dashboards** (Enterprise only): dashboards em aplicações ou websites; usuários autenticados (SSO/SAML/AD) ou anônimos (session capacity pricing = N sessions/mês ou /ano); anonymous access remove "Powered by QuickSight" no plano anual
- **Paginated Reports** (Enterprise, custo adicional): PDFs multi-página até 1.000 páginas; page size/orientation/layout definidos pelo author; agendável; $500/mês para 500 report units (1 unit = 100 páginas ou 100 MB)
- **Sources QuickSight**: AWS-native (S3, Athena, Redshift, Aurora, OpenSearch, IoT Analytics, RDS); data warehouses externos (Snowflake, Teradata); SaaS (Salesforce, Jira, ServiceNow, GitHub, Twitter, Adobe Analytics); arquivos (CSV, JSON, XLSX via upload ou S3)

## Reference Tables

### SPICE vs Direct Query — quando usar

| Critério | SPICE | Direct Query |
|---------|-------|-------------|
| Latência do dashboard | Muito baixa (in-memory) | Depende da fonte |
| Custo de query (Athena on-demand) | Uma vez no refresh | A cada acesso |
| Freshness | Depende do refresh schedule | Sempre atual |
| Timeout (2 min) | Não se aplica | Risco com queries pesadas |
| Alta concorrência de readers | Ideal | Sobrecarga na fonte |
| Dados em tempo real | Não recomendado | Recomendado |
| Recomendação padrão | Relatórios de negócio | Dashboards operacionais de equipes pequenas |

### Standard vs Enterprise — diferenças-chave

| Feature | Standard | Enterprise |
|---------|---------|-----------|
| Preço author | $12/user/mês | Fixo (maior) |
| Preço reader | = author | $0.30/sessão (máx $5/mês) |
| AD / SAML | Não | Sim |
| Embedded dashboards | Não | Sim |
| ML Insights | Não | Sim |
| Paginated Reports | Não | Sim |
| Encryption at rest | Não | Sim |
| Incremental SPICE refresh | Não | Sim (a cada 15 min) |
| SPICE limit por dataset | 25 M rows / 25 GB | 1 B rows / 1 TB |
| Downgrade possível | N/A | **Não** |

### Visual types — quando usar

| Visual | Quando usar |
|--------|-------------|
| Line chart | Trend de métrica ao longo do tempo |
| Geospatial / Points on map | Dados com lat/lng ou código geográfico |
| Heat map | Correlação entre duas dimensões (cor = intensidade) |
| Bar chart | Comparação de métrica entre categorias |
| KPI | Progresso vs meta (revenue atual vs target) |
| AutoGraph | Exploração inicial sem saber o visual correto |
| Pivot table | Análise multidimensional (linhas × colunas) |
| Forecasting (ML) | Predição de valores futuros com histórico suficiente |
| Anomaly detection | Identificar outliers em séries temporais de métricas |

## Worked Example

**Hands-on Ch12 — Geospatial visualization: cidades por população**

**Dataset**: `worldcities.csv` (simplemaps.com, CC BY 4.0); ~41.000 cidades; campos: `city`, `lat`, `lng`, `population`

**Setup QuickSight**:
```
Edition:      Standard (upgrade para Enterprise quando necessário)
Auth method:  IAM federated identities
Account name: data-engineering-<initials>
```

**Criar visual "Points on Map"**:
```
Visual type:    Points on Map
Geospatial:     lat, lng (drag ambos no mesmo field well)
Size:           population
Color:          city
```

**Filtro — exibir apenas cidades com pop ≥ 5M**:
```
Field:      population
Condition:  Greater than or equal to
Value:      5000000
→ Click APPLY
```

**Resultado**: mapa mundial com círculos proporcionais à população; ~50 cidades visíveis; maior concentração em Ásia (China, Índia); América do Sul com 2–3 pontos (São Paulo, Buenos Aires, Bogotá).

**Publicar como dashboard**:
```
SHARE → Publish dashboard → Name: "World Cities by Population" → Publish dashboard
```
→ Disponível para todos os QuickSight users do account com acesso de reader.

**Interatividade para readers**:
- Hover sobre círculo → popup com city, lat, lng, population
- Zoom in/out no mapa
- Filtrar por population diferente (self-service)
- Download CSV dos dados filtrados

## Key Takeaways

1. SPICE é o padrão para relatórios de negócio: importa dado uma vez, dashboards leem in-memory sem custo de query; refresh agendado ou event-driven (Enterprise via API) mantém dado atualizado
2. Direct query é exceção: usar somente para dados em tempo real com equipes pequenas e queries rápidas (< 2 min); custo de query pago a cada acesso de dashboard
3. ETL fora do QuickSight para datasets reutilizados: pipeline formal (Glue, DataBrew) → dado disponível para Athena + Redshift + QuickSight; QuickSight ETL apenas para transformações simples de uso único
4. Standard Edition para começar, Enterprise quando necessário: não é possível fazer downgrade → avaliar necessidade de embedded dashboards, ML Insights, e fine-grained access control antes de subir
5. ML Insights democratiza análise avançada: autonarratives, anomaly detection e forecasting sem conhecimento de ML; disponível apenas no Enterprise; requisito mínimo de dados para forecasting (38+ data points diários)
6. QuickSight Q reduz intermediários: analistas fazem NLQ diretamente sem data engineer; Topics exigem configuração inicial por author + fine-tune contínuo com base em feedback de uso real
7. Embedded dashboards para distribuição ampla: registrados (SSO/SAML) ou anônimos (session capacity) — viabiliza disseminação de dados para público externo ou aplicações customizadas sem exposição do console AWS

## Connects To

- **Ch08**: QuickSight introduzido como ferramenta primária para Business Users; SPICE como alternativa ao Redshift para caching in-memory
- **Ch09**: Redshift como fonte de alta performance para QuickSight; SPICE vs Redshift: SPICE = caching em QuickSight; Redshift = DW dedicado com concorrência própria
- **Ch11**: Athena como fonte QuickSight; SPICE importa resultado Athena → elimina custo de query on-demand a cada acesso de dashboard
- **Ch13**: Amazon Bedrock (LLMs) powers QuickSight Generative BI; SageMaker models podem gerar scores que alimentam dashboards QuickSight
- **Ch15**: Data Mesh — cada data product domain pode ter seu próprio dataset QuickSight; embedded dashboards como mecanismo de consumo federado
