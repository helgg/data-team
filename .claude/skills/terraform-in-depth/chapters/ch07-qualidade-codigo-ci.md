# Capítulo 7: Qualidade de Código e Integração Contínua

## Ideia Central
Terraform é desenvolvimento de software. A indústria de software acumulou décadas de práticas — linters, formatadores, scanners de segurança, CI — que se aplicam diretamente ao IaC. Este capítulo monta o pipeline completo: templates de projeto → makefile → ferramentas de qualidade → pre-commit hooks → GitHub Actions com matrix strategy.

---

## Frameworks Introduzidos

### CI como Prática (não apenas sistema)
CI (Continuous Integration) = times conseguem integrar mudanças ao mainline **regularmente** (idealmente múltiplas vezes ao dia). Isso só é possível quando as ferramentas de qualidade são fáceis o suficiente para rodar localmente antes de abrir PR.

**Sequência de construção do capítulo:**
```
Template (Cookiecutter) → Makefile → Ferramentas locais → Pre-commit → GitHub Actions
```

---

### Cookiecutter — Templates de Projeto

```bash
# Gerar novo projeto a partir do template do livro
cookiecutter gh:TerraformInDepth/terraform-module-cookiecutter

# Perguntas interativas:
[1/6] name (): terraform-aws-test-module
[2/6] Select license (1-5): 1
[3/6] author (): Robert Hafner
[4/6] primary_provider (hashicorp/aws):
[5/6] provider_min_version (5.0):
[6/6] private_registry_url ():   # deixar vazio se não há registry privado
```

**Arquivos gerados:**
```
.checkov.yml
.github/
.gitignore
.opentofu-version
.pre-commit-config.yml
.terraform-docs.yml
.terraform-version
.tflint.hcl
LICENSE
README.md
main.tf
makefile
outputs.tf
providers.tf
variables.tf
```

**Quando usar templates dinâmicos (vs. repo estático):** quando há campos variáveis por projeto (nome, provider, licença) ou quando configs de ferramentas mudam conforme o provider (ex: plugins do TFLint para AWS vs GCP).

---

### Makefile — Padronização de Comandos

```makefile
# Variável de engine — permite trocar sem alterar código
TF_ENGINE:=terraform

ifeq ($(TF_ENGINE), terraform)
    TF_BINARY:=terraform
else ifeq ($(TF_ENGINE), opentofu)
    TF_BINARY:=tofu
endif

# Agrupamento hierárquico de targets
.PHONY: chores
chores: documentation format        # make chores executa ambos

.PHONY: security
security: test_checkov test_trivy   # make security executa ambos

# Truque do target não-PHONY: terraform init só roda se .terraform/ não existe
.terraform:
    $(TF_BINARY) init -backend=false

.PHONY: test_validation
test_validation: .terraform         # depende do target acima
    $(TF_BINARY) validate
```

**Trocar engine na linha de comando:**
```bash
make format TF_ENGINE=opentofu
make test_validation TF_ENGINE=opentofu
```

**Instalação de dependências (detecção automática de package manager):**
```makefile
BREW_PACKAGES := cosign tenv terraform-docs tflint checkov trivy
CHOCOLATEY_PACKAGES := cosign tenv terraform-docs tflint trivy

INSTALLER_PATH := $(shell { command -v brew || command -v choco; } 2>/dev/null)
INSTALLER := $(shell { basename $(INSTALLER_PATH) ; } 2>/dev/null)

.PHONY: install
install: install_$(INSTALLER)       # dynamically resolves to install_brew or install_choco

.PHONY: install_brew
install_brew:
    brew tap tofuutils/tap
    brew install $(BREW_PACKAGES)

.PHONY: install_choco
install_choco:
    choco install $(CHOCOLATEY_PACKAGES)

.PHONY: install_
install_:                           # fallback se nenhum package manager encontrado
    echo "No package manager found."
```

---

### tenv — Gerenciamento de Versões

Substitui `tfenv` e `tofuenv`; suporta Terraform, OpenTofu e Terragrunt em um único tool.

