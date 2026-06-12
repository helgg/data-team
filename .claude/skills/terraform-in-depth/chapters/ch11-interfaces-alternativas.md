# Capítulo 11: Alternative Interfaces

## Ideia Central

Terraform foi projetado para ser operado tanto por humanos quanto por máquinas. Este capítulo cobre três camadas de integração programática: (1) **wrapping** — controlar o engine Terraform a partir de outra linguagem via CLI wrapper; (2) **JSON como HCL** — gerar configurações Terraform programaticamente usando `.tf.json`; (3) **CDKTF** — escrever infraestrutura em TypeScript/Python/Go sem tocar em HCL.

---

## Frameworks Introduzidos

### CLI Wrapper (tofupy)
Wrappers envolvem a CLI com código próprio: executam comandos, capturam saída, traduzem JSON/JSONL para objetos nativos.

**Dois formatos de saída Terraform:**
- **JSON output format** — resposta única (comandos `show`, `validate`, `output`); parse direto de um objeto JSON
- **Machine-readable UI** — streaming JSONL linha a linha (comandos `plan`, `apply`); cada linha = 1 objeto JSON independente; permite processar eventos em tempo real

**Estrutura do wrapper:**
- Classe `Tofu` com `cwd`, `binary_path`, `log_level`, `env`
- Método `_run(args, raise_on_error)` → `CommandResults` (batch)
- Método `_run_stream(args)` → generator de eventos (streaming)
- `TF_IN_AUTOMATION=1` desabilita prompts interativos

### Data Classes como camada de parsing
Cada output Terraform mapeado para dataclass Python com:
- `data` (raw dict, `repr=False`) recebido no construtor
- Campos calculados com `field(init=False)` populados em `__post_init__`
- Objetos aninhados instanciados recursivamente

### Event Handlers
`apply()` e `plan()` aceitam `event_handlers: Dict[str, Callable]`:
- Chave = `type` do evento (ex.: `"apply_start"`, `"change_summary"`)
- Chave `"all"` → handler chamado em todo evento
- Permite streaming de logs em tempo real para console/servidor

### JSON como Terraform (`.tf.json`)
- Arquivos `.tf.json` (ou `.tofu.json`) misturáveis com `.tf` no mesmo diretório
- Chaves top-level = block types HCL: `resource`, `data`, `variable`, `output`, `locals`, `module`, `provider`, `terraform`
- Referências como string templates: `"${var.name}"`, `"${data.http.site.response_body}"`
- Blocks repetíveis (ex.: `provider` com alias) → array JSON
- Comentários: campo `"//"` com valor string (qualquer nível)

