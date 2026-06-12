# Capítulo 10: Advanced Terraform Topics

## Ideia Central

Este capítulo é uma coletânea de padrões avançados e ferramentas de nicho: naming hierárquico, subnetting dinâmico, provisioners, external/local providers, checks/conditions e limites do Terraform. Nem tudo se usa todo dia — mas quando o problema surgir, você vai agradecer por conhecer.

---

## Frameworks Introduzidos

### Naming Hierárquico
Nomes propagam-se de cima para baixo. O módulo raiz define `base_name = "${app}-${env}"`; submodules recebem o prefixo completo e adicionam sufixo descritivo. Recursos constroem sobre o nome do módulo.

- **Critérios de bom nome**: unique, human-readable, identifiable, sortable
- **Regra de ouro**: nunca incluir o tipo do recurso no nome — `logs` em vez de `logging_bucket`
- **Randomness para constraints específicas** (S3 namespace squatting, `aws_secretsmanager_secret` que não pode ser recriado): gerenciar dentro do módulo com `random_string`

### Subnetting Dinâmico com `cidrsubnet`
```hcl
cidrsubnet(cidr, bits, index)
# bits = quantos bits tomar; 2^bits = número de subnets
# index = qual subnet retornar (0-based)
```
Topologias:
- **2-tier**: 1 bit → public (map_public_ip=true + NAT gateway) + private (route table → NAT)
- **3-tier**: split em 2, depois split da segunda metade → private (maior) + public + isolated

Módulo high-level aceita `availability_zones` como número, calcula `subnet_bits` com ternário, usa `count` (não `for_each`) para AZs, retorna `spare_subnet_cidr_blocks` para os slots não usados.

### Provisioners — Last Resort
Criar arquivos e rodar comandos ao criar/destruir recursos. **Usar apenas quando não há alternativa.**

Problemas: ponto de falha extra, tempo adicional, menos portável, difícil de debugar.

### External Provider — Last Resort
`data "external"`: chama programa local, lê stdin (JSON do `query`), espera stdout (JSON com resultados). Único data source, zero resources. Usa quando não existe provider/data source nativo.

### Checks e Conditions
Validações em runtime dentro do Terraform — diferentes de testes do Ch09 (que rodam em dev).

---

## Conceitos-chave

- **`cidrsubnet(cidr, bits, index)`**: divide rede em 2^bits subnets, retorna a de índice `index`
- **`cidrnetmask(cidr)`**: retorna subnet mask de uma notação CIDR
- **`data "aws_availability_zones"`**: lista AZs disponíveis na region
- **NAT gateway**: permite private subnet acessar internet sem ser diretamente acessível
- **`connection` block**: SSH/WinRM; `self` referencia atributos do próprio recurso
- **`remote-exec`**: roda comandos na máquina remota (`inline`, `script`, `scripts`)
- **`local-exec`**: roda comando na máquina que executa o Terraform
- **`file` provisioner**: copia arquivo local → remoto (`source`/`content` + `destination`)
- **`when = destroy`**: provisioner roda ao destruir, não ao criar
- **`on_failure = continue`**: ignora falha do provisioner; default = `fail` (taint + stop)
- **Cloud-Init**: ferramenta open source para configuração de VMs na inicialização; alternativa principal a provisioners
- **`data "external"`**: `program` (array), `query` (map(string)), `working_dir`; resultado em `.result["key"]`
- **`provider::local::direxists()`**: função do local provider (v1.8+) para verificar diretório
- **`local_sensitive_file`**: igual a `local_file` mas marca conteúdo como sensitive
- **`precondition`/`postcondition`**: em `lifecycle`; bloqueiam execução se falham; `self` para auto-referência
- **`check` block** (v1.5+): não bloqueia execução; múltiplos `assert`; scoped data sources
- **`.tofu` files** (OpenTofu v1.8+): OpenTofu usa `.tofu` em vez de `.tf` quando ambos existem; Terraform ignora `.tofu`
- **Imutable infrastructure**: build image com software instalado; Cloud-Init só para configuração → evita provisioners
- **Artifact management fora do Terraform**: containers, libs, machine images devem ter CI/CD próprio

---

## Modelos Mentais

