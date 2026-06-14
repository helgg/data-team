# Chapter 14: Building Transactional Data Lakes

## Core Idea
Data lakes tradicionais (Hive) eram imutáveis na prática: atualizar um registro exigia reescrever a partição inteira, sem garantias ACID, sem time travel, sem schema evolution segura. Open Table Formats (OTFs) — Delta Lake, Apache Hudi, Apache Iceberg — resolvem esses problemas adicionando uma camada de metadata sobre o Parquet/S3 existente. O resultado: data lake com capacidades de data warehouse, mantendo custo e flexibilidade do object storage.

## Frameworks Introduced

- **COW vs MOR — escolha de write vs read performance**
  - **COW (Copy-on-Write)**: ao atualizar/deletar registro, reescreve o arquivo Parquet afetado inteiro com os novos dados; metadata aponta para novo arquivo; snapshot anterior aponta para arquivo original (base do time travel); leituras rápidas, escritas lentas
  - **MOR (Merge-on-Read)**: ao atualizar/deletar, cria delete tracking file + arquivo com registro atualizado; leitura faz merge em tempo de query; escritas rápidas, leituras mais lentas; compaction periódico mescla delta logs no Parquet base para restaurar performance de leitura
  - Quando usar COW: updates/deletes infrequentes; workload read-heavy; simplicidade operacional
  - Quando usar MOR: escritas frequentes (streaming, CDC); workload write-heavy + compaction em horário off-peak

- **OTF Metadata Hierarchy (Iceberg como modelo)**
  - Glue Catalog → aponta para `metadata.json` atual
  - `metadata.json` → schema, partitioning, snapshot stats, ref para manifest list
  - Manifest list (Avro, prefixo `snap-`) → lista de manifest files para aquele snapshot
  - Manifest files (Avro) → metadata por data file (column min/max, record count, null count, partition info)
  - Data files (Parquet) → dados reais
  - Benefício: query planner lê apenas metadata para identificar quais Parquet files abrir → evita listar todos arquivos da partição e ler metadata de cada um individualmente (overhead do Hive)

## Key Concepts

### Limitações do Hive que OTFs resolvem

- **Problema de row-level update no Hive**: S3 é imutável — não há update in-place; para deletar 1 registro em partição com 300 Parquet files de 1 GB cada → ler toda a partição → criar novo dataframe sem o registro → reescrever todos os 300 arquivos; 300 GB de I/O para apagar 1 linha
- **Race condition no Hive**: dois jobs atualizando a mesma partição simultaneamente → inconsistência dos dados ou corrupção da partição
- **ACID ausente no Hive**: sem atomicity (update parcial pode falhar deixando partição inconsistente) e sem isolation (query durante update pode retornar resultado misto)

### Propriedades ACID nos OTFs

- **Atomicity**: transação com múltiplos updates = tudo ou nada; se update 3 de 5 falha → rollback dos updates 1 e 2
- **Consistency**: query durante update recebe resultado da tabela antes ou depois do update, nunca estado intermediário
- **Isolation**: transações concorrentes não interferem entre si; uma completa antes da outra começar
- **Durability**: commit bem-sucedido persiste; todas as leituras futuras refletem estado pós-commit

### Benefícios comuns aos 3 OTFs

- **Record-level updates**: INSERT, UPDATE, DELETE em nível de registro; OTF gerencia complexidade de localizar e atualizar/reescrever apenas os arquivos corretos
- **Schema evolution**: ADD COLUMN, DROP COLUMN, RENAME COLUMN, REORDER COLUMNS, CHANGE TYPE (int → long) sem quebrar queries existentes
- **Time travel**: query `FOR TIMESTAMP AS OF '...'` retorna dado como estava naquele timestamp; snapshots mantidos até VACUUM os deletar; cuidado: GDPR deletion (right to be forgotten) exige VACUUM explícito para deletar snapshot que contém o dado

### Delta Lake

