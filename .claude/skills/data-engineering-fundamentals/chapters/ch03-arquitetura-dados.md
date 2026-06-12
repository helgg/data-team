# Capítulo 3: Desenvolvendo uma Boa Arquitetura de Dados

## Core Idea
Arquitetura de dados é o desenvolvimento de sistemas para suportar necessidades dinâmicas de uma empresa por meio de **decisões flexíveis e reversíveis** e avaliação criteriosa de compensações. Nunca está concluída — mudança e evolução são sua essência. Boa arquitetura ≠ arquitetura ideal; boa arquitetura = a "menos problemática".

## Frameworks Introduzidos

- **9 Princípios de Boa Arquitetura de Dados**:
  1. Escolha componentes comuns com sabedoria (storage, orquestração, observabilidade compartilhados)
  2. Planeje para falhas (disponibilidade, confiabilidade, RTO, RPO)
  3. Projete para escalabilidade (ampliação, redução, escalar para zero)
  4. Arquitetura é cerne da liderança (orienta equipes, não apenas decide)
  5. Esteja sempre arquitetando (arquitetura linha de base → alvo → plano sequencial)
  6. Desenvolva sistemas fracamente acoplados (Mandato da API de Bezos)
  7. Tome decisões reversíveis (portas de mão dupla de Bezos)
  8. Priorize segurança (zero-trust, modelo responsabilidade compartilhada)
  9. Adote FinOps (gerenciamento de custo em nuvem como prática cultural)

- **Portas de Sentido Único vs. Mão Dupla** (Bezos):
  - Sentido único (Tipo 1): decisão praticamente irreversível — requer deliberação profunda
  - Mão dupla (Tipo 2): decisão reversível — preferir sempre; permite velocidade e aprendizado
  - Quando usar: ao avaliar qualquer escolha arquitetural, perguntar "consigo reverter isso?"

- **Padrão Estrangulador** (Strangler Pattern):
  - Novos sistemas substituem componentes legados incrementalmente
  - Quando usar: projetos brownfield que precisam modernizar sem reformulação total
  - Como: identificar componente, criar paralelo, migrar tráfego, depreciar legado

- **Data Mesh (Dehghani)** — 4 componentes:
  - Propriedade e arquitetura de dados orientadas a domínio (descentralizada)
  - Dados como produto
  - Infraestrutura como plataforma self-service
  - Governança computacional federada

## Key Concepts

- **Arquitetura operacional vs. técnica**: operacional = O QUE fazer (processos, SLAs, pessoas); técnica = COMO fazer (ingestão, armazenamento, transformação)
- **Disponibilidade**: proporção de tempo em estado operacional
- **Confiabilidade**: probabilidade de atender padrões definidos no intervalo especificado
- **RTO (Recovery Time Objective)**: tempo máximo aceitável de inatividade
- **RPO (Recovery Point Objective)**: perda máxima de dados aceitável após recuperação
- **Elasticidade**: sistema escalável que se expande/contrai automaticamente; "escalar para zero" = desligamento em ociosidade
- **Acoplamento forte vs. fraco**: forte = dependências rígidas entre componentes; fraco = comunicação via APIs/mensagens, componentes independentes
- **Monolito**: código-base único, acoplamento técnico e de domínio; risco de "big ball of mud"
- **Microsserviços**: serviços separados, descentralizados, fracamente acoplados; cada um com uma função
- **Shared-nothing**: cada nó gerencia sua solicitação isoladamente; sem contenção de recursos
- **Shared-disk**: nós compartilham disco; útil para failover mas risco de contenção
- **Projeto brownfield**: redesenho de arquitetura existente; limitado por escolhas passadas
- **Projeto greenfield**: arquitetura nova do zero; risco de "síndrome do objeto brilhante" e RDD
- **RDD (Resumé-Driven Development)**: acumular tecnologias por valor de currículo, não por necessidade do negócio — anti-padrão
- **Data warehouse**: hub central para relatórios/análise; dados formatados; MPP; separação OLAP/OLTP
- **Data lake**: armazenamento de todos os dados (estruturados e não estruturados) em objeto; primeira geração falhou por falta de governança
- **Data lakehouse**: convergência DW + data lake; transações ACID em object storage; ex: Delta Lake, Databricks
- **Pilha de dados moderna**: componentes modulares plug-and-play em nuvem; reduz complexidade
- **Arquitetura Lambda**: camadas separadas de lote + streaming + disponibilização; difícil manter
- **Arquitetura Kappa**: tudo como stream; lote como caso especial de streaming; complexo e caro
- **Modelo Dataflow / Apache Beam**: dados ilimitados (stream) + limitados (lote) unificados via janelas
- **Mandato da API de Bezos (2002)**: toda comunicação entre equipes via interfaces de serviço; base do acoplamento fraco na Amazon → origem da AWS
- **FinOps**: prática de gerenciar custos em nuvem colaborativamente entre engenharia, finanças e negócio; monitora gastos como SPC monitora performance
- **Segurança zero-trust**: sem perímetro físico confiável; cada acesso verificado individualmente; adequado à nuvem
- **Modelo de responsabilidade compartilhada**: provedor garante segurança DA nuvem; usuário garante segurança NA nuvem

## Mental Models

