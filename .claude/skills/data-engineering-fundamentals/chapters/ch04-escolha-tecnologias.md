# Capítulo 4: Escolhendo Tecnologias ao Longo do Ciclo de Vida da Engenharia de Dados

## Core Idea
Arquitetura é estratégia (o quê, por quê, quando); ferramentas são tática (como). Escolher tecnologia antes de definir arquitetura é o erro fundamental do capítulo. O critério central de qualquer escolha: **a tecnologia agrega valor ao produto de dados e ao negócio?**

## Frameworks Introduzidos

- **TCO vs. TOCO**:
  - **TCO (Total Cost of Ownership)**: custo total estimado incluindo diretos (salários, faturas AWS) e indiretos (custos gerais); comprar vs. opex/capex
  - **TOCO (Total Opportunity Cost of Ownership)**: custo das oportunidades perdidas ao escolher uma tecnologia — o que você exclui ao adotar a pilha A inclui B, C e D; tecnologias inflexíveis = "armadilhas de urso"
  - Quando usar: antes de qualquer adoção nova; calcular ambos, não apenas TCO

- **Tecnologias Imutáveis vs. Transitórias**:
  - **Imutáveis**: resistem ao tempo — object storage (S3), SQL, bash, redes, segurança; beneficiam do Efeito Lindy ("quanto mais tempo estabelecida, mais tempo será usada")
  - **Transitórias**: surgem e desaparecem — frameworks JS, Hive, ferramentas de dados emergentes
  - Quando usar: ao avaliar qualquer adoção; construir tecnologias transitórias *sobre* imutáveis; reavaliar escolhas a cada 2 anos
  - Regra: armazenamento de objetos + SQL = base segura; camadas superiores = revisáveis

- **Capex vs. Opex → Opex-first**:
  - Capex: investimento inicial, hardware próprio, depreciação longa; captura de capital
  - Opex: pagamento conforme uso; gradual; flexível; direto; nuvem = modelo opex por padrão
  - Recomendação: adotar **opex-first** centrado em nuvem e tecnologias flexíveis de pagamento conforme uso

- **Build vs. Buy**:
  - Build: controle total, sem lock-in de fornecedor — justificado apenas quando gera vantagem competitiva real
  - Buy: OSS, COSS, SaaS — padrão para tudo que não é diferencial competitivo
  - Regra: "Você fabrica seus próprios pneus?" — use o que existe; construa apenas o que *move o negócio*
  - Mapa de decisão: OSS gratuito → COSS gerenciado → SaaS proprietário → build interno (último recurso)

- **Serverless vs. Com Servidor**:
  - Serverless: FaaS (Lambda), BigQuery-style; custo por evento; escalonamento automático; baixo overhead operacional
  - Com servidor: mais controle; custo menor em uso contínuo alto; contêineres + Kubernetes para cargas complexas
  - Regra: comece serverless → migre para servidores quando custo por evento × volume > custo de servidor contínuo

## Key Concepts

