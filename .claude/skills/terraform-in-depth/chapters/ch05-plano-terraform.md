# Capítulo 5: O Plano Terraform

## Ideia Central
O Terraform usa um DAG (directed acyclic graph) para representar infraestrutura internamente. Essa estrutura permite calcular dependências, paralelizar criações e gerar um plano determinístico antes de qualquer mudança. Entender o DAG explica a maior parte dos erros e comportamentos surpreendentes do Terraform.

---

## Frameworks Introduzidos

### DAG — Directed Acyclic Graph

**O que é:**
- **Grafo**: conjunto de nós (recursos) e arestas (dependências).
- **Directed**: dependências têm direção (A depende de B ≠ B depende de A).
- **Acyclic**: nenhuma dependência pode formar um ciclo.

**Por que importa:** IaC representa infraestrutura naturalmente como DAG — recursos têm dependências, mas dependências circulares são impossíveis na realidade física (você não pode criar uma VPC que depende das suas próprias subnets).

**Quando usar o modelo mental:** sempre que Terraform se comportar de forma inesperada — a causa está quase sempre na estrutura do grafo.

---

### Grafo de Recursos do Terraform

Três tipos de nós no resource graph interno:

| Nó | Representa |
|----|-----------|
| **Resource** | Um recurso ou data source (um por instância de `count`/`for_each`) |
| **Provider Configuration** | Uma configuração de provider (uma por alias) |
| **Resource Meta** | Grupo de recursos com `count > 1` — apenas para visualização |

**Insight crítico:** módulos **não existem** no grafo. Os recursos de módulo filho são "achatados" no grafo junto com os do módulo raiz. Consequência: recursos de módulo B podem ser criados antes do módulo A mesmo que B "dependa" de A — Terraform só respeita dependências entre resources individuais.

---

### Modos de Plano

| Modo | Flag | O que faz |
|------|------|-----------|
| **default** | (nenhum) | Compara código vs estado, gera mudanças necessárias |
| **destroy** | `-destroy` | Planeja destruição de todos os recursos gerenciados |
| **refresh-only** | `-refresh-only` | Atualiza estado local sem mudar infraestrutura |

---

### Métodos de Input Variables (precedência alta → baixa)

1. `-var` e `-var-file` (último na CLI vence)
2. `*.auto.tfvars` / `*.auto.tfvars.json` (ordem lexicográfica)
3. `terraform.tfvars.json`
4. `terraform.tfvars`
5. Variáveis de ambiente `TF_VAR_<nome>`
6. Input interativo (ou erro se `-input=false`)

---

## Conceitos-Chave

- **Speculative plan**: plan sem `-out` — não se pretende aplicar; útil para review em PRs.
- **Plan file** (`.tfplan`): formato binário; use `terraform show <file>` para ler, `-json` para parsear programaticamente.
- **`terraform graph`**: gera dot file com o grafo; pipe para `dot -Tpng > graph.png` via GraphViz.
- **`-replace`**: força destruição + recriação de resource específico; mostra cascata de impactos no plano antes de aplicar. Substitui `terraform taint` (deprecated).
- **Resource targeting** (`-target`): limita plan/apply a recursos específicos. Anti-pattern — nunca use em módulos que precisem disso para funcionar; apenas para debug emergencial.
- **`-refresh=false`**: pula refresh; plano sem dados atuais → alta probabilidade de falha no apply. Evitar.
- **`terraform refresh`**: deprecated; use `terraform apply -refresh-only`. O `refresh` direto pode remover recursos do estado quando credenciais expiram.
- **`-parallelism=n`**: padrão 10 ações simultâneas; reduzir para 1 facilita debug de logs.
- **`-lock=false`**: desabilita lock de estado; aceitável apenas para speculative plans.
- **`-auto-approve`**: aplica sem confirmação — conveniente em destroy local, perigoso em produção.
- **Eternal drift**: mudança sempre detectada no plan mesmo após apply — bug de provider (type mismatch entre API e estado Terraform).
- **`depends_on`**: cria dependência explícita quando não há referência de atributo entre recursos (ex: NAT Gateway → Internet Gateway).