- "Nunca busque a arquitetura ideal — busque a menos problemática." (Richards & Ford)
- "Soluções técnicas não existem por si só — existem para suportar objetivos do negócio."
- "Portas de mão dupla sempre que possível; portas de sentido único exigem deliberação profunda."
- "Engenheiro de dados = engenheiro de segurança — a nuvem transferiu responsabilidade de perímetro para quem constrói."
- "Monolito por velocidade no início é aceitável — não se acomode; saiba quando fragmentar."

## Anti-patterns

- **Big ball of mud**: monolito não gerenciado que cresce sem modularização; resultado de ignorar complexidade
- **Síndrome do objeto brilhante**: adotar última tecnologia sem avaliar impacto no valor do projeto (especialmente em greenfield)
- **RDD — Resumé-Driven Development**: escolher tecnologia por valor de currículo, não por requisitos do negócio
- **Reformulação completa em brownfield**: mergulhar em redesenho total sem plano; resulta em decisões irreversíveis custosas; prefira padrão estrangulador
- **Data lake sem governança**: resulta em data swamp, dark data, WORN — arquitetura de primeira geração falhou por esse motivo
- **Multilocação sem isolamento**: vazamento de dados entre clientes; risco crítico; sempre verificar documentação do sistema
- **Arquiteto de dados isolado**: arquitetura sem sintonia com engenharia; gap que vai diminuir à medida que engenharia se torna mais ágil

## Reference Tables

### Padrões de Arquitetura — Comparação

| Padrão | Modelo | Ponto forte | Limitação |
|---|---|---|---|
| Data Warehouse | Centralizado, ETL/ELT, MPP | Governança, SQL, análise estruturada | Custo, rigidez, menos flexível para dados brutos |
| Data Lake 1.0 | Objeto, tudo raw | Custo baixo, flexibilidade | Sem governança, data swamp, sem DML |
| Data Lakehouse | Objeto + ACID, MPP | Melhor dos dois mundos | Complexidade emergente |
| Pilha Moderna | Modular, plug-and-play | Agilidade, custo, comunidade | Fragmentação de ferramentas |
| Lambda | Lote + stream separados | Latência baixa + histórico | Dois code paths, difícil conciliar |
| Kappa | Tudo como stream | Unificado | Caro, imaturidade de tooling |
| Dataflow/Beam | Janelas sobre streams | Lote+stream no mesmo código | Curva de aprendizado |
| Data Mesh | Domínios como produtos | Descentralização, ownership | Governança distribuída exige maturidade |

### Brownfield vs. Greenfield

| Dimensão | Brownfield | Greenfield |
|---|---|---|
| Restrições | Legado existente | Liberdade total |
| Risco principal | Decisões irreversíveis na migração | Síndrome do objeto brilhante |
| Abordagem recomendada | Padrão estrangulador | Priorizar requisitos do negócio |
| Foco | Compreender o porquê do legado | Começar simples, evoluir |

## Worked Example

**Mandato da API de Bezos → origem da AWS:**

Em 2002, a Amazon tinha sistemas fortemente acoplados. Bezos emitiu o mandato:
- Toda equipe expõe dados/funcionalidades via interface de serviço
- Comunicação apenas via APIs — sem leitura direta de BD alheio, sem memória compartilhada
- Todas as interfaces projetadas para serem terceirizadas desde o início

Resultado:
1. Equipes passaram a tratar serviços internos como produtos
2. Componentes tornaram-se reutilizáveis e independentes
3. A infraestrutura interna (computação, storage, mensagens) estava pronta para ser exposta externamente
4. A AWS nasceu como subproduto dessa arquitetura fracamente acoplada

**Lição aplicada à engenharia de dados**: pipelines de dados, armazenamentos e transformações expostos via APIs/contratos de dados permitem que equipes evoluam componentes independentemente — substituir o data warehouse ou o motor de ingestão sem refatorar todo o pipeline.

## Key Takeaways

1. Boa arquitetura = decisões flexíveis e reversíveis + avaliação de compensações; nunca está concluída.
2. Prefira portas de mão dupla (reversíveis); restrinja portas de sentido único a decisões realmente críticas.
3. Acoplamento fraco é o padrão a buscar; comece com monolito se necessário, mas saiba quando e como fragmentar.
4. Data warehouse, data lake e data lakehouse convergem; escolha plataforma de dados por ecossistema e caso de uso, não por modismo.
5. Brownfield: padrão estrangulador, decisões reversíveis, entender o porquê do legado.
6. Greenfield: priorizar negócio, evitar RDD e síndrome do objeto brilhante.
7. Engenheiro de dados é engenheiro de segurança — zero-trust e responsabilidade compartilhada são base.
8. FinOps: trate custo em nuvem como métrica operacional monitorada continuamente.

## Connects To

- **Ch2**: Elementos subjacentes (segurança, DataOps, orquestração) são a base de qualquer arquitetura
- **Ch4**: Escolha de tecnologias ao longo do ciclo — operacionaliza os princípios deste capítulo
- **Ch6**: Armazenamento — DW, data lake, lakehouse em profundidade
- **Ch8**: Transformações e modelagem de dados — Kimball, Inmon, Data Vault dentro do DW
- **Ch11**: Pilha de dados moderna e tendências futuras
- **DDIA (Kleppmann)**: referência externa para sistemas distribuídos em profundidade
