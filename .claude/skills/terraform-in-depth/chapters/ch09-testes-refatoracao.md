# Capítulo 9: Testing and Refactoring

## Ideia Central

Testes automatizados são o alicerce da qualidade e da segurança psicológica da equipe. Com uma suite de testes sólida, refatoração deixa de ser assustadora — é possível reestruturar código com confiança de que mudanças não quebram o que já funciona.

---

## Frameworks Introduzidos

### Por que testar IaC
- **Safety net técnico**: bugs encontrados mais rápido; regressões evitadas via atualização da suite após cada bug
- **Safety net social**: revisão de PRs facilitada (sem precisar subir o código localmente); redução de ansiedade ao fazer deploys
- **Backward compatibility**: breaking changes quebram os testes — sinalizando antes que usuários sejam afetados

### O que testar (e o que não)
Não teste os providers — eles já são testados pelo time que os mantém. Teste **sua lógica**:
- Transformações de dados (`"${var.name}.${data.aws_region.current.name}.${var.domain}"`)
- Strings geradas dinamicamente
- Expressões regulares — com múltiplos padrões
- Dynamic blocks — zero, um e muitos elementos
- Funcionalidade do sistema — endpoint HTTP acessível, credenciais funcionando

### Desafios específicos de IaC
| Desafio | Impacto | Mitigação |
|---------|---------|-----------|
| **Tempo** | Launch de RDS = 30–45min; ciclo completo pode passar de 1h | Agrupar assertions por configuração; paralelizar |
| **Dinheiro** | Recursos reais são criados e destruídos — custam dinheiro | `defer Destroy`; cleanup automático (aws-nuke); contas isoladas |
| **Timeouts** | Go testing default = 10min; infra pode levar mais | `-timeout 60m` (Terratest); CI system timeout |
| **Orphaned resources** | Timeout/crash antes do destroy | Scheduled account reset (aws-nuke via cron) |

### Terratest vs Terraform testing framework

| Característica | Terratest | Terraform Testing Framework |
|---|---|---|
| Linguagem | Go | HCL nativo |
| Disponível desde | 2018 | v1.6 (2023) |
| Versões flexíveis | Sim | Não (acoplado ao TF) |
| Mocks nativos | Não | Sim (v1.7+, beta) |
| Acesso a named values | Via outputs apenas | Qualquer atributo direto |
| Copilot support | Sim | Limitado (modelo ainda não treinado) |
| Terceiros / helpers | 20+ pacotes Go | Não |
| Recomendado para | Projetos com multi-versão; times com Go | Times novos em TF; projetos modernos |

### Unit vs Integration em IaC
IaC é majoritariamente **integration testing** — os providers já fazem o unit testing de cada recurso. O desenvolvedor Terraform testa como recursos interagem com configurações específicas. Mocks (v1.7+) aproximam ao unit testing sem lançar infraestrutura real.

---

## Conceitos-chave

- **Terratest**: framework Go da Gruntwork; wraps Terraform com helpers para assertions e outputs
- **`defer terraform.Destroy`**: garante cleanup mesmo com falha no teste
- **`terraform.InitAndApply`**: roda `init` + `apply` numa chamada
- **`t.Parallel()`**: permite que múltiplos testes rodem ao mesmo tempo
- **`.tftest.hcl`**: arquivo de teste nativo do Terraform; fica no mesmo diretório do módulo
- **`run` block**: cada bloco = um teste; default `command = apply`; pode usar `command = plan`
- **`assert` block**: `condition` (expressão booleana) + `error_message`
- **`mock_provider`**: substitui provider real por fake; valores padrão: numbers=0, bool=false, map={}, list=[]
- **`override_data` / `override_resource`**: sobrescreve valores específicos no scope do `run` block
- **`tfmock.hcl`**: arquivo de mocks reutilizáveis; importado por diretório (não por arquivo)
- **Parallel change** (expand and contract): padrão para renomear variável sem breaking change
- **`moved` block**: renomeia recurso no state sem destroy/recreate; nunca deletar até major version
- **Technical debt**: funcionalidade ou qualidade adiada; ~20% do tempo em codebase maduro
- **Refactoring interno**: sem mudança em inputs/outputs; invisível para usuário; tests não devem quebrar
- **Refactoring externo**: muda inputs/outputs; requer major version bump; deve ser batched com outras breaking changes
- **aws-nuke / azure-nuke**: ferramentas "Vendor Nuke" para reset automático de conta de testes; agendar via cron; **apenas em contas isoladas de teste**
- **UPGRADE.md / CHANGELOG.md**: documentação de breaking changes para usuários de módulo

---

## Modelos Mentais

