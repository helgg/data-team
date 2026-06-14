# Chapter 13: Enabling Artificial Intelligence and Machine Learning

## Core Idea
Data engineer não constrói modelos ML — data engineer constrói os pipelines que alimentam modelos ML com dados certos na frequência certa. Sem pipeline confiável, o modelo ML não consegue fazer predições que a organização passou a depender. Este capítulo mapeia o stack AWS de ML/AI em três camadas e detalha onde o data engineer se encaixa em cada serviço.

## Frameworks Introduced

- **AWS ML/AI Stack — 3 Camadas**
  - **ML Frameworks & Infrastructure**: AMIs e Docker containers com frameworks deep learning pré-instalados (TensorFlow, PyTorch); casos de uso avançados fora do escopo do livro
  - **ML Services (SageMaker)**: simplifica todo ciclo de vida de ML — prepare, build, train, tune, deploy, manage — sem gerenciar infraestrutura; acessível para developers sem expertise ML
  - **AI Services**: modelos pré-treinados acessíveis via API simples; nenhuma infraestrutura, nenhum expertise ML necessário; billing por uso (por caractere, por imagem, por segundo de áudio)
  - Regra de decisão: caso de uso genérico → AI Service; modelo customizado com dados proprietários → SageMaker; deep learning experimental com controle total → ML Frameworks layer

- **Data Engineer Role in ML Pipelines**
  - Não é o data scientist (que constrói o modelo)
  - É quem garante que dados certos chegam ao modelo na frequência correta
  - Pipeline failure → modelo faz predições ruins ou não faz
  - Padrão: ingest (Kinesis/DMS) → transform (Glue) → store (S3) → serve para modelo (SageMaker batch transform ou endpoint) → resultado de volta ao lake/DW (S3 + Redshift COPY)

## Key Concepts

### SageMaker — Fases do ML

- **SageMaker Ground Truth**: labeling de dados via ML + curadoria humana; pré-requisito para treinar modelos supervisionados; ex.: labeling de raça de cachorro em fotos
- **SageMaker Data Wrangler**: preparação visual de dados para ML; 300+ transformações sem código; integrado ao SageMaker Studio (IDE para ML); visualização de resultado de transformações
- **SageMaker Clarify**: detecta bias em dataset de treinamento; analisa atributos como idade, gênero, estado civil; alerta sobre concentração ou ausência de grupos → modelo treinado com bias faz predições imprecisas para grupos sub-representados
- **SageMaker Studio Notebooks**: notebooks interativos (Jupyter-compatíveis) no console AWS; backed por EC2 de escolha do usuário; storage em EFS (persiste entre instâncias); compartilhamento para colaboração entre data scientists
- **SageMaker Autopilot**: AutoML para developers sem expertise ML; input = dataset tabular + coluna a predizer; output = leaderboard de múltiplos modelos treinados e tunados; usuário escolhe melhor modelo e deploya
- **SageMaker JumpStart**: soluções end-to-end pré-construídas + modelos pré-treinados; inclui foundation models (HuggingFace, Stable Diffusion, AI21 Labs, Cohere, LightOn); exemplos: churn prediction, credit risk, computer vision, predictive maintenance
- **Hyperparameter Tuning**: SageMaker testa milhares de combinações de parâmetros automaticamente para maximizar acurácia; usuário especifica ranges de hiperparâmetros
- **SageMaker Experiments**: tracking automático de inputs, parâmetros, configurações e resultados de cada training job; integrado ao SageMaker Studio; exporta para pandas DataFrame para análise
- **SageMaker Batch Transform**: predição sobre dataset inteiro em S3; sem endpoint permanente; custo pelo compute do job
- **SageMaker Endpoints**: inference em tempo real; aplicação chama endpoint com dados → recebe predição em millisegundos; ex.: detecção de fraude em transação de cartão
- **SageMaker Model Monitor**: monitora qualidade de modelos em produção continuamente; detecta data quality drift, model quality drift, bias drift; envia notificações quando desvios detectados

### AI Services — Speech & Text

