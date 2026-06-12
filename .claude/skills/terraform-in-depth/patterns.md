# Padrões e Técnicas — Terraform in Depth

---

## Estrutura de Código

### Pattern: Separação de Arquivos por Responsabilidade
**Quando usar**: todo módulo Terraform
**Como**: `providers.tf` (terraform{} + provider{}), `variables.tf` (inputs), `main.tf` (resources + locals), `outputs.tf`, `lookups.tf` (data sources)
**Referência**: [ch02]

### Pattern: Module como Função Pública
**Quando usar**: ao criar módulo reutilizável
**Como**: inputs → variáveis tipadas com validation; outputs → o que o caller precisa; locals → tudo que é interno. Nunca expor `provider` block no módulo filho.
**Referência**: [ch03]

### Pattern: Naming Hierárquico
**Quando usar**: qualquer projeto com múltiplos ambientes e módulos
**Como**: root define `base_name = "${app}-${env}"`; submodules adicionam sufixo descritivo; recursos herdam o nome do módulo. Nunca incluir o tipo do recurso no nome.
**Referência**: [ch10]

### Pattern: Environment as Root Module
**Quando usar**: múltiplos ambientes (staging, production, regional)
**Como**: cada ambiente é um diretório com thin wrapper que chama o módulo de aplicação com versão exata. Versão exata no root; ranges apenas em módulos reutilizáveis.
**Trade-offs**: overhead de diretório por ambiente; ganho: rollout gradual independente, audit trail completo.
**Referência**: [ch08]

---

## Expressões e Iterações

### Pattern: Toggle de Recurso com Ternário + count
**Quando usar**: feature opcional em módulo
**Como**: `variable "enable_feature" { type = bool; default = false }` → `count = var.enable_feature ? 1 : 0`
**Trade-offs**: `count` cria instâncias indexadas; não gera string de chave para referência. Adequado para features binárias.
**Referência**: [ch04]

### Pattern: Dynamic Block para Subblocks Variáveis
**Quando usar**: número variável de regras em security groups, tags, etc.
**Como**: `dynamic "ingress" { for_each = var.sg_rules; content { ... ingress.value.field ... } }`
Toggle: `for_each = var.enable ? ["placeholder"] : []`
**Referência**: [ch04]

### Pattern: for_each com Identidade Própria
**Quando usar**: recursos com configurações distintas (frota de VMs, múltiplos DNS records)
**Como**: `locals { machines = { "web" = {type="t3.nano"}, "bg" = {type="t3.micro"} } }` → `for_each = local.machines`
**Trade-offs**: mais estável que `count` em reordenações; exige chaves únicas conhecidas no plan.
**Referência**: [ch04]

### Pattern: try() para Recursos Opcionais
**Quando usar**: acessar atributos de recurso com `count = 0 ou 1`
**Como**: `try(resource.name[0].id, null)` — evita erro se o recurso não existe.
**Referência**: [ch04]

### Pattern: Splat para Listar Atributos de Múltiplas Instâncias
**Quando usar**: expor lista de IPs, IDs, ARNs de recursos criados com count/for_each
**Como**: `aws_instance.main[*].private_ip` equivale a `[for x in aws_instance.main : x.private_ip]`
**Referência**: [ch04]

---

## State Management

### Pattern: Backend Parcial
**Quando usar**: credentials de backend não devem ir ao VCS
**Como**: parâmetros comuns no `.tf`; `address`, `path`, `token` em arquivo externo `backend.tfvars` → `terraform init -backend-config=backend.tfvars`
**Referência**: [ch06]

### Pattern: moved block para Renomear sem Destruir
**Quando usar**: refatoração que muda o endereço de um recurso no state
**Como**: `moved { from = old.name; to = new.name }` — idempotente; manter no código; nunca deletar até major version em módulos compartilhados.
**Trade-offs**: seguro em PRs; visível no plan; alternativa ao `terraform state mv` que não deixa rastro.
**Referência**: [ch06, ch09]

### Pattern: terraform_remote_state como Módulo de Abstração
**Quando usar**: um projeto precisa de dados (VPC, subnets) de outro projeto
**Como**: encapsular a lógica de `terraform_remote_state` em módulo próprio; root module consome o módulo, não o data source diretamente. Somente outputs do root module ficam disponíveis.
**Referência**: [ch06]

### Pattern: keepers para Controlar Regeneração
**Quando usar**: `random_*` ou `time_*` que deve regenerar somente quando configuração muda
**Como**: `resource "random_uuid" "x" { keepers = { name = var.name } }` — regenera se e somente se `var.name` mudar.
**Referência**: [ch06]

---

## Qualidade de Código e CI

### Pattern: Makefile como Contrato de Comandos
**Quando usar**: todo projeto Terraform
**Como**: targets `chores`, `security`, `test_validation`, `test_lint`; variável `TF_ENGINE` para trocar entre Terraform/OpenTofu; targets não-PHONY para caching de `init`.
**Referência**: [ch07]

### Pattern: Matrix Strategy para Múltiplos Engines/Versões
**Quando usar**: módulos que devem ser compatíveis com Terraform e OpenTofu
**Como**: `matrix: { engine: [opentofu, terraform], version: [1.6, 1.7, 1.8] }` + `TF_ENGINE=${{ matrix.engine }}`. Versões alpha com `experimental: true` + `continue-on-error`.
**Referência**: [ch07]