- **"Test the logic, not the provider"** — providers têm seus próprios testes; testar pass-through de variáveis agrega zero valor
- **"Examples são o ponto de partida dos testes"** — manter `examples/` com casos reais facilita teste de integração e serve de documentação viva
- **"Randomize names"** — testes concorrentes + nomes únicos = `random_string.random.result` no name
- **Mocks como complemento, não substituto** — mocks testam lógica rápido; integration tests validam comportamento real; use ambos

---

## Exemplos de Código

### Terratest Hello World

```go
package tests

import (
    "os"
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestExample(t *testing.T) {
    t.Parallel()

    testInput := "test"

    terraformBinary := os.Getenv("TERRATEST_BINARY")
    if len(terraformBinary) <= 0 {
        terraformBinary = "terraform"   // fallback para terraform; TERRATEST_BINARY=tofu para OpenTofu
    }

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir:    "../examples/basic",
        TerraformBinary: terraformBinary,
        Vars: map[string]interface{}{
            "test_input": testInput,
        },
    })

    defer terraform.Destroy(t, terraformOptions)  // roda mesmo se o teste falhar

    terraform.InitAndApply(t, terraformOptions)

    testOutput := terraform.Output(t, terraformOptions, "test_output")
    assert.Equal(t, testInput, testOutput)
}
```

### Terraform Testing Framework Hello World

```hcl
# tests/example.tftest.hcl
variables {
  test_input = "test"   # aplica a todos os run blocks do arquivo
}

run "input_and_output_match" {
  # command = apply (default)
  assert {
    condition     = output.test_output == "test"
    error_message = "The output does not match the input."
  }
}
```

### Acesso a Named Values (sem output)

```hcl
run "input_passed_to_resource" {
  assert {
    condition     = terraform_data.this.input == "test"   # acessa atributo direto
    error_message = "The resource parameter does not match the input."
  }
}
```

### Mocks com override_data

```hcl
mock_provider "aws" {}

run "dns_record_name" {
  command = plan   # não lança infra real

  override_data {
    target = data.aws_region.current
    values = { name = "us-east-1" }
  }

  variables {
    zone_id = "Z1234567890"
    records = ["127.0.0.1"]
    domain  = "example.com"
    name    = "my_test"
  }

  assert {
    condition     = aws_route53_record.main.name == "my_test.us-east-1.example.com"
    error_message = "Domain name not properly generated from region."
  }
}
```

### random_string para concorrência

```hcl
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

module "alb_example" {
  source = "../"
  name   = "testing_${random_string.random.result}"   # evita colisão em runs paralelos
}
```

### Parallel Change — renomear variável sem breaking change

```hcl
variable "my_old_variable" {
  type    = string
  default = null            # null = detecta ausência; descrição: "deprecated"
}

variable "my_new_variable" {
  type    = string
  default = "my_fancy_default"
}

locals {
  use_this_variable = var.my_old_variable != null ? var.my_old_variable : var.my_new_variable
}

output "my_output" {
  value = local.use_this_variable   # referência sempre via local
}
```

### AWS Nuke — cleanup automático agendado

```yaml
name: AWS Nuke Job
on:
  schedule:
    - cron: "0 0 * * *"   # todo dia à meia-noite

env:
  AWS_ROLE_ARN: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
  AWS_DEFAULT_REGION: us-east-1
  AWS_NUKE_VERSION: 2.25.0

jobs:
  aws-nuke:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ env.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_DEFAULT_REGION }}
      - run: |
          curl -L https://github.com/rebuy-de/aws-nuke/releases/download/v${AWS_NUKE_VERSION}/aws-nuke-v${AWS_NUKE_VERSION}-linux-amd64.tar.gz --output aws_nuke.tar.gz
          tar -xvf aws_nuke.tar.gz
          sudo mv aws-nuke-v${AWS_NUKE_VERSION}-linux-amd64 /usr/local/bin/aws-nuke
      - run: aws-nuke --config nuke-config.yml   # config define o que pode ser deletado
```

### Makefile — Terratest

```makefile
TERRATEST_FILES:=$(wildcard terratest/*_test.go)
GO_TEST_OPTS:=

terratest/go.mod:
    cd terratest && go mod init ModuleTests

terratest/go.sum: tests/go.mod $(TERRATEST_FILES)
    cd tests && go mod tidy

.PHONY: terratest
terratest: terratest/go.sum
    cd terratest && \
    TERRATEST_BINARY=$(TF_BINARY) go test -v -timeout 60m $(GO_TEST_OPTS)
```

```bash
# Rodar só um teste específico:
make terratest GO_TEST_OPTS="-run TestExample"
```