- **"Names flow down"** — raiz define base_name; cada nível adiciona sufixo; recursos herdam o prefixo completo do módulo
- **"Provision first, configure later"** — Packer constrói imagem (imutable); Cloud-Init configura na inicialização; Terraform só orquestra
- **"Check doesn't block, postcondition does"** — use `check` para monitorar saúde em produção; use `postcondition` para impedir misconfiguration
- **"External provider is a hack"** — se precisa de API calls, use HTTP provider; se precisa de lógica complexa, escreva um provider Go (Ch12)

---

## Exemplos de Código

### Naming Hierárquico — Módulo Raiz

```hcl
variable "environment" { type = string }

locals {
  application = "acme"
  base_name   = "${local.application}-${var.environment}"
  base_domain = "${var.environment}.${local.application}.${var.domain}"
}

module "api" {
  source = "./service"
  name   = "${local.base_name}-api"
  domain = "api.${local.base_domain}"
}

module "database" {
  source = "./db"
  name   = "${local.base_name}-db"
}
```

### Naming com Random para Constraints de Resource

```hcl
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.name}-${random_string.suffix.result}"
}
```

> `random_string` > `random_id` para nomes: mais entropia em menos chars. `random_password` marca como sensitive (ruim para nomes).

### cidrsubnet — Topologia 2-tier

```hcl
locals {
  private_subnet_cidr_block = cidrsubnet(var.cidr_block, 1, 0)
  public_subnet_cidr_block  = cidrsubnet(var.cidr_block, 1, 1)
}

resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.public_subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = { Network = "Public" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}
```

### cidrsubnet — Topologia 3-tier (split assimétrico)

```hcl
locals {
  private_subnet_cidr_block  = cidrsubnet(var.cidr_block, 1, 0)         # metade maior
  intermediary_block         = cidrsubnet(var.cidr_block, 1, 1)
  public_subnet_cidr_block   = cidrsubnet(local.intermediary_block, 1, 0)
  isolated_subnet_cidr_block = cidrsubnet(local.intermediary_block, 1, 1)
}
```

> Private fica com 50%; public e isolated dividem os outros 50%.

### Módulo High-Level com AZs Dinâmicas

```hcl
variable "availability_zones" {
  type = number
  validation {
    condition     = var.availability_zones > 0 && var.availability_zones <= 4
    error_message = "Must be between 1 and 4."
  }
}

locals {
  subnet_bits = var.availability_zones == 1 ? 0 : (var.availability_zones > 2 ? 2 : 1)
  subnet_count = pow(2, local.subnet_bits)

  spare_subnet_cidr_blocks = [
    for i in range(var.availability_zones, local.subnet_count)
    : cidrsubnet(var.cidr_block, local.subnet_bits, i)
  ]
}

data "aws_availability_zones" "available" { state = "available" }

# count (não for_each) para evitar dependência de valor desconhecido no plan
module "two_tier_subnets" {
  source            = "./modules/az_2"
  count             = var.enable_isolated_subnet ? 0 : local.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, local.subnet_bits, count.index)
}

locals {
  subnet_module = var.enable_isolated_subnet ? module.three_tier_subnets : module.two_tier_subnets
}

output "private_subnet_ids" {
  value = local.subnet_module[*].private_subnet_id  # splat operator
}
```

### Provisioner remote-exec

```hcl
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["sudo apt-get update", "sudo apt-get install -y nginx"]
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/install.sh"
  }
}
```

### Provisioner local-exec com destroy + on_failure

```hcl
resource "aws_instance" "main" {
  # ...
  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = "bash ${path.module}/deregister_instance.sh '${self.id}'"
  }
}
```

### terraform_data para provisioner multi-dependência

```hcl
resource "terraform_data" "provisioners" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.main.public_ip
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/initialize.sh"
  }

  depends_on = [aws_instance.main, aws_db_instance.main]
}
```

### External Provider — Bash simples

```hcl
data "external" "main" {
  program = ["bash", "${path.module}/square_root.sh", "128"]
}

output "result" {
  value = data.external.main.result["value"]
}
```

```bash
#!/usr/bin/env bash
a=$(bc <<<"scale=0; sqrt($1)")
echo "{\"value\":\"$a\"}"
```

### External Provider — Python com query

```hcl
data "external" "query" {
  program = ["python", "${path.module}/square_root.py"]
  query   = { "0" = "128", "1" = "256", "random" = "1024" }
}
```

