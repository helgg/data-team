# Chapter 15: Implementing a Data Mesh Strategy

## Core Idea
Data mesh não é uma solução técnica — é uma abordagem organizacional para gestão de dados analíticos. Criada por Zhamak Dehghani em 2019, move a responsabilidade de criar dados analíticos dos times centralizados para os domínios de negócio que produzem os dados transacionais. AWS habilita data mesh via Lake Formation (cross-account sharing) + Amazon DataZone (business data catalog).

## Frameworks Introduced

- **Os 4 Princípios de Dehghani para Data Mesh**
  1. **Domain-oriented, decentralized data ownership**: cada domínio de negócio é responsável tanto pelos dados transacionais quanto pelos analíticos; sem time central coletando dados de todos os domínios
  2. **Data as a product**: datasets analíticos tratados como produtos de software — com SLA, documentação, owners, qualidade garantida, acessíveis e descobríveis
  3. **Self-service data infrastructure as a platform**: time central constrói e mantém plataforma que outros times usam para criar data products; não implementa pipelines de negócio
  4. **Federated computational governance**: representantes de todos os domínios + plataforma definem padrões mínimos de governança; enforcement via automação; máxima autonomia para cada domínio
  - Quando usar: org com múltiplos domínios de negócio independentes, bottleneck no time central de dados, dados analíticos inacessíveis para outras equipes

- **Data Producers vs Data Consumers**
  - **Data producers**: times que criam e publicam data products no mesh
  - **Data consumers**: times que buscam no catálogo e subscrevem datasets de outros domínios
  - Um time pode ser os dois: consome dataset do domínio de música + cria novo dataset de top artistas e publica para o mesh
  - Quando usar: modelo mental para desenhar quem tem quais responsabilidades em cada interação com o data mesh

## Key Concepts

### Limitações do modelo centralizado (que data mesh resolve)

- **Bottleneck do time central**: time sobrecarregado com requests de ingestão e transformação de múltiplos domínios; priorização difícil sem visibilidade de impacto de negócio; lento para aprender sobre dados que não conhece
- **"Analytics is not my problem"**: owners de sistemas transacionais resistem a extrações de dados por medo de impacto na performance/disponibilidade dos sistemas; data mesh muda cultura: cada domínio é responsável tanto por dados transacionais quanto analíticos
- **Ausência de visibilidade**: sem catálogo centralizado, times não sabem o que já existe; modelo reativo (central team responde a requests) → data mesh é proativo (dados já publicados, self-service discovery)

### Mudanças organizacionais

- **Time central de dados → time de plataforma**: novo foco é construir/manter infraestrutura (S3, Glue, Lake Formation, DataZone, CI/CD) que domínios usam; clientes deixam de ser business users → passam a ser data engineers dos domínios
- **Data product owner** (novo papel por domínio): responsável por criar e manter data products; entende o negócio do domínio e o que outros domínios precisam; define SLA, coordena ingestão, garante qualidade e usabilidade
- **Data steward** (por domínio): garante que data products atendam políticas do governance team central; pode criar políticas adicionais específicas do domínio (ex.: HR tem requisitos extras de privacidade); representa o domínio no federated governance group
- **Executive buy-in**: mudança organizacional requer patrocínio executivo; sem sponsor C-level, domínios de negócio não aceitam nova responsabilidade

### Self-service platform — componentes

Central data mesh team provê:
- Scalable storage (S3), ingestão (DMS, Glue), qualidade (DataBrew, Glue Data Quality), transformação (Glue Studio), catálogo central (DataZone ou Collibra), automação de sharing, DW (Redshift), access control (Lake Formation), orquestração (MWAA, Step Functions), CI/CD (CodePipeline)

### Federated computational governance

- Governance group = representantes de data owners + data platform owner
- Decide padrões mínimos: formato de datas, nomenclatura de campos comuns (todos usam `customer_id`, nunca `cust-id` ou `customer_key`), métricas de qualidade mínimas, metadata obrigatória por data product
- Menos padronização = mais autonomia para domínios; mais padronização = melhor interoperabilidade
- Automação monitora compliance: data quality checks automáticos, scan de PII em datasets que não deveriam ter, alertas para data product owners fora de compliance

### Amazon DataZone

Serviço AWS lançado out/2023; business data catalog com funcionalidade de data mesh integrada ao Lake Formation.

