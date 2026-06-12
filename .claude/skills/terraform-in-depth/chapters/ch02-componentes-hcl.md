# Capítulo 2: Componentes HCL do Terraform

## Ideia Central
Terraform HCL é organizado em **blocos** — a construção primária da linguagem. Cada bloco tem um tipo, rótulos (labels), argumentos e subblocks. Os 12 tipos de blocos cobrem desde configuração do workspace até gerenciamento de infraestrutura. A ordem dos blocos no arquivo é irrelevante; Terraform determina a ordem de execução pelo DAG de dependências.

---

## Frameworks Introduzidos

### Anatomia de um Bloco HCL
```hcl
type "label" {              # tipo + rótulo = identificador único
  parametro1 = "valor"      # argumento (string, bool, number, object, null)
  parametro2 = 12

  subblock {                # subblock: pode ser repetido
    sub_param = "valor"
  }

  lifecycle {               # meta-argumento subblock: sempre no final
    ignore_changes = [ami]
  }
}
```
- **Blocos = substantivos** (nouns): representam infraestrutura e configuração.
- **Argumentos = adjetivos**: modificam o comportamento do bloco.
- **Atributos**: saídas exportadas por um bloco; usadas como argumentos em outros blocos.

### Os 12 Tipos de Blocos Terraform

| Tipo | Propósito |
|------|-----------|
| `terraform` | Configura o workspace: providers, backend, versão |
| `provider` | Configura um provider (credenciais, região) |
| `resource` | Cria/atualiza infraestrutura — o bloco mais importante |
| `data` | Lookup read-only de dados externos |
| `variable` | Input externo para módulo ou workspace |
| `locals` | Variáveis internas ao módulo |
| `module` | Abstração para reuso de código HCL |
| `import` | Importa infraestrutura existente para Terraform |
| `moved` | Renomeia/move recursos no state sem recriar |
| `removed` | Marca recurso como removido sem destruir |
| `check` | Valida infraestrutura após deploy |
| `output` | Expõe dados de um módulo para outros módulos |

### Tabela de Referência de Blocos

| Tipo | Subtype/1º Label | 2º Label | Referência Completa |
|------|-----------------|----------|---------------------|
| `resource` | `aws_instance` | `hello_world` | `resource.aws_instance.hello_world` (ou `aws_instance.hello_world`) |
| `data` | `aws_vpc` | `default` | `data.aws_vpc.default` |
| `variable` | `instance_type` | — | `var.instance_type` |
| `module` | `vpn` | — | `module.vpn` |

### Meta Argumentos de Lifecycle

**Quando usar cada um:**

| Meta argumento | Quando usar | Cuidado |
|----------------|-------------|---------|
| `create_before_destroy = true` | HA: novo recurso antes de destruir o antigo | Erro se recurso não permite dois simultâneos (IAM role, elastic IP) |
| `prevent_destroy = true` | Prevenir destruição acidental (logs de compliance) | Remove-se ao deletar o bloco; não use como regra geral |
| `ignore_changes = [ami]` | Ignorar mudanças em campos específicos após criação | Cuidado: pode mascarar drift real |
| `ignore_changes = all` | Recurso nunca é atualizado após criação | Torna o recurso efetivamente read-only |
| `replace_triggered_by = [recurso]` | Forçar substituição quando outro recurso muda | Deve referenciar resource/attribute, não variable |

---

## Conceitos-Chave

- **Block type**: primeira palavra do bloco; define como todo o resto é interpretado.
- **Labels**: identificadores do bloco; 0, 1 ou 2 dependendo do tipo.
- **Subtype**: primeiro label de `resource` e `data` — identifica o tipo de infraestrutura (ex: `aws_instance`, `aws_vpc`).
- **Atributos computados**: campos marcados como `(known after apply)` no plan — existem apenas após a criação do recurso.
- **Provider alias**: múltiplas configurações do mesmo provider (ex: dois `provider "aws"`, um por região).
- **`depends_on`**: dependência explícita quando não há ligação via atributos (ex: Internet Gateway → NAT Gateway).
- **`terraform fmt`**: comando que aplica automaticamente as regras de estilo HCL (alinhamento de `=`, ordenação de subblocks).
- **`required_providers`**: sempre declarar explicitamente para pinnar versão e evitar quebras.
- **Backend vs Cloud block**: `backend` para backends genéricos (S3, GCS); `cloud` específico para HCP Terraform.
- **Experimentos**: features instáveis, optin via `experiments = [...]`; evitar em produção.
- **`import` block**: importa infra existente para Terraform sem recriar; remover após uso.
- **`moved` block**: seguro deixar no código; renomeia recurso no state sem recriar.

