# Capítulo 1: Visão Geral do Terraform

## Ideia Central
Terraform é a ferramenta padrão de IaC (Infrastructure as Code): define infraestrutura com linguagem declarativa (HCL), executa um grafo de dependências para atingir o estado desejado, e abstrai todos os vendors por trás de providers. OpenTofu é o fork open source criado após HashiCorp mudar a licença em 2023.

---

## Frameworks Introduzidos

### IaC como Prática de Engenharia de Software
- **Quando usar**: sempre que infraestrutura precisa ser criada, replicada, auditada ou colaborada em equipe.
- **Como**: versionar com Git, escanear com linters, testar em CI/CD — os mesmos processos de software aplicados à infra.
- **Benefício-chave**: infraestrutura vira bloco de construção reutilizável; melhorias propagam para todos os projetos que usam o módulo.

### Modelo de Abstração Terraform
```
Desenvolvedor → HCL (código declarativo)
              ↓
        Terraform Core (CLI)
              ↓
        Providers (plugins em Go, via gRPC)
              ↓
        APIs dos Vendors (AWS, GCP, Azure, DNS, SSO…)
```
- **Providers**: wrappers de API, um por vendor; >3.280 no Terraform Registry.
- **Backends**: onde o estado é armazenado (local, S3, GCS, AzureRM, HTTP…).
- **Workspaces**: deployments independentes de uma mesma codebase (produção, staging, feature ephemeral).

### Fluxo de Deployment (Init → Plan → Apply)
- **Quando usar**: toda vez que uma mudança precisa ser aplicada.
- **Como**:
  1. `terraform init` — baixa providers e módulos; inicializa backend.
  2. `terraform plan` — Refresh (lê estado real do vendor) → Compare (confronta com código) → Plan (gera DAG de ações).
  3. `terraform plan -out tfplan` — salva o plano para revisão antes do apply.
  4. `terraform apply tfplan` — executa as ações do plano na ordem definida pelo DAG.

---

## Conceitos-Chave

- **IaC (Infrastructure as Code)**: classe de tecnologia que permite provisionar infra usando práticas de código (versionamento, testes, revisão de PR).
- **HCL (HashiCorp Configuration Language)**: linguagem declarativa proprietária do HashiCorp; legível, usada por Terraform, Packer, Nomad e Consul.
- **Declarativa vs. Imperativa**: declarativa define o *estado final* desejado; imperativa define os *passos* para chegar lá.
- **DAG (Directed Acyclic Graph)**: grafo de ações ordenadas sem ciclos; base do plano Terraform. Garante ordem correta de criação de recursos.
- **Provider**: plugin que expõe recursos de um vendor ao Terraform; distribuído independentemente do core.
- **Backend**: configuração de onde o state file é armazenado; o backend local usa o filesystem local por padrão.
- **Workspace**: deployment específico de uma codebase com backend e variáveis próprias; análogo a uma instalação específica de um programa.
- **TACOS (Terraform Automation and Collaboration Software)**: plataformas de CI/CD especializadas em Terraform (HCP Terraform, Spacelift, Scalr, env0).
- **OpenTofu**: fork open source do Terraform, criado após a mudança de licença HashiCorp (BSL) em 2023; mantido pela Linux Foundation; superset do Terraform.
- **BSL (Business Source License)**: licença shared source — código visível, mas restringe construir produtos competitivos ao HashiCorp sem licença especial.

---

## Modelos Mentais

- **IaC como biblioteca de software**: use quando quiser que uma melhoria feita por um time se propague para todos que usam o módulo — igual a atualizar uma biblioteca de dependências.
- **Declarativo = nouns + adjectives; Imperativo = verbs**: ao escrever HCL, descreva *o que* você quer existir (a máquina, o bucket, o registro DNS), não *os passos* para criá-la.
- **Workspace = instalação de programa**: assim como você pode ter múltiplas instalações do mesmo software, cada workspace é independente — próprio estado, próprias variáveis, próprio lifecycle.
- **DAG = dependência implícita**: se o recurso A usa um valor do recurso B, Terraform infere automaticamente que B deve ser criado antes de A — sem necessidade de declaração explícita de ordem.

---

## Anti-patterns

- **Dependências circulares**: recurso A depende de B, B depende de C, C depende de A → nenhum pode ser criado. Capítulo 5 aborda soluções manuais.
- **Backend local em equipes**: state file no filesystem local torna o workspace acessível apenas da máquina do desenvolvedor; use remote backend desde o início.
- **Usar OpenTofu features exclusivas sem planejar migração**: OpenTofu é superset do Terraform; features extras do OpenTofu não funcionam em Terraform, tornando a volta difícil.

---

## Exemplo Trabalhado — Init → Plan → Apply

Adicionando uma instância EC2:

```bash
# 1. Inicializar — baixa o provider AWS
$ terraform init
# → Instala HashiCorp/aws v4.41.0
# → Cria .terraform.lock.hcl (pin de versão para VCS)

# 2. Planejar — calcula o DAG de mudanças
$ terraform plan -out tfplan
# Refresh: lê data sources (VPC, AMI, subnets) do AWS
# Plan: 1 to add, 0 to change, 0 to destroy
# Campos "known after apply" = valor só existe após criação

# 3. Aplicar — executa o plano
$ terraform apply tfplan
# aws_instance.hello_world: Creating... → Complete after 12s
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
# Outputs: aws_instance_arn = "arn:aws:ec2:..."
```

**O que demonstra**: o fluxo completo, como o plan salvo em arquivo garante que o apply executa exatamente o que foi revisado, e como outputs expõem valores criados dinamicamente.

---

## Casos de Uso Reais

| Caso | Benefício do Terraform |
|------|------------------------|
| Cluster de ML (70+ recursos: VPC, EFS, Redis, Lambda) | De semanas para minutos; iteração por desenvolvedor individual |
| Web services (LB, instâncias, SSL, DNS, subnets) | Módulo reutilizável: dev sobe serviço sem conhecer infra |
| SSO/Okta (grupos, políticas, roles) | Auditoria via Git; múltiplas aprovações via PR; rastreabilidade |
| Prototipagem rápida | Infra como ferramenta, não como obstáculo |

---

## Key Takeaways

1. **IaC aplica engenharia de software à infra**: versionamento, testes, revisão de PR — os mesmos benefícios.
2. **HCL declarativo = descreva o estado final**, não os passos; Terraform resolve a ordem de criação via DAG.
3. **Providers isolam o Terraform dos vendors**: troque AWS por GCP sem reescrever o core do workflow.
4. **Fluxo obrigatório: init → plan → apply**; salve o plan com `-out tfplan` para garantir que apply executa exatamente o que foi revisado.
5. **OpenTofu é drop-in replacement** para Terraform; use `tofu` CLI no lugar de `terraform`; compatível com todo o código HCL existente.
6. **Dependências circulares quebram o DAG** — o maior pitfall estrutural de linguagens declarativas.

---

## Conecta Com

- **Ch02**: todos os blocos HCL mencionados aqui (resources, data sources, outputs) são detalhados no capítulo 2.
- **Ch03**: módulos são o mecanismo de reuso/compartilhamento mencionado em IaC.
- **Ch05**: DAGs e debugging de planos em profundidade; soluções para dependências circulares.
- **Ch06**: backends remotos para state management em equipes.
- **Ch07–Ch08**: CI/CD (TACOS, GitHub Actions) para automatizar o fluxo init/plan/apply.