- **Domain**: organiza data assets, projetos, contas AWS associadas; alinha com unidade de negócio (finance, HR, sales, marketing)
- **Data sources**: suporta Glue Data Catalog e Redshift; Glue também pode catalogar RDS, Snowflake, etc.
- **Business glossary**: dicionário de termos padronizados; evita variações (Country: USA vs United States vs U.S.) que dificultam busca; produtores selecionam termos do glossário ao publicar metadata
- **Metadata forms**: formulários por domínio que definem metadata obrigatória para datasets publicados; campos podem ser string, boolean, date, integer, decimal ou linked a glossário
- **Data portal**: UI fora do console AWS; acessível via SSO (Identity Center); data producers publicam, data consumers buscam e subscrevem; sem necessidade de acesso ao console AWS para usuários regulares
- **Projects e environments**: project = grupo de pessoas + data assets; environment = coleção de recursos configurados (S3, Glue databases, Athena workgroup) + IAM principals; acesso a data products concedido ao projeto, não ao indivíduo

### AWS Support para Data Mesh

- **Lake Formation cross-account sharing**: S3-based tables e Redshift tables compartilhadas entre contas sem copiar dados; consumidor vê tabela como local; producer controla acesso granular (column/row-level); DataZone automatiza o Lake Formation share após aprovação de subscription
- **Redshift data shares**: tabelas Redshift compartilhadas entre clusters via Lake Formation; consumidor consulta como tabela local
- **DataZone automated sharing**: só funciona com managed assets (S3 com Lake Formation permissions, ou Redshift); unmanaged assets exigem processo manual após aprovação da subscription

### Arquiteturas

**AWS-native**: DataZone domain (conta central) → data producer publica em Glue Catalog → DataZone importa metadata → consumer subscreve → DataZone usa Lake Formation para sharing automático → consumer usa Athena sobre dados do producer (ainda no S3 do producer)

**Multi-vendor/hybrid**: Collibra como catálogo central → JDBC connectors para Snowflake/Databricks/Teradata → subscription aprovada → ServiceNow ticket → admin faz share manual (ou automação via Collibra marketplace); query federation via Starburst como alternativa ao data copying

## Reference Tables

### 4 Princípios — implicações práticas

| Princípio | O que muda | Quem é afetado |
|-----------|-----------|----------------|
| Domain-oriented ownership | Domínios criam próprios data products | Todos os domínios de negócio |
| Data as a product | SLA, documentação, quality garantida | Data product owner por domínio |
| Self-service platform | Time central para de fazer pipelines | Time central vira platform team |
| Federated governance | Standards mínimos + automação de compliance | Governance group + data stewards |

### Novos papéis por domínio

| Papel | Responsabilidade principal | Novo ou realocado |
|-------|--------------------------|-------------------|
| Data product owner | Criar, manter e garantir qualidade dos data products | Novo papel |
| Data architect/engineer | Implementar pipelines ETL usando a plataforma | Pode ser realocado do time central |
| Data steward | Garantir compliance com governance policies | Novo papel |
| Data platform owner (central) | Roadmap e desenvolvimento da plataforma | Evolução do líder do time central |

### DataZone — fluxo do data mesh

| Etapa | Ator | Ferramenta |
|-------|------|-----------|
| 1. Criar data product no S3 | Data engineer do domínio | Glue ETL |
| 2. Registrar metadata técnica | Glue Crawler | Glue Data Catalog |
| 3. Importar + adicionar business metadata | Data producer | DataZone data portal |
| 4. Publicar no catálogo | Data product owner | DataZone data portal |
| 5. Buscar e subscrever | Data consumer | DataZone data portal |
| 6. Aprovar subscription | Data owner/steward | DataZone notificação |
| 7. Sharing automático | DataZone + Lake Formation | Automático (managed assets) |
| 8. Consumir dado | Data consumer | Athena / Redshift Spectrum |

### DataZone vs Collibra — quando usar

| Cenário | Solução recomendada |
|---------|-------------------|
| 100% AWS-native (S3 + Redshift) | Amazon DataZone (sharing automático) |
| Multi-vendor (Snowflake + Databricks) | Collibra / Atlan / Alation + integrações |
| Data lineage necessário | Collibra / Atlan (DataZone não suporta ainda) |
| Apenas sharing, sem catálogo sofisticado | Lake Formation diretamente |
| Organização pequena iniciando data mesh | AWS-native + DataZone |

## Worked Example

**Hands-on Ch15 — DataZone: setup → publicar data product → subscrever**

**Objetivo**: film catalog team publica `film_category` no DataZone; marketing team descobre e subscreve.

**1. Configurar Identity Center** (para login no DataZone portal):
```
Serviço: IAM Identity Center
Usuários criados:
  - film-catalog-team-admin (email: user+film-catalog-team-admin@example.com)
  - marketing-team-admin (email: user+marketing-team-admin@example.com)
Grupo: DataZone Users
```

