# Glossário — Terraform in Depth

**Acceptance tests (`TestAcc*`)** — testes que chamam API real; ativados por `TF_ACC=1`; executam via `make testacc`. (Ch12)

**ApplyLog** — dataclass Python que herda PlanLog; resultado do `apply` com streaming JSONL. (Ch11)

**Application as root module** — anti-pattern: todos os ambientes compartilham o mesmo código; impossibilita rollout gradual. (Ch08)

**Atributo computado** — campo marcado `(known after apply)` no plan; só existe após criação do recurso. (Ch02)

**Backend** — onde o state file é armazenado; local (nunca em produção), S3, GCS, azurerm, consul, pg, http. (Ch01, Ch06)

**Backend parcial** — configurar no `.tf` apenas parâmetros comuns; credenciais e path via `-backend-config` fora do VCS. (Ch06)

**Backend: 3 pilares** — Resiliência + Segurança + Disponibilidade (mínimo 99,99% = 4 nines). (Ch06)

**BSL (Business Source License)** — licença HashiCorp v1.6+; proíbe concorrentes de usar Terraform em produtos. (Ch01, Ch08)

**can(expr)** — retorna bool sem lançar erro; usar exclusivamente em `validation` blocks. (Ch04)

**CD (Continuous Delivery/Deployment)** — entrega de infraestrutura para ambientes; distinto de CI. (Ch08)

**CDKTF** — framework HashiCorp: TypeScript/Python/Go → JSON → Terraform; não suporta OpenTofu. (Ch11)

**check block** — validação v1.5+ que não bloqueia execução; suporta scoped data sources e múltiplos asserts. (Ch10)

**Checkov** — scanner de segurança open source; políticas YAML ou OPA; complementar ao Trivy. (Ch07)

**cidrsubnet(cidr, bits, index)** — divide rede em 2^bits subnets, retorna subnet de índice `index`. (Ch10)

**CI (Continuous Integration)** — prática de integrar mudanças ao mainline regularmente; requer ferramentas fáceis de rodar localmente. (Ch07)

**Cloud-Init** — ferramenta para configuração de VMs na inicialização; alternativa principal a provisioners. (Ch10)

**CommandResults** — dataclass Python com command/stdout/stderr/returncode + métodos `.json()`, `.jsonl()`, `.raise_error()`. (Ch11)

**Computed** — atributo calculado pelo provider, não fornecido pelo usuário; desconhecido no plan. (Ch12)

**Cookiecutter** — ferramenta de templates de projeto; elimina setup repetitivo de qualidade de código. (Ch07)

**count** — meta-argumento numérico para criar múltiplos recursos; acesso via `count.index`. (Ch04)

**CRUD** — Create, Read, Update, Delete — as quatro operações obrigatórias de um resource Terraform. (Ch12)

**DAG (Directed Acyclic Graph)** — grafo de ações ordenadas sem ciclos; base do plano Terraform; determina paralelismo e ordem. (Ch01, Ch05)

**data source** — lookup read-only de dados externos; referenciado como `data.<type>.<name>`. (Ch02)

**Dependabot** — ferramenta GitHub que cria PRs automáticos para atualizar providers, módulos e actions. (Ch07)

**depends_on** — dependência explícita quando não há ligação via atributos; último recurso. (Ch02, Ch05)

**dev_overrides** — bloco em `~/.terraformrc` que aponta Terraform para provider binário local durante desenvolvimento. (Ch12)

**Diagnostics** — `resp.Diagnostics` acumula múltiplos erros sem interromper; `.AddAttributeError`, `.AddError`, `.HasError`. (Ch12)

**dynamic block** — único mecanismo para gerar número variável de subblocks; usa `for_each` interno. (Ch04)

**Environment as root module** — cada ambiente é um diretório independente com thin wrapper + versão exata do módulo. (Ch08)

**Eternal drift** — mudança sempre detectada no plan após apply; geralmente type mismatch entre API e state. (Ch05)

**event handlers** — dict `{tipo: callable}` passado a `apply()`/`plan()` do wrapper; `"all"` captura todos os eventos. (Ch11)

**Expressão** — qualquer valor à direita de `=` em HCL; pode ser literal, referência, operação ou função. (Ch04)

**External provider** — `data "external"`: chama programa local, lê stdin JSON, espera stdout JSON; usar como last resort. (Ch10)

**for expression** — transforma coleção em nova coleção; não modifica coleção existente. `[for x in list : expr]`. (Ch04)

**for_each** — meta-argumento para criar recursos com identidade própria; input: map, object ou set. (Ch04)

**FunctionData** — não existe; functions nunca têm acesso a clientes externos. (Ch12)

