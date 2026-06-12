# Capítulo 8: Entrega Contínua e Deploy

## Ideia Central

CI garante que o código funcione; CD garante que ele chegue aos usuários. São práticas distintas que se complementam: CI é a fundação de segurança que torna CD possível. Deploy de infraestrutura é fundamentalmente diferente de entrega de módulos — é como reformar um avião em voo.

---

## Frameworks Introduzidos

### Separação CI vs CD

| Aspecto | CI | CD |
|---------|----|----|
| **Foco** | Código-fonte, qualidade, validação | Deploy para ambientes, entrega de valor |
| **Trigger** | Todo commit/push | Merge no main, schedule, drift |
| **Ferramenta** | GitHub Actions, GitLab CI | TACOS, Atlantis, Terragrunt |
| **Output** | Branch sempre funcional | Infraestrutura deployada e reconciliada |

### 4 Princípios GitOps (CNCF)

| Princípio | Definição |
|-----------|-----------|
| **Declarativo** | Estado desejado expresso declarativamente |
| **Versionado e imutável** | Estado armazenado com imutabilidade e histórico completo |
| **Pulled automaticamente** | Agentes puxam o estado desejado da fonte |
| **Continuamente reconciliado** | Agentes observam o estado real e aplicam o desejado |

> **Nota CNCF:** "Continuous" = reconciliação continua acontecendo, não necessariamente instantânea.

Terraform é, por design, quase uma implementação de GitOps: é declarativo, imutável por natureza, e reconcilia estado. Falta apenas o "continuously pulled" — que os CD platforms adicionam.

---

## Semantic Versioning de Módulos

### Regras semver 2.0 (`vMajor.Minor.Patch`)

| Tipo de mudança | Campo | Exemplo |
|-----------------|-------|---------|
| Bug fix | Patch | `v1.0.1` → `v1.0.2` |
| Novo recurso (backward compatible) | Minor | `v1.0.2` → `v1.1.0` |
| Breaking change | Major | `v1.1.1` → `v2.0.0` |

**Requisito do registro:** módulos DEVEM usar tags Git no formato `vX.Y.Z` — está embutido no Terraform Module Registry Protocol.

### Operadores de Constraint

```hcl
version = "1.1.1"                    # exato
version = ">= 1.1.0, < 2.0.0"       # range explícito
version = ">= 1.1.0, < 2.0.0, != 1.3.2"  # excluindo versão específica
version = "~> 1.1.0"                 # pessimistic: só patch (>= 1.1.0, < 1.2.0)
version = "~> 1.1"                   # pessimistic: minor + patch (>= 1.1.0, < 2.0.0)
```

**Regra para autores de módulos:** usar `~> Major.Minor` — permite upgrades de patch/minor, bloqueia breaking changes. Suportar a maior faixa possível para evitar conflitos com outros módulos.

**Limitação de Git direto:** fontes `git@github.com:...` não suportam o campo `version`. Só `?ref=v1.0.1` (pin exato) — sem ranges, sem `~>`.

---

## Entrega de Módulos

### Opções de Registro

| Método | Version constraints | Manutenção | Quando usar |
|--------|--------------------|-----------|-|
| Git direto (default branch) | ✗ | Zero | Desenvolvimento local/testes de branch |
| Git direto (`?ref=tag`) | Só pin exato | Manual | Times pequenos que aceitam overhead |
| Registro público (OpenTofu/HCP) | ✓ | Zero pós-registro | Módulos open source |
| Registro privado (TACOS incluído) | ✓ | Integrado ao SCM | Maioria dos casos corporativos |
| Artifactory | ✓ (push manual) | Via makefile + CI | Empresas com Artifactory existente |

### Artifactory — Push via makefile

```makefile
ARTIFACTORY_NAMESPACE:=your_namespace
ARTIFACTORY_TF_PROVIDER:=azurerm
TAG:=

publish_artifactory:
    @if [ -z "$(TAG)" ]; then echo "Please specify TAG"; exit 1; fi
    jf terraform-config
    jf tf p --namespace=$(ARTIFACTORY_NAMESPACE) --provider=$(ARTIFACTORY_TF_PROVIDER) --tag=$(TAG)
```