- Criado pela Databricks (criadores do Spark); open-source via Linux Foundation; versão comercial = Databricks Lakehouse Platform
- **Formato único**: somente Parquet (ao contrário de Hudi e Iceberg que suportam múltiplos formatos)
- **Delta Lake transaction log protocol**: padrão aberto; toda implementação deve seguir o protocolo → interoperabilidade entre implementações (delta-io open-source, Microsoft Fabric, Databricks Delta Lake)
- **Shallow clone**: copia referências dos arquivos fonte sem copiar dados; alterações no clone não afetam tabela original; uso: testar schema changes em produção; captura de estado para retreinar modelos ML
- **Z Ordering**: reorganiza dados em arquivos para otimizar queries que filtram por múltiplas colunas simultaneamente; reescreve todos os Parquet files do subset; quanto mais colunas especificadas, menor o benefício individual por coluna; ideal para 2–3 colunas de filtro frequente
- **Change Data Feed (CDF)**: log de auditoria de todos os inserts/updates/deletes em nível de tabela; habilitado por tabela; uso: (1) auditoria/governança de mudanças; (2) alimentar tabelas downstream incrementalmente sem reprocessar toda a tabela

### Apache Hudi

- Desenvolvido no Uber em 2016; Apache top-level project em 2020; nome = **H**adoop **U**pdates **D**eletes and **I**ncrementals
- **Primary keys**: record key + partition path → garante unicidade dentro de partição; key generators configuráveis: `SimpleKeyGenerator` (1 campo cada), `ComplexKeyGenerator` (múltiplos campos), `NonpartitionedKeyGenerator` (sem partição)
- **File groups e file slices**: dentro de cada partição → file groups → file slices (base data file + delta log files Avro); delta logs = MOR; base file atualizado diretamente = COW
- **Compaction (MOR)**: processo periódico que mescla delta log Avro no Parquet base; necessário para manter performance de leitura em MOR; rodar em horário off-peak
- **Record-level index** (único entre os 3 OTFs): armazena mapeamento record key → file group/file ID; query/update/delete encontra arquivo exato sem scan; altamente configurável; customizável via código

### Apache Iceberg

- Criado pela Netflix; Apache top-level project em 2021; maior momentum de adoção e suporte de vendors no momento do livro
- **Estrutura de metadata** (deep dive):
  - `00000-<UUID>-metadata.json` → primeiro commit; `00001-...` → segundo commit; número sequencial incrementa por commit
  - Glue Data Catalog: `metadata_location` = metadata.json atual; `previous_metadata_location` = versão anterior
  - Manifest list file (`snap-*.avro`): criada por snapshot; lista manifest files relevantes para aquele snapshot
  - Manifest file (Avro): metadata de subset de data files — partition, record count, column lower/upper bounds, null count
  - Data files (Parquet): na prefix `/data/`; metadata files na prefix `/metadata/`
- **Snapshot por commit**: INSERT, UPDATE, DELETE, OPTIMIZE = novo snapshot = novo metadata.json; time travel navega por snapshot IDs/timestamps
- **Maintenance — OPTIMIZE**: compação dos data files; merge de small files em files maiores; merge de delete files nos base files → leituras do snapshot atual não precisam mais fazer merge; `REWRITE DATA USING BIN_PACK`
- **Maintenance — VACUUM**: deleta snapshots antigos e arquivos associados; `vacuum_max_snapshot_age_seconds` (padrão: 5 dias); `vacuum_min_snapshots_to_keep` (padrão: 1); se min_snapshots exige manter mais que age permitiria → age é ignorado; VACUUM é o que efetivamente deleta dados do S3 para GDPR compliance
- **Metadata queries Athena**: `$manifests`, `$files`, `$partitions`, `$history` — queries sobre as tabelas de metadata sem acessar data files

### AWS Service Support para OTFs

- **Glue Crawler**: detecta e registra Delta Lake, Hudi e Iceberg no Glue Catalog automaticamente
- **Glue ETL (Apache Spark)**: suporte nativo a todos os 3 OTFs desde nov/2022; sem connector adicional necessário
- **Lake Formation + OTFs**: suporte varia por serviço; melhor suporte = Athena + Redshift Spectrum (todos os 3, read); EMR 6.9.0 suporta Hudi column-level LF permissions, não suporta Iceberg/Delta; Glue não suporta LF permissions com OTFs
- **Amazon EMR 6.9.0+**: suporte nativo aos 3 OTFs sem instalação adicional; configuração adicional pode ser necessária dependendo do engine (Spark, Presto, Trino, Flink)
- **Redshift Spectrum**: Hudi (COW apenas) + Delta Lake desde set/2020; Iceberg (preview jul/2023); write operations limitadas
- **Amazon Athena**: suporte mais completo; todos os 3 em read; Iceberg: read + write completo (INSERT/UPDATE/DELETE) + OPTIMIZE + VACUUM