---

## Modelos Mentais

- **Providers = SDKs de vendor**: assim como Python usa Boto3 para AWS, Terraform usa o AWS Provider — instala, configura, e usa os recursos que ele expõe.
- **Ordem de blocos ≠ ordem de execução**: escreva blocos em qualquer ordem; Terraform resolve o DAG pelos atributos usados como argumentos.
- **resource.aws_instance → nome é prefixado pelo provider**: `aws_instance` → provider `aws`; `linode_instance` → provider `linode`. Convenção universal.
- **Subblocks ≠ argumentos de objeto**: argumentos usam `=` e só podem aparecer uma vez; subblocks não usam `=` e podem ser repetidos.

---

## Anti-patterns

- **Hardcode de region no `provider`**: use variável — `region = var.aws_region`, não `region = "us-east-1"`.
- **Omitir `required_providers`**: Terraform infere o provider pelo nome mas não controla versão → código pode quebrar em nova versão do provider.
- **`prevent_destroy` como proteção principal**: não funciona se o `resource` block for deletado; prefira `ignore_changes`.
- **`ignore_changes = all` em produção**: recurso nunca acompanha o estado desejado após criação; use apenas em casos muito específicos.
- **Provider block dentro de módulo filho**: `provider` blocks só podem existir no módulo raiz; passe o alias via argumento `providers`.

---

## Exemplo Trabalhado — Hello World Completo

Estrutura de arquivos recomendada:
```
projeto/
├── providers.tf    # terraform{} e provider{}
├── lookups.tf      # data sources
└── main.tf         # resources e outputs
```

**providers.tf:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"   # use var em produção
}
```

**lookups.tf:**
```hcl
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]   # atributo do bloco acima
  }
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]         # Canonical (Ubuntu)
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

**main.tf:**
```hcl
resource "aws_instance" "hello_world" {
  ami           = data.aws_ami.ubuntu.id
  subnet_id     = data.aws_subnets.default.ids[0]
  instance_type = "t3.micro"

  lifecycle {
    ignore_changes = [ami]              # novo AMI não recria instância
  }
}
```

**O que demonstra**: separação de arquivos por responsabilidade, uso de `data` para lookup dinâmico (sem hardcode de AMI ou subnet), e `lifecycle.ignore_changes` para estabilidade de instâncias existentes.

---

## Tabelas de Referência

### Estilo HCL — Ordem dentro de um bloco
```
1. Meta argumentos simples (provider = aws.west)
2. Argumentos específicos do recurso (alinhados com =)
3. Subblocks específicos do recurso
4. lifecycle {} — sempre por último
```

### Provider Aliases — Multi-região
```hcl
provider "aws" {
  region = "us-east-1"           # default
}
provider "aws" {
  alias  = "west"
  region = "us-west-2"           # alias
}

resource "aws_instance" "backup" {
  provider = aws.west            # usa o alias
  ...
}
```

---

## Key Takeaways

1. **Tudo em Terraform é um bloco**; entender o tipo de bloco é entender a linguagem.
2. **`resource` é o bloco mais importante** — os outros blocos existem para dar suporte a ele.
3. **Ordem de blocos não importa** — o DAG de dependências resolve a ordem de execução.
4. **Sempre declarar `required_providers`** com versão explícita; nunca deixar Terraform inferir.
5. **`lifecycle.ignore_changes`** é o meta argumento mais usado; prefira-o ao `prevent_destroy`.
6. **`data` sources = lookup read-only** — use para AMI mais recente, subnet IDs, VPC IDs — nunca hardcode valores que mudam.
7. **`depends_on`** para dependências sem ligação de atributos (Internet Gateway → NAT Gateway).
8. **`moved` block é seguro deixar no código** após renomear; `import` block deve ser removido após uso.

---

## Conecta Com

- **Ch03**: `variable`, `locals`, `output` — entradas e saídas de módulos.
- **Ch04**: expressões e iterações dentro de argumentos.
- **Ch05**: planos e DAG em profundidade; debugging de dependências.
- **Ch06**: backends para state management em equipes.
- **Ch09**: `import`, `moved`, `removed` em detalhe para refactoring e migração.