```python
import json, math, sys
data = json.load(sys.stdin)               # query chega como JSON no stdin
return_data = {k: str(math.sqrt(float(v))) for k, v in data.items()}
json.dump(return_data, sys.stdout)        # resultado retorna como JSON no stdout
```

### Local Provider — direxists + local_file

```hcl
locals {
  file_exists = fileexists("${path.module}/example.txt")
  dir_exists  = provider::local::direxists("${path.module}/scripts/")  # v1.8+
}

resource "local_sensitive_file" "key" {
  content  = tls_private_key.main.private_key_pem
  filename = "${path.module}/private_key.pem"
}
```

### Precondition e Postcondition

```hcl
resource "aws_lb" "example" {
  # ...
  lifecycle {
    precondition {
      condition     = var.type == "application" ? true : var.ip_address_type != "dualstack-without-public-ipv4"
      error_message = "ip_address_type dualstack-without-public-ipv4 only valid for application LB."
    }
  }
}

data "aws_ami" "ubuntu" {
  # ...
  lifecycle {
    postcondition {
      condition     = timecmp(timestamp(), self.deprecation_time) == -1
      error_message = "Unable to find non-deprecated AMI."
    }
  }
}
```

> A partir do v1.9.0, blocos `validation` em `variable` também podem referenciar outras variáveis — use quando possível (mais fácil de encontrar que `precondition` em resource).

### Check Block com Scoped Data Source

```hcl
check "health_check" {
  data "http" "api" {
    url = "${module.api.url}/health"
    request_headers = { Accept = "application/json" }
    depends_on = [module.api]   # obrigatório quando não há dependência implícita
  }

  assert {
    condition     = data.http.api.status_code >= 200 && data.http.api.status_code < 300
    error_message = "Healthcheck failed with ${data.http.api.status_code}."
  }
}
```

### Tofu Files para Compatibilidade Dual-Engine

```hcl
# compatibility.tf — só lido pelo Terraform
locals { my_engine = "terraform" }
```

```hcl
# compatibility.tofu — OpenTofu usa este; ignora o .tf de mesmo nome
locals { my_engine = "tofu" }
```

### Container Version como Variável (CD-managed)

```hcl
variable "api_service_version" { type = string; default = "latest" }

resource "aws_ecs_task_definition" "this" {
  # ...
  lifecycle {
    ignore_changes = [container_definitions]  # CD tool gerencia a versão
  }
}
```

### Cloud-Init para Configuração de VM

```hcl
data "cloudinit_config" "node" {
  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      users = { admin = { ssh_authorized_keys = ["ssh-rsa AAAA..."] } }
    })
  }
  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/init.sh")
  }
}

resource "aws_instance" "node" {
  ami       = data.aws_ami.ubuntu.id
  user_data = data.cloudinit_config.node.rendered
}
```

---

## Tabelas de Referência

### Critérios de Bom Nome de Resource

| Critério | Por quê | Exemplo |
|----------|---------|---------|
| **Único** | Sistemas recusam duplicatas; evita confusão humana | `prod-api-lb` vs `dev-api-lb` |
| **Human-readable** | Humanos fazem manutenção | `prod-api-lb` > `abd236a` |
| **Identifiable** | Saber o que é sem contexto | `prod-api-lb` > `large-finch` |
| **Sortable** | Clustering natural em listagens | Prefixos `prod-`, `dev-` |

### Topologias de Rede

| Topologia | Subnets | Uso |
|-----------|---------|-----|
| 2-tier | public + private | Aplicações padrão |
| 3-tier | public + private + isolated | Dados altamente sensíveis |
| Single AZ | `subnet_bits = 0` | Dev/staging; sem HA |

### Quando Não Usar Terraform

| Caso | Ferramenta Correta |
|------|--------------------|
| Deploy em cluster Kubernetes | `kubectl`, Helm, ArgoCD |
| Build de container images | CI/CD (GitHub Actions, etc.) |
| Build de machine images | Packer |
| Gerenciar versão de container via CD | `ignore_changes = [container_definitions]` |
| Qualquer artifact packaging | Integration side, não Terraform |

### Provisioners e Alternativas

| Propósito | Provisioner | Alternativa Preferida |
|-----------|-------------|----------------------|
| Instalar software | `remote-exec` | Packer (imagem pré-built) |
| Configurar instância | `remote-exec` / `file` | Cloud-Init |
| Adicionar arquivos env-específicos | `file` | Cloud-Init |
| Shutdown customizado | `local-exec` (destroy) | Shutdown service no image |
| Salvar metadata de máquina | `local-exec` | `output` + local provider |

