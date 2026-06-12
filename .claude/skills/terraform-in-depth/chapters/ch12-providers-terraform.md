# Capítulo 12: Terraform Providers

## Ideia Central

Construir um provider Terraform é a forma de expor qualquer sistema externo como recursos gerenciáveis — mas requer Go, segue interfaces rígidas do Plugin Framework, e é necessário apenas para plataformas sem provider existente, plataformas internas, ou conjuntos de funções utilitárias.

## Frameworks Introduzidos

- **Terraform Plugin Framework (Protocol v6)**: SDK atual para criar providers em Go; abstrai gRPC entre Terraform e provider; substitui SDKs anteriores
  - Quando usar: sempre — é o padrão atual
  - Como: implementar interfaces `provider.Provider`, `datasource.DataSource`, `resource.Resource`, `function.Function`

- **Provider Scaffolding Template**: template oficial HashiCorp para bootstrap de providers
  - Quando usar: início de todo novo provider
  - Como: clonar → renomear módulo Go (`go mod edit -module`) → limpar arquivos HashiCorp-específicos (`.copywrite.hcl`, `CODEOWNERS`) → `go mod tidy`

- **Developer Overrides**: mecanismo para usar provider local sem publicar
  - Quando usar: desenvolvimento e testes locais
  - Como: `go install` → editar `~/.terraformrc` com bloco `dev_overrides`

## Conceitos-chave

- **Plugin Framework**: biblioteca Go que abstrai protocolo gRPC entre Terraform e providers; suporta Protocol v6
- **Schema**: estrutura de dados que define parâmetros, atributos e valores de configuração; usado em providers, resources e data sources
- **Diagnostics**: objeto `resp.Diagnostics` para acumular múltiplos erros sem interromper processamento; `.AddAttributeError`, `.AddError`, `.HasError`
- **tflog**: pacote de logging do framework; usar em vez de `log`; mapeia aos níveis de `TF_LOG`; suporta mascaramento de valores sensíveis (`MaskFieldValuesWithFieldKeys`)
- **Computed**: atributo calculado pelo provider, não fornecido pelo usuário; não disponível no plan
- **UseStateForUnknown**: plan modifier que evita "Attribute known after apply" para campos que não mudam entre apply
- **Acceptance tests (`TestAcc*`)**: testes que chamam API real; ativados por `TF_ACC=1`; executam via `make testacc`
- **Unit tests (`Test*`)**: testes sem dependência externa; usados principalmente para functions
- **CRUD**: Create, Read, Update, Delete — as quatro operações de um resource
- **ImportState**: função opcional de resource para importar recursos existentes ao state
- **FunctionData**: **não existe** — functions nunca têm acesso a clientes externos; são pure logic
- **tfplugindocs**: ferramenta que gera docs markdown a partir dos campos `MarkdownDescription` do schema; ativada via `go generate`
- **dev_overrides**: bloco em `~/.terraformrc` que aponta Terraform para provider binário local durante desenvolvimento
- **State normalization**: quando servidor modifica campos (ex: HTML wrapping em conteúdo), o provider deve normalizar para evitar state drift
- **tfsdk tag**: tag Go struct que mapeia campo Go ao nome do atributo no schema Terraform

## Modelos Mentais

- **Provider = fábrica de recursos**: o provider configura o cliente uma vez em `Configure` e distribui para todos os data sources e resources via `DataSourceData`/`ResourceData`
- **Schema = contrato com o usuário**: define o que o usuário pode/deve fornecer vs. o que o provider calcula
- **Read é o árbitro da verdade**: toda normalização feita em Create deve também ser feita em Read — ou haverá state drift perpétuo
- **Functions = pure logic, sem efeitos colaterais**: nunca alcançam serviços externos; por isso não têm `FunctionData` e usam `resource.UnitTest` (não `TestAcc`)
- **Não interrompa no primeiro erro**: acumule todos os erros em `Diagnostics` antes de `return`; nunca use `log.Fatal`

## Anti-patterns

- **Usar `log.Fatal` ou `os.Exit`**: mata o processo sem retornar erros ao Terraform; pode corromper state
- **Retornar no primeiro erro de `Configure`**: priva o usuário de ver todos os problemas de configuração de uma vez
- **Esquecer normalização em Read**: se Create strip HTML mas Read não, cada `terraform plan` mostra drift
- **Functions acessando serviços externos**: violam o modelo de funções puras; usam `FunctionData` que não existe
- **Não registrar recurso/data source/function no provider**: objeto implementado mas nunca exposto ao Terraform

## Exemplos de Código

### Provider: ~/.terraformrc com dev_overrides
```hcl
provider_installation {
  dev_overrides {
    "terraformindepth/mastodon" = "/Users/tedivm/go/bin/"
  }
  direct {}
}
```

### Provider: Struct modelo com tfsdk tags
```go
type MastodonProviderModel struct {
    Host         types.String `tfsdk:"host"`
    ClientID     types.String `tfsdk:"client_id"`
    ClientSecret types.String `tfsdk:"client_secret"`
    Email        types.String `tfsdk:"email"`
    Password     types.String `tfsdk:"password"`
    AccessToken  types.String `tfsdk:"access_token"`
}
```

