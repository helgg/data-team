# Skill: terraform-in-depth

## Filosofia Central

1. **IaC = engenharia de software aplicada à infra**: versionamento, testes, CI/CD, revisão de PR — tudo se aplica.
2. **Declarativo = descreva o estado final**: HCL define o que deve existir; Terraform resolve como via DAG.
3. **Providers isolam vendors**: o mesmo workflow init → plan → apply funciona para AWS, GCP, Azure, DNS.
4. **State é o ledger da infraestrutura**: proteger o backend é tão crítico quanto proteger o código.
5. **Providers, modules, registries, CD platforms** formam o ecossistema; Terraform Core é só o engine.

---

## Topic Index — Use-Case → Chapter

### "Preciso criar/modificar recursos"
→ [ch02] Blocos HCL, lifecycle, meta-argumentos
→ [ch04] Expressões, count/for_each, dynamic blocks
→ [ch05] Como o plano funciona, ler o DAG, -replace

### "Preciso organizar e reutilizar código"
→ [ch03] Módulos, variáveis, tipos, validação
→ [ch08] Semver, registries privados, Environment as root module
→ [ch10] Naming hierárquico, subnetting dinâmico

### "Preciso gerenciar state"
→ [ch06] Backends, drift, moved/removed, remote state, state-only providers
→ [ch05] Modos de plan, refresh, locking
→ [ch09] import block, refactoring, parallel change

### "Preciso configurar CI/CD"
→ [ch07] TFLint, Checkov, Trivy, Makefile, pre-commit, GitHub Actions matrix
→ [ch08] GitOps, OIDC, CD platforms (TACOS), Terragrunt
→ [ch05] Speculative plan, -input=false, -lock=false

### "Preciso testar"
→ [ch09] Terratest, .tftest.hcl, mocks, parallel change, aws-nuke
→ [ch10] precondition, postcondition, check blocks

### "Preciso integrar programaticamente"
→ [ch11] CLI wrapper (Python), JSON vs JSONL streaming, .tf.json, CDKTF
→ [ch10] External provider, local provider, .tofu files

### "Preciso construir um provider customizado"
→ [ch12] Plugin Framework (Go), Schema, CRUD, Functions, testes, publicação

### "Quero entender segurança"
→ [ch08] OIDC, secret managers, state file = plaintext
→ [ch07] Checkov, Trivy, políticas customizadas
→ [ch06] sensitive flag, backend encryption

### "Preciso de alternativas ao Terraform"
→ [ch01] OpenTofu (fork BSL-livre)
→ [ch08] TACOS comparison table, GitOps platforms
→ [ch11] CDKTF (TypeScript/Python/Go)

---

## Chapter Index

| # | Arquivo | Tema central |
|---|---------|-------------|
| 01 | [ch01-visao-geral-terraform.md](chapters/ch01-visao-geral-terraform.md) | IaC, HCL declarativo, DAG, init→plan→apply, OpenTofu |
| 02 | [ch02-componentes-hcl.md](chapters/ch02-componentes-hcl.md) | 12 tipos de blocos, lifecycle, meta-argumentos, provider alias |
| 03 | [ch03-variaveis-modulos.md](chapters/ch03-variaveis-modulos.md) | Módulos, sistema de tipos, input/output/locals, validation |
| 04 | [ch04-expressoes-iteracoes.md](chapters/ch04-expressoes-iteracoes.md) | Operadores, funções, count/for_each, for expressions, dynamic |
| 05 | [ch05-plano-terraform.md](chapters/ch05-plano-terraform.md) | DAG interno, modos de plan, -replace, dependências circulares |
| 06 | [ch06-gerenciamento-estado.md](chapters/ch06-gerenciamento-estado.md) | State JSON, backends, drift, moved/removed, remote state |
| 07 | [ch07-qualidade-codigo-ci.md](chapters/ch07-qualidade-codigo-ci.md) | Makefile, tenv, TFLint, Checkov, Trivy, pre-commit, GitHub Actions |
| 08 | [ch08-entrega-continua-deploy.md](chapters/ch08-entrega-continua-deploy.md) | CI vs CD, semver, OIDC, Terragrunt, CD platforms |
| 09 | [ch09-testes-refatoracao.md](chapters/ch09-testes-refatoracao.md) | Terratest, .tftest.hcl, mocks, parallel change, aws-nuke |
| 10 | [ch10-topicos-avancados.md](chapters/ch10-topicos-avancados.md) | Naming, cidrsubnet, provisioners, external/local, check/conditions |
| 11 | [ch11-interfaces-alternativas.md](chapters/ch11-interfaces-alternativas.md) | CLI wrapper Python, JSONL streaming, .tf.json, CDKTF |
| 12 | [ch12-providers-terraform.md](chapters/ch12-providers-terraform.md) | Plugin Framework Go, Schema, CRUD, Functions, publicação |

---

## Artefatos de Referência

| Arquivo | Conteúdo |
|---------|---------|
| [glossary.md](glossary.md) | ~100 termos alfabéticos com capítulo de origem |
| [patterns.md](patterns.md) | 22 padrões práticos com when/how/trade-offs |
| [cheatsheet.md](cheatsheet.md) | Tabelas de decisão: blocos, count vs for_each, backends, secrets, testes, CD platforms |

---

## Conceitos Fundamentais para Orientação

**DAG** — grafo de dependências que define tudo: ordem de criação, paralelismo, e a maioria dos erros.
Sempre ler o plan de baixo para cima (recursos sem deps ficam no fundo).

**State** — JSON que mapeia código para infra real. `sensitive` mascara logs, não protege o state file.
3 pilares do backend: Resiliência + Segurança + Disponibilidade.

**Módulo** — unidade de reuso. Root module configura providers; módulos filho herdam.
Interface: inputs entram, outputs saem, locals ficam dentro.

**Providers** — plugins Go que abstraem APIs de vendors.
>3.280 no registry público. OpenTofu usa os mesmos providers.

**OpenTofu** — fork BSL-livre; drop-in replacement; `tofu` no lugar de `terraform`.
Use quando construindo produtos ou ferramentas sobre IaC.

---

## Fluxo de Trabalho Padrão

```
Novo módulo:
  cookiecutter → makefile + pré-commit + GitHub Actions template
  → code → make chores → make security → git commit (hooks rodam)
  → PR → matrix CI → speculative plan no CD platform
  → merge → CD aplica em staging → production

Novo provider:
  clonar scaffolding template → limpar arquivos HashiCorp
  → design interfaces (resources, data sources, functions)
  → implementar Schema + CRUD + Configure
  → go install → dev_overrides em ~/.terraformrc
  → testes unit (functions) + acceptance (resources)
  → go generate (docs) → GPG key → GitHub release → registry

State refactoring:
  renomear: moved block (nunca deletar até major version)
  remover: removed { lifecycle { destroy = false } }
  importar: import block (remover após apply)
  drift: diagnosticar tipo → solução específica (ver cheatsheet)
```
