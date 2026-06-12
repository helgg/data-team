# Capítulo 4: Expressões e Iterações

## Ideia Central
Expressões são tudo à direita de um `=` em HCL. Este capítulo cobre os operadores, a biblioteca padrão de funções, templates de strings, e os dois mecanismos de iteração do Terraform: `count`/`for_each` para criar múltiplos recursos, e `for` para transformar coleções. Juntos, permitem módulos verdadeiramente dinâmicos — recursos que se habilitam/desabilitam, multiplicam-se, e derivam configuração de forma declarativa.

---

## Frameworks Introduzidos

### Operadores

**Matemáticos:**
```hcl
locals {
  zones    = min(var.az_count, 3)   # min() — função matemática
  subnets  = local.zones * 2        # * operador
}
```
Operadores: `+` `-` `*` `/` `%`

**Comparação:** `==` `!=` `<` `<=` `>` `>=`
- `"15" == 15` → `false` (tipos diferentes; use `tonumber("15") == 15`)

**Booleanos:** `||` `&&` `!`

**Ternário (condicional):**
```hcl
count = var.enable_ssm ? 1 : 0   # boolean → liga/desliga recurso
```
- Terraform avalia **ambos** os lados mesmo que só um seja retornado — use `try()` quando um lado pode não existir.

**Ordem de precedência** (maior → menor): `!` `-unário` → `* / %` → `+ -` → `> >= < <=` → `== !=` → `&&` → `||`

---

### Padrão: Toggle de Recurso com Ternário + count
```hcl
variable "enable_ssm" { type = bool; default = false }

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.ssm_arn.arn
}
```
**Quando usar**: qualquer feature opcional em módulo. Bool input → `count = var.enable ? 1 : 0`.

---

### Funções

Funções transformam dados; não executam ações (sem I/O, sem side effects).

**Categorias da stdlib:**

| Categoria | Exemplos |
|-----------|---------|
| Numeric | `min`, `max`, `abs`, `ceil`, `floor` |
| String | `upper`, `lower`, `split`, `startswith`, `replace`, `substr` |
| Collection | `merge`, `concat`, `length`, `toset`, `element`, `flatten` |
| Encoding | `jsonencode`, `yamlencode`, `base64encode` |
| Filesystem | `file`, `templatefile` |
| Date/Time | `timestamp`, `formatdate` |
| Hash | `md5`, `sha256` |
| IP Network | `cidrsubnet`, `cidrhost` |
| Type Conversion | `tostring`, `tonumber`, `tobool`, `tolist`, `tomap`, `toset` |

> A partir de Terraform/OpenTofu v1.8, providers podem adicionar funções próprias.

**Funções puras vs impuras:**
- **Pura**: mesmo input → mesmo output (ex: `upper`, `length`).
- **Impura**: resultado varia a cada chamada (`timestamp()`, `uuid()`).
- **Problema**: função impura em argumento de resource → Terraform detecta drift *sempre* após apply.

```hcl
# ANTI-PATTERN: uuid() gera novo valor a cada plan
resource "aws_instance" "bad" {
  tags = { id = uuid() }   # sempre "mudado"
}
```

---

### Templates de String

**`file(path)`** — carrega arquivo como string estática:
```hcl
user_data = file("${path.module}/files/cloud-init.txt")
```

**`templatefile(path, vars)`** — arquivo com interpolação + lógica:
```hcl
user_data = templatefile("${path.module}/templates/cloud-init.tftpl", {
  services = ["nomad", "consul"],
  hostname = "${var.name}-nomad"
})
```

**Linguagem de template** (dentro de `.tftpl`):
```
%{ if enable_feature }
feature_flag = 1
%{ else }
feature_flag = 0
%{ endif }

%{ for key, value in variable_object }
${key} = ${value}
%{ endfor }
```

**Quando NÃO usar template:** se Terraform tem suporte nativo ao formato (JSON, YAML, IAM policies), use funções de encoding:
```hcl
locals {
  config = { name = var.name, enabled = true }
  json   = jsonencode(local.config)   # correto
  yaml   = yamlencode(local.config)   # correto
}
```