### GitHub Action — Trigger por tag semver

```yaml
on:
  push:
    tags:
      - "v[0-9]+.[0-9]+.[0-9]+"   # só executa em releases semânticos

jobs:
  artifactory:
    permissions:
      id-token: write               # OIDC — sem senhas hardcoded
    steps:
      - uses: actions/checkout@v4
      - uses: jfrog/setup-jfrog-cli@v4
        env:
          JF_URL: https://registry.example.com
        with:
          oidc-provider-name: github-action-workflow
      - name: Publish Module
        run: make publish_artifactory TAG=${{ github.ref_name }}
```

---

## Estruturas de Projeto

### Application as Root Module

```
main.tf, variables.tf, outputs.tf  # código compartilhado
staging.tfvars                      # variáveis por ambiente
production.tfvars
```

**Problema crítico:** todos os ambientes usam o mesmo código. Qualquer mudança afeta TODOS os ambientes simultaneamente — impossível fazer rollout gradual (staging → production com versões diferentes).

### Environment as Root Module (padrão recomendado)

```
staging/
  main.tf         # thin wrapper que chama o módulo de aplicação
production/
  main.tf
future/
  main.tf
```

```hcl
# staging/main.tf — thin wrapper
variable "logging_api_key" {
  sensitive = true   # nunca hardcoded, nunca no SCM
}

module "application" {
  source  = "registry.example.com/example/aws/application"
  version = "1.1.1"     # EXATO — não range; upgrade requer PR

  network_name    = "dev_network"
  db_size         = 20
  num_tasks       = 5
  logging_api_key = var.logging_api_key
}

output "application_url" {
  value = module.application.url
}
```

**Benefícios:** ambientes completamente independentes; cada env tem seu próprio `version`; upgrade = PR = audit trail.

**Repositório:** manter todos os ambientes de uma aplicação no mesmo repo (a menos que times diferentes gerenciem ambientes diferentes).

### Terragrunt

Thin wrapper sobre Terraform que gera o root module automaticamente a partir de `terragrunt.hcl`.

```bash
# Instalar via tenv
tenv terragrunt install

# Gerar config a partir de módulo publicado
terragrunt scaffold github.com/TerraformInDepth/three_tier_example
```

```hcl
# terragrunt.hcl — gerado pelo scaffold
terraform {
  source = "git::https://github.com/TerraformInDepth/three_tier_example?ref=v1.0.2"
}

inputs = {
  num_tasks = 5
  db_size   = "20"
  network   = "dev_network"
}
```

```
staging/terragrunt.hcl
production/terragrunt.hcl
future/terragrunt.hcl
```

**Comandos espelham Terraform:**
```bash
terragrunt plan
terragrunt apply
terragrunt run-all plan    # executa em todos os ambientes de uma vez
```

**Importante:** Terragrunt **não** suporta version constraints — sempre usa versão exata. Cada upgrade de `ref=` cria um commit = audit trail automático.

**Quando usar:** times que gerenciam muitos ambientes. Não é requisito — muitos times nunca usam Terragrunt.

---

## Gerenciamento de Segredos

Hierarquia de preferência (do melhor para o pior):

### 1. OIDC — Eliminar o segredo

OIDC (OpenID Foundation + OAuth 2.0) permite autenticação machine-to-machine **sem credenciais estáticas**. Todo major cloud provider suporta.

**Fluxo de configuração:**
1. Obter provider URL do IdP (GitHub Actions: `https://token.actions.githubusercontent.com`)
2. Registrar URL como provider no vendor (AWS, Azure, GCP)
3. Criar role/service principal com condições específicas ao repositório

```hcl
# Registrar GitHub Actions como OIDC provider no AWS
locals {
  gh_actions_token_url = "https://token.actions.githubusercontent.com"
}

data "tls_certificate" "gh_actions" {
  url = local.gh_actions_token_url
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = local.gh_actions_token_url
  thumbprint_list = data.tls_certificate.gh_actions.certificates[*].sha1_fingerprint
  client_id_list  = ["sts.amazonaws.com"]
}
```