- **Arquitetura vs. Ferramentas**: arquitetura = o quê/por quê/quando (estratégico); ferramentas = como (tático); confundir os dois gera "máquina fantástica do Dr. Seuss"
- **Engenharia de culto à carga**: equipes pequenas copiando práticas de grandes empresas tech sem contexto — resulta em complexidade sem ROI
- **Efeito Lindy**: quanto mais tempo uma tecnologia está estabelecida, mais tempo continuará sendo usada; SQL, bash, redes elétrica = candidatos imutáveis
- **Gravidade dos dados (data gravity)**: dados em nuvem atraem serviços; saída de dados = custosa; entrada = gratuita ou barata; lock-in real mesmo sem contratos
- **Maldição da familiaridade**: novos produtos projetados para parecer com algo familiar induzem erros; lift-and-shift ≠ cloud-native
- **Lift-and-shift**: migrar servidores on-premises 1:1 para VMs na nuvem — válido como fase inicial, mas servidores long-running na nuvem são mais caros que on-premises; exige adaptação ao modelo de preços
- **Monolito distribuído**: sistema distribuído com dependências compartilhadas ou código comum entre nós; pior dos dois mundos (fragilidade do monolito + complexidade do distribuído); ex: Hadoop cluster clássico, Airflow com dependências globais
- **OSS comunitário**: código aberto mantido por comunidade; critérios: mindshare (stars/forks/commits), maturidade, resolução de issues, plano de ação, auto-hospedagem
- **COSS (OSS Comercial)**: versão gerenciada de OSS por fornecedor (Databricks/Spark, Confluent/Kafka, dbt Labs/dbt); avalie valor, modelo de entrega, suporte, longevidade financeira da empresa
- **Jardins murados proprietários**: produtos fechados de ISVs ou nuvens (DynamoDB, BigQuery); integração nativa com ecossistema da nuvem; critério: interoperabilidade + TCO vs. independente
- **Benchmark wars**: comparações de desempenho manipuladas; táticas comuns: datasets minúsculos que cabem em SSD, comparações de custo assimétricas (temporário vs. permanente), otimização assimétrica (indexar um lado, não o outro)
- **Cláusula de DeWitt**: restrição contratual proibindo benchmarks sem autorização do fabricante — estava desaparecendo na época do livro
- **Regra das duas pizzas** (Bezos): equipe máxima = grupo alimentado por duas pizzas (~5 pessoas); limita domínio de responsabilidade → força decomposição modular
- **Airflow**: orquestrador OSS dominante; vantagens: comunidade ativa, disponível como COSS (Astronomer, GCP, AWS); desvantagens: agendador e BD não escaláveis, monolito distribuído, sem suporte nativo a schema/linhagem

## Mental Models

- "Arquitetura primeiro, tecnologia depois — nunca ao contrário."
- "Tecnologia que é fácil de entrar e difícil de sair = armadilha de urso; avalie o custo de saída antes de entrar."
- "Efeito Lindy: aposte em imutáveis como base; use transitórias como camadas substituíveis."
- "Serverless por padrão; servidores quando o custo por evento × volume supera o custo contínuo."
- "Você não é o Dropbox — repatriação para on-premises só faz sentido em escala de exabytes e terabits/s."

## Anti-patterns

- **Tecnologia antes da arquitetura**: síndrome do objeto brilhante + RDD aplicados à escolha tática; resulta em "máquina do Dr. Seuss" — muitas peças sem coerência
- **Engenharia de culto à carga**: pequena equipe tentando replicar stack de FAANG sem case de uso equivalente; consome tempo sem entregar valor
- **Lift-and-shift sem adaptação**: mover servidores on-premises para VMs long-running na nuvem sem autoscaling = fatura surpresa alta
- **Monolito distribuído**: sistema distribuído com dependências globais compartilhadas; falhas se propagam como monolito; complexidade operacional do distribuído
- **Build por padrão**: construir internamente o que já existe como OSS/COSS; custo oculto de TCO + TOCO gigante sem vantagem competitiva
- **Benchmark-driven decisions**: confiar em benchmarks de fornecedores sem replicar no próprio caso de uso; datasets pequenos, otimizações assimétricas, custos incomparáveis
- **Multicloud por padrão sem necessidade**: complexidade de integração/segurança/rede sem ROI; adote apenas com razão de negócio concreta

## Reference Tables

### Localização de Deploy — Comparação

| Modelo | Controle | Flexibilidade | Custo | Quando usar |
|---|---|---|---|---|
| On-premises | Total | Baixa | Capex alto | Escala de exabytes/terabits, produto altamente especializado de hardware |
| Nuvem única | Baixo | Alta | Opex variável | Padrão para maioria das organizações |
| Nuvem híbrida | Médio | Média | Misto | Empresas em migração, regulatório, cargas analíticas separadas |
| Multicloud | Baixo | Alta | Opex variável + complexidade | Reduzir latência de clientes em múltiplas nuvens, serviços específicos por nuvem |

