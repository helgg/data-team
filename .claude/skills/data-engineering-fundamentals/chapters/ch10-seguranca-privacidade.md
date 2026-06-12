# Ch10 — Segurança e Privacidade

## Core Idea

Segurança não é uma checklist de compliance — é um hábito constante de pensamento e ação. O elo mais fraco é sempre humano. Engenheiros de dados lidam com os dados mais sensíveis da organização; uma violação pode destruir carreiras e empresas. A ordem correta de atenção é: **Pessoas → Processos → Tecnologia**.

---

## Frameworks Introduzidos

### 1. Triângulo de Segurança para DE

```
         PESSOAS
        (elo mais fraco)
           /    \
    PROCESSOS — TECNOLOGIA
```

Resolver pessoas e processos primeiro. Tecnologia sem disciplina humana falha.

### 2. Pensamento Negativo como Ferramenta de Segurança

Atul Gawande: pensamento positivo deixa despreparado; pensamento negativo permite considerar cenários desastrosos e tomar medidas preventivas.

Aplicação prática:
- Antes de ingerir dados: "O que acontece se esses dados vazarem?"
- Antes de conceder acesso: "O que pode dar errado com esse privilégio?"
- Antes de publicar pipeline: "Que vetor de ataque isso abre?"

### 3. Segurança Ativa vs. Compliance Passivo

| Modo | Comportamento | Resultado |
|------|--------------|-----------|
| Compliance passivo | Checklist anual, política que ninguém lê, auditorias de papel (SOC-2, ISO 27001) | Falsa sensação de segurança |
| Segurança ativa | Investigar ataques reais ocorridos, analisar vulnerabilidades específicas da organização, revisar mensalmente | Redução real de risco |

### 4. Princípio do Privilégio Mínimo

- Pessoas: funções IAM exatamente necessárias, revogadas quando não mais precisadas
- Sistemas: contas de serviço com escopo mínimo
- Dados: controle de acesso em nível de coluna/linha/célula
- Emergências: processo de "quebra de vidro" para dados super-sensíveis (acesso aprovado, auditado, revogado após uso)

### 5. Modelo de Responsabilidade Compartilhada na Nuvem

| Responsabilidade | Provedor cloud | Você |
|-----------------|---------------|------|
| Segurança física dos data centers | ✓ | |
| Hardware e infraestrutura | ✓ | |
| Configuração de serviços, permissões, código | | ✓ |
| Gestão de credenciais e acesso | | ✓ |
| Criptografia de dados (configuração) | | ✓ |

A maioria das violações em cloud é causada pelo usuário, não pelo provedor.

---

## Key Concepts

**Privacidade como requisito legal** — FERPA (educação, 1970s), HIPAA (saúde, 1990s), GDPR (Europa, 2016), leis estaduais EUA em expansão. Violações acarretam multas devastadoras. DE toca dados cobertos por todas essas leis.

**Melhor proteção = não coletar** — dado não ingerido não pode vazar. Colete dados sensíveis apenas se houver necessidade downstream real.

**SSO + MFA como padrão** — Single Sign-On elimina proliferação de senhas. MFA torna roubo de credencial insuficiente para acesso. Nunca compartilhar senhas, nem entre colegas.

**Credenciais no código = vazamento garantido** — scripts comitados com senha vão para repositórios, logs, backups. Usar gerenciadores de credenciais; tratar senhas como configuração externa.

**Criptografia em repouso** — full-disk encryption em dispositivos; server-side encryption em todos os buckets/bancos; backups criptografados. Não é varinha mágica: falha se credenciais forem comprometidas.

**Criptografia over the wire** — HTTPS obrigatório; evitar FTP (suscetível a man-in-the-middle mesmo com dados "públicos"). Verificar que buckets públicos não expõem dados sensíveis — HTTPS não protege se permissão estiver aberta.

**Monitoramento de acesso** — "Quem acessou o quê, quando e de onde?" Padrões incomuns (usuário acessando sistema que nunca usa) = possível comprometimento. Auditar logs regularmente.

**Monitoramento de faturamento** — pico inesperado de custo cloud = possível exploração maliciosa de recursos. Configurar alertas de orçamento.

**Excesso de permissões (Permission Sprawl)** — ferramentas modernas detectam permissões não usadas por período configurável e revogam automaticamente. Analista sem acesso ao Redshift por 6 meses → revogar; abrir chamado se precisar novamente.

**Backup + teste de restauração** — ransomware está crescendo; seguradoras reduzindo reembolsos. Backup sem teste = falsa segurança. Testar restauração periodicamente.