**GitHub Actions usando OIDC para AWS:**
```yaml
permissions:
  id-token: write    # habilita OIDC token
  contents: read

steps:
  - uses: actions/checkout@v4
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::999999999999:role/github-actions-${{ github.repository }}
      region: us-west-2
```

**Spacelift com OIDC:**
```hcl
provider "aws" {
  assume_role_with_web_identity {
    role_arn                = var.aws_role_arn
    web_identity_token_file = "/mnt/workspace/spacelift.oidc"
  }
}
```

**Crítico:** sempre adicionar **condições** no role/service principal que limitam ao repositório/stack específico. Sem condições, qualquer usuário do mesmo IdP pode assumir o role.

### 2. Secret Managers

Para credenciais sem suporte OIDC: AWS Secrets Manager, Azure Key Vault, HashiCorp Vault.

```hcl
# AWS Secrets Manager
data "aws_secretsmanager_secret" "example" {
  arn = var.secret_arn
}
data "aws_secretsmanager_secret_version" "v" {
  secret_id = data.aws_secretsmanager_secret.example.id
}
output "secret" {
  value     = data.aws_secretsmanager_secret_version.v.value
  sensitive = true
}

# HashiCorp Vault
data "vault_generic_secret" "example" {
  path = var.vault_path
}
output "vault_secret" {
  value     = data.vault_generic_secret.example.data[var.vault_key]
  sensitive = true
}

# Azure Key Vault
data "azurerm_key_vault" "example" {
  name                = var.azure_vault_id
  resource_group_name = var.azure_resource_group
}
data "azurerm_key_vault_secret" "example" {
  name         = var.azure_secret_name
  key_vault_id = data.azurerm_key_vault.example.id
}
```

**Aviso:** valores obtidos via `data` source **ainda aparecem no state file**. Proteger o backend ou usar métodos machine-to-machine que não passam pelo state (ex: AWS ECS carregando direto do Secrets Manager via ARN).

Os próprios secret managers suportam OIDC — não é necessário armazenar credenciais para acessá-los.

### 3. Orchestrator Settings

Último recurso: variáveis sensíveis armazenadas no próprio CD platform. Problema de escala: atualizar uma chave em 500 projetos vira pesadelo. Considerar secret manager centralizado quando isso ocorrer.

---

## Features de CD Platforms

### Features Universais (todo platform relevante)
- GitOps-based workflows
- RBAC (role-based access control)
- OIDC support
- Secret management
- Speculative plan em PRs

### Features Diferenciadoras

| Feature | Relevância |
|---------|-----------|
| **State backend** | TACOS: incluso. Outros: precisa backend externo |
| **Registro privado** | TACOS: incluso. CI/CD genérico: não incluso |
| **Drift detection** | Maioria detecta; auto-correção é opt-in (assustador) |
| **Múltiplos frameworks IaC** | Prefira plataformas além de Terraform (Helm, Ansible, Pulumi) |
| **Policy enforcement** | OPA domina; HCP Terraform também usa Sentinel |
| **Estimativa de custo** | HCP Terraform: built-in; outros: via Infracost; só AWS/Azure/GCP; são estimativas |

**Terraform vs OpenTofu em CD:** BSL do HashiCorp proíbe concorrentes de usar Terraform. Todos os vendors (exceto HCP Terraform) migraram para OpenTofu v1.6+.

---

## Matriz de CD Platforms

| Sistema | Open Source | State | Registry | Só Terraform/OpenTofu | Policy | Custo |
|---------|------------|-------|----------|-----------------------|--------|-------|
| **HCP Terraform** | ✗ | ✓ | ✓ | Sim (Terraform only) | Sentinel + OPA | Built-in |
| **Spacelift** | ✗ | ✓ | ✓ | Não | OPA | Infracost |
| **Env0** | ✗ | ✓ | ✓ | Não | OPA | Infracost |
| **Scalr** | ✗ | ✓ | ✓ | Sim | OPA | Infracost |
| **Digger** | ✓ | ✗ | ✗ | Sim | OPA | — |
| **Terrateam** | ✗ | ✗ | ✗ | Sim | Checkov + OPA | Infracost |
| **Atlantis** | ✓ | ✗ | ✗ | Sim | Nenhuma | — |
| **Terrakube** | ✓ | ✓ | ✓ | Sim | OPA | Infracost |
| **Harness** | ✗ | ✗ | ✗ | Não | OPA | Infracost |
| **Octopus Deploy** | ✗ | ✗ | ✗ | Não | Nenhuma | Infracost |