`template_file` (data source) → **deprecated**; substitua por `templatefile()`.

---

### count vs for_each

| | `count` | `for_each` |
|--|---------|------------|
| Input | `number` | `map`, `object`, `set` |
| Variável interna | `count.index` | `each.key`, `each.value` |
| Acesso a atributo | `resource.name[0]` | `resource.name["key"]` |
| Reordenação | pode recriar recursos | estável (chave imutável) |
| Valor deve ser conhecido em plan | sim | sim |

```hcl
# count — número simples
resource "aws_instance" "servers" {
  count         = var.num_instances
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  instance_type = "t3.micro"
}

# for_each — configurações por chave
locals {
  machines = {
    "web"        = { type = "t3.nano" }
    "background" = { type = "t3.micro" }
  }
}
resource "aws_instance" "fleet" {
  for_each      = local.machines
  instance_type = each.value.type
  tags          = { Name = each.key }
}
```

---

### for Expression — Transformar Coleções

```hcl
# lista → lista transformada
[for item in var.list : "prefix-${item}"]

# lista → lista filtrada
[for x in var.numbers : x if x % 2 == 0]

# lista → objeto  (usa {} e =>)
{ for s in var.list : s => md5(s) }

# objeto → lista de pares
[for k, v in var.obj : "${k}=${v}"]

# grouping mode (...)
{ for server in aws_instance.main[*] : server.subnet_id => server.id... }
```

---

### Splat `[*]` — Atalho para for

```hcl
# equivalentes:
[for x in module.instances : x.aws_instance_ip]
module.instances[*].aws_instance_ip

# converte single value → list de um elemento:
vpc_security_group_ids = var.sg_id[*]
```

---

### Dynamic Blocks — Subblocks Dinâmicos

```hcl
variable "sg_rules" {
  type = list(object({ from_port=number, to_port=number, protocol=string, cidr_blocks=list(string) }))
}

resource "aws_security_group" "main" {
  dynamic "ingress" {
    for_each = var.sg_rules          # itera sobre a lista
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}

# toggle de subblock:
dynamic "ingress" {
  for_each = var.enable_https ? ["placeholder"] : []
  content { from_port = 443; to_port = 443; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
}
```

---

## Conceitos-Chave

- **Expressão**: qualquer valor à direita de `=`; pode ser literal, referência, operação, ou chamada de função.
- **`terraform console`**: REPL interativo para testar funções e expressões sem criar recursos.
- **`try(expr, default)`**: retorna o primeiro argumento sem erro; use para atributos de recursos opcionais (`try(resource.name[0].id, null)`).
- **`can(expr)`**: retorna `bool` — `false` se expressão gerar erro. Use exclusivamente em `validation` blocks.
- **`sensitive(value)` / `nonsensitive(value)`**: cria novo valor com flag de sensibilidade alterada; o original não muda.
- **`regex(pattern, str)`**: retorna match ou erro se não encontrar. Retorno varia: string (sem grupos), lista (grupos não-nomeados), mapa (grupos nomeados).
- **`regexall(pattern, str)`**: retorna lista de todos os matches; lista vazia se não encontrar (sem erro).
- **Regex syntax**: Terraform usa Golang regex — use Regex101 no modo Go para testar.
- **`path.module` / `path.root` / `path.cwd`**: valores especiais para caminhos relativos ao módulo.
- **`for_each` limitação**: o valor passado deve ser conhecido no início da fase de plan — não pode depender de atributos de recursos a serem criados.

---

## Modelos Mentais

- **Funções = transformações de dados, não ações**: em Terraform, funções nunca fazem I/O ou chamadas de API — apenas calculam um novo valor. Para "fazer algo", use resource ou data source.
- **`count` = quantos; `for_each` = quem**: se os recursos são idênticos exceto pelo número, use `count`. Se cada um tem identidade própria (nome, configuração diferente), use `for_each`.
- **`for` expression ≠ loop imperativo**: não modifica coleção existente; cria uma *nova* coleção transformada. Declarativo puro.
- **`dynamic` block = subblock multiplicado por for_each**: a única forma de gerar um número variável de subblocks sem repetir código.