```bash
# Arquivo de versão por projeto
echo "1.7.2" > .terraform-version    # versão exata
echo "latest" > .opentofu-version    # versão mais recente

# Override temporário para testar versão específica
tenv tf use 1.8.0
tenv tofu use latest-allowed         # máximo permitido pela constraint do módulo
tenv tf use min-required             # mínimo requerido pela constraint do módulo
```

**Opções de versão aceitas:**
- Exata: `1.7.2`
- Constraint: `~>1.5`
- Keywords: `latest`, `latest-stable`, `latest-pre` (pre-release)
- Relativos: `latest-allowed`, `min-required`

**Como funciona:** `tenv` intercepta chamadas a `terraform` e `tofu` e roteia para o binário correto transparentemente.

---

### Pre-commit Hooks

**Opção 1 — Mapear targets do makefile:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: format
        name: Test format
        entry: make test_format
        language: system
        pass_filenames: false
      - id: validation
        name: Test validation
        entry: make test_validation
        language: system
        pass_filenames: false
      - id: lint
        name: Test lint
        entry: make test_lint
        language: system
        pass_filenames: false
      - id: security
        name: Test security
        entry: make test_security
        language: system
        pass_filenames: false
```

**Opção 2 — Plugin pre-commit-terraform (Anton Babenko):**
```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_checkov
```

```bash
pre-commit install    # instala hooks no repositório git
pre-commit run        # roda todos os hooks sem fazer commit
```

---

### terraform validate

```bash
# Inicializa sem backend (deixa backend existente intacto)
terraform init -backend=false

# Valida sintaxe, nomes de atributos/funções — sem precisar de variáveis ou backend
terraform validate
# → "Success! The configuration is valid."
# ou → erro idêntico ao que apareceria no plan
```

**Truque de performance no makefile:** usar `.terraform` como target não-PHONY. Make pula o `init` se o diretório `.terraform/` já existe.

---

### TFLint — Linter Estático

```hcl
# .tflint.hcl — configuração base
plugin "terraform" {
  enabled = true
  preset  = "recommended"   # ou "all" para mais regras
}

# Adicionar regra específica fora do preset
rule "terraform_comment_syntax" {
  enabled = true   # exige # em vez de // para comentários
}

# Desabilitar regra específica
rule "terraform_comment_syntax" {
  enabled = false
}