**2. Criar DataZone domain**:
```
Domain name: streaming
Quick setup: ✓ Setup this account for data consumption and publishing
User management: ✓ Enable users in IAM Identity Center
→ Resultado: data portal URL gerada (https://<domain-id>.datazone.aws/)
```

**3. Criar projeto e environment (como film-catalog-team-admin)**:
```
Project: Film Catalog Project
Environment: Film Datasets S3
Environment profile: DataLakeProfile
→ DataZone cria: Glue databases (producer + consumer), S3 bucket, Lake Formation permissions
```

**4. Importar data source**:
```
Data source: films-CuratedZoneDB
Type: AWS Glue
Database: curatedzonedb
→ Importa tabelas do Glue Data Catalog para inventário do projeto
→ DataZone gera automated business names para colunas (ex.: category_id → "Category ID")
```

**5. Adicionar business metadata e publicar**:
```
Asset name: "Movie listings with category"
Description: "This table contains a complete listing of all films in our streaming 
              movie catalog, including category/genre information for each film..."
Column category_name: "This field contains the movie category/genre. 
                       Sample categories include Animation, Comedy, Sports..."
→ Publicar: disponível no data catalog para todos os usuários
```

**6. Consumer busca e subscreve (como marketing-team-admin)**:
```
Projeto: marketing-team-analysis
Environment: marketing-team-datalake (DataLakeProfile)
Busca no catálogo: "movie genre"
→ Encontra "Movie listings with category" (Glue table foi curatedzonedb.film_category)
→ Subscribe → reason: "Need access for marketing project"
```

**7. Producer aprova subscription**:
```
Notificação → Subscription request created
Approve → Decision comment → Approve
→ Dataset compartilhado (automático apenas se managed via Lake Formation)
```

**Observação crítica**: `film_category` é unmanaged asset (sem Lake Formation permissions) → DataZone não faz sharing automático após aprovação; requer processo manual (IAM permissions para Glue/S3). Para sharing totalmente automático → todos os datasets devem usar Lake Formation.

## Key Takeaways

1. Data mesh é mudança organizacional primeiro, técnica depois: sem executive buy-in e redistribuição de responsabilidades pelos domínios, ferramentas não resolvem o problema; implementação técnica sem mudança organizacional = fracasso
2. "Data as a product" muda a mentalidade: domain team para de ser fornecedor reativo de dados e passa a ser owner proativo de produtos; SLA, qualidade, documentação e acessibilidade são responsabilidade do domínio produtor
3. Self-service platform separa infraestrutura de negócio: time central constrói S3 + Glue + Lake Formation + DataZone; times de domínio usam essa infraestrutura para criar pipelines de negócio; time central não implementa lógica de negócio
4. Federated governance = mínimo necessário + máxima autonomia: standard de nomes de campos comuns + formato de datas = o suficiente para interoperabilidade; cada domínio tem liberdade adicional; automação de compliance > policies manuais
5. DataZone automatiza o loop de sharing: busca → subscrever → aprovar → Lake Formation sharing automático; funciona bem em ambientes 100% AWS-native; híbrido/multi-vendor exige custom integrations ou catalogs como Collibra
6. Data mesh "limitado" tem valor: adotar apenas data catalog + sharing entre contas já resolve o problema de visibilidade; não é fracasso; é evolução iterativa em direção ao modelo completo de Dehghani
7. Lake Formation é a cola técnica: cross-account sharing de S3 e Redshift sem copiar dados; consumidor vê tabela como local; DataZone usa Lake Formation como mecanismo de enforcement após aprovação de subscription

## Connects To

- **Ch04**: Lake Formation introduzido como ferramenta de access control; Ch15 usa Lake Formation para cross-account sharing como mecanismo de data mesh
- **Ch08**: data consumers (business users, analysts) são o público-alvo dos data products publicados no data mesh; DataZone data portal como interface self-service
- **Ch09**: Redshift data shares via Lake Formation = mecanismo para data products em DW; consumer vê tabela Redshift de outro domínio como local
- **Ch11**: Athena para consumo de data products S3 compartilhados via Lake Formation; consumidor roda queries como se dados fossem locais
- **Ch12**: QuickSight embedded dashboards = mecanismo de consumo federado de data products; cada domínio pode ter seu próprio dataset publicado via DataZone
- **Ch14**: OTFs (Iceberg) por domínio + Lake Formation sharing = transactional data lake distribuído; consumidor lê tabela Iceberg de outro domínio com garantias ACID
