# Cheatsheet — Terraform in Depth

---

## Blocos HCL — Referência Rápida

| Bloco | Propósito | Labels | Referência |
|-------|-----------|--------|------------|
| `terraform {}` | versão, backend, providers | 0 | — |
| `provider "aws" {}` | credenciais, região | 1 (tipo) | — |
| `resource "aws_instance" "web" {}` | cria infraestrutura | 2 (tipo + nome) | `aws_instance.web` |
| `data "aws_vpc" "default" {}` | lookup read-only | 2 (tipo + nome) | `data.aws_vpc.default` |
| `variable "name" {}` | input externo | 1 (nome) | `var.name` |
| `locals {}` | variáveis internas | 0 | `local.name` |
| `module "vpn" {}` | reuso de código | 1 (nome) | `module.vpn` |
| `output "url" {}` | expõe dados | 1 (nome) | — |
| `moved {}` | renomeia no state | 0 | — |
| `removed {}` | remove do state | 0 | — |
| `check "name" {}` | saúde pós-apply | 1 (nome) | — |
| `import {}` | importa existente | 0 | — |

---

## count vs for_each — Quando Usar Cada Um

| Critério | count | for_each |
|----------|-------|----------|
| Input | número | map, object, set |
| Identidade | indexada (`[0]`, `[1]`) | por chave (`["web"]`) |
| Reordenação | pode recriar | estável |
| Recursos idênticos | ✓ melhor | funciona |
| Recursos com configuração distinta | funciona | ✓ melhor |
| Valor deve ser conhecido no plan | sim | sim |
| Toggle de feature | `count = var.enable ? 1 : 0` | `for_each = var.enable ? {"x"=true} : {}` |

**Regra prática**: "quantos" → `count`; "quem" → `for_each`.

---

## Precedência de Input Variables (maior → menor)

1. `-var` e `-var-file` na CLI (último vence)
2. `*.auto.tfvars` e `*.auto.tfvars.json` (ordem lexicográfica)
3. `terraform.tfvars.json`
4. `terraform.tfvars`
5. Variáveis de ambiente `TF_VAR_<nome>`
6. Input interativo (ou erro se `-input=false`)

---

## lifecycle — Quando Usar Cada Meta-Argumento

| Meta-argumento | Usar quando | Evitar quando |
|----------------|-------------|---------------|
| `create_before_destroy = true` | recurso sem downtime (LB, SG) | recurso proíbe duplicatas (IAM role, Elastic IP) |
| `prevent_destroy = true` | último recurso contra deleção acidental | default — não protege se o bloco for deletado |
| `ignore_changes = [attr]` | atributo gerenciado externamente (tags, AMI) | como workaround para drift que deveria ser corrigido |
| `ignore_changes = all` | recurso read-only após criação | produção sem razão clara |
| `replace_triggered_by = [res]` | forçar replace quando dep. muda | nunca referenciar variables |

---

## Seleção de Backend

| Backend | Usar quando | Não usar quando |
|---------|-------------|-----------------|
| `local` | dev individual, módulos sem state real | equipes, produção |
| `s3` | stack AWS; S3+DynamoDB para locking | sem DynamoDB = risco de corrupção |
| `gcs` | stack GCP | — |
| `azurerm` | stack Azure | — |
| `consul` | self-hosted com HA | sem replicação |
| `cloud` (TACOS) | quer plan/apply remoto + registry + state | precisa de OpenTofu (HCP não suporta) |

**3 pilares**: Resiliência + Segurança + Disponibilidade (mín. 99,99%)

---

## Diagnóstico de State Drift

| Tipo | Sintoma | Solução |
|------|---------|---------|
| Acidental manual | plan mostra mudança que não deveria existir | `terraform apply` corrige; prevenir com CI/CD |
| Intencional manual | on-call fez mudança emergencial | corrigir no código PRIMEIRO; não rodar `apply` antes |
| Conflito automatizado | auto-scaling, minor RDS upgrades | `lifecycle.ignore_changes`; ou `apply -refresh-only` |
| Erro do Terraform | crash antes de salvar state | `terraform import` para recurso órfão |

---

## Hierarquia de Gerenciamento de Segredos (melhor → pior)

1. **OIDC** — sem credenciais estáticas; toda major cloud suporta; configurar condições no role
2. **Secret managers** (Vault, AWS Secrets Manager, Azure Key Vault) — atenção: valor vai ao state file
3. **Orchestrator settings** (variáveis no CD platform) — problema de escala em muitos projetos
4. **Arquivo externo via `-var-file`** — nunca commitar; nunca em `-var` (fica no shell history)
5. **Jamais**: credenciais hardcoded no HCL ou no `.tf`/`.tfvars` no VCS

---

## Seleção de Framework de Testes