# Plugins de cloud (AWS 700+ regras, Azure 100+, GCP 200+)
plugin "aws" {
    enabled = true
    version = "0.30.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Plugin OPA para políticas customizadas (só se equipe já usa OPA)
plugin "opa" {
  enabled = true
  version = "0.6.0"
  source  = "github.com/terraform-linters/tflint-ruleset-opa"
}
```

**Ignorar inline:**
```hcl
resource "aws_instance" "this" {
  ami = "ami-867166b8518f055af"
  # tflint-ignore: aws_instance_invalid_type    ← ignora só a próxima linha
  instance_type = "p8.48xlarge"
}
```

**Makefile targets:**
```makefile
.PHONY: test_tflint
test_tflint:
    tflint --init   # rápido mesmo se já rodou
    tflint

.PHONY: tflint_fix
tflint_fix:
    tflint --init
    tflint --fix    # autofix — revisar antes de usar
```

**Regra:** rodar `tflint` sem `--fix` primeiro, revisar resultados, adicionar exceções inline onde necessário, depois rodar `--fix` no que sobrar. `tflint_fix` **não** entra no target `chores`.

---

### Segurança — Checkov e Trivy

**Checkov** (open source, sem servidor central):
```bash
checkov --directory .
```

**Exceção inline:**
```hcl
resource "aws_instance" "this" {
  #checkov:skip=CKV_AWS_88:This instance is meant to be publicly accessible.
  associate_public_ip_address = true
}
```

**Políticas customizadas (YAML — preferível a OPA para a maioria dos casos):**
```yaml
---
metadata:
  name: "Disable the P and G families of AWS Instances."
  id: "CKV2_CUSTOM_AWS_1"          # usar nome da empresa no ID
  category: "COST_SAVINGS"
definition:
  and:
    - cond_type: "attribute"
      resource_types: ["aws_instance"]
      attribute: "instance_type"
      operator: "not_regex_match"
      value: '^p\d\..*$'           # bloqueia P-family (GPU, caro)
    - cond_type: "attribute"
      resource_types: ["aws_instance"]
      attribute: "instance_type"
      operator: "not_regex_match"
      value: '^g\d\..*$'           # bloqueia G-family (GPU, caro)
```

**Makefile com políticas remotas (repositório compartilhado):**
```makefile
CHECKOV_OPTIONS:=--external-checks-git https://github.com/YOUR_ORG/custom_policies.git

.PHONY: test_checkov
test_checkov:
    checkov --directory . $(CHECKOV_OPTIONS)
```

**Trivy** (ex-TFSec):
```bash
trivy config .
```

**Exceção por arquivo (`trivyignore`):**
```
# Allow public IP addresses to be used in this module.
AVD-AWS-0009
```

**Exceção inline:**
```hcl
resource "aws_instance" "this" {
  #checkov:skip=CKV_AWS_88:This instance is meant to be publicly accessible.
  # Trivy: Ignore Public IP address rule.
  #trivy:ignore:AVD-AWS-0009
  associate_public_ip_address = true
}
```

**Regra:** usar Checkov **e** Trivy — gratuitos, cobertura complementar. Exceções **sempre** com justificativa documentada.

---

### Automação de Chores

**terraform-docs:**
```yaml
# .terraform-docs.yml
formatter: "markdown table"
output:
  file: "README.md"
  mode: inject          # preserva conteúdo fora dos marcadores
sort:
  enabled: true
  by: required          # variáveis obrigatórias primeiro
```

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->    ← terraform-docs injeta aqui
```

```makefile
.PHONY: documentation
documentation:
    terraform-docs -c .terraform-docs.yml .

.PHONY: test_documentation
test_documentation:
    terraform-docs -c .terraform-docs.yml --output-check .  # falha se docs desatualizados
```

**terraform fmt:**
```makefile
.PHONY: format
format:
    $(TF_BINARY) fmt -recursive .

.PHONY: test_format
test_format:
    $(TF_BINARY) fmt -check -recursive .    # apenas verifica, não modifica
```

---

## GitHub Actions — CI com Matrix Strategy

**Workflow base:**
```yaml
name: Lint
on:
  push:
  pull_request:

jobs:
  tflint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source code
        uses: actions/checkout@v4
      - name: Setup TFLint
        uses: terraform-linters/setup-tflint@v4
      - name: Run TFLint
        run: make test_tflint       # mesmos targets que roda localmente
```

**Matrix strategy — testar Terraform + OpenTofu × múltiplas versões:**
```yaml
name: Validation
on:
  push:
    branches: [main]
  pull_request:

jobs:
  validation:
    strategy:
      fail-fast: false              # continua outros jobs se um falhar
      matrix:
        engine: ["opentofu", "terraform"]
        version: ["1.6", "1.7", "1.8"]
        experimental: [false]
        include:
          - engine: "terraform"
            version: "1.10"
            experimental: true      # alpha — falhas não bloqueiam merge

    continue-on-error: ${{ matrix.experimental }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Terraform
        uses: hashicorp/setup-terraform@v3
        if: ${{ matrix.engine == 'terraform' }}
        with:
          terraform_version: ${{ matrix.version }}

      - name: Install OpenTofu
        uses: opentofu/setup-opentofu@v1
        if: ${{ matrix.engine == 'opentofu' }}
        with:
          tofu_version: ${{ matrix.version }}

      - name: Test Validation
        run: make test_validation TF_ENGINE=${{ matrix.engine }}
```

---

### Dependabot — Atualizações Automáticas

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "terraform"    # monitora módulos e providers
    directory: "/"
    schedule:
      interval: "weekly"

registries:                           # para registries privados
  terraform-private:
    type: terraform-registry
    url: https://my.private.registry.com
    token: ${{ secrets.TERRAFORM_REGISTRY_API_TOKEN }}
    # ATENÇÃO: registry precisa ser acessível pelo GitHub (não funciona atrás de firewall)
```

---

## Exemplo Trabalhado — Stack Completa de Quality Gates

```
Desenvolvedor escreve código
         ↓
[git commit] → pre-commit hooks rodam:
  • make test_format       (terraform fmt -check)
  • make test_validation   (terraform validate)
  • make test_documentation (terraform-docs --output-check)
  • make test_lint         (tflint)
  • make test_security     (checkov + trivy)
         ↓
[git push] → GitHub Actions dispara:
  • Lint workflow:       setup-tflint → make test_tflint
  • Validation workflow: matrix [terraform, opentofu] × [1.6, 1.7, 1.8]
  • Security workflow:   make security (checkov + trivy)
         ↓
[PR aberto] → Branch protection bloqueia merge se:
  • Qualquer pipeline falhar
  • Não houver aprovação de reviewer
         ↓
[Merge aprovado] → Dependabot monitora:
  • GitHub Actions actions (semana)
  • Providers e módulos Terraform (semana)
  → Cria PRs automáticos para updates → testes rodam novamente
```

**O que demonstra:**
- Pre-commit = feedback imediato ao desenvolvedor antes de qualquer push
- Makefile = mesmos comandos locais e CI (sem divergência de ambiente)
- Matrix strategy = cobertura automática de Terraform + OpenTofu sem duplicar código
- `experimental: true` + `continue-on-error` = testar versões alpha sem bloquear equipe

---

## Comandos de Referência

```bash
# Cookiecutter
cookiecutter gh:TerraformInDepth/terraform-module-cookiecutter

# tenv
tenv tf use 1.8.0
tenv tofu use latest-allowed
tenv tf use min-required

# Make targets
make install              # instala todas as ferramentas (detecta brew/choco)
make chores               # format + documentation
make test_format          # terraform fmt -check -recursive
make test_validation      # terraform init -backend=false + validate
make test_documentation   # terraform-docs --output-check
make test_tflint          # tflint --init + tflint
make tflint_fix           # tflint --init + tflint --fix
make test_checkov         # checkov --directory .
make test_trivy           # trivy config .
make security             # test_checkov + test_trivy
make precommit_install    # pre-commit install

# Override de engine
make test_validation TF_ENGINE=opentofu

# Pre-commit
pre-commit install    # instala hooks no repo
pre-commit run        # roda hooks manualmente sem commit

# terraform validate
terraform init -backend=false && terraform validate

# terraform fmt
terraform fmt -recursive .
terraform fmt -check -recursive .   # só verifica

# terraform-docs
terraform-docs -c .terraform-docs.yml .
terraform-docs -c .terraform-docs.yml --output-check .

# TFLint
tflint --init
tflint
tflint --fix

# Checkov
checkov --directory .
checkov --directory . --external-checks-git https://github.com/ORG/policies.git

# Trivy
trivy config .
```

---

## Anti-patterns

- **Ferramentas não padronizadas entre projetos:** cada dev lembrando comandos diferentes. Solução: makefile + Cookiecutter.
- **CI sem testes locais correspondentes:** divergência entre ambiente local e CI deixa erros escaparem até o PR. Solução: mesmos `make` targets nos dois lugares.
- **`tflint --fix` sem revisão prévia:** pode aplicar mudanças indesejadas (ex: deprecações de provider ainda em uso). Rodar `tflint` primeiro, revisar, então `--fix`.
- **Exceções de segurança sem justificativa:** `#checkov:skip=CKV_AWS_88` sem texto após o `:` torna impossível auditar por que a exceção existe.
- **Desabilitar regra global vs. inline:** `.trivyignore` desabilita para o projeto todo; inline é mais granular. Preferir inline.
- **Branch protection desativado:** sem proteção qualquer dev pode fazer merge com testes falhando.
- **Dependabot sem secret store para registries:** tokens de registry nunca em `dependabot.yml` no git — usar `${{ secrets.NAME }}`.
- **Não testar `min-required`:** declarar `required_version = "~> 1.5"` sem testar na 1.5 cria compatibilidade fictícia.

---

## Erros Comuns e Soluções

### TFLint: `required_version` ausente
```
Warning: terraform "required_version" attribute is required (terraform_required_version)
```
Solução: adicionar `required_version = "~> 1.7"` no bloco `terraform {}`.

### TFLint: provider declarado mas não usado
```
Warning: provider 'aws' is declared in required_providers but not used by the module
```
Normal em módulos novos sem recursos ainda. Desaparecer automaticamente quando recursos do provider forem adicionados.

### Make: "missing separator" error
```
Makefile:5: *** missing separator.  Stop.
```
Causa: indentação com espaços em vez de tabs. Solução: converter para tab (`sed -i 's/^    /\t/' makefile`).

### terraform-docs: documentação divergente no CI
```
Error: There is a diff in the output
```
Causa: documentação desatualizada. Solução: rodar `make documentation` localmente antes de commit (ou o pre-commit hook pega automaticamente).

### GitHub Actions: versão alpha quebrando pipeline
Solução: `experimental: true` + `continue-on-error: ${{ matrix.experimental }}` — testa sem bloquear.

---

## Modelos Mentais

- **Makefile = contrato de comandos:** qualquer dev, qualquer máquina, mesmo comando, mesmo resultado.
- **Pre-commit = feedback imediato:** erros detectados antes do push custam menos (nenhum ciclo de PR).
- **CI = automated reviewer:** libera reviewers humanos para o que não pode ser automatizado (lógica, segurança de contexto, conformidade com arquitetura).
- **Matrix strategy = multiplicador de cobertura:** N engines × M versões = N×M testes com um único arquivo de workflow.
- **`experimental: true` = test without block:** testar versões alpha mantém visibilidade sobre compatibilidade futura sem parar o time.
- **Templates = memória institucional:** o esforço inicial de configurar Cookiecutter se amortiza em cada novo módulo criado.

---

## Key Takeaways

1. **CI é prática, não sistema:** o GitHub Actions ou Jenkins só funciona depois que os testes locais existem e são fáceis de rodar.
2. **Makefile resolve o problema de memória:** ninguém precisa memorizar 15 comandos; `make chores` e `make security` cobrem o essencial.
3. **tenv centraliza versões:** `.terraform-version` e `.opentofu-version` por projeto eliminam conflitos de versão entre membros do time.
4. **Pre-commit = last line of defense local:** pega problemas antes do push, reduz ciclos de PR.
5. **TFLint preset "all" > "recommended":** regras de descrição de variáveis/outputs valem o custo de configurar exceções.
6. **Checkov + Trivy = cobertura complementar:** gratuitos, coberturas diferentes, sem motivo para usar apenas um.
7. **Checkov YAML policies > OPA para a maioria:** muito mais simples; OPA só vale se equipe já usa Rego.
8. **Matrix strategy resolve Terraform vs. OpenTofu:** `TF_ENGINE` no makefile + `if: ${{ matrix.engine == '...' }}` no workflow = cobertura total sem duplicação.
9. **Dependabot fecha o loop:** mantém providers, módulos e GitHub Actions atualizados automaticamente.
10. **Tudo isso pertence ao Cookiecutter template:** o overhead de configuração só acontece uma vez.

---

## Conecta Com

- **Ch06**: backends e autenticação — como o CI acessa o state backend em ambientes automatizados (credenciais via env vars, não hardcoded).
- **Ch08**: continuous delivery — o que acontece depois do merge; `import` blocks; uso de `terraform plan -out` em pipelines de CD.
- **Ch09**: testing framework (Terraform v1.6+) e Terratest — os stubs `terratest` e `terraform_test` do makefile serão preenchidos aqui.
- **Ch11**: Terragrunt — `tenv` também gerencia versões do Terragrunt; estratégias de versionamento de módulos.