### Pattern: Exceções de Segurança com Justificativa
**Quando usar**: regra de segurança não se aplica ao caso específico
**Como**: `#checkov:skip=CKV_AWS_88:This instance is meant to be publicly accessible.` (justificativa obrigatória após `:`)
**Referência**: [ch07]

---

## Entrega Contínua

### Pattern: OIDC para Autenticação em CI/CD
**Quando usar**: qualquer pipeline de CD em cloud provider
**Como**: registrar GitHub Actions como OIDC provider no AWS/Azure/GCP; criar role com condições restritas ao repositório; `permissions: id-token: write` no workflow.
**Trade-offs**: mais configuração inicial; elimina rotação de credenciais, service users e vazamentos.
**Referência**: [ch08]

### Pattern: GitOps Flow com Speculative Plan
**Quando usar**: times com CD platform (TACOS, Atlantis)
**Como**: PR → CI (validate, lint, security) + CD platform gera speculative plan → review → merge → apply automático. Drift detection notifica mas não auto-corrige sem revisão.
**Referência**: [ch08]

---

## Testes

### Pattern: defer Destroy para Cleanup Garantido
**Quando usar**: todo teste com `terraform.InitAndApply` em Terratest
**Como**: `defer terraform.Destroy(t, terraformOptions)` — executa mesmo se o teste falhar.
**Referência**: [ch09]

### Pattern: random_string em Nomes de Teste
**Quando usar**: testes que rodam em paralelo ou em múltiplos PRs
**Como**: `resource "random_string" "random" { length=8; special=false; upper=false }` → `name = "testing_${random_string.random.result}"`
**Referência**: [ch09]

### Pattern: Parallel Change para Renomear Variável
**Quando usar**: renomear variável de módulo sem breaking change
**Como**: (1) adicionar nova variável com default; (2) tornar antiga nullable; (3) `locals { use_this = var.old != null ? var.old : var.new }`; (4) deprecar antiga em UPGRADE.md; (5) remover na próxima major version.
**Referência**: [ch09]

### Pattern: mock_provider + command = plan
**Quando usar**: testar lógica de geração de nomes/expressões sem criar infraestrutura
**Como**: `mock_provider "aws" {}` + `override_data { target = data.aws_region.current; values = { name = "us-east-1" } }` + `command = plan`
**Referência**: [ch09]

### Pattern: aws-nuke Agendado
**Quando usar**: conta isolada de testes com risco de recursos órfãos
**Como**: GitHub Actions com `schedule: cron: "0 0 * * *"` + OIDC auth + `aws-nuke --config nuke-config.yml`. **Nunca em conta de produção.**
**Referência**: [ch09]

---

## Tópicos Avançados

### Pattern: cidrsubnet para Redes Dinâmicas
**Quando usar**: módulo de rede que deve suportar 1–N AZs sem hardcode de CIDRs
**Como**: `subnet_bits = az_count == 1 ? 0 : (az_count > 2 ? 2 : 1)` → `cidrsubnet(var.cidr_block, local.subnet_bits, count.index)` com `count` (não `for_each`, pois AZ names são desconhecidos no plan).
**Referência**: [ch10]

### Pattern: precondition / postcondition / check
**Quando usar**:
- `precondition` → impedir misconfiguration antes de criar (ex: tipo inválido de LB)
- `postcondition` → validar resultado após criação (ex: AMI não deprecada)
- `check` → monitorar saúde em produção sem bloquear (ex: healthcheck HTTP)
**Referência**: [ch10]

### Pattern: terraform_data como Proxy de Provisioner
**Quando usar**: provisioner precisa de dependência em múltiplos recursos
**Como**: `resource "terraform_data" "prov" { connection {...}; provisioner "remote-exec" {...}; depends_on = [aws_instance.main, aws_db_instance.main] }`
**Referência**: [ch10]

---

## Interfaces Alternativas

### Pattern: CLI Wrapper com Event Handlers
**Quando usar**: ferramenta/plataforma que precisa controlar Terraform programaticamente
**Como**: classe com `_run` (batch, JSON único) e `_run_stream` (generator, JSONL); `TF_IN_AUTOMATION=1`; `extra_args` como escape hatch; dataclasses com `field(init=False)` + `__post_init__` para parsing.
**Referência**: [ch11]

---

## Providers Customizados

### Pattern: Configure com Coleta Completa de Erros
**Quando usar**: implementar `Configure` em qualquer provider
**Como**:
1. `IsUnknown()` → `AddAttributeError` (valor derivado não disponível)
2. `os.Getenv()` → valor base do env var
3. `!IsNull()` → override com config block
4. `== ""` → `AddAttributeError` (valor ausente)
5. `HasError()` → `return` (só após processar TODOS os campos)
Nunca retornar no primeiro erro; nunca usar `log.Fatal`.
**Referência**: [ch12]

### Pattern: State Normalization em Create + Read
**Quando usar**: servidor modifica campos após criação (ex: HTML wrapping)
**Como**: aplicar a mesma transformação (ex: `bluemonday.Sanitize`) tanto em `Create` quanto em `Read`. Sem isso, cada `plan` detectará drift.
**Referência**: [ch12]