### Provider: Schema com Sensitive e Optional
```go
func (p *MastodonProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
    resp.Schema = schema.Schema{
        Attributes: map[string]schema.Attribute{
            "host": schema.StringAttribute{
                MarkdownDescription: "Mastodon host to connect to.",
                Optional:            true,
            },
            "client_secret": schema.StringAttribute{
                MarkdownDescription: "Client Secret for Mastodon App.",
                Optional:            true,
                Sensitive:           true, // filtrado dos logs
            },
            "access_token": schema.StringAttribute{
                Optional:  true,
                Sensitive: true,
            },
        },
    }
}
```

### Provider: Configure — padrão de validação por atributo
```go
func (p *MastodonProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
    var data MastodonProviderModel
    tflog.Debug(ctx, "mastodon_provider configure")
    resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)

    if data.Host.IsUnknown() {
        resp.Diagnostics.AddAttributeError(
            path.Root("host"),
            "Unknown Mastodon API Host",
            "...",
        )
    }
    host := os.Getenv("MASTODON_HOST")    // 1. env var
    if !data.Host.IsNull() {
        host = data.Host.ValueString()     // 2. config block override
    }
    if host == "" {
        resp.Diagnostics.AddAttributeError(path.Root("mastodon-host"), "Missing Mastodon Credentials", "...")
    }
    // ... outros atributos seguem o mesmo padrão ...

    if resp.Diagnostics.HasError() {
        return  // só retorna APÓS coletar todos os erros
    }
    // criar cliente e passar para DataSourceData/ResourceData
    resp.DataSourceData = c
    resp.ResourceData = c
    // NÃO existe resp.FunctionData
}
```

### Data source: Schema (Required para param, Computed false para outputs)
```go
type AccountDataSourceModel struct {
    Username    types.String `tfsdk:"username"`
    Id          types.String `tfsdk:"id"`
    DisplayName types.String `tfsdk:"display_name"`
    Locked      types.Bool   `tfsdk:"locked"`
}
// no Schema():
"username": schema.StringAttribute{Required: true},
"id":       schema.StringAttribute{Optional: false, Required: false}, // computed pelo provider
```

