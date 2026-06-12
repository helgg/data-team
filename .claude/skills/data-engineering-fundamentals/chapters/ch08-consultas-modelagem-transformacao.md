# Ch08 — Consultas, Modelagem e Transformação

## Core Idea

Dados brutos só geram valor quando consultados, modelados e transformados. Consultas recuperam dados; modelos impõem lógica de negócios; transformações persistem resultados para consumo downstream escalável. Sem modelagem deliberada os sistemas degenerem em data swamps — dados redundantes, inconsistentes e inúteis.

---

## Frameworks Introduzidos

### 1. Ciclo de Vida de uma Consulta SQL
1. Parsing e validação semântica
2. Compilação em bytecode
3. Otimizador de consultas (reordena etapas, escolhe índices, minimize custo)
4. Execução e produção de resultados

O otimizador é o parceiro invisível. Compreendê-lo elimina a maioria dos problemas de desempenho.

### 2. Abordagens de Modelagem Analítica em Lote

| Abordagem | Orientação | Normalização | Ponto forte | Limitação |
|-----------|-----------|--------------|-------------|-----------|
| Inmon | Top-down (DW → data marts) | Rigorosa (3NF) | Única fonte de verdade corporativa | Lento para iterar |
| Kimball | Bottom-up (data marts = DW) | Flexível (desnorm. aceita) | Rápido, acessível para negócios | Redundância potencial |
| Data Vault | Separação estrutura/atributos | Insert-only; hubs/links/satélites | Ágil, tolerante a mudanças | Complexidade de consulta |
| Tabela Ampla | Nenhuma | Totalmente desnormalizada | Simplicidade, desempenho colunar | Perde lógica de negócios |

### 3. Dimensões de Alteração Lenta (SCD)

| Tipo | Comportamento | Quando usar |
|------|--------------|-------------|
| Tipo 1 | Substitui o registro | Sem histórico necessário |
| Tipo 2 | Novo registro + datas efetivas | Histórico completo (padrão recomendado) |
| Tipo 3 | Novo campo para mudança | Apenas mudança mais recente importa |

### 4. Padrões de Atualização em Bancos Colunares

| Padrão | Descrição | Trade-off |
|--------|-----------|-----------|
| Truncar + recarregar | Apaga e regrava | Simples, pesado para tabelas grandes |
| Insert-only | Só insere, deduplicação na query | Barato de gravar, caro de ler |
| Exclusão suave | Marca registro como excluído | Mantém histórico, query mais complexa |
| Upsert/Merge | Match por chave + insert/update | COW custoso; evitar frequência alta |

### 5. Hierarquia de Virtualização de Consultas
**Visualização** → **Visualização Materializada** → **Consulta Federada** → **Virtualização de Dados (Trino/Presto)**

---

## Key Concepts

**DDL / DML / DCL / TCL** — as quatro sub-linguagens do SQL: definem objetos, manipulam dados, controlam acesso e controlam transações.

**Pruning** — reduzir dados lidos: em colunar, selecionar só colunas necessárias + cluster/partition keys; em orientado por linhas, usar índices.

**Explosão de linhas** — junção muitos-para-muitos com chaves repetidas produz produto cartesiano; reordenar predicados ou aplicar filtro antes da junção resolve.

**Aspiração (VACUUM)** — remoção de registros obsoletos gerados por transações. Crítico em PostgreSQL/MySQL; automático ou configurável em BigQuery/Snowflake/Databricks.

**Granularidade** — nível de detalhe de uma tabela. Sempre modele no menor nível possível; agregar é trivial, desagregar é impossível.

**Normalização 1NF/2NF/3NF** — 1NF: valores atômicos + chave primária. 2NF: sem dependências parciais. 3NF: sem dependências transitivas.

**Esquema estrela (Kimball)** — tabela fato central (eventos quantitativos, imutáveis, estreita e longa) + tabelas dimensão ao redor (atributos qualitativos, largas e curtas, desnormalizadas).

**Data Vault** — Hubs (chaves de negócio únicas), Links (relacionamentos muitos-para-muitos entre hubs), Satélites (atributos descritivos). Tudo insert-only; lógica de negócio aplicada na query, não no carregamento.

**Janelas de streaming** — sessão (inatividade delimita), tempo fixo/cascata (intervalos regulares), deslizante (sobreposição). Marcas d'água controlam dados atrasados.

**MapReduce → pós-MapReduce** — MapReduce: tudo em disco, rígido porém escalável. Pós-MapReduce (Spark, BigQuery): cache em memória, mais rápido, exige otimização manual.

**COW (Copy On Write)** — sistemas baseados em arquivos (data lakes, colunares) reescrevem o arquivo inteiro ao atualizar. Upserts frequentes são caros; prefira lotes.

**Camada de métricas/semântica** — codifica lógica de negócios fora dos scripts ETL, permitindo que analistas construam análises a partir de definições centralizadas (ex: dbt metrics, Looker LookML).

**FinOps em queries** — data warehouses cloud cobram por bytes lidos/computação; otimizar queries = reduzir custo direto, não apenas latência.

---

## Mental Models

**"Consulta recupera; transformação persiste."** — A distinção é sobre durabilidade dos resultados. Se você precisa reutilizar o cálculo, transforme e armazene.