### Guia de Seleção

**Quer TACOS completo + multi-framework?** → Spacelift ou Env0 (sponsors do OpenTofu, polished, suportam Helm/Ansible/Pulumi)

**Quer TACOS similar ao HCP Terraform + CLI-driven?** → Scalr

**Quer GitOps via PR comments + GitHub-first?** → Digger ou Terrateam

**Quer open source self-hosted?**
- Feature completo (state + registry): Terrakube
- GitOps tight com SCM: Atlantis

**Quer CD genérico com enterprise features?** → Harness (IDP completo) ou Octopus Deploy

**HCP Terraform:** só se já estiver locked in; pricing por recurso/hora é problemático (72 resources por VPC = $7.25/mês/VPC); não suporta OpenTofu.

---

## Exemplo Trabalhado — GitOps Flow Completo

```
Developer workflow para novo feature em Factory Analytics
(sistema multi-região: Asia, Europe, North America)

1. git checkout -b feature/nova-metrica
   terraform apply (local backend, feature environment)
   → testa mudanças de forma isolada
   
2. git push origin feature/nova-metrica
   → CI executa: validate + TFLint + Checkov + Trivy + terraform fmt
   → CD platform gera speculative plan (mostra mudanças sem aplicar)
   
3. Pull request aberto:
   - CI checks ✅
   - Speculative plan revisado pelo time
   - Code review + aprovação
   
4. Merge para main
   → CD platform detecta mudança
   → Aplica automaticamente em staging/europe/
   → Aguarda validação manual (ou testes automatizados)
   → Aplica em production/europe/, production/asia/, production/north-america/
   
5. Se drift detectado (auto-scaling alterou config):
   → CD platform notifica Slack
   → Agenda reconciliação automática ou abre ticket
   → NÃO afeta o feature deployment em andamento (environments isolados)

6. terraform destroy (feature environment)
   → recursos efêmeros limpos
```

---

## Ambientes e Isolamento

### Tipos de Ambiente

| Tipo | Duração | Backend | Quem usa |
|------|---------|---------|---------|
| Feature/dev | Efêmero (local) | `local` | Developer individual |
| Staging | Permanente | Remoto | Testes automatizados + manuais |
| Production | Permanente | Remoto | Clientes |
| Regional | Permanente | Remoto por região | Compliance legal + latência |
| Customer-specific | Permanente | Remoto por cliente | Contratos com isolamento total |

**Regra de isolamento:** cada ambiente deve ter própria conta, rede, subdomínio, banco, state. Um ambiente **não deve depender** de outro ambiente da mesma aplicação para funcionar.

---

## Comandos de Referência

```bash
# Terragrunt
tenv terragrunt install
terragrunt scaffold github.com/org/module
terragrunt plan
terragrunt apply
terragrunt run-all plan      # todos os ambientes
terragrunt run-all apply     # cuidado — aplica em tudo

# Terraform login (registros privados)
terraform login registry.example.com

# Artifactory (jf CLI)
jfrog config add --artifactory-url=https://registry.example.com/
make publish_artifactory TAG=v1.2.3
```

---

## Anti-patterns

