# Chapter 4: Data Governance, Security, and Cataloging

## Core Idea
Pipeline eficiente sem governança é risco corporativo: dados mal protegidos geram multas bilionárias e perda de confiança; dados mal catalogados viram data swamp. Governança cobre segurança, qualidade, lineage e catalogação — é responsabilidade do data engineer, não só da equipe de segurança.

## Frameworks Introduced

- **Data Governance Pillars (5 áreas)**
  - **Segurança**: proteger contra acesso não autorizado (criptografia, IAM, KMS)
  - **Privacidade**: cumprir GDPR/CCPA/HIPAA — PII tokenizado na entrada, não no fim
  - **Qualidade**: dados corretos, completos, consistentes e atualizados
  - **Lineage**: rastrear origem e transformações de cada dataset
  - **Catalogação**: descobribilidade via catálogo técnico (Glue) + catálogo de negócio (DataZone)

- **Data Swamp Prevention Model**
  - Dado sem catálogo = swamp: existe mas ninguém sabe o que é, de onde veio, ou se pode confiar
  - Dois requisitos: (1) catálogo central com search e (2) políticas que só permitem datasets de qualidade com metadata obrigatório
  - Quando aplicar: antes de adicionar qualquer dataset ao lago — catálogo primeiro, ingestão depois

- **IAM + Lake Formation (Two-Layer Permission Model)**
  - IAM: controle amplo (acesso ao serviço Athena, Glue, S3 em nível de conta)
  - Lake Formation: controle fino (banco, tabela, coluna específica) sem precisar de permissões diretas no S3
  - Regra de ouro: IAM policy geral → Lake Formation para granularidade; usuário não precisa de S3 direto quando Lake Formation está ativo

## Key Concepts

- **PII (Personally Identifiable Information)**: qualquer dado que identifica um indivíduo direta ou indiretamente (nome, CPF, IP, foto); sujeito a regulamentações como GDPR
- **Encryption in transit**: TLS protege dados em movimento entre sistemas; toda comunicação entre serviços AWS deve usar HTTPS/TLS
- **Encryption at rest**: dados escritos em disco devem estar criptografados; AWS KMS gerencia as chaves
- **Anonymization**: remoção irreversível de PII — não pode ser revertida; risco: combinação de campos ainda pode reidentificar (87% da população US com ZIP + gênero + data de nascimento)
- **Pseudonymization/Tokenization**: substituição de PII por token aleatório com mapeamento seguro separado; GDPR-compliant; reversível para usuários autorizados
- **Hashing para PII**: NÃO usar — rainbow tables revertem SHA-256 de nomes e SSNs em segundos; salting ajuda mas ainda insuficiente para dados com domínio limitado
- **Federated Identity**: autenticação delegada para Active Directory ou Okta; quando usuário sai da empresa, acesso AWS é revogado automaticamente
- **Least Privilege**: usuário autorizado apenas para o mínimo necessário ao seu trabalho
- **Data Quality Dimensions**: Accuracy (reflete a realidade?), Completeness (campos preenchidos?), Consistency (formatos e valores coerentes?), Timeliness (atualizado?)
- **Data Profiling**: análise descritiva de dataset — valores nulos, distintos, únicos, min/max — sem julgamento de qualidade; permite ao consumidor avaliar adequação antes de solicitar acesso
- **Data Lineage**: visualização das fontes e transformações que geraram um dataset; constrói confiança do consumidor
- **DQDL (Data Quality Definition Language)**: linguagem usada pelo AWS Glue Data Quality para definir regras; baseada no framework open-source Deequ
- **IAMAllowedPrincipals**: permissão especial do Lake Formation que desativa o controle LF e delega para IAM (pass-through); deve ser removida para ativar Lake Formation
- **Amazon DataZone**: serviço AWS lançado em 2022 que combina catálogo de negócio + integração com Glue; aprofundado no Ch15
- **AWS Macie**: ML + pattern matching para detectar PII em objetos S3 automaticamente
- **KMS key deletion**: mínimo 7 dias de espera; se chave for deletada, dados criptografados com ela são irrecuperáveis — proteger com SCP em AWS Organizations

## Reference Tables

### Regulamentações de privacidade relevantes

| Regulação | Jurisdição | Escopo |
|-----------|-----------|--------|
| GDPR | União Europeia | Qualquer org que processa dados de residentes EU |
| CCPA/CPRA | Califórnia, EUA | Empresas com dados de residentes californianos |
| HIPAA | EUA | Dados de saúde individuais |
| PCI DSS | Global | Dados de cartão de crédito |
| POPIA | África do Sul | Informação pessoal |
| PDP Bill | Índia | Dados pessoais digitais |

### Técnicas de de-identificação de PII