### CDKTF
Framework HashiCorp: linguagem (TS/Python/Java/C#/Go) → CDKTF library → JSON → Terraform → providers.
- **App**: container top-level; chama `app.synth()` ao final
- **Stack**: equivale a top-level module; tem estado próprio; classes que herdam `TerraformStack`
- **Resource**: equivale a `resource` block HCL; primeiro arg = stack (`self`), segundo = ID único
- `cdktf synth` → JSON; `cdktf deploy <stack>` → plan + apply; `cdktf destroy <stack>`
- **Não suporta OpenTofu** (apenas Terraform)

---

## Conceitos-chave

- **`TF_IN_AUTOMATION=1`**: desabilita prompts e modifica mensagens para uso programático
- **JSONL (JSON Lines)**: formato de streaming — uma linha = um objeto JSON; usado por `plan` e `apply`
- **`CommandResults`**: dataclass com `command`, `stdout`, `stderr`, `returncode`; métodos `.json()`, `.jsonl()`, `.raise_error()`
- **generator (Python)**: função com `yield`; produz um valor por vez — permite processar eventos Terraform conforme chegam
- **`subprocess.run`**: módulo Python para execução de processos externos; `capture_output=True` para batch, `stdout=PIPE + bufsize=1` para streaming
- **`@dataclass` + `field(init=False)`**: cria classe sem repetir `__init__`; campos calculados populados em `__post_init__`
- **`StreamLog → PlanLog → ApplyLog`**: hierarquia de herança; lógica compartilhada de parsing em `StreamLog`
- **`ChangeContainer`**: wrapper de metadados ao redor de `Change` (address, mode, type, name, index, action_reason)
- **`Change`**: ações (`create`/`update`/`delete`/ambas para replace), `before`, `after`, `before_sensitive`, `after_sensitive`, `after_unknown`
- **plan return code**: 0 = sucesso sem mudanças, 1 = erro, 2 = mudanças planejadas
- **`extra_args`**: parâmetro presente em todos os métodos wrapper — escape hatch para flags não previstas
- **`cdktf provider add`**: instala biblioteca do provider na linguagem-alvo
- **Stack vs top-level module**: cada Stack tem estado próprio; múltiplas stacks no mesmo App = múltiplos workspaces
- **Quando não usar CDKTF**: gerenciamento normal de infra (HCL é superior); usar CDKTF apenas para geração programática de configurações (ferramentas, produtos)
- **Licença Terraform v1.6+**: não é mais open source (BUSL); para produtos/ferramentas, preferir OpenTofu (licença permissiva)

---

## Modelos Mentais

- **"Wrap, don't reimplement"** — o wrapper chama a CLI; não reimplementa a lógica do Terraform; toda a inteligência permanece no engine
- **"JSON output = single parse; machine-readable UI = stream"** — escolher o método de captura correto (`_run` vs `_run_stream`) com base no comportamento do comando
- **"Data classes como contrato"** — cada `@dataclass` documenta o link para a spec oficial; `data` bruto fica disponível como escape hatch
- **"HCL para humanos, JSON para máquinas"** — não escrever JSON manualmente; gerar programaticamente; `.tf.json` + `.tf` coexistem sem conflito

---

## Exemplos de Código

### Classe Tofu — construtor e `_run`

```python
import os, shutil, subprocess, json
from pathlib import Path
from typing import Dict, List, Any
from dataclasses import dataclass, field

@dataclass
class CommandResults:
    command: str
    stdout: str
    stderr: str
    returncode: int

    def json(self) -> Dict[str, Any]:
        return json.loads(self.stdout)

    def jsonl(self):
        for line in self.stdout.splitlines():
            yield json.loads(line)

    def raise_error(self) -> None:
        try:
            for log in self.jsonl():
                if log.get("@level") == "error" and (d := log.get("diagnostic")):
                    raise RuntimeError(
                        f"Terraform command '{self.command}' failed: "
                        f"{d.get('summary')}\n{d.get('detail')}", d
                    )
        except Exception:
            raise RuntimeError(f"Terraform command '{self.command}' failed: {self.stdout}.")


class Tofu:
    def __init__(self, cwd=os.getcwd(), binary="tofu", log_level="ERROR", env={}):
        self.cwd = cwd
        self.log_level = log_level
        self.env = env
        self.binary_path = shutil.which(binary)
        if not self.binary_path:
            raise FileNotFoundError(f"Could not find {binary}, please make sure it is installed.")

        results = self._run(["version", "-json"])
        version = results.json()
        self.version = version["terraform_version"]
        self.platform = version["platform"]
        if int(self.version.split(".")[0]) != 1:
            raise RuntimeError(f"TofuPy only works with major version 1, found {self.version}.")

    def _run(self, args: List[str], raise_on_error: bool = True) -> CommandResults:
        args = [self.binary_path] + [str(x) for x in args]
        results = subprocess.run(
            args, cwd=self.cwd, capture_output=True, encoding="utf-8",
            env={**os.environ, "TF_IN_AUTOMATION": "1", "TF_LOG": self.log_level, **self.env},
            timeout=None,
        )
        results = CommandResults(
            command=" ".join(args),
            stdout=results.stdout, stderr=results.stderr, returncode=results.returncode,
        )
        if raise_on_error and results.returncode != 0:
            results.raise_error()
        return results
```

### Streaming com `_run_stream` + generator

```python
def _run_stream(self, args: List[str]):
    args = [self.binary_path] + [str(x) for x in args]
    process = subprocess.run(
        args, cwd=self.cwd, stdout=subprocess.PIPE, capture_output=False,
        universal_newlines=True, encoding="utf-8", bufsize=1,
        env={**os.environ, "TF_IN_AUTOMATION": "1", "TF_LOG": self.log_level, **self.env},
        timeout=None,
    )
    event_line = ""
    for buffer in process.stdout:
        if buffer == "\n":
            yield json.loads(event_line)
            event_line = ""
        else:
            event_line += buffer
```

### `apply` com event handlers

```python
from typing import Callable

def apply(
    self,
    plan_file=None, variables={}, destroy=False,
    event_handlers: Dict[str, Callable] = {},
    extra_args=[],
) -> "ApplyLog":
    args = ["apply", "-auto-approve", "-json"] + extra_args
    if plan_file:
        args += [str(plan_file)]
    for key, value in variables.items():
        args += ["-var", f"{key}={value}"]
    if destroy:
        args += ["-destroy"]

    output = []
    for event in self._run_stream(args):
        output.append(event)
        if event["type"] in event_handlers:
            event_handlers[event["type"]](event)   # handler por tipo
        if "all" in event_handlers:
            event_handlers["all"](event)           # handler global
    return ApplyLog(output)
```

### `plan` retornando `(PlanLog, Plan | None)`

```python
import tempfile
from typing import Tuple

def plan(self, variables={}, plan_file=None, event_handlers={}, extra_args=[]) -> Tuple["PlanLog", "Plan | None"]:
    try:
        temp_dir = None
        if not plan_file:
            temp_dir = tempfile.TemporaryDirectory()
            plan_file = Path(temp_dir.name) / "plan.tfplan"  # extensão .tfplan obrigatória

        args = ["plan", "-json", "-out", str(plan_file)] + extra_args
        for key, value in variables.items():
            args += ["-var", f"{key}={value}"]

        output = []
        for event in self._run_stream(args):
            output.append(event)
            if event["type"] in event_handlers:
                event_handlers[event["type"]](event)
            if "all" in event_handlers:
                event_handlers["all"](event)

        plan_log = PlanLog(output)

        if plan_file.exists():
            show_res = self._run(["show", "-json", plan_file])
            return plan_log, Plan(show_res.json())
        return plan_log, None
    finally:
        if temp_dir:
            temp_dir.cleanup()
```

### Hierarquia StreamLog → PlanLog → ApplyLog

```python
@dataclass
class StreamLog:
    data: List[Dict[str, Any]] = field(repr=False)
    terraform_version: str = field(init=False)
    outputs: Dict[str, "Output"] = field(init=False)
    added: int = field(init=False)
    changed: int = field(init=False)
    removed: int = field(init=False)
    imported: int = field(init=False)
    operation: str = field(init=False)
    errors: List["Diagnostic"] = field(init=False)
    warnings: List["Diagnostic"] = field(init=False)

    def __post_init__(self):
        self.outputs = {}; self.errors = []; self.warnings = []
        for line in self.data:
            t = line.get("type")
            if t == "version":
                self.terraform_version = line.get("version")
            elif t == "diagnostic":
                (self.errors if line.get("@level") == "error" else self.warnings).append(Diagnostic(line))
            elif t == "outputs":
                for k, v in line.get("outputs").items():
                    self.outputs[k] = Output(v)
            elif t == "change_summary":
                ch = line.get("changes", {})
                self.added = ch.get("add", 0); self.changed = ch.get("change", 0)
                self.removed = ch.get("remove", 0); self.imported = ch.get("import", 0)
                self.operation = ch.get("operation")

class PlanLog(StreamLog): pass
class ApplyLog(PlanLog): pass
```

### State — combinar `state pull` + `show`

```python
def state(self) -> "State":
    pull_res = self._run(["state", "pull"])
    state_pull = pull_res.json()
    with tempfile.NamedTemporaryFile(suffix=".tfstate") as tmp:
        tmp.write(pull_res.stdout.encode())
        tmp.seek(0)  # flush buffer para disco
        show_res = self._run(["show", "-json", tmp.name])
    return State(
        data=show_res.json(),
        serial=state_pull["serial"],    # ausente no show JSON
        lineage=state_pull["lineage"],  # ausente no show JSON
    )
```

### Security scanner com tofupy + typer

```python
import typer
from tofupy import Tofu

app = typer.Typer()

@app.command()
def scan(working_dir: Path = typer.Argument(default=os.getcwd())):
    tofu = Tofu(cwd=working_dir)
    tofu.init()
    log, plan = tofu.plan()
    if not plan or plan.errored:
        typer.echo("Plan failed"); return

    for address, cc in plan.resource_changes.items():
        if cc.type == "aws_vpc_security_group_ingress_rule":
            if cc.change.after.get("cidr_ipv4") == "0.0.0.0/0":
                typer.echo(f"Security group {address} allows all traffic from the internet")

if __name__ == "__main__":
    app()
```

### JSON como HCL — estrutura `.tf.json`

```json
{
  "//": "Gerado automaticamente — não editar manualmente.",
  "variable": {
    "website": {
      "type": "string",
      "description": "URL para consulta.",
      "default": "https://catfact.ninja/fact"
    }
  },
  "data": {
    "http": {
      "site": {
        "url": "${var.website}",
        "request_headers": { "Accept": "application/json" }
      }
    }
  },
  "resource": {
    "terraform_data": {
      "main": {
        "input": "${data.http.site.response_body}",
        "depends_on": ["data.http.site"]
      }
    }
  },
  "output": {
    "site_data": { "value": "${resource.terraform_data.main.output}" }
  }
}
```

### Provider alias em JSON (array para blocks repetíveis)

```json
{
  "provider": {
    "aws": [
      { "region": "us-east-1" },
      { "alias": "backups", "region": "us-west-2" }
    ]
  }
}
```

### CDKTF — Stack, App, Resources

```python
from cdktf import App, TerraformStack
from cdktf_cdktf_provider_random.password import Password
from cdktf_cdktf_provider_null.resource import Resource
from constructs import Construct

class MyStack(TerraformStack):
    def __init__(self, scope: Construct, id: str):
        super().__init__(scope, id)
        random_password = Password(self, "my_password", special=False)
        Resource(self, "example", length=10, triggers={"password": random_password.result})

app = App()
MyStack(app, "staging")
MyStack(app, "production")  # estado separado por stack
app.synth()                 # gera JSON para Terraform consumir
```

---

## Tabelas de Referência

### Comandos Terraform e seus formatos de saída

| Comando | Flag | Formato de resposta | Classe retornada |
|---------|------|---------------------|------------------|
| `version` | `-json` | JSON único | dict |
| `validate` | `-json` | JSON único | `Validate` |
| `output` | `-json` | JSON único | `Dict[str, Output]` |
| `show <file>` | `-json` | JSON único | `State` ou `Plan` |
| `state pull` | — | JSON único | dict (bruto) |
| `plan` | `-json` | JSONL streaming | `(PlanLog, Plan\|None)` |
| `apply` | `-json` | JSONL streaming | `ApplyLog` |

### Campos comuns de evento JSONL (machine-readable UI)

| Campo | Significado |
|-------|-------------|
| `@level` | `info` / `warn` / `error` |
| `@message` | Mensagem human-readable |
| `@module` | `tofu.ui` ou `terraform.ui` |
| `@timestamp` | ISO8601 preciso |
| `type` | Tipo do evento — define campos extras presentes |

### Tipos de evento principais

| Tipo | Dados extras | Quando ocorre |
|------|-------------|---------------|
| `version` | `tofu`, `ui` | Início de qualquer comando |
| `apply_start` | `hook.resource`, `hook.action` | Início de operação em recurso |
| `apply_complete` | `hook.resource`, `elapsed_seconds` | Fim de operação em recurso |
| `change_summary` | `changes.{add,change,remove,import,operation}` | Fim do apply/plan |
| `outputs` | `outputs` (dict) | Após change_summary |
| `diagnostic` | `@level=error/warning`, `diagnostic.{summary,detail}` | Em caso de erro |

### JSON vs HCL — diferenças chave

| HCL | JSON equivalente |
|-----|-----------------|
| `resource "aws_s3_bucket" "main" { }` | `{"resource": {"aws_s3_bucket": {"main": {}}}}` |
| `var.name` | `"${var.name}"` |
| `depends_on = [data.http.site]` | `"depends_on": ["data.http.site"]` |
| `# comentário` | `"//": "comentário"` |
| Múltiplos `provider "aws" {}` | `"provider": {"aws": [{...}, {...}]}` |

### CDKTF — quando usar e quando não usar

| Cenário | Recomendação |
|---------|-------------|
| Equipe gerenciando infra diretamente | HCL nativo — ecossistema mais rico, menos abstração |
| Ferramenta/produto que gera configurações | CDKTF é adequado |
| Equipe quer evitar aprender HCL | CDKTF não resolve — os desafios reais são IaC concepts, state, CI/CD |
| Precisa de OpenTofu | CDKTF não suporta |

---

## Exemplo Trabalhado — Security Scanner

**Objetivo**: ferramenta CLI que inspeciona um módulo Terraform e detecta security groups com CIDR aberto.

**Fluxo completo**:
```
scanner.py ./module
  → Tofu(cwd="./module")
  → tofu.init()                     # baixa providers
  → (plan_log, plan) = tofu.plan()  # plan() roda plan + show
  → itera plan.resource_changes
  → detecta aws_vpc_security_group_ingress_rule com cidr_ipv4 == "0.0.0.0/0"
  → imprime alerta
```

**Por que `plan()` retorna `(PlanLog, Plan)`**:
- `PlanLog` vem do streaming JSONL (eventos em tempo real, change summary, erros)
- `Plan` vem do `terraform show -json <plan_file>` (estrutura completa de mudanças)
- Ambos necessários: log para observabilidade, plan para análise programática

**Módulo de teste violando a regra**:
```hcl
resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.example.id
  cidr_ipv4         = "0.0.0.0/0"  # DETECTADO pelo scanner
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
```

**Saída**:
```
% python scanner.py ./module
Scanning module
Found security group: aws_vpc_security_group_ingress_rule.example
Security group aws_vpc_security_group_ingress_rule.example allows all traffic from the internet
```

Este padrão se aplica também a: estimativa de custo (ler tipos de recursos do plan), validação de compliance, análise de drift (`plan.resource_drift`).

---

## Key Takeaways

1. Terraform foi projetado para automação: `-json` flag em quase todos os comandos; data structures versionadas com backward compatibility
2. **Dois formatos**: JSON output (resposta única, `show`/`validate`/`output`) vs machine-readable UI (JSONL streaming, `plan`/`apply`)
3. `TF_IN_AUTOMATION=1` é essencial em wrappers — desabilita prompts interativos
4. `_run_stream` + generator = processar eventos Terraform **conforme chegam**, não após completar
5. Dataclasses com `field(init=False)` + `__post_init__` = mapping limpo sem boilerplate
6. `plan()` retorna `(PlanLog, Plan|None)` — combine streaming log com análise estrutural do plan
7. `.tf.json` misturável com `.tf`; referências são string templates `"${...}"`; providers repetíveis = arrays
8. Comentários JSON: campo `"//"` com string — útil para rastrear gerador e linha de origem
9. CDKTF: use para **ferramentas que geram configurações**, não para gerenciar infra diretamente
10. Para produtos/ferramentas em cima do Terraform: atenção à licença BUSL (v1.6+) — considerar OpenTofu

---

## Anti-Patterns

- **Reinventar o engine** — wrapping não reimplementa lógica Terraform; toda a inteligência fica na CLI
- **Escrever `.tf.json` manualmente** — JSON foi projetado para máquinas; use HCL se for humano
- **Usar CDKTF para substituir HCL em times de infra** — os desafios reais (state, CI/CD, testing) não mudam; CDKTF só resolve sintaxe
- **Ignorar `extra_args`** — Terraform evolui rápido; wrapper sem escape hatch fica desatualizado
- **Capturar stdout batch quando o comando faz streaming** — `plan`/`apply` com `-json` retornam JSONL linha a linha; `_run` (batch) vai bloquear até o fim sem processar eventos intermediários

---

## Conecta Com

- **[ch08]** — deploy pipelines; `apply()` com `event_handlers` pode emitir eventos para sistemas de observabilidade
- **[ch09]** — Terratest usa o mesmo padrão de wrapping (Go em vez de Python)
- **[ch10]** — external provider (`data "external"`) é outra forma de integrar linguagens externas; mais leve mas unidirecional
- **[ch12]** — custom providers: extensão interna do Terraform, alternativa ao wrapping externo
