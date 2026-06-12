# Capítulo 6: Gerenciamento de Estado

## Ideia Central
Estado é o mecanismo que permite ao Terraform mapear código para infraestrutura real. Sem ele, o Terraform não saberia quais recursos gerencia. Com ele, vêm responsabilidades: armazenamento resiliente, seguro e disponível — e uma taxonomia de problemas (state drift) que todo operador precisa saber diagnosticar.

---

## Frameworks Introduzidos

### Por Que Estado Existe — 4 Benefícios

| Benefício | Descrição |
|-----------|-----------|
| **Real-world linkage** | Mapeia recurso ao seu ID real (ARN, etc.) sem depender de tags — que nem todo provider suporta e são frágeis |
| **Reduced complexity** | Elimina a necessidade de lookup automático por provider; simplifica o engine e o desenvolvimento de providers |
| **Performance** | Plan rápido via lookup de state em vez de full API refresh |
| **State-only resources** | Permite providers como `tls`, `random`, `null`, `cloudinit` que só existem em state |

---

### Os 3 Pilares para Escolha de Backend

| Pilar | O que avaliar |
|-------|---------------|
| **Resiliência** | Durabilidade histórica, backups testados periodicamente |
| **Segurança** | MFA, encryption at rest, acesso mínimo necessário, logging |
| **Disponibilidade** | SLA em "nines" — mínimo recomendado: 99,99% (4 nines = < 4,5 min/mês de downtime) |

---

### Estrutura do State JSON

```json
{
  "version": 4,               // versão do schema do state
  "terraform_version": "1.5.4",
  "serial": 6,               // incrementa a cada mudança
  "lineage": "<uuid>",        // UUID único do projeto — nunca muda
  "outputs": { ... },         // apenas outputs do módulo raiz
  "resources": [ ... ],       // todos os resources e data sources
  "check_results": [ ... ]    // resultados de check blocks
}
```

Cada entrada em `resources`:
```json
{
  "module": "module.my_password",
  "mode": "managed",          // ou "data"
  "type": "random_password",
  "name": "new_password",
  "provider": "provider[\"registry.terraform.io/hashicorp/random\"]",
  "instances": [{
    "schema_version": 3,
    "attributes": { ... },    // todos os atributos, incluindo sensíveis
    "sensitive_attributes": []
  }]
}
```

**Insight crítico:** `sensitive` em outputs não encripta o valor — apenas informa ao Terraform para não exibir. O valor plaintext fica no JSON do state.

---

### Tabela de Backends

| Backend | Sistema | Workspaces | Notas |
|---------|---------|------------|-------|
| `local` | Filesystem | Sim | **Nunca em produção** |
| `s3` | AWS S3 | Sim | Requer DynamoDB para locking |
| `gcs` | Google Cloud Storage | Sim | Boa opção para equipes GCP |
| `azurerm` | Azure Storage | Sim | Boa opção para equipes Azure |
| `consul` | HashiCorp Consul | Sim | Boa para self-hosting com HA |
| `pg` | PostgreSQL | Sim | State em banco SQL |
| `kubernetes` | K8s Secrets | Sim | Evitar antes de v1.6 (limite de tamanho) |
| `http` | Custom HTTP API | Não | Para backends custom via REST |
| `remote` | Terraform Enterprise | Sim | Substituído pelo `cloud` block |
| `cloud` | TACOS | Não | Mais que backend — executa plan/apply remotamente |

**TACOS** (Terraform Automation and Collaboration Software): HCP Terraform, Scalr, Env0, Spacelift.

---

### Padrão de Configuração Parcial de Backend

```hcl
# main.tf — só o que é igual em todos os ambientes
terraform {
  backend "consul" {
    scheme = "https"   # hardcoded: válido para todos
    # address, path, access_token: passados via -backend-config
  }
}
```

```bash
# backend.tfvars — fora do VCS (contém credenciais)
address      = "consul.internal:8500"
path         = "terraform/state/my-project"
access_token = "01a56e2d-a96a-4ca5-9d39-d5152015f533"
```

```bash
# Inicializar com configuração parcial
terraform init -backend-config=backend.tfvars

# Ou inline (menos seguro — fica no shell history)
terraform init \
  -backend-config="address=consul.internal:8500" \
  -backend-config="path=terraform/state/my-project"
```

**Regra:** parâmetros passados via `-backend-config` são salvos em `.terraform/` — não coloque credenciais em flags de CLI se esse diretório for commitado ou logado.

---

### Cloud Block (TACOS)

```hcl
# Com tags — habilita terraform workspace
terraform {
  cloud {
    organization = "acme-org"
    hostname     = "app.terraform.io"   # obrigatório no OpenTofu
    workspaces {
      tags = ["acme_application", "development"]
    }
  }
}

# Com nome fixo — desabilita terraform workspace
terraform {
  cloud {
    organization = "acme-org"
    hostname     = "acme.scalr.io"
    workspaces {
      name = "acme_development_workspace"
    }
  }
}
```