- **Amazon Transcribe**: transcrição speech-to-text via ASR (Automatic Speech Recognition); batch (arquivo S3) + streaming (chunks em tempo real, ex.: live captioning); identifica múltiplos speakers; remove PII (credit card, email) e palavras indesejadas; especialidades: **Transcribe Medical** (terminologia médica), **Transcribe Call Analytics** (sentiment de agente + cliente, interrupções, talk speed)
- **Amazon Textract**: extrai texto de documentos PDF e imagens (impressos e manuscritos); output semi-estruturado (tabelas → CSV, forms → key-value); features: **Analyze Lending** (split automático de loan packages por tipo de documento), detecção de assinaturas, **Textract Queries** (NLQ sobre dados extraídos — ex.: "What is the customer name?"), identity documents (passaporte, driver's license EUA)
- **Amazon Comprehend**: insights de texto via ML pré-treinado; tipos de análise: sentiment (positive/negative/neutral/mixed), entities (pessoa, organização, localização, data), key phrases, PII detection, dominant language, topics; batch (até 25 docs por API call ou job em bucket S3) + near-real-time; **Comprehend Medical** para terminologia médica; custom entity detection com dados próprios

### AI Services — Images & Video

- **Amazon Rekognition**: extrai metadata de imagens e vídeos; features: label detection (objetos, atividades, landmarks), dominant color, facial recognition + comparison + search, celebrity detection, content moderation (unsafe images), text in images; **Rekognition Video**: retorna timestamp de onde objeto foi detectado → índice pesquisável de conteúdo

### AI Services — Forecasting & Personalization

- **Amazon Forecast**: predição de time series; treina modelo customizado sem expertise ML; inputs: dataset histórico (ex.: vendas diárias por loja) + related datasets (ex.: visitantes por loja) + geolocation + timezone → integra previsão meteorológica de 14 dias automaticamente; output: predições exportáveis para S3
- **Amazon Fraud Detector**: detecção de transações fraudulentas e fake account registrations; combina dados históricos da organização com modelo treinado no dataset de fraude da Amazon; latência em milliseconds (inline no checkout)
- **Amazon Personalize**: recomendações personalizadas; captura live events (click-stream) + histórico de perfil → recomenda itens relevantes; ex.: próximo filme, produto relacionado

### Generative AI

- **Foundation Model (FM)**: modelo pré-treinado em massa de dados pública (ex.: todo conteúdo da internet); base para construir soluções especializadas; exemplos: GPT (OpenAI), Claude (Anthropic), Bard (Google), DALL-E (imagens), Stable Diffusion (imagens)
- **LLM (Large Language Model)**: FM para texto; arquitetura Transformer; entende + gera texto conversacional; casos de uso: summarization, Q&A, tradução, geração de conteúdo (marketing copy, histórias)
- **Amazon Bedrock** (lançado set/2023): serverless; FMs de múltiplos providers via API unificada — AI21 Labs, Anthropic (Claude), Cohere, Meta, Stability AI, Amazon; fine-tune privado com dados próprios (dados não vazam para provider); **Amazon Titan Embeddings** (texto → representação numérica para search/personalization), **Titan Text Express** (custo-benefício), **Titan Text Lite** (compacto para tarefas básicas)
- **SageMaker JumpStart para GenAI**: foundation models deployáveis em cluster privado; dados de treino e prompts ficam no account do cliente → confidencialidade garantida; alternativa ao Bedrock quando controle de infraestrutura é necessário

## Reference Tables

### SageMaker — fases e ferramentas

| Fase | Ferramentas SageMaker | Função |
|------|----------------------|--------|
| Preparação | Ground Truth | Labeling de dados |
| Preparação | Data Wrangler | Transformação visual sem código |
| Preparação | Clarify | Detecção de bias no dataset |
| Build | Studio Notebooks | IDE interativo para desenvolvimento do modelo |
| Build | Autopilot | AutoML: treina + tuna múltiplos modelos |
| Build | JumpStart | Soluções pré-construídas + foundation models |
| Train/Tune | Training jobs | Cluster distribuído temporário; data em S3 |
| Train/Tune | Hyperparameter Tuning | Testa milhares de combinações automaticamente |
| Train/Tune | Experiments | Tracking automático de todos os runs |
| Deploy/Manage | Batch Transform | Predição sobre dataset inteiro em S3 |
| Deploy/Manage | Endpoints | Inference em real-time via API |
| Deploy/Manage | Model Monitor | Detecta drift de qualidade em produção |

### AI Services — quando usar qual

| Necessidade | Serviço AWS | Billing |
|------------|-------------|---------|
| Transcrever áudio → texto | Amazon Transcribe | Por segundo de áudio |
| Extrair texto de PDF / imagem / manuscrito | Amazon Textract | Por página |
| Sentiment, entidades, PII de texto | Amazon Comprehend | Por unidade de texto (100 chars) |
| Labels, faces, objetos em imagem/vídeo | Amazon Rekognition | Por imagem / por minuto de vídeo |
| Forecast de séries temporais | Amazon Forecast | Por dataset + por predição |
| Fraude em transações | Amazon Fraud Detector | Por evento analisado |
| Recomendações personalizadas | Amazon Personalize | Por evento de treinamento + por predição |
| Tradução de texto | Amazon Translate | $0.000015/caractere |
| Chatbot, Q&A, geração de conteúdo | Amazon Bedrock | Por token (input + output) |

### Pipeline padrão do data engineer com AI services

| Fonte | Ingestão | Transformação | AI Service | Output |
|-------|----------|---------------|------------|--------|
| Call center recordings | Kinesis Firehose → S3 | — | Transcribe → texto | Comprehend → sentiment → DynamoDB |
| PDF invoices | S3 upload | — | Textract → CSV | Glue ETL → curated zone → Redshift |
| Product images | S3 upload | — | Rekognition → labels | DynamoDB (índice de labels) |
| Sales history | Glue ETL → S3 | Aggregação horária | Forecast → predições | Step Functions → S3 → Redshift COPY |

## Worked Example

**Hands-on Ch13 — Análise de sentiment de reviews com Amazon Comprehend + SQS + Lambda**

**Cenário**: rede hoteleira recebe centenas de reviews diários no site; necessita identificar reviews negativos para follow-up do customer service.

**Arquitetura**:
```
SQS queue (website-reviews-queue)
    → Lambda trigger (website-reviews-analysis-function)
        → Comprehend API (detect_sentiment + detect_entities)
            → CloudWatch Logs (resultado)
```

**Lambda function completa**:
```python
import boto3, json

comprehend = boto3.client(
    service_name='comprehend',
    region_name='us-east-2'
)

def lambda_handler(event, context):
    for record in event['Records']:
        payload = record["body"]

        # Sentiment analysis
        response = comprehend.detect_sentiment(
            Text=payload, LanguageCode='en'
        )
        sentiment = response['Sentiment']          # POSITIVE / NEGATIVE / NEUTRAL / MIXED
        sentiment_score = response['SentimentScore']

        # Entity detection
        response = comprehend.detect_entities(
            Text=payload, LanguageCode='en'
        )
        for entity in response['Entities']:
            print(
                f"ENTITY: {entity['Text']}, "
                f"ENTITY TYPE: {entity['Type']}"
            )
    return  # retorno sem exceção = mensagem deletada da fila SQS
```

**IAM setup**:
```
Lambda execution role:
  - AmazonSQSPollerPermissions  (para ler da fila)
  - ComprehendReadOnly           (para chamar Comprehend API)
```

**Teste com review positivo**:
```
Input: "I recently stayed at the Kensington Hotel in downtown Cape Town..."
→ SENTIMENT: POSITIVE (99% confidence)
→ ENTITY: Kensington Hotel, ORGANIZATION
→ ENTITY: Cape Town, LOCATION
→ ENTITY: Elizabeth's Kitchen, ORGANIZATION
```

**Produção — próximo passo com Step Functions**:
```
Choice state baseado em sentiment:
  NEGATIVE → Lambda → notificação para customer service
  MIXED    → Lambda → envio para manager decidir próximo passo
  POSITIVE → termina sem ação
```

**Configuração do SQS trigger na Lambda**: Lambda > Configuration > Triggers > Add trigger > SQS → selecionar `website-reviews-queue` → Save.

## Key Takeaways

1. Data engineer alimenta ML, não constrói ML: pipeline de dados de qualidade é pré-requisito para qualquer ML funcionar em produção; falha no pipeline = predições incorretas ou ausentes
2. AI Services eliminam necessidade de ML expertise para casos de uso comuns: Transcribe, Textract, Comprehend, Rekognition são APIs com billing por uso; nenhuma infraestrutura, nenhum treinamento de modelo necessário
3. SageMaker Autopilot democratiza modelos customizados: developer sem expertise ML fornece dataset tabular + coluna target → Autopilot treina, tuna e ranqueia múltiplos modelos → usuário deploya o melhor
4. Padrão Transcribe → Comprehend para call centers: transcriver gravações de atendimento → extrair sentiment + entidades → identificar clientes insatisfeitos automaticamente sem revisão humana
5. Textract desestrutura documentos para o lake: PDFs, formulários, manuscritos → dados estruturados → pipeline de análise; sem Textract, esses dados ficariam inacessíveis
6. Amazon Bedrock simplifica generative AI: FMs de múltiplos providers via API serverless; fine-tune com dados próprios sem expor confidencialidade; alternativa a SageMaker JumpStart quando controle de infra não é necessário
7. Amazon Forecast supera forecasting tradicional: integra weather data automaticamente quando geolocation presente; considera fatores externos que fórmulas tradicionais ignoram

## Connects To

- **Ch06**: pipelines de ingestão (Kinesis Firehose) entregam dados de audio/imagem/texto para S3 → AI services processam esses arquivos
- **Ch07**: Glue ETL transforma e agrega dados históricos → input para Amazon Forecast training
- **Ch08**: SageMaker introduzido como ferramenta de ML para data consumers no toolkit; Comprehend e Rekognition mencionados
- **Ch10**: Step Functions orquestra pipeline com AI services — Lambda states chamam Transcribe, Comprehend, Forecast; Choice states roteiam por sentiment
- **Ch09**: pipeline Amazon Forecast exporta predições para S3 → Redshift COPY carrega para análise em DW
- **Ch12**: QuickSight Generative BI usa Amazon Bedrock; scores de SageMaker models alimentam dashboards QuickSight