### Data source: Read
```go
func (d *AccountDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
    var data AccountDataSourceModel
    resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() { return }

    account, err := d.client.AccountLookup(ctx, data.Username.ValueString())
    if err != nil {
        resp.Diagnostics.AddError("Failed to lookup account", fmt.Sprintf("...: %s", err))
        return
    }
    data.Id = types.StringValue(string(account.ID))
    data.DisplayName = types.StringValue(account.DisplayName)
    data.Locked = types.BoolValue(account.Locked)

    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Resource: Schema com UseStateForUnknown e Default
```go
"id": schema.StringAttribute{
    Computed: true, Required: false, Optional: false,
    PlanModifiers: []planmodifier.String{
        stringplanmodifier.UseStateForUnknown(), // evita "known after apply" desnecessário
    },
},
"visibility": schema.StringAttribute{
    Optional: true, Computed: true,
    Default: stringdefault.StaticString("public"),
},
```

### Resource: Create com normalização HTML
```go
func (r *PostResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
    var data PostResourceModel
    resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() { return }

    toot := mastodon.Toot{
        Status: data.Content.ValueString(),
        Visibility: data.Visibility.ValueString(),
    }
    post, err := r.client.PostStatus(context.Background(), &toot)
    if err != nil {
        resp.Diagnostics.AddError("Client Error", fmt.Sprintf("Unable to create post: %s", err))
        return
    }
    p := bluemonday.NewPolicy()
    data.Content = types.StringValue(p.Sanitize(post.Content)) // normaliza HTML do servidor
    data.Id = types.StringValue(string(post.ID))
    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Function: Definition e Run
```go
func (r IdentityFunction) Definition(_ context.Context, _ function.DefinitionRequest, resp *function.DefinitionResponse) {
    resp.Definition = function.Definition{
        Summary: "Identity function",
        Parameters: []function.Parameter{
            function.StringParameter{Name: "username"},
            function.StringParameter{Name: "server"},
        },
        Return: function.StringReturn{},
    }
}

func (r IdentityFunction) Run(ctx context.Context, req function.RunRequest, resp *function.RunResponse) {
    var username, server string
    resp.Error = function.ConcatFuncErrors(req.Arguments.Get(ctx, &username, &server))
    if resp.Error != nil { return }
    resp.Error = function.ConcatFuncErrors(resp.Result.Set(ctx, "@"+username+"@"+server))
}
// chamada em HCL: provider::mastodon::identity("tedivm", "hachyderm.com")
```

## Tabelas de Referência

### Interfaces do Plugin Framework

| Interface | Funções obrigatórias |
|-----------|---------------------|
| `provider.Provider` | `Metadata`, `Schema`, `Configure`, `Resources`, `DataSources`, `Functions`, `New` |
| `datasource.DataSource` | `Metadata`, `Schema`, `Configure`, `Read` |
| `resource.Resource` | `Metadata`, `Schema`, `Configure`, `Create`, `Read`, `Update`, `Delete` |
| `function.Function` | `Metadata`, `Definition`, `Run` |

### Schema: atributos por papel

| Papel | Required | Optional | Computed | Sensitive |
|-------|----------|----------|----------|-----------|
| Parâmetro obrigatório do usuário | `true` | `false` | `false` | — |
| Parâmetro opcional do usuário | `false` | `true` | `false` | — |
| Atributo retornado pelo servidor | `false` | `false` | `true` | — |
| Credencial/secret | `false` | `true` | `false` | `true` |
| Campo com default | `false` | `true` | `true` | — |

### Padrão de validação em Configure

```
1. IsUnknown() → AddAttributeError (valor derivado ainda não disponível)
2. os.Getenv()  → valor base do env var
3. !IsNull()    → override com valor do config block
4. == ""        → AddAttributeError (valor faltando)
5. HasError()   → return  (só após processar TODOS os campos)
```

### Ciclo de vida de testes

| Tipo | Prefixo | Função | Ativa por | Quando usar |
|------|---------|---------|-----------|-------------|
| Unit | `Test*` | `resource.UnitTest` | sempre | functions, lógica pura |
| Acceptance | `TestAcc*` | `resource.Test` | `TF_ACC=1` | resources, data sources |

### Fluxo de publicação

```
go generate               → docs automáticos via tfplugindocs
gpg --full-generate-key   → RSA 4096
                          → registrar public key no Terraform Registry / OpenTofu Issues
GitHub release (semver)   → GitHub Actions + .goreleaser.yml → builds multi-arch
                          → uploads para release → Terraform/OpenTofu Registry sync
```

## Exemplo Trabalhado

**Provider Mastodon completo** (plataforma de microblogging federado):

```
Objetivo: post, lookup de conta, validação de username a partir do Terraform

Provider: mastodon
  - Schema: host, client_id, client_secret, email, password, access_token
  - Configure: env vars → config block → criar mastodon.Client → resp.DataSourceData = resp.ResourceData = c

Data source: mastodon_account
  - Param: username (Required)
  - Outputs: id, display_name, note, locked, bot (todos Computed)
  - Read: AccountLookup(username) → preencher model → State.Set

Resource: mastodon_post
  - Param: content (Required), visibility (Optional+Computed, default "public"), sensitive (Optional+Computed, default false)
  - Outputs: id, created_at, account (todos Computed + UseStateForUnknown)
  - Create: PostStatus → p.Sanitize(post.Content) → State.Set
  - Read:   GetStatus(id) → p.Sanitize(post.Content) → State.Set
  - Update: UpdateStatus(id) → p.Sanitize → State.Set
  - Delete: DeleteStatus(id) → Terraform remove do state automaticamente

Function: provider::mastodon::identity
  - Params: username (String), server (String)
  - Return: "@username@server"
  - Sem acesso a clientes; testado com UnitTest

Uso:
  data "mastodon_account" "me" { username = "tedivm" }
  resource "mastodon_post" "deploy" { content = "Deploy v2.3.0 concluído!" }
  output "identity" { value = provider::mastodon::identity("tedivm", "hachyderm.io") }
```

## Key Takeaways

1. Provider development requer Go; usar Terraform Plugin Framework Protocol v6 (SDK atual)
2. Iniciar sempre pelo **design das interfaces** (resources, data sources, functions) antes de qualquer código
3. **Provider Scaffolding template** elimina boilerplate; limpar arquivos HashiCorp-internos antes de usar
4. `~/.terraformrc` com `dev_overrides` permite testar provider local sem publicar
5. Em `Configure`, acumular todos os erros antes de retornar — nunca `log.Fatal`
6. Padrão de validação: `IsUnknown` → env var → config block → validar → `HasError` → return
7. **State normalization**: toda transformação feita em Create deve também ocorrer em Read (ex: strip HTML)
8. Functions são **pure logic** — sem clientes, sem state; testadas com `resource.UnitTest`; requerem Terraform v1.8+
9. `go generate` produz documentação automática a partir de `MarkdownDescription` nos schemas
10. Publicação: GPG RSA 4096 → registrar key no Registry → tag semver no GitHub → GitHub Actions publica automaticamente

## Conecta Com

- **Ch01**: providers como núcleo do ecossistema Terraform; registry público
- **Ch02**: HCL blocks `provider {}`, `resource`, `data` — agora entendemos como são implementados
- **Ch05**: plan e apply interagem com Create/Read/Update/Delete do provider
- **Ch06**: state management — o provider é responsável por popular o state corretamente
- **Ch07**: `go generate` + tfplugindocs integra com CI para documentação automática
- **Ch09**: Terraform Plugin Testing é extensão do Go testing, similar ao Terratest
- **Ch11**: CDKTF gera configurações HCL que consomem providers escritos exatamente como este