| Técnica | Reversível | Segurança | Quando usar |
|---------|-----------|-----------|-------------|
| Tokenização | Sim (sistema separado) | Alta | Produção: PII deve ser acessível para usuários autorizados |
| Anonimização | Não | Alta (se bem feita) | Dados que nunca precisarão revelar PII original |
| Hashing (SHA-256) | Não (mas rainbow tables!) | Baixa para dados limitados | Evitar para nomes/SSN/datas de nascimento |
| Redaction | Não | Alta | Logs, relatórios onde campo nunca é necessário |

### AWS Glue Data Quality — exemplos de regras DQDL

| Regra | Exemplo | Descrição |
|-------|---------|-----------|
| `ColumnExists` | `ColumnExists "email"` | Verifica se coluna existe |
| `ColumnLength` | `ColumnLength "zip_code" = 5` | Comprimento exato |
| `Completeness` | `Completeness "email" > 0.95` | % de valores não-nulos |
| `RowCount` | `RowCount between 10000 and 15000` | Número de linhas no range |

### IAM vs Lake Formation

| Aspecto | IAM policies | Lake Formation |
|---------|-------------|----------------|
| Granularidade | Bucket/prefix S3 | Database/tabela/coluna |
| Permissão S3 direta | Necessária | Não — LF fornece credenciais temporárias |
| Interface | JSON policies | Console ou API (grant/revoke) |
| Column-level security | Não | Sim |
| Compatibilidade | Todos serviços | Athena, QuickSight, EMR, Redshift Spectrum, Glue, SageMaker Studio |

## Worked Example

**Transição IAM → Lake Formation com column-level exclusion:**

**Cenário**: `datalake-user` deve ter acesso SELECT na tabela `csvtoparquet` do `cleanzonedb`, mas sem ver a coluna `favorite_num`.

**Passo 1 — IAM policy** (acesso amplo ao serviço, limitado ao DB):
```json
{
  "Effect": "Allow",
  "Action": ["glue:GetDatabase", "glue:GetTable", "glue:GetPartitions", ...],
  "Resource": [
    "arn:aws:glue:*:*:catalog",
    "arn:aws:glue:*:*:database/cleanzonedb",
    "arn:aws:glue:*:*:table/cleanzonedb/*"
  ]
}
```

**Passo 2 — Remover IAMAllowedPrincipals** do database e da tabela no console Lake Formation → ativa controle LF.

**Passo 3 — Grant Lake Formation** para `datalake-user`:
- Table permissions: `SELECT`
- Data permissions: Column-based access → **Exclude columns** → `favorite_num`

**Resultado**: query `SELECT * FROM cleanzonedb.csvtoparquet` retorna todos os campos exceto `favorite_num`. Column-level security impossível somente com IAM.

**Fluxo de tokenização** (boas práticas):
```
Ingestão (landing zone)
    ↓
Tokenization service (sistema isolado)
    → substitui PII por token aleatório
    → salva mapeamento token↔original em DB separado e protegido
    ↓
Clean zone (dados tokenizados)
    ↓
Curated zone (analytics sem PII)

Para re-identificar: consumidor autorizado envia dataset tokenizado
ao tokenization service → retorna com PII original
```

## Key Takeaways

1. PII deve ser tokenizado na primeira etapa após ingestão — nunca processar dados sensíveis sem tokenização prévia
2. Encryption in transit (TLS) + at rest (KMS) são obrigatórios; não são opcionais em nenhum ambiente produtivo
3. Hashing NÃO é de-identificação adequada para dados com domínio limitado (SSN, nomes) — rainbow tables revertem em segundos
4. Lake Formation adiciona column-level security impossível com IAM puro; IAMAllowedPrincipals deve ser removida para ativar
5. Catálogo técnico (Glue) ≠ catálogo de negócio (DataZone/Collibra) — ambos necessários; Glue mapeia arquivos→tabelas, DataZone mapeia dados→contexto de negócio
6. Data profiling descreve o shape dos dados; data quality evalua contra regras — profiling primeiro para avaliar adequação, quality rules para validação contínua em pipelines
7. Federated identity + least privilege + auditoria (CloudTrail) formam a tríade de segurança no AWS

## Connects To

- **Ch03**: Glue Data Catalog (técnico) introduzido como hub central — este capítulo aprofunda segurança e permissões sobre o catálogo
- **Ch06**: Ingestão — momento certo para aplicar tokenização de PII antes de prosseguir para clean zone
- **Ch11**: Athena usa Glue Catalog com Lake Formation permissions para queries no data lake
- **Ch15**: Amazon DataZone como catálogo de negócio no contexto de Data Mesh
- **Ch16**: DataOps e observabilidade incluem data quality como métrica de pipeline