```bash
terraform login acme.scalr.io   # salva token em disco; sem credenciais hardcoded
```

**Armadilha:** `cloud` block usa `workspaces` com semântica diferente do `terraform workspace` padrão. Cloud workspaces são ambientes completamente independentes; workspaces locais compartilham código e módulos.

---

### moved e removed Blocks (Code-Driven State Changes)

```hcl
# Renomear resource sem destruir
moved {
  from = random_password.my_password
  to   = random_password.main
}

# Mover resource para dentro de módulo
moved {
  from = random_password.my_password
  to   = module.password.random_password.main
}

# Remover resource do state sem destruir infraestrutura
removed {
  from = aws_s3_bucket.bucket
  lifecycle {
    destroy = false   # false = apenas remove do state; true = destrói
  }
}
```

O `moved` block só age se o `from` existir no state — é idempotente. Crítico em módulos compartilhados para evitar que upgrades destruam recursos dos usuários.

---

### Taxonomia de State Drift

| Tipo | Causa | Solução |
|------|-------|---------|
| **Acidental manual** | Engenheiro executou comando no ambiente errado | Terraform plan corrige; prevenir com CI/CD e acesso restrito |
| **Intencional manual** | On-call fez mudança emergencial fora do Terraform | Refletir mudança no código imediatamente; não rodar Terraform até resolver |
| **Conflito automatizado** | Auto-scaling, tags externas, minor version upgrades (RDS) | `lifecycle.ignore_changes` para atributos irrelevantes; `refresh-only` para aceitar |
| **Erro do Terraform** | Crash antes de salvar state, backend inacessível, expiração de credencial | Revisar logs, importar recursos órfãos ou deletar manualmente |

---

### terraform_remote_state

```hcl
# Boa prática: remote state no top-level module, passado como variável para child modules
data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = var.rds_state_path
    region = var.state_region
  }
  defaults = {
    rds_uri = null   # dependência soft — não falha se state não existir
  }
}

module "service" {
  source  = "./modules/service"
  rds_uri = data.terraform_remote_state.rds.outputs.rds_uri
}
```

**Regra:** apenas outputs do módulo raiz ficam disponíveis via `terraform_remote_state`. Outputs de módulos filho não são exportados ao state.

---

### State-Only Providers

| Provider | Recursos principais | `keepers`/`triggers` |
|----------|--------------------|-----------------------|
| `random` | `random_password`, `random_integer`, `random_uuid`, `random_pet` | `keepers` |
| `time` | `time_static`, `time_rotating`, `time_offset`, `time_sleep` | `triggers` |
| `null` | `null_resource` | `triggers` (legado) |
| `terraform_data` | built-in (v1.4+) | `triggers_replace` |
| `tls` | chaves, certs, CAs | — |

**Padrão de keepers:**
```hcl
resource "random_uuid" "example" {
  keepers = { "name" = var.name }   # regenera se var.name mudar
}
```

---

## Comandos de Referência

```bash
# Backup e restore de state
terraform state pull > backup.tfstate
terraform state push backup.tfstate
terraform state push -force backup.tfstate   # ignorar serial/lineage check

# Listar e remover recursos do state
terraform state list
terraform state rm <resource_address>
terraform state replace-provider <old_provider> <new_provider>

# Migrar backend
terraform init -migrate-state    # migrar state para novo backend
terraform init -reconfigure      # ignorar state existente, começar do zero

# Workspaces
terraform workspace list
terraform workspace new <nome>
terraform workspace select <nome>
terraform workspace delete <nome>

# Autenticação para cloud block
terraform login <hostname>
```

---

## Exemplo Trabalhado — Módulo de Rede Compartilhado via Remote State

```hcl
# modules/network-state/variables.tf
variable "network_name" {
  type        = string
  description = "Nome da rede para buscar no state."
}

# modules/network-state/main.tf
data "terraform_remote_state" "network" {
  backend = "consul"
  config = {
    address = "consul.internal"
    scheme  = "https"
    path    = "terraform/state/networks/${var.network_name}"
  }
}

# modules/network-state/outputs.tf
output "vpc_id"            { value = data.terraform_remote_state.network.outputs.vpc_id }
output "private_subnet_ids"{ value = data.terraform_remote_state.network.outputs.private_subnet_ids }
output "public_subnet_ids" { value = data.terraform_remote_state.network.outputs.public_subnet_ids }
```

```hcl
# top-level module — consome o módulo de rede
module "network_data" {
  source       = "github.com/acme/terraform-network//modules/network-state"
  network_name = "production"
}

module "service" {
  source     = "./modules/service"
  vpc_id     = module.network_data.vpc_id
  subnet_ids = module.network_data.private_subnet_ids
}
```

