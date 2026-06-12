# Capítulo 3: Variáveis e Módulos Terraform

## Ideia Central
Módulos são o mecanismo de reuso em Terraform: coleções de resources e data sources empacotadas como componentes reutilizáveis. Variáveis (input, output, local) são a interface pública do módulo — inputs recebem dados, outputs expõem atributos, locals encapsulam lógica interna. Juntos, permitem construir sistemas complexos a partir de blocos menores e independentes.

---

## Frameworks Introduzidos

### Módulo como Função
```
module "my_instance" {
  source    = "github.com/user/terraform-aws-in-depth//modules/ec2_instance"
  subnet_id = var.subnet_id        # input = argumento de função
}
output "arn" {
  value = module.my_instance.aws_instance_arn   # output = retorno de função
}
# locals = variáveis internas da função (invisíveis externamente)
```
- **Input variables** = parâmetros: o que entra no módulo.
- **Output variables** = return values: o que sai do módulo.
- **Locals** = variáveis internas: só existem dentro do módulo.

### Três Sabores de Módulo

| Tipo | O que é | Uso típico |
|------|---------|------------|
| **Root module** | Módulo onde `terraform init` é executado; configura providers | Workspace / ponto de entrada |
| **Shared module** | Baixado de registry ou Git por outros módulos | Biblioteca reutilizável |
| **Submodule** | Parte de outro módulo, em `modules/` | Divisão interna de complexidade |

### Sistema de Tipos Terraform

| Tipo | Keyword | Característica |
|------|---------|----------------|
| String | `string` | Unicode; suporta interpolação `"${var.x}-suffix"` |
| Number | `number` | Único tipo para inteiros e floats |
| Boolean | `bool` | `true` / `false` |
| List | `list(type)` | Ordenado; todos os elementos do mesmo tipo; acesso por índice |
| Set | `set(type)` | Sem ordem; sem duplicatas |
| Tuple | `tuple([t1, t2, t3])` | Tamanho fixo; cada posição pode ter tipo diferente |
| Object | `object({key=type})` | Chaves definidas; chaves extras descartadas; suporta `optional(type, default)` |
| Map | `map(type)` | Chaves livres (arbitrárias); todos os valores do mesmo tipo |
| Null | — | Valor não definido; default comum para inputs opcionais |
| Any | `any` | Sem restrição de tipo (homogeneidade ainda exigida em listas/maps) |

---

## Conceitos-Chave

- **Module registry**: repositório de módulos prontos. Público em `registry.terraform.io` (~12.000 módulos); privado em Terraform Cloud, Spacelift, Artifactory.
- **`source`**: argumento obrigatório do bloco `module`; aceita registry, caminho relativo, URL Git, GitHub/GitLab/Bitbucket.
- **`version`**: restrição de versão para módulos de registry; evita quebras por atualização inesperada.
- **`providers`**: passa aliases de provider do módulo pai para o módulo filho.
- **`sensitive = true`**: em inputs e outputs — mascara o valor em logs. O valor ainda fica gravado no state file.
- **`nullable = true/false`**: controla se um input pode receber `null` (default `true`).
- **`validation` subblock**: valida inputs com `condition` (expressão booleana) + `error_message`. Múltiplos blocos por variável são permitidos. A partir de Terraform 1.9, pode referenciar outras variáveis.
- **`depends_on` em output**: força o output a aguardar outro resource concluir antes de ser retornado.
- **`//` no source**: separa o repositório Git do caminho do submodule: `github.com/user/repo//modules/ec2`.
- **`terraform-PROVIDER-NAME`**: convenção de nomenclatura para repositórios de módulos (ex: `terraform-aws-instance`).

---

## Modelos Mentais

- **Módulo = pacote Python / módulo JS**: coleção de código relacionada; pode ser importada e reutilizada; tem versão e interface pública.
- **Scope de variáveis**: apenas inputs chegam de fora; apenas outputs saem para fora; locals nunca cruzam fronteiras do módulo.
- **Todas as variáveis Terraform são constantes**: linguagem declarativa — sem mutação durante a execução. Lógica e transformações acontecem via `locals`, não via reatribuição.
- **Map vs Object**: map = dicionário livre (tags, labels); object = struct tipado (configuração com campos fixos). Se as chaves variam, use map; se as chaves são fixas e tipadas, use object.

---