## Reference Tables

### COW vs MOR — comparação

| Critério | COW | MOR |
|---------|-----|-----|
| Performance de escrita | Pior (reescreve arquivo) | Melhor (append delta log) |
| Performance de leitura | Melhor (1 arquivo por snapshot) | Pior (merge base + delta) |
| Compaction necessária | Não | Sim (periódica, off-peak) |
| Quando usar | Updates/deletes infrequentes | Workload write-heavy |
| Suporte Hudi | Desde o início | Desde 2018 |
| Suporte Iceberg | Desde v1 | Desde v2 |
| Suporte Delta Lake | Sempre | Deletion Vectors (jul/2023) |

### Comparação de OTFs — features distintas

| Feature | Delta Lake | Apache Hudi | Apache Iceberg |
|---------|-----------|-------------|----------------|
| Origem | Databricks (2016) | Uber (2016) | Netflix |
| Apache project | Não (Linux Foundation) | Sim (2020) | Sim (2021) |
| Formato de arquivo | Parquet only | Parquet + Avro + HFile | Parquet + ORC + Avro |
| Record-level index | Não | **Sim** (único) | Não |
| Shallow clone | **Sim** | Não | Não (via branching em v2) |
| Z Ordering | **Sim** | Não nativo | Não nativo (sorting configs) |
| Change Data Feed | **Sim** | Incremental queries | Não nativo |
| Interoperabilidade | Via protocolo aberto | Ampla | **Maior** (mais vendors) |
| AWS Athena write | Não | Não | **Sim** (full) |
| AWS momentum | Médio | Médio | **Alto** |

### Athena — operações Iceberg

| Operação | Sintaxe Athena |
|---------|----------------|
| Criar tabela | `CREATE TABLE ... TBLPROPERTIES ('table_type'='ICEBERG', 'format'='parquet')` |
| Inserir dados | `INSERT INTO table SELECT * FROM source_table` |
| Deletar registros | `DELETE FROM table WHERE condition` |
| Query metadata — arquivos | `SELECT * FROM "db"."table$files"` |
| Query metadata — manifests | `SELECT * FROM "db"."table$manifests"` |
| Query metadata — partições | `SELECT * FROM "db"."table$partitions"` |
| Query metadata — histórico | `SELECT * FROM "db"."table$history"` |
| Time travel | `SELECT * FROM table FOR TIMESTAMP AS OF TIMESTAMP '2023-07-23 19:00:00 UTC'` |
| Compaction | `OPTIMIZE db.table REWRITE DATA USING BIN_PACK` |
| Config vacuum | `ALTER TABLE db.table SET TBLPROPERTIES ('vacuum_max_snapshot_age_seconds'='60')` |
| Vacuum | `VACUUM db.table` |

## Worked Example

**Hands-on Ch14 — Apache Iceberg com Amazon Athena: create, insert, delete, time travel, optimize, vacuum**

**Tabela criada** (`streaming_films_ib` em formato Iceberg):
```sql
CREATE TABLE curatedzonedb_iceberg.streaming_films_ib (
  timestamp string, eventtype string, film_id_streaming int,
  distributor string, platform string, state string,
  ingest_year string, ingest_month string, category_id bigint,
  category_name string, film_id bigint, title string,
  description string, release_year bigint, language_id bigint,
  original_language_id double, length bigint, rating string,
  special_features string
)
PARTITIONED BY (category_name)
LOCATION 's3://dataeng-curated-zone-gse23/iceberg/streaming_films/'
TBLPROPERTIES ('table_type' = 'ICEBERG', 'format' = 'parquet');
```
→ Cria `metadata/00000-<UUID>-metadata.json` no S3 (snapshot inicial vazio).

**Inserir dados da tabela existente**:
```sql
INSERT INTO curatedzonedb_iceberg.streaming_films_ib
SELECT * FROM curatedzonedb.streaming_films;
```
→ Novo `00001-...-metadata.json` + manifest list file + manifest files + 127 data files Parquet (16 partições = 16 categorias). Dataset: 8.550 registros.