### Differences: precondition vs postcondition vs check

| Aspecto | `precondition` | `postcondition` | `check` |
|---------|---------------|-----------------|---------|
| Quando roda | Antes de criar | Após criar | Após criar |
| Bloqueia execução | Sim | Sim | Não |
| `self` disponível | Não | Sim | Não |
| Scoped data sources | Não | Não | Sim |
| Múltiplos asserts | Um por bloco | Um por bloco | Sim |
| Versão mínima | v1.x | v1.x | v1.5 |

---

## Exemplo Trabalhado — Módulo de Rede Reutilizável

**Cenário**: módulo que cria VPC com suporte a 1–4 AZs e 2 ou 3 tiers de subnet.

**Interface do usuário** (simples):
```hcl
module "network" {
  source                 = "./top_level"
  enable_isolated_subnet = true
  availability_zones     = 3
  cidr_block             = "192.168.0.0/16"
}
```

**Internamente**, o módulo:
1. Calcula `subnet_bits` → `availability_zones=3` precisa de 2 bits → 4 subnets, 1 spare
2. `data.aws_availability_zones` → lista AZs disponíveis
3. `count = local.subnet_count` → cria um módulo de location por AZ
4. Cada location module divide seu `cidr_block` com `cidrsubnet(var.cidr_block, 1, 0/1)`
5. Binary toggle: `enable_isolated_subnet ? module.three_tier : module.two_tier`
6. Splat `[*].private_subnet_id` → lista de IDs para uso por outros módulos

**Resultado para dev (1 AZ)**: 1 VPC, 1 public + 1 private subnet, 1 NAT gateway
**Resultado para prod (3 AZs)**: 1 VPC, 3 public + 3 private subnets, 3 NAT gateways

O **usuário** não precisa conhecer CIDR math — apenas passa `cidr_block` e `availability_zones`.

---

## Key Takeaways

1. Naming hierárquico: `base_name = "${app}-${env}"` → submodules herdam + sufixo; recursos herdam o nome do módulo
2. `random_string` encapsulado no módulo resolve constraints específicas de recursos (S3, secretsmanager) sem expor para usuários
3. `cidrsubnet(cidr, bits, index)` + `count` = módulo de rede dinâmico para qualquer número de AZs
4. Provisioners são last resort — Cloud-Init + Packer resolvem 95% dos casos com menos acoplamento
5. External provider = hack útil para edge cases; prefira HTTP provider ou custom provider Go
6. `local_file` útil em desenvolvimento (gerar configs de VPN local), problemático em produção (estado de arquivo não portátil)
7. `precondition` bloqueia misconfiguration antes de criar; `postcondition` valida resultado; `check` monitora saúde sem bloquear
8. `check` com scoped data sources = health checks em produção integrados ao Terraform state
9. `.tofu` files permitem código compatível TF/OTF com comportamento diferente por engine
10. Não use Terraform para: deploy em K8s, build de images, artifact packaging — essas são responsabilidades do CI/CD

---

## Anti-Patterns

- **Incluir tipo no nome do resource** — `my_s3_logs_bucket` em vez de `logs`; redundante e aumenta tamanho
- **Nomes sem prefixo de ambiente** — impossível distinguir `prod` de `dev` em buscas de log
- **Usar provisioners como atalho** — sempre perguntar "Cloud-Init pode fazer isso?" antes
- **External provider para redistribuição** — reduz portabilidade; outros times precisam de Python/Bash configurado
- **`local_file` em produção** — Terraform detecta drift quando roda de máquina diferente
- **check sem depends_on** — check roda no primeiro plan antes da infra existir → falha espúria
- **Build de container dentro do Terraform** — aumenta tempo de deploy; acopla app e infra
- **Provider Kubernetes para deploy em cluster** — abstração sobre abstração; use kubectl/Helm

---

## Conecta Com

- **[ch02]** — `lifecycle`, `precondition`/`postcondition` em recursos
- **[ch04]** — `for` expressions, `cidrsubnet`, funções de rede, `pow()`
- **[ch05]** — `count` vs `for_each`; plan-time unknown values
- **[ch09]** — testes vs checks: testes em dev, checks em produção
- **[ch12]** — alternative to external provider: custom provider em Go