---

## Anti-patterns

- **Funções impuras em argumentos de resource** (`uuid()`, `timestamp()`): plan sempre detecta drift. Use providers `random` e `time`.
- **Templates para JSON/YAML**: propenso a erros de escape; use `jsonencode`/`yamlencode`.
- **`for_each` com lista**: erro em runtime. Converta para `set` com `toset()`, mas entenda que duplicatas serão removidas e a ordem perdida.
- **`for_each`/`count` com valores calculados de outros resources**: Terraform exige que os valores sejam conhecidos no início do plan. Refatore para usar `count` com locals intermediários.
- **Múltiplos `apply` em sequência como workaround**: anti-pattern documentado pelo próprio livro — "horrible practice". Refatore o código.
- **Misturar `count` e `for_each` no mesmo block**: erro de sintaxe — use apenas um.
- **`nonsensitive()` sem justificativa documentada**: pode vazar dados sensíveis para logs.

---

## Exemplo Trabalhado — Módulo EC2 Expandido

```hcl
# variables.tf
variable "name_prefix"            { type = string }
variable "instance_count"         { type = number; default = 1 }
variable "tags"                   { type = map(string); default = {} }
variable "enable_systems_manager" { type = bool; default = false }

# main.tf — IAM role para o EC2
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions    = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ec2.amazonaws.com"] }
  }
}

resource "aws_iam_role" "main" {
  name               = "${var.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "main" {
  name = aws_iam_role.main.name
  role = aws_iam_role.main.name
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_systems_manager ? 1 : 0   # toggle pattern
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.ssm.arn
}

resource "aws_instance" "main" {
  count                = var.instance_count          # múltiplas instâncias
  ami                  = data.aws_ami.ubuntu.id
  subnet_id            = var.subnet_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.main.name

  tags = merge(var.tags, {                           # merge: combina maps
    Name = "${var.name_prefix}-${count.index}"       # nome único por índice
  })
}

# outputs.tf
output "instance_ips" {
  value = aws_instance.main[*].private_ip            # splat → lista de IPs
}
output "iam_role" {
  value = aws_iam_role.main                          # expõe role para o caller
}
```

**Chamada do módulo:**
```hcl
module "fleet" {
  source                 = "github.com/user/terraform-aws-in-depth//modules/ec2"
  name_prefix            = "production"
  instance_count         = 5
  enable_systems_manager = true
  tags                   = { BillingGroup = "platform" }
}
```

---

## Key Takeaways

1. **Ternário `cond ? a : b` + `count`** = padrão universal para features opcionais em módulos.
2. **Funções transformam dados** — sem side effects; resultado depende só dos inputs.
3. **`timestamp()` e `uuid()` em resource arguments** = drift perpétuo; use providers `random`/`time`.
4. **`for_each` > `count`** quando recursos têm identidade própria — menos recreações em mudanças.
5. **`for_each`/`count` exigem valor conhecido no plan** — não pode depender de atributos de outros resources a serem criados.
6. **`templatefile` para templates; `jsonencode`/`yamlencode` para estruturas de dados** — nunca template para JSON/YAML.
7. **`dynamic` block** é a única forma de gerar subblocks variáveis; sintaxe confusa mas essencial para security groups, tags customizadas, etc.
8. **`try(expr, null)`** para atributos de recursos opcionais (count 0 ou 1); `can(expr)` exclusivamente em `validation`.

---

## Conecta Com

- **Ch03**: `variable` blocks com `validation` — este capítulo expande as funções usadas nas validações.
- **Ch05**: como o Terraform constrói o plan a partir do DAG; por que `count`/`for_each` precisam de valores conhecidos.
- **Ch06**: providers `random` e `time` como alternativa às funções impuras.
- **Ch08**: `for_each` com configurações complexas em contexto de CI/CD.
- **Ch10**: `preconditions` e `postconditions` — validação além do `validation` block.