## Anti-patterns

- **Submodule de submodule**: nesting profundo de submodules aumenta complexidade sem benefício claro; evite mais de um nível.
- **`provider` block em módulo filho**: providers só podem ser configurados no root module. Módulos filhos recebem providers via herança ou argumento `providers`.
- **`type = any` sem razão**: perde as garantias de tipagem; bugs de tipo só aparecem em runtime. Prefira o tipo mais específico possível.
- **Objeto com muitas chaves aninhadas**: dificulta leitura e manutenção. Prefira múltiplos inputs simples.
- **Não marcar output como `sensitive`** quando o valor vem de um input `sensitive`: Terraform trata isso como exposição acidental e gera erro.
- **`list(any)` com elementos de tipos mistos**: mesmo com `any`, todos os elementos devem ser do mesmo tipo — strings e numbers numa mesma lista causam erro.

---

## Exemplo Trabalhado — Módulo Reutilizável de EC2

**Estrutura final:**
```
terraform-aws-in-depth/
├── modules/
│   └── ec2_instance/
│       ├── providers.tf   # só terraform{} block, sem provider{}
│       ├── variables.tf   # inputs com tipos e validação
│       ├── main.tf        # resource aws_instance
│       └── outputs.tf     # arn, ip, objeto completo
└── examples/
    └── basic/
        ├── providers.tf   # terraform{} + provider{} (root module)
        └── main.tf        # data lookups + module block + output
```

**variables.tf** (módulo filho):
```hcl
variable "instance_type" {
  type        = string
  description = "The type of instance to launch."
  default     = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the Subnet to launch the instance into."

  validation {
    condition     = length(regexall("^subnet-[\\d|\\w]+$", var.subnet_id)) == 1
    error_message = "The subnet_id must match the pattern ^subnet-[\\d|\\w]+$"
  }
}
```

**outputs.tf** (módulo filho):
```hcl
output "aws_instance_arn" {
  description = "The AWS Resource Name for the instance."
  value       = aws_instance.hello_world.arn
}
output "aws_instance_ip" {
  description = "IP Address for the private network interface."
  value       = aws_instance.hello_world.private_ip
}
output "aws_instance" {
  description = "The entire instance resource."
  value       = aws_instance.hello_world
}
```

**main.tf** (workspace de exemplo / root module):
```hcl
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter { name = "vpc-id"; values = [data.aws_vpc.default.id] }
}

module "test_instance" {
  source    = "../"
  subnet_id = data.aws_subnets.default.ids[0]
}

output "aws_instance_arn" {
  value = module.test_instance.aws_instance_arn
}
```

**O que demonstra**: separação entre módulo reutilizável (sem `provider` block) e workspace de teste (root module com `provider`); validação de input via regex; outputs compostos para permitir integração com outros módulos.

---

## Key Takeaways

1. **Módulos = unidade de reuso em Terraform** — empacote resources relacionados em módulos para que equipes usem sem conhecer os detalhes de implementação.
2. **Só o root module configura providers** — módulos filhos herdam ou recebem providers via argumento `providers`.
3. **Interface de módulo: inputs entram, outputs saem, locals ficam** — escreva módulos pensando em sua API pública.
4. **Adicione `type` e `validation` em todos os inputs** — pega erros antes do plan/apply, não durante.
5. **`sensitive = true` mascara logs mas não protege o state** — segurança do state é separada (Ch06).
6. **Map para chaves livres, object para chaves fixas** — regra prática para escolher entre os dois tipos.
7. **Variáveis Terraform são imutáveis** — toda lógica de transformação vai para `locals`.
8. **Convenção de nomes**: `terraform-PROVIDER-NAME` para repositórios; `variables.tf`, `outputs.tf`, `main.tf` para arquivos.

---

## Conecta Com

- **Ch04**: funções e expressões para transformar valores em `locals` e validações mais complexas.
- **Ch05**: DAG e como módulos participam do grafo de dependências; debugging de planos com módulos.
- **Ch06**: state management; por que `sensitive` não é suficiente para proteger segredos no state.
- **Ch08**: CI/CD e publicação de módulos em registries privados; convenções de versionamento.
- **Ch09**: `import`, `moved` e refactoring dentro de módulos; testes de módulos.
- **Ch10**: `preconditions` em outputs (mencionado em 3.4); validação avançada.