---

## Tabela de Referência: Arquivos de Variáveis

| Extensão | Formato | Carregamento |
|----------|---------|--------------|
| `*.tfvars` | HCL | `-var-file` flag |
| `*.auto.tfvars` | HCL | Automático |
| `terraform.tfvars` | HCL | Automático |
| `*.tfvars.json` | JSON | `-var-file` flag |
| `*.auto.tfvars.json` | JSON | Automático |
| `terraform.tfvars.json` | JSON | Automático |

---

## Comandos de Referência

```bash
# Visualizar grafo como PNG
terraform graph | dot -Tpng > graph.png
terraform graph -type=apply -plan=create.tfplan | dot -Tsvg > apply.svg

# Plano com arquivo de saída (recomendado)
terraform plan -out=plan.tfplan
terraform show plan.tfplan              # human-readable
terraform show -json plan.tfplan        # machine-readable

# Modos alternativos de plano
terraform plan -destroy -out=destroy.tfplan
terraform plan -refresh-only

# Substituir recurso específico (sempre use aspas simples no shell)
terraform plan -replace='aws_instance.web[0]'

# Aplicar
terraform apply plan.tfplan             # com arquivo (sem confirmação)
terraform apply                         # plano + apply + confirmação
terraform apply -auto-approve           # sem confirmação (usar com cautela)
terraform destroy                       # alias para apply -destroy

# Input variables
terraform plan -var 'vpc=vpc-01234567890abcdef' -var 'num_instances=2'
terraform plan -var-file=production.tfvars
terraform plan -input=false             # erro se faltam inputs (obrigatório em CI)

# Debug
TF_LOG=debug terraform plan -parallelism=1
```

---

## Exemplo Trabalhado — Módulo TLS (DAG em Ação)

O exemplo canônico do capítulo é um módulo de CA de desenvolvimento:

```hcl
# Dependency chain: ca_key → ca_cert → child_certificates
#                   child_key[domain] → child_request[domain] → child_certificate[domain]

resource "tls_private_key" "ca_key" {
  algorithm = "ED25519"
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem   = tls_private_key.ca_key.private_key_pem  # dep: ca_key
  is_ca_certificate = true
  validity_period_hours = 24
  allowed_uses = ["digital_signature", "cert_signing", "crl_signing"]
}

resource "tls_private_key" "child_key" {
  for_each  = var.domains
  algorithm = "ECDSA"
}

resource "tls_cert_request" "child_request" {
  for_each        = var.domains
  private_key_pem = tls_private_key.child_key[each.value].private_key_pem  # dep: child_key
}

resource "tls_locally_signed_cert" "child_certificate" {
  for_each           = var.domains
  cert_request_pem   = tls_cert_request.child_request[each.value].cert_request_pem  # dep: request
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem                       # dep: ca_key
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem                         # dep: ca_cert
  validity_period_hours = 12
  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}
```

**O que demonstra:**
- `ca_key` e `child_key[*]` não têm dependências → criados em paralelo.
- `ca_cert` aguarda `ca_key`; `child_request[d]` aguarda `child_key[d]`.
- `child_certificate[d]` aguarda tanto a cadeia da CA quanto o seu `child_request[d]`.
- Mudança em `ca_key.algorithm` → cascata: `ca_cert` + todos `child_certificate[*]` são recriados (5 de 11 recursos).
- Saída de plan lida de baixo para cima = ordem de criação (recursos sem dependências ficam no fundo).

---

## Anti-patterns