**generator (Python)** — função com `yield`; produz um valor por vez; usado para streaming de eventos Terraform. (Ch11)

**GitOps** — 4 princípios CNCF: declarativo + versionado + pulled automaticamente + continuamente reconciliado. (Ch08)

**HCL (HashiCorp Configuration Language)** — linguagem declarativa do Terraform; legível; .tf e .tf.json. (Ch01)

**IaC (Infrastructure as Code)** — infraestrutura gerenciada com práticas de software: versionamento, testes, revisão de PR. (Ch01)

**ImportState** — função opcional de resource para importar recursos existentes ao state Terraform. (Ch12)

**import block** — importa infraestrutura existente para o state sem recriar; remover após uso. (Ch02, Ch09)

**JSON output format** — resposta única para `show`, `validate`, `output`; oposto do JSONL streaming. (Ch11)

**JSONL (JSON Lines)** — formato de streaming; uma linha = um objeto JSON; usado por `plan` e `apply -json`. (Ch11)

**keepers / triggers** — map que controla quando `random`/`time`/`null` regenera valores; novo valor = recreate. (Ch06)

**Labels** — identificadores do bloco; 0, 1 ou 2 dependendo do tipo. (Ch02)

**lifecycle** — subblock de meta-argumentos: `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by`. (Ch02)

**lineage** — UUID único do projeto Terraform; nunca muda; identifica o state. (Ch06)

**locals** — variáveis internas ao módulo; transformações de dados; imutáveis como todos os valores Terraform. (Ch03)

**local-exec provisioner** — roda comando na máquina que executa Terraform; usar com `when=destroy` para deregistros. (Ch10)

**Machine-readable UI** — streaming JSONL linha a linha para `plan` e `apply`; permite processar eventos em tempo real. (Ch11)

**Makefile** — padronização de comandos; mesmos targets locais e CI; variável `TF_ENGINE` para trocar entre Terraform/OpenTofu. (Ch07)

**mock_provider** — substitui provider real por valores fake em testes; números=0, bool=false, map={}, list=[]. (Ch09)

**moved block** — renomeia recurso no state sem destroy/recreate; seguro manter no código; nunca deletar até major version. (Ch02, Ch06, Ch09)

**Module registry** — repositório de módulos; público em registry.terraform.io; privado em TACOS, Artifactory. (Ch03)

**Módulo** — coleção de resources empacotada como componente reutilizável; input variables + output variables + locals. (Ch03)

**NAT gateway** — permite private subnet acessar internet sem ser diretamente acessível. (Ch10)

**nonsensitive(value)** — cria valor sem flag de sensibilidade; documentar justificativa obrigatória. (Ch04)

**nullable** — controla se input pode receber `null`; default `true`. (Ch03)

**OIDC** — autenticação machine-to-machine sem credenciais estáticas; preferir sobre service accounts em CD. (Ch08)

**OpenTofu** — fork open source do Terraform; mantido pela Linux Foundation; licença MPL; superset do Terraform. (Ch01)

**output variable** — expõe dados de módulo para o caller; só outputs do root module ficam no state. (Ch03)

**override_data / override_resource** — sobrescreve valores específicos no scope de um `run` block de teste. (Ch09)

**Parallel change** — renomear variável sem breaking change: variável antiga nullable + local com coalesce. (Ch09)

**Plan file (.tfplan)** — formato binário; usar `terraform show <file>` para ler; `-json` para parsear. (Ch05)

**Plugin Framework** — SDK atual para criar providers Terraform em Go; abstrai gRPC Protocol v6. (Ch12)

**postcondition** — valida resultado após criação de recurso; bloqueia execução se falhar; acesso a `self`. (Ch10)

**pre-commit hooks** — ferramentas que rodam antes de git commit; mapear targets do makefile. (Ch07)

**precondition** — bloqueia execução antes de criar recurso; sem acesso a `self`. (Ch10)

**Provider** — plugin que expõe recursos de um vendor; distribuído independentemente do core; >3.280 no registry. (Ch01)

**Provider alias** — múltiplas configurações do mesmo provider; ex: duas regiões AWS. (Ch02)

**Provider Scaffolding Template** — template oficial HashiCorp para bootstrap de providers; limpar arquivos HashiCorp-internos. (Ch12)

**random provider** — state-only; `random_password`, `random_integer`, `random_uuid`, `random_pet`; use `keepers`. (Ch06)

**regexall(pattern, str)** — retorna lista de todos os matches; lista vazia se não encontrar (sem erro). (Ch04)

**remote-exec provisioner** — roda comandos na máquina remota via SSH/WinRM; last resort. (Ch10)

