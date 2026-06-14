# Chapter 1: An Introduction to Data Engineering

## Core Idea
Dados tornaram-se ativo corporativo estratégico, e o engenheiro de dados é o responsável por construir as pipelines que ingerem, transformam e disponibilizam esses dados para os consumidores — papel análogo ao engenheiro civil que constrói infraestrutura de transporte.

## Frameworks Introduced

- **Three Organizational Data Maturity States**
  - Estado 1: programa de analytics e ML eficaz que diferencia dos concorrentes
  - Estado 2: projetos piloto avaliando como modernizar analytics para vantagem competitiva
  - Estado 3: liderança preocupada com concorrentes usando analytics para ganhar vantagem
  - Quando usar: diagnóstico de maturidade; usado para priorizar investimentos
  - Como: identificar onde a organização está para definir o roadmap de modernização

- **Data Infrastructure Evolution (linha do tempo)**
  - Single DB → múltiplos DBs (silos) → Data Warehouse → Hadoop/MapReduce → Apache Spark → Data Lakes → Data Mesh
  - Cada salto foi impulsionado pelo custo ou limitação do modelo anterior

- **Data Mesh (Zhamak Dehghani / Thoughtworks)**
  - Equipes que geram dados ficam responsáveis por criar e manter a versão analítica dos seus dados (data products)
  - Dois níveis: time central cria plataforma de dados padronizada; times de produto criam e publicam seus data products
  - Quando usar: organizações grandes com dados distribuídos em múltiplos domínios de negócio
  - Como: nomear um Data Product Manager por domínio; esse papel cuida de qualidade, freshness, schema changes e SLA do produto

## Key Concepts

- **Data Lake**: repositório centralizado que armazena dados estruturados e não estruturados em escala, usando object storage de baixo custo (ex.: Amazon S3) com catálogo central (Apache Hive)
- **Apache Spark**: framework de processamento de big data que opera principalmente em memória; padrão de fato para processar grandes volumes
- **Hadoop/MapReduce**: predecessor do Spark; criado no Yahoo para indexar 1 bilhão de páginas web; complexo de operar
- **Data Silo**: banco de dados ou sistema isolado que não compartilha dados com outros sistemas da organização
- **Data Product**: versão analítica de dados operacionais, gerenciada pela equipe que gera os dados, com SLA, qualidade e documentação próprios
- **Data Product Manager**: papel responsável por criar, manter e evoluir um data product dentro de uma equipe de produto
- **CDO (Chief Data Officer)**: executivo C-level responsável pela estratégia de dados; cresceu de 12% das empresas em 2012 para 65% em 2021
- **IAM (Identity and Access Management)**: serviço AWS para controlar acesso a recursos; usuário root deve ser protegido com MFA e não usado para atividades cotidianas
- **Sandbox Account**: conta AWS isolada dos sistemas de produção corporativos, usada para experimentação segura

## Mental Models

- **Engenheiro Civil Analogy**: Use o engenheiro de dados como o engenheiro civil — ele constrói estradas e pontes (pipelines); o cientista de dados projeta novos meios de transporte (modelos ML); o analista é o piloto que leva o usuário ao destino (insights). Quando precisar explicar papéis, use essa analogia.
- **Ativo Corporativo**: Pense em dados como propriedade intelectual — ignorar durante anos porque era "caro de gerenciar" é análogo a ter petróleo e não refinar. A falta de estratégia equivale a perder vantagem competitiva para quem refina.
- **Centralização vs. Descentralização**: Data lakes centralizados criam gargalo na equipe central que não tem contexto de negócio dos dados. Data mesh descentraliza ownership mas mantém plataforma central — melhor dos dois mundos para organizações maduras.

## Anti-patterns

- **Root User como conta diária**: Logar com root user para atividades rotineiras expõe a conta a riscos críticos — criar usuário IAM com AdministratorAccess e usar MFA
- **Data Warehouse único para tudo**: Limita volume por custo de storage; exclui dados semi-estruturados e não estruturados; cria múltiplos data marts sem fonte única da verdade
- **Data mesh como projeto puramente técnico**: Implementar data mesh apenas como solução de compartilhamento de dados sem mudar processos e cultura falha — é uma mudança organizacional, não só técnica

## Worked Example

**Cenário do gerente de vendas** (walkthrough dos três papéis):

*Objetivo*: entender quais produtos alternativos o cliente considera antes de comprar, e prever demanda por categoria com base no clima.

| Papel | Responsabilidade no cenário | Ferramentas |
|-------|----------------------------|-------------|
| Data Engineer | Ingerir: BD de pedidos, logs web, dados de terceiros (Amazon.com), dados meteorológicos | Kafka, Spark, Presto |
| Data Scientist | Treinar modelo ML correlacionando vendas históricas com clima → prever top-selling por categoria | Modelos ML/AI |
| Data Analyst | Queries sobre quais produtos alternativos foram visualizados antes da compra → relatório de padrões | BI Tools, SQL |

*Dependência*: o cientista de dados depende do engenheiro para ter os dados; o analista depende do engenheiro para ter dados estruturados e do cientista para modelos avançados.

## Key Takeaways

1. Dados são ativo estratégico — organização sem estratégia de dados perde vantagem competitiva
2. Data Engineer: design + implementação + manutenção de pipelines de ingestão, transformação e disponibilização de dados
3. Data Mesh resolve o gargalo da equipe central descentralizando ownership dos data products para quem gera os dados
4. Amazon S3 é o storage layer de fato para data lakes em AWS — escalabilidade ilimitada a baixo custo
5. Conta AWS: nunca usar root user no dia a dia; criar IAM user com AdministratorAccess e habilitar MFA

## Connects To

- **Ch02**: arquiteturas de data management (data warehouse, data lake, data lakehouse) — aprofunda a evolução introduzida aqui
- **Ch06**: ingestão batch e streaming — implementação prática do papel do data engineer
- **Ch07**: transformação de dados — segunda responsabilidade central do data engineer
- **Ch15**: Implementing a Data Mesh — aprofundamento do conceito introduzido neste capítulo
- **Ch16**: Modern Data Platform — DataOps e observabilidade, evolução natural da plataforma centralizada