**O que demonstra:**
- Encapsula a configuração de Consul no módulo — o caller só precisa do `network_name`
- `terraform_remote_state` fica no módulo de abstração, não espalhado por módulos de negócio
- Outputs do módulo raiz de rede ficam disponíveis sem que a equipe de serviço acesse o state completo

---

## Anti-patterns

- **Backend `local` em produção:** falha em todos os 3 pilares (resiliência, segurança, disponibilidade).
- **S3 sem DynamoDB locking:** state corrompido com applies concorrentes.
- **Credenciais hardcoded no `backend` block:** vazamento ao commitar; preferir env vars ou config files externos.
- **Edição manual do state:** last resort; qualquer erro de JSON é fatal; usar `moved`/`removed` blocks ou CLI primeiro.
- **`terraform_remote_state` em módulos filho:** cria dependência de backend no módulo, reduz reusabilidade; colocar apenas no top-level module.
- **Rodar Terraform com drift intencional pendente:** `terraform apply` vai reverter as mudanças do on-call. Resolver o drift no código primeiro.
- **Confundir workspaces locais com workspaces do cloud block:** semântica completamente diferente.
- **Kubernetes backend antes de v1.6:** limites de tamanho de K8s secrets causam falhas com states maiores.
- **`random_password` + state sem proteção:** o resultado (plaintext) fica no JSON do state — proteger backend com encryption e acesso mínimo.

---

## Erros Comuns e Soluções

### Lineage mismatch
```
Error: state lineage "abc..." does not match expected "xyz..."
```
Causa: tentando usar state de projeto diferente. Solução: confirmar que o `path`/`bucket`/`key` do backend aponta para o projeto correto.

### Serial mais baixo ao fazer push
```
Error: cannot push state with serial N if remote state has serial M (M > N)
```
Solução: `terraform state push -force` — mas backup antes.

### State drift não resolve com apply
Causa: drift intencional ou conflito automatizado. Solução: investigar origem; se legítimo usar `lifecycle.ignore_changes` ou `terraform apply -refresh-only` para aceitar.

### Resource órfão após crash do Terraform
Sintoma: próximo `plan` quer criar resource que já existe.
Solução: `terraform import` (ou `import` block, ch08) para reintegrar ao state.

---

## Modelos Mentais

- **State = ledger da infraestrutura:** registra o que foi criado, com que atributos, por qual provider. Sem o ledger, o Terraform não tem memória.
- **Lineage = identidade do projeto; serial = versão do snapshot:** lineage nunca muda, serial incrementa a cada apply.
- **Backend = onde o ledger fica guardado:** escolha pelo que a equipe já usa; configure antes de qualquer plan de produção.
- **moved block = rename sem destroy:** sempre preferir ao `state mv` CLI — fica no código, é revisável e reprodutível.
- **State drift ≠ problema do Terraform:** drift é sintoma de processo. A pergunta certa é "por que aconteceu?" não "como reverter?".
- **terraform_remote_state = leitura apenas:** nunca modifica o state remoto — é como um `data source` para outputs de outro projeto.

---

## Key Takeaways

1. **State existe por razões legítimas:** linkage confiável, performance, e recursos state-only são benefícios reais — não apenas overhead.
2. **Resiliência + segurança + disponibilidade:** os 3 pilares para avaliar qualquer backend; local falha em todos.
3. **Nunca commitar credenciais de backend:** usar configuração parcial + `-backend-config` com arquivo externo ao VCS.
4. **moved/removed blocks > CLI state commands:** versionáveis, revisáveis, e automáticos para todos os ambientes.
5. **State drift tem 4 categorias distintas:** cada uma com causa e solução diferente — diagnosticar antes de agir.
6. **terraform_remote_state: apenas outputs do root module:** planejar os outputs que outros projetos precisarão.
7. **random/time providers resolvem funções impuras:** `keepers`/`triggers` controlam quando regerar — nunca `uuid()` ou `timestamp()` direto em resource arguments.
8. **terraform_data substitui null_resource a partir de v1.4:** mesmas capabilities; `triggers_replace` no lugar de `triggers`; permite `replace_triggered_by` com locals via proxy.
9. **`state push -force` requer backup prévio:** sempre `state pull > backup.tfstate` antes de qualquer operação destrutiva no state.

---

## Conecta Com

- **Ch02**: `lifecycle.ignore_changes` — solução para drift de conflitos automatizados (seção 6.6.3).
- **Ch05**: backends e locking no contexto do plan — `terraform refresh` deprecated e `-lock=false` para speculative plans.
- **Ch07**: CI/CD e como pipelines acessam state — autenticação de backend em ambientes automatizados.
- **Ch08**: `import` block (substituto moderno de `terraform import` CLI); provisioners com `terraform_data`.
- **Ch09**: `check` blocks cujos resultados ficam salvos no state (`check_results`).
- **Ch10**: estratégias de tagging para facilitar data source lookups (alternativa a `terraform_remote_state`).