### OSS Comunitário vs. COSS vs. Proprietário — Decisão

| Critério | OSS Comunitário | COSS | Proprietário ISV | Proprietary Cloud |
|---|---|---|---|---|
| Custo base | Gratuito | Pago (gerenciamento) | Pago | Pay-per-use |
| Overhead ops | Alto (auto-hospedagem) | Baixo | Baixo | Mínimo |
| Lock-in | Baixo | Médio | Alto | Alto (data gravity) |
| Longevidade | Depende da comunidade | Depende da empresa | Depende da empresa | Alta (big cloud) |
| Customização | Total | Parcial | Limitada | Limitada |

### Serverless vs. Servidor — Quando Mudar

| Situação | Recomendação |
|---|---|
| Eventos baixos (<100/s), tarefas simples | Serverless |
| Uso contínuo alto, custo/evento × volume > servidor | Servidor |
| Dependências complexas, cargas longas | Contêineres + Kubernetes |
| Multilocação com isolamento necessário | Kubernetes gerenciado ou VMs |

## Worked Example

**"Você não é o Dropbox" — Caso de repatriação cloud → on-premises:**

O artigo "The Cost of Cloud, A Trillion Dollar Paradox" (Wang & Casado) gerou debate sobre repatriação. Dropbox é citado como sucesso.

Por que o Dropbox funcionou on-premises:
1. **Volume**: múltiplos exabytes de dados — custos de saída em nuvem pública seriam astronomicamente altos
2. **Largura de banda**: centenas de gigabits de conectividade de internet; custos de egress proibitivos em cloud pública
3. **Produto especializado**: sistema de sincronização diferenciada (nível de bloco + objeto) — nenhuma nuvem pública oferece exatamente isso; stack hardware+software integrado = vantagem competitiva real
4. **Parcial**: Dropbox *manteve* cargas analíticas na AWS — repatriou apenas o produto core

**Conclusão aplicada**: repatriar faz sentido quando (a) escala = exabytes/terabits/s, (b) produto exige hardware personalizado integrado, (c) custos de egress são fator dominante. Para 99% das organizações, nenhuma dessas condições se aplica.

**Regra derivada**: "Antes de citar o Dropbox como exemplo, verifique: você armazena exabytes? Você tem terabits/s de tráfego de saída? Seu produto core *é* o armazenamento? Se não, você não é o Dropbox."

## Key Takeaways

1. Arquitetura = estratégia; tecnologia = tática. Definir arquitetura primeiro, escolher ferramentas depois.
2. TCO sem TOCO é análise incompleta — o custo de oportunidade de tecnologias inflexíveis pode superar o custo direto.
3. Efeito Lindy: construir sobre imutáveis (object storage, SQL, bash); usar transitórias como camadas substituíveis revisadas a cada 2 anos.
4. Opex-first: prefira pagamento conforme uso em nuvem; evite capex em hardware que ficará obsoleto.
5. Build apenas quando gera vantagem competitiva; para todo o resto, compre (OSS → COSS → SaaS).
6. Serverless por padrão; migre para servidores quando custo × volume superar servidor contínuo.
7. Benchmarks de fornecedores são marketing; replique no seu caso de uso antes de decidir.
8. Gravidade dos dados é real — avalie custos de egress antes de entrar em qualquer plataforma.

## Connects To

- **Ch3**: Arquitetura define o "o quê"; este capítulo define o "como" — tecnologias para operacionalizar
- **Ch1**: Tipo A (abstração/SaaS) vs. Tipo B (build) — operacionalizado aqui como decisão build vs. buy
- **Ch2**: Elementos subjacentes (DataOps, orquestração, segurança) — como avaliar suporte de cada tecnologia
- **Ch8**: Transformação — modelagem e ferramentas de transformação à luz dos critérios deste capítulo
- **Ch11**: Pilha moderna — tecnologias emergentes avaliadas pelos critérios imutável/transitório/modular
