# ADR-004: Autenticação das entregas com HMAC-SHA256 e secret por endpoint, com rotação e grace period de 24 h

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada na reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Sofia (Segurança), com Bruno (Pedidos), Diego (Plataforma) e Larissa (Tech Lead)
- **Relacionados:** [ADR-005](./ADR-005-entrega-at-least-once-com-event-id.md) · [ADR-006](./ADR-006-reuso-dos-padroes-do-projeto.md)

## Contexto

Os webhooks são **apenas de saída** — a plataforma envia, o cliente recebe ([09:02] Marcos, [09:03] Sofia). Os eventos carregam dados de pedidos para endpoints fora da infraestrutura da empresa, e o cliente precisa conseguir validar duas coisas: que **a requisição veio de fato da plataforma** e que **ninguém adulterou o payload** no caminho ([09:19] Sofia).

Há histórico concreto de risco: "a gente já teve cliente que vazou secret em log de aplicação dele uma vez" ([09:22] Diego).

## Decisão

"Decidido: HMAC-SHA256 sobre o corpo do request, secret por endpoint, suporte a rotação com grace period de 24h" ([09:22] Sofia). Em detalhe:

1. **Assinatura HMAC** do corpo do request com uma secret compartilhada entre plataforma e cliente, enviada no header `X-Signature`; o cliente recalcula e compara ([09:20] Sofia).
2. **Algoritmo SHA-256**, padrão de mercado com bibliotecas disponíveis para qualquer cliente ([09:20] Sofia).
3. **Uma secret por endpoint de webhook**, nunca uma secret global da plataforma ([09:21] Sofia), armazenada na configuração do webhook junto com url, `customer_id` e estado ativo ([09:21] Bruno, [09:21] Sofia).
4. **Secret gerada pela plataforma** e devolvida ao cliente na criação do webhook ([09:31] Marcos).
5. **Rotação pela API:** o cliente solicita uma nova secret; a antiga continua válida por **24 horas em paralelo** e depois é invalidada ([09:21] Sofia).
6. **Revisão de segurança dedicada** do código de HMAC e de geração de secret, com pelo menos dois dias úteis antes do deploy ([09:46] Sofia).

Complementam esta decisão, como requisitos e não como decisões arquiteturais: URL obrigatoriamente `https` validada no schema Zod ([09:23] Sofia) e header `X-Timestamp` para permitir ao cliente detectar replay ([09:44] Diego) — detalhados no FDD.

> **Proposta aprovada (L-03) — assinatura durante o grace period.** Como quem verifica é o cliente, "a antiga fica válida por 24 horas" ([09:21] Sofia) significa que, durante a janela, a plataforma precisa assinar de forma que **tanto a secret nova quanto a antiga validem**. A reunião não definiu o mecanismo. Proposta: durante as 24 h, enviar **duas assinaturas** no `X-Signature` (uma por secret). O formato exato fica no FDD e o ponto segue como questão em aberto no RFC, para a revisão da Sofia.

## Alternativas Consideradas

### A. Secret global da plataforma — `ADR-004-ALT-A`
Uma única secret para assinar os envios de todos os clientes. **Descartada:** "se vaza uma, vaza tudo" ([09:21] Sofia) — o vazamento em um cliente comprometeria a autenticidade das entregas de todos.

### B. Apenas TLS, sem assinatura (alternativa plausível, não discutida) — `ADR-004-ALT-B`
Confiar só no `https`. **Não atende:** TLS protege o transporte e autentica o servidor do cliente para a plataforma, mas não prova ao cliente que a requisição partiu da plataforma — que é a exigência de [09:19] Sofia. Por isso o `https` é obrigatório ([09:23] Sofia), mas como complemento ao HMAC.

## Consequências

### Positivas
- **Autenticidade e integridade** verificáveis pelo cliente com bibliotecas comuns ([09:20] Sofia).
- **Raio de impacto limitado:** um vazamento compromete apenas um endpoint ([09:21] Sofia).
- **Rotação sem downtime:** a janela de 24 h dá tempo ao cliente para migrar seus sistemas ([09:21] Sofia).
- **Sem dependência nova:** o módulo nativo `crypto` do Node ≥ 20 (`package.json`, `engines`) cobre HMAC-SHA256 e geração aleatória de secrets.

### Negativas
- **A secret precisa ser recuperável em texto claro** pela plataforma para assinar — ao contrário de senhas, não pode ser guardada só como hash. O armazenamento vira um ativo sensível.
- **Risco de vazamento em log:** o `redact` atual do logger (`src/shared/logger/index.ts`) não cobre `secret` nem `X-Signature`; o FDD deve propor incluir esses caminhos.
- **Complexidade da janela de rotação:** gerenciar duas secrets ativas e duas assinaturas por 24 h.
- **Responsabilidade do cliente:** ele precisa implementar a verificação corretamente.

### Trade-off aceito
Aceita-se o custo de **guardar e gerenciar uma secret por endpoint, com rotação**, em troca de **autenticidade por cliente e contenção de vazamentos** — risco que já aconteceu na prática ([09:22] Diego).

## Referências

- Transcrição: [09:02] Marcos, [09:03] Sofia, [09:19] Sofia, [09:20] Sofia, [09:20] Bruno, [09:21] Sofia, [09:21] Bruno, [09:22] Diego, [09:22] Sofia, [09:23] Sofia, [09:31] Marcos, [09:44] Diego, [09:46] Sofia
- Código: `package.json` (Node ≥ 20, módulo `crypto` nativo), `src/shared/logger/index.ts` (configuração de `redact`)