**removed block** — remove recurso do state sem destruir infraestrutura; `destroy = false`. (Ch02, Ch06)

**required_providers** — declarar explicitamente com versão; nunca deixar Terraform inferir. (Ch02)

**Resource** — bloco mais importante do Terraform; cria/atualiza infraestrutura; referenciado sem prefixo. (Ch02)

**resource targeting (-target)** — limita plan/apply a recursos específicos; anti-pattern em produção. (Ch05)

**Root module** — módulo onde `terraform init` é executado; configura providers; único que pode ter `backend`. (Ch03)

**run block** — cada bloco = um teste no .tftest.hcl; default `command = apply`. (Ch09)

**Schema** — estrutura de dados que define atributos de providers, resources e data sources em Go. (Ch12)

**semver** — vMajor.Minor.Patch; Patch=bugfix, Minor=compatível, Major=breaking. Requisito do Module Registry. (Ch08)

**sensitive** — mascara valor em logs; não protege no state file (plaintext). (Ch03)

**serial** — contador do state; incrementa a cada mudança; usado para detecção de conflitos. (Ch06)

**Speculative plan** — plan sem `-out`; útil para review em PRs; não garante reprodutibilidade. (Ch05)

**splat [*]** — atalho para `for`; `resource.name[*].attr` = lista de atributos de todas as instâncias. (Ch04)

**State** — mapeamento entre código HCL e infraestrutura real; JSON com resources, outputs, lineage, serial. (Ch06)

**State drift** — 4 tipos: acidental manual, intencional manual, conflito automatizado, erro do Terraform. (Ch06)

**State normalization** — transformações em Create devem ser repetidas em Read para evitar drift perpétuo. (Ch12)

**State-only providers** — random, time, null, terraform_data, tls — só existem no state, sem API externa. (Ch06)

**TACOS** — Terraform Automation and Collaboration Software: HCP Terraform, Spacelift, Scalr, Env0. (Ch01, Ch06, Ch08)

**Technical debt** — funcionalidade ou qualidade adiada; ~20% do tempo em codebase maduro. (Ch09)

**templatefile(path, vars)** — arquivo com interpolação + lógica HCL; usar para templates; nunca para JSON/YAML. (Ch04)

**tenv** — gerenciador de versões para Terraform, OpenTofu e Terragrunt; substitui tfenv + tofuenv. (Ch07)

**Terragrunt** — thin wrapper sobre Terraform; gera root modules a partir de `terragrunt.hcl`; não suporta version constraints. (Ch08)

**Terratest** — framework Go (Gruntwork) para testes de integração de IaC; `defer Destroy`, `InitAndApply`. (Ch09)

**terraform console** — REPL interativo para testar funções e expressões sem criar recursos. (Ch04)

**terraform-docs** — gera documentação markdown de módulos a partir dos campos description/variables/outputs. (Ch07)

**terraform_data** — provider built-in (v1.4+); substitui null_resource; `triggers_replace`. (Ch06)

**terraform_remote_state** — lê outputs de outro project's state; read-only; apenas no root module. (Ch06)

**TFLint** — linter estático com presets e plugins de cloud; 700+ regras AWS; suporta autofix. (Ch07)

**tflog** — pacote de logging do Plugin Framework; mapeia a `TF_LOG`; `MaskFieldValuesWithFieldKeys` para secrets. (Ch12)

**tfplugindocs** — gera docs markdown a partir de `MarkdownDescription` nos schemas; ativado via `go generate`. (Ch12)

**tfsdk tag** — tag Go struct que mapeia campo Go ao nome de atributo no schema Terraform. (Ch12)

**tftest.hcl** — arquivo de teste nativo Terraform; `.tftest.hcl` no mesmo diretório do módulo. (Ch09)

**Trivy** — scanner de segurança (ex-TFSec); complementar ao Checkov; exceções via `.trivyignore`. (Ch07)

**try(expr, default)** — retorna primeiro argumento sem erro; usar com recursos opcionais. (Ch04)

**Unit tests (Test*)** — testes sem dependência externa; principalmente para functions do Plugin Framework. (Ch12)

**UseStateForUnknown** — plan modifier que evita "Attribute known after apply" para campos estáveis. (Ch12)

**validation subblock** — valida inputs com condition + error_message; múltiplos por variável; v1.9+ pode referenciar outras vars. (Ch03)

**version constraint** — `~> Major.Minor` em módulos filhos; versão exata no root module; semver 2.0. (Ch08)

**Workspace** — deployment independente de uma codebase com backend e variáveis próprias. (Ch01, Ch06)

**Workspace (cloud block)** — semântica completamente diferente dos workspaces locais; ambiente independente com state próprio. (Ch06)