### Makefile — Terraform Testing Framework com múltiplos exemplos

```makefile
TERRAFORM_EXAMPLES:=$(wildcard examples/*)
TF_TEST_OPTS:=

.PHONY: $(TERRAFORM_EXAMPLES)
$(TERRAFORM_EXAMPLES):
    @echo "Testing $@"
    cd $@ && \
    $(TF_ENV_COMMAND) && \
    $(TF_BINARY) init -backend=false && \
    $(TF_BINARY) test $(TF_TEST_OPTS)

.PHONY: terraform_test
terraform_test: $(TERRAFORM_EXAMPLES)
    @echo "Testing Root Module"
    $(TF_BINARY) test $(TF_TEST_OPTS)
```

---

## Tabelas de Referência

### Mock value defaults (Terraform v1.7+)

| Tipo HCL | Valor mockado |
|----------|---------------|
| `number` | `0` |
| `bool` | `false` |
| `map` | `{}` |
| `list` / `set` | `[]` |
| `object` | atributos criados com os defaults acima |

### Scope dos override blocks

| Onde declarado | Escopo |
|----------------|--------|
| Dentro de `mock_provider` | Só quando esse provider cria o recurso |
| Top-level do arquivo | Todos os `run` blocks |
| Dentro de `run` block | Só aquele bloco |

### GitHub Actions CI matrix — Terratest com múltiplos testes

```yaml
strategy:
  matrix:
    engine: ["opentofu", "terraform"]
    version: ["1.6", "1.7", "1.8"]
    test: [BasicTest, LambdaTest, ECSTest, Ec2Test]
...
- run: make terratest TF_ENGINE=${{matrix.engine}} GO_TEST_OPTIONS="-run ${{matrix.test}}"
```

---

## Exemplo Trabalhado — Testing Flow Completo

**Cenário**: módulo ALB com 3 integrações (Lambda, ECS, EC2).

1. **Estrutura de exemplos**:
```
examples/
  basic/main.tf      # smoke test
  lambda/main.tf     # integração ALB → Lambda
  ecs/main.tf        # integração ALB → ECS
  ec2/main.tf        # integração ALB → EC2
```

2. **Terratest** aponta `TerraformDir` para cada exemplo:
```go
terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "../examples/ecs",
    Vars: map[string]interface{}{
        "name": "testing_" + random_string,
    },
})
defer terraform.Destroy(t, terraformOptions)
terraform.InitAndApply(t, terraformOptions)
// assertions aqui
```

3. **CI matrix** roda cada exemplo independentemente:
```yaml
test: [BasicTest, LambdaTest, ECSTest, Ec2Test]
```
Resultado: 4 jobs × 2 engines × 3 versions = 24 jobs paralelos; cada um com seu próprio infra lifecycle.

4. **aws-nuke** agendado todo dia à meia-noite garante cleanup de recursos órfãos caso timeout ocorra.

---

## Key Takeaways

1. Teste **sua lógica** (transforms, strings dinâmicas, dynamic blocks) — não os providers
2. Use `defer terraform.Destroy` (Terratest) ou cleanup automático para não deixar recursos órfãos
3. `random_string` nos nomes previne colisões em testes concorrentes
4. `-timeout 60m` é obrigatório no Terratest; Go default (10min) é insuficiente para infra real
5. Exemplos funcionais (`examples/`) servem como base de testes + documentação viva
6. Terraform testing framework acessa atributos internos diretamente, sem precisar de outputs
7. Mocks (v1.7+) testam lógica em segundos — complementam, não substituem, integration tests
8. **Parallel change**: renomear variável sem breaking change = old var nullable + local com precedência
9. `moved` block: nunca deletar até major version
10. Batche breaking changes — lançar todas juntas no major version reduz interrupções para usuários

---

## Anti-Patterns

- **Testar o provider** — `var.name == output.name` não testa nada além do que AWS/TF já garantem
- **Esquecer `-timeout 60m`** — teste morto antes do destroy = recursos órfãos custando dinheiro
- **Nomes fixos em testes concorrentes** — dois PRs paralelos colidem em `aws_secretsmanager_secret`
- **Deletar `moved` blocks** — usuários em versões antigas do módulo vão ter destroy/recreate inesperado
- **Rodar tests em conta de produção** — aws-nuke + conta errada = catástrofe

---

## Conecta Com

- **[ch06]** — `moved` block (renaming resources no state)
- **[ch07]** — makefile pattern; CI com GitHub Actions matrix; `tenv` para gestão de versões
- **[ch08]** — OIDC para autenticação em testes; conta de testes isolada para CD
- **[ch03]** — estrutura de módulos; `examples/` directory; outputs e variables