**Segurança zero-trust vs. perímetro** — cloud adota zero-trust (cada ação exige autenticação). On-premises usa perímetro (confia em quem está dentro da rede). Zero-trust é mais seguro para a maioria das organizações modernas.

---

## Mental Models

**"Aja como se você fosse sempre um alvo."** — A qualquer momento, alguém tenta comprometer suas credenciais. Postura defensiva constante, online e offline.

**"Nunca dê mais acesso do que o necessário."** — Qualquer permissão extra = superfície de ataque extra. Acesso mínimo como padrão; expandir apenas quando justificado.

**"Segurança precisa ser simples o suficiente para virar hábito."** — Política extensa que ninguém lê = zero segurança. Revisões mensais curtas > auditoria anual longa.

**"Você também é guarda de privacidade e ética."** — Desconforto com dados coletados ou uso dos dados = sinal importante. Falar com colegas e liderança. Conformidade com a lei não é teto — é piso.

**"Em dúvida sobre credenciais? Verifique primeiro."** — Uma ligação para confirmar vale mais que horas de resposta a incidente de ransomware.

---

## Anti-patterns

- **Admin para todos por conveniência** — um comprometimento = acesso total ao ambiente.
- **Credenciais hardcoded no código/notebook** — vaza para git, logs, backups automaticamente.
- **S3 bucket público com dados sensíveis** — causa mais comum de grandes vazamentos de dados em cloud.
- **SSH aberto para 0.0.0.0/0** — qualquer IP do mundo pode tentar conexão; whitelisting de IPs obrigatório.
- **Banco de dados acessível pela internet pública** — nunca expor diretamente; usar VPC, VPN, bastion host.
- **Compliance de papel (SOC-2 sem comprometimento)** — auditorias passam, cultura de segurança não existe.
- **Backup sem teste de restauração** — backup corrompido ou processo quebrado só é descoberto na emergência.
- **FTP para dados "públicos"** — suscetível a man-in-the-middle; dados podem ser alterados em trânsito.
- **Ignorar alertas de atualização de software** — vulnerabilidades conhecidas permanecem abertas desnecessariamente.

---

## Worked Example

**Política de segurança mínima para time de dados (baseada no exemplo do livro):**

**Credenciais:**
```
✓ SSO como padrão (evitar senha individual)
✓ MFA em todos os sistemas
✗ Nunca compartilhar senha (nem com cliente)
✗ Nunca hardcode credentials no código
✓ Gerenciador de senhas para credenciais necessárias
✓ Desativar/excluir credenciais antigas
✓ Privilégio mínimo para todas as funções IAM
```

**Dispositivos:**
```
✓ MDM (Mobile Device Management) configurado
✓ MFA no login do dispositivo
✓ Criptografia de disco completo
✓ Modo "não perturbe" em videochamadas
✓ Nunca deixar dispositivo fora do alcance visual
```

**Monitoramento (dashboard da equipe):**
- Logs de acesso: novos usuários, padrões incomuns, falhas de autenticação
- Recursos: picos de CPU/memória/disco inexplicados
- Faturamento: alertas de orçamento com limites configurados
- Permissões: relatório semanal de permissões não utilizadas há >30 dias

---

## Key Takeaways

1. Pessoas são o elo mais fraco. Cultura de segurança > ferramentas de segurança.
2. Pensamento negativo é ferramenta preventiva: "O que pode dar errado com essa decisão?"
3. Segurança ativa > compliance passivo. Checklists de papel não protegem; hábitos constantes sim.
4. Princípio do privilégio mínimo: mínimo acesso necessário, para o tempo necessário, para humanos e sistemas igualmente.
5. Criptografia em repouso + over the wire é requisito básico, não diferencial.
6. Monitorar acesso, recursos e faturamento — picos inesperados são sinal de comprometimento.
7. Backup sem teste de restauração não é backup. Ransomware está crescendo; seguradoras reduzindo cobertura.
8. Não coletar dados sensíveis desnecessários = melhor proteção de privacidade possível.

---

## Connects To

- [ch02] Ciclo de vida DE — segurança é elemento subjacente presente em todas as etapas
- [ch03] Arquitetura — zero-trust vs. segurança de perímetro; nuvem é mais segura para maioria das organizações
- [ch05] Sistemas de origem — DCL, controle de acesso, contratos de dados
- [ch08] Transformações — DCL para controle de acesso em queries; credenciais em pipelines
- [ch09] Disponibilização — maior superfície de segurança do ciclo de vida; privilégio mínimo por papel (analista vs. cientista de dados vs. pipeline)