- **`-replace` sem revisar o plano**: uma substituição pode cascatear para dezenas de recursos dependentes. Sempre revisar.
- **`terraform taint`**: deprecated; use `-replace`. Problema: modifica estado imediatamente, sem preview.
- **Resource targeting em produção**: módulos que exigem `-target` para funcionar são anti-pattern — indica arquitetura quebrada.
- **`-refresh=false`**: plano baseado em estado desatualizado → apply propenso a erros.
- **`terraform refresh`**: deprecated e perigoso — pode apagar recursos do estado com credenciais expiradas.
- **`-auto-approve` em apply de produção**: remove a última barreira de segurança antes de mudanças reais.
- **Secrets em `-var` ou `.tfvars` em VCS**: qualquer dos dois pode vazar. Use secret manager ou CI/CD com suporte a secrets.
- **Circular dependencies**: sinal de arquitetura excessivamente acoplada. Solução: quebrar o link substituindo referência de resource por variável/local com o mesmo valor.
- **`count`/`for_each` com valores de resource attributes**: falha no plan. Substituir por `var.*` ou `local.*` calculado de inputs conhecidos.
- **Múltiplos apply em sequência como workaround**: "horrible practice" — refatorar o código.

---

## Erros Comuns e Soluções

### Circular Dependency
```
Error: Cycle: null_resource.alpha, null_resource.bravo, null_resource.charlie
```
**Solução:** quebrar o link de referência; usar variável intermediária em vez de atributo de resource.

### count/for_each com valor calculado
```
Error: Invalid for_each argument
│ The "for_each" value depends on resource attributes that cannot be
│ determined until apply...
```
**Solução:** substituir `aws_route53_record.example.name` por `var.domain` diretamente no local que alimenta o `count`.

### Always detected changes (eternal drift)
Causa: type mismatch (int vs float, bool vs string, lista reordenada).
**Solução:** ajustar input para coincidir com o formato retornado pela API; reportar ao tracker do provider.

### Hidden dependency
Sintoma: resource falha ao criar porque dependência não existe ainda.
**Solução:** adicionar `depends_on` explícito.

---

## Modelos Mentais

- **Plano = snapshot de diff**: o `.tfplan` binário é o diff completo entre estado atual e estado desejado. `terraform show` traduz para humano; `-json` para máquinas.
- **Apply executa o grafo do plano**: recursos sem dependências são criados em paralelo (até `parallelism`); cada resource espera seus antecessores no DAG.
- **Destroy inverte a ordem do grafo**: dependentes são destruídos antes das dependências — oposto do create.
- **Módulo = namespace, não barreira**: fronteiras de módulo somem no resource graph. Terraform pode intercalar recursos de módulos diferentes se o DAG permitir.

---

## Key Takeaways

1. **DAG define tudo**: ordem de criação, paralelismo, e a maioria dos erros vêm da estrutura do grafo.
2. **Sempre salvar plan com `-out`** em automação; speculative plans sem `-out` não garantem reprodutibilidade.
3. **Ler o plano de baixo para cima**: recursos no fundo = sem dependências = primeiros a serem criados.
4. **`forces replacement` no plan = perigo**: uma mudança pequena pode cascatear por toda a árvore de dependências.
5. **`-replace` substituiu `taint`**: sempre use `-replace` para ver o impacto antes de aplicar.
6. **`count`/`for_each` exigem valores conhecidos no plan**: nunca depender de atributos de resources ainda não criados.
7. **`terraform refresh` é deprecated**: usar `terraform apply -refresh-only` que pede confirmação antes.
8. **Precedência de variáveis**: `-var`/`-var-file` > `auto.tfvars` > `terraform.tfvars` > env vars > input interativo.

---

## Conecta Com

- **Ch02**: `lifecycle.ignore_changes` — usado para suprimir cascata de replacements em atributos não relevantes.
- **Ch04**: `count`/`for_each` — limitação de valores calculados explicada aqui pelo mecanismo do DAG.
- **Ch06**: state management, backends, locking — continuação direta das seções de refresh e lock deste capítulo.
- **Ch07**: CI/CD, speculative plans, `-input=false` em automação.
- **Ch10**: `preconditions`/`postconditions` e `null_resource` — mencionados brevemente aqui.
- **Ch11**: output JSON do CLI (`-json`) para integração programática com planos.