**Deletar categoria Documentary**:
```sql
DELETE FROM curatedzonedb_iceberg.streaming_films_ib
WHERE category_name = 'Documentary';
```
→ Novo snapshot (`00002-...-metadata.json`); partições: 16 → 15; S3: 136 → novas metadata files.

**Time travel — recuperar registros deletados**:
```sql
SELECT * FROM "curatedzonedb_iceberg"."streaming_films_ib"
FOR TIMESTAMP AS OF TIMESTAMP '2023-07-23 19:00:00 UTC'
WHERE category_name = 'Documentary';
```
→ Retorna registros Documentary do snapshot pré-delete (dados ainda no S3).

**Compaction — OPTIMIZE**:
```sql
OPTIMIZE curatedzonedb_iceberg.streaming_films_ib
REWRITE DATA USING BIN_PACK;
```
→ 116 data files → 15 files (1 por categoria); tamanho: 789 KB → 1 MB (metadata adicional + novo snapshot). Queries agora leem 1 arquivo por categoria.

**VACUUM — deletar snapshots antigos**:
```sql
-- Configurar retenção curta (60 segundos para o hands-on)
ALTER TABLE curatedzonedb_iceberg.streaming_films_ib
SET TBLPROPERTIES ('vacuum_max_snapshot_age_seconds'='60');

-- Executar vacuum
VACUUM curatedzonedb_iceberg.streaming_films_ib;
```
→ Snapshots antigos deletados; apenas snapshot mais recente (OPTIMIZE) mantido; S3: 155 objects → 27 objects; 1 MB → 273 KB. Time travel para antes do delete já não funciona.

**Observação crítica**: `OPTIMIZE` e `VACUUM` não podem ter database/table entre aspas no Athena (comportamento inconsistente vs `$files`/`$history`).

## Key Takeaways

1. OTFs resolvem o maior problema do Hive: row-level update sem reescrever partição inteira; metadata file localiza arquivo exato → reescreve só os afetados (COW) ou appenda delta log (MOR)
2. ACID no data lake é real: OTFs garantem que queries durante update recebem estado consistente (pré ou pós), nunca intermediário — elimina race conditions do Hive
3. Time travel tem custo de storage: cada snapshot retém dados anteriores até VACUUM; para GDPR (right to be forgotten), VACUUM explícito é obrigatório após DELETE; snapshots antigos = dado ainda acessível
4. COW para reads, MOR para writes: escolha baseada no padrão predominante de acesso; MOR + compaction off-peak = melhor dos dois mundos para workloads mistos
5. Iceberg tem maior suporte AWS: único OTF com read+write+maintenance completo no Athena; Glue ETL suporta todos os 3 nativamente desde nov/2022; Hudi tem record-level index único
6. OPTIMIZE antes de VACUUM: OPTIMIZE reescreve data files para snapshot atual (pequenos → grandes, delete files → base files); VACUUM deleta snapshots antigos; ordem correta: OPTIMIZE → VACUUM → storage mínimo + performance máxima
7. Athena + Glue Catalog = combinação de menor friction: Athena cria e gerencia Iceberg via SQL; Glue Catalog rastreia `metadata_location`; outros engines (EMR, Redshift Spectrum) leem a mesma tabela de forma transacionalmente consistente

## Connects To

- **Ch07**: Parquet gerado pelo Glue ETL → base dos data files em OTFs; COW reescreve Parquet files; MOR usa Avro para delta logs + Parquet para base files
- **Ch09**: Redshift Spectrum lê Hudi (COW) e Delta Lake desde 2020; Iceberg em preview jul/2023; dados do transactional lake acessíveis sem carga no cluster
- **Ch11**: Athena suporta Iceberg com full read/write/maintenance; `OPTIMIZE` e `VACUUM` via SQL; OTF support mencionado em Ch11 como "detalhes em Ch14"
- **Ch04**: GDPR e data governance — time travel retém dados deletados até VACUUM; right to be forgotten = DELETE + VACUUM explícito; Lake Formation permissions com OTFs têm limitações por serviço
- **Ch15**: Data mesh — cada domínio pode ter seu próprio transactional data lake em OTF; Redshift data sharing + Iceberg = mecanismos de distribuição federada