| Critério | Terratest (Go) | Terraform Testing Framework (.tftest.hcl) |
|----------|---------------|------------------------------------------|
| Versão | v1.6+ | v1.6+ |
| Linguagem | Go | HCL nativo |
| Mocks | não nativos | sim (v1.7+, beta) |
| Atributos internos | via outputs | direto |
| Multi-versão | sim (TERRATEST_BINARY) | não (acoplado ao TF) |
| Melhor para | projetos complexos, time com Go | projetos novos, lógica simples |

**Regra**: use os dois — `.tftest.hcl` para lógica com mocks, Terratest para integração real.

---

## Seleção de CD Platform

| Necessidade | Plataforma |
|-------------|-----------|
| Multi-framework (Helm, Ansible, Pulumi) + polished | Spacelift ou Env0 |
| Similar ao HCP + CLI-driven + OpenTofu | Scalr |
| GitOps via PR comments + GitHub | Digger ou Terrateam |
| Open source self-hosted completo (state + registry) | Terrakube |
| Open source GitOps tight com SCM | Atlantis |
| Só Terraform (não OpenTofu) + enterprise | HCP Terraform |

---

## Versioning de Módulos — Regras

| Onde | Constraint | Razão |
|------|-----------|-------|
| Root module | versão exata `"1.1.1"` | deploy controlado; upgrade = PR = audit trail |
| Módulo filho (reutilizável) | `"~> Major.Minor"` | permite patch/minor; bloqueia breaking |
| Git direto | `?ref=v1.0.1` (pin) | sem suporte a ranges; só versão exata |

---

## Validação — Onde Declarar

| Tipo | Onde | Bloqueia? | self? | Múltiplos? |
|------|------|-----------|-------|------------|
| `validation` em `variable` | fora do resource | plan | não | sim |
| `precondition` | lifecycle do resource | antes de criar | não | sim |
| `postcondition` | lifecycle do resource | após criar | sim | sim |
| `check` block | top-level | não bloqueia | não | sim (asserts) |
| `.tftest.hcl` | testes | só em dev | — | sim (runs) |

---

## Comandos Essenciais — Referência Rápida

```bash
# Fluxo básico
terraform init                          # baixa providers e módulos
terraform plan -out=plan.tfplan         # salva plano (recomendado)
terraform apply plan.tfplan             # aplica exatamente o plano salvo
terraform destroy                       # alias para apply -destroy

# Debug e inspeção
terraform graph | dot -Tpng > g.png     # visualiza o DAG
terraform show -json plan.tfplan        # plano legível por máquina
TF_LOG=debug terraform plan -parallelism=1  # debug detalhado

# State
terraform state list                    # lista recursos no state
terraform state pull > backup.tfstate   # backup antes de operações
terraform apply -refresh-only           # aceitar drift sem mudar infra

# Substituição forçada
terraform plan -replace='aws_instance.web[0]'  # preview de cascata

# Variáveis
terraform plan -var 'key=value' -var-file=prod.tfvars -input=false

# Workspaces
terraform workspace new staging
terraform workspace select production

# Makefile (projeto com template)
make chores          # format + documentation
make security        # checkov + trivy
make test_validation # init (cached) + validate
make test_lint       # tflint --init + tflint
make terratest       # go test -timeout 60m
```

---

## Plugin Framework — Interfaces Go

| Interface | Funções obrigatórias |
|-----------|---------------------|
| `provider.Provider` | Metadata, Schema, Configure, Resources, DataSources, Functions |
| `datasource.DataSource` | Metadata, Schema, Configure, Read |
| `resource.Resource` | Metadata, Schema, Configure, Create, Read, Update, Delete |
| `function.Function` | Metadata, Definition, Run |

**Schema por papel**:

| Papel | Required | Optional | Computed | Sensitive |
|-------|----------|----------|----------|-----------|
| Param obrigatório | `true` | — | — | — |
| Param opcional | — | `true` | — | — |
| Saída do servidor | — | — | `true` | — |
| Credencial | — | `true` | — | `true` |
| Campo com default | — | `true` | `true` | — |

---

## Funções Impuras — Evitar em Resource Arguments

| Função | Problema | Alternativa |
|--------|----------|-------------|
| `uuid()` | novo valor a cada plan = drift perpétuo | `random_uuid` com `keepers` |
| `timestamp()` | novo valor a cada plan | `time_static` com `triggers` |
| `bcrypt()` | salt randômico a cada call | `random_password` → armazenar hash |

---

## .tofu vs .tf — Compatibilidade Dual-Engine

```
arquivo.tf      → lido por Terraform; ignorado pelo OpenTofu se existir arquivo.tofu de mesmo nome
arquivo.tofu    → lido pelo OpenTofu; ignorado pelo Terraform
```

Use para: locals com `my_engine = "terraform"` vs `"tofu"` — permite código diferente por engine no mesmo diretório.