**"Lote é caso especial de streaming."** — Janelas de tempo fixo com intervalo longo = processamento em lote. A abstração streaming é mais geral.

**"Modelar dados = traduzir lógica de negócios em estrutura."** — Um modelo ruim não é apenas feio; é uma mentira sobre o negócio. Envolva stakeholders antes de modelar.

**"Quanto mais granular, melhor."** — Você sempre pode agregar; nunca pode desagregar. Modelo no nível mais atômico possível.

**"Não lute contra o banco de dados."** — Cada banco tem pontos fortes. Aprenda o otimizador do seu sistema antes de tentar contorná-lo.

**"Data swamp = ingestão sem modelagem."** — O data lake 1.0 provou: jogar dados sem plano gera caos. Modelagem não é opcional.

---

## Anti-patterns

- **SELECT * sem predicados** — full table scan; em cloud OLAP cobrado por bytes lidos.
- **Inserções de linha única em banco colunar** — gera dezenas de arquivos pequenos; destruição de desempenho de leitura.
- **Upsert/merge em alta frequência via CDC** — COW sobrecarrega sistemas colunares; consolidar em lotes (ex: a cada hora).
- **UDFs Python no Spark sem necessidade** — força saída do runtime JVM; preferir API nativa ou Scala.
- **Modelar no nível agregado** — perde granularidade para futuros relatórios mais detalhados.
- **Dados sem modelo = data swamp** — ausência de lógica de negócios impede análises consistentes.
- **ETL "jogar e esquecer"** — ingerir sem transformar resulta em dados nunca usados (Inmon: "já vi dados esperando seis meses").
- **Virtualizar banco de produção para análise** — o sistema de virtualização extrai do MySQL na query; continua impactando produção.

---

## Worked Example

**Cenário:** E-commerce precisa de relatório "vendas brutas por cliente por dia" e suporte a SCDs para mudanças de endereço.

**Decisão de modelagem (Kimball):**
- `fato_pedidos(OrderID, CustomerKey, DateKey, GrossSalesAmt)` — granularidade: um pedido por linha
- `dim_data(DateKey, Date-ISO, Year, Quarter, Month, DayOfWeek)`
- `dim_cliente(CustomerKey, FirstName, LastName, ZipCode, EFF_StartDate, EFF_EndDate)` — SCD Tipo 2

**Padrão de atualização:**
- Novos pedidos: insert-only na tabela fato
- Mudança de endereço de cliente: fechar linha atual (atualizar EFF_EndDate) + inserir nova linha com novo ZIP e EFF_StartDate = hoje, EFF_EndDate = 9999-01-01

**Otimização de query:**
```sql
-- Ruim: full scan + recálculo de junção
SELECT c.FirstName, SUM(f.GrossSalesAmt)
FROM fato_pedidos f
JOIN dim_cliente c ON f.CustomerKey = c.CustomerKey
GROUP BY c.FirstName;

-- Melhor: filtrar cliente ativo antes da junção (broadcast join)
WITH clientes_ativos AS (
  SELECT CustomerKey, FirstName
  FROM dim_cliente
  WHERE EFF_EndDate = '9999-01-01'
)
SELECT c.FirstName, SUM(f.GrossSalesAmt)
FROM fato_pedidos f
JOIN clientes_ativos c ON f.CustomerKey = c.CustomerKey
GROUP BY c.FirstName;
```

---

## Key Takeaways

1. O otimizador de consultas é seu aliado; use EXPLAIN para diagnosticar e reordenar predicados/junções conscientemente.
2. Kimball (esquema estrela) é bottom-up e rápido de iterar; Inmon é top-down e rigoroso; Data Vault é ágil para esquemas instáveis.
3. SCD Tipo 2 é o padrão de rastreamento histórico de dimensões mais usado na prática.
4. Em sistemas colunares: inserções em lote >> inserções linha a linha; upserts frequentes destroem desempenho (COW).
5. Visualizações materializadas = transformação gerenciada pelo banco; compostas (Databricks Live Tables) = pipelines declarativos.
6. Microlotes vs. streaming puro não tem resposta universal — depende de latência aceitável, expertise da equipe e caso de uso.
7. A camada de métricas/semântica (dbt, LookML) descentraliza lógica de negócios dos scripts ETL, reduzindo divergências.
8. Transformações devem servir ao negócio, não à tecnologia; valor = dados confiáveis que stakeholders downstream podem usar.

---

## Connects To

- [ch02] Ciclo de vida DE — transformação é a etapa onde dados se tornam úteis
- [ch03] Arquitetura — ETL/ELT, Lambda, Kappa, data lakehouse com suporte a updates
- [ch05] Sistemas de origem — CRUD, ACID, CDC que alimentam consultas e transformações
- [ch06] Armazenamento — colunar vs. orientado por linhas, índices, particionamento, pruning
- [ch07] Ingestão — CDC contínua como base para streaming queries (seguidor rápido)
- [ch09] Disponibilização — camada semântica/métricas mencionada aqui é detalhada lá
- [ch11] Pilha de dados em tempo real — transformações se aproximam dos sistemas de origem