- **Deploy local em ambientes compartilhados:** state locking previne conflitos, mas dois desenvolvedores podem sobrescrever um ao outro (cada um sem o código do outro). Centralizar SEMPRE.
- **Credenciais estáticas para CI/CD:** usar OIDC elimina rotação, vazamento, e service users.
- **Application as root module único:** perde versionamento independente por ambiente — todos os envs upgradados juntos.
- **Version ranges no root module:** root module deve usar versão exata. Ranges são para módulos reutilizáveis; o root precisa de deploy controlado via PR.
- **Secrets no SCM:** mesmo em repositório privado — não há controle de onde o repo vai após clone, e GitHub Apps frequentemente têm acesso ao código.
- **Data sources de secrets sem proteger o state:** valor plaintext acaba no JSON do state.
- **Self-hosted CD platform no mesmo cloud/região que a infra:** se a infra cai, o sistema de recovery também cai.
- **Dependabot/drift correction automático sem review:** detectar é seguro; corrigir automaticamente requer confiança estabelecida.
- **HCP Terraform para equipes com muitos recursos:** pricing por resource/hora se torna proibitivo rapidamente.

---

## Erros Comuns

### "Não preciso de CD platform, uso GitHub Actions"
Possível, mas complexo: reconciliação contínua, drift detection com schedule, e boa experiência de speculative plan são muito mais fáceis em plataformas dedicadas.

### "Vou usar `~> 1.1` no root module"
Root modules usam versão exata (`version = "1.1.1"`). Ranges são para módulos filhos. O root precisa de audit trail — cada versão = commit explícito.

### "OIDC é complicado, vou usar uma service account"
OIDC tem mais configuração inicial, mas elimina rotação de credenciais, vazamento, e gestão de service users. O investimento compensa.

### "Self-hosted tem custo zero"
Tem custo de manutenção, disponibilidade, e risco operacional. Self-hosted CD platform offline durante outage = incapaz de responder ao outage.

---

## Modelos Mentais

- **Semantic versioning = sinalização de risco:** `Patch` = safe, `Minor` = novo mas compatível, `Major` = esforço de migração. Cultura importa mais que ferramenta para manter isso consistente.
- **GitOps = Terraform + SCM como fonte de verdade + deploy automático:** Terraform sozinho não é GitOps; precisa do SCM e do CD platform.
- **Environment as root module = isolamento verdadeiro:** thin wrapper + versão exata = cada ambiente vive em seu próprio tempo.
- **OIDC = eliminar o problema, não resolver:** melhor que rotacionar segredos é nunca tê-los.
- **CD sem CI é como dirigir sem cinto:** pode funcionar por um tempo, mas eventualmente um erro passa despercebido.
- **State no state file:** valores obtidos via `data` source ainda persistem no state — não é só o que você cria explicitamente.

---

## Key Takeaways

1. **CI ≠ CD:** CI mantém código funcional; CD entrega infraestrutura para usuários. São ferramentas e práticas distintas.
2. **Semver + version constraints reduzem manutenção:** `~> Major.Minor` em módulos filhos; versão exata no root module.
3. **Environment as root module > application as root module:** isolamento real por versão de módulo — staging pode estar na v1.1, production na v1.0.
4. **Terragrunt automatiza root modules:** especialmente valioso para times com muitos ambientes; não é requisito universal.
5. **OIDC elimina credenciais estáticas:** todo major cloud suporta; primeiro investimento em segurança de CD.
6. **State file contém segredos:** mesmo usando secret managers via `data` source — proteger o backend é obrigatório.
7. **Preferir plataformas multi-framework:** Terraform não é o único IaC; evitar lock-in em plataforma Terraform-only.
8. **Reconciliação contínua ≠ correção automática:** detectar drift é seguro e recomendado; auto-corrigir requer confiança e revisão cuidadosa.
9. **Self-hosted CD platform = isolamento obrigatório:** conta própria, rede própria, preferencialmente região diferente.

---

## Conecta Com

- **Ch07**: CI como fundação do CD — sem qualidade gate (TFLint, Checkov, validate), GitOps é perigoso.
- **Ch06**: State backends e locking — backends remotos são requisito para CD centralizado; TACOS gerenciam o backend transparentemente.
- **Ch05**: Speculative plan — CD platforms geram plan em PRs; base do GitOps review process.
- **Ch09**: Testing automatizado — próximo nível de segurança para deployments; complementa as práticas de CD.
- **Ch03**: Módulos reutilizáveis — a entidade que está sendo versionada e entregue via registros.
