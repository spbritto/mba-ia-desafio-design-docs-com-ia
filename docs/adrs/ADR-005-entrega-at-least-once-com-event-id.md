# ADR-005: Garantia de entrega at-least-once com deduplicação pelo cliente via `X-Event-Id`

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada na reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma); trade-off levantado por Sofia (Segurança); comunicação ao cliente por Marcos (PM)
- **Relacionados:** [ADR-001](./ADR-001-outbox-no-mysql.md) · [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md) · [ADR-004](./ADR-004-autenticacao-hmac-sha256-por-endpoint.md)

## Contexto

A combinação outbox + worker + retry ([ADR-001](./ADR-001-outbox-no-mysql.md), [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md)) torna inevitável que, em alguns casos, o cliente receba o mesmo evento mais de uma vez. Um exemplo típico: o cliente processa a requisição, mas a resposta não chega à plataforma dentro do timeout de 10 s ([09:42] Diego); a plataforma registra falha e reenvia.

É preciso definir **qual garantia de entrega** a plataforma oferece e **como o cliente distingue duplicatas**.

## Decisão

"At-least-once com X-Event-Id pra dedup do lado do cliente. Decisão." ([09:26] Larissa)

1. A plataforma garante **entrega pelo menos uma vez**; o cliente pode receber o mesmo evento duas vezes e deve estar preparado ([09:24] Diego).
2. Cada evento recebe um **UUID gerado no momento em que entra na outbox**, único por evento, enviado no header `X-Event-Id` ([09:25] Diego).
3. O **cliente deduplica** pelo `X-Event-Id` do lado dele ([09:25] Diego).
4. A semântica é **documentada em destaque no portal de desenvolvedor** ([09:26] Marcos).

> **Interpretação — `event_id` no replay da DLQ.** O replay "recoloca na outbox como pendente" ([09:18] Diego) — é o mesmo evento, não um novo. Leitura adotada: o replay **preserva o `event_id` original**, para que a deduplicação do cliente continue funcionando caso ele já tenha recebido o evento.

## Alternativas Consideradas

### A. Exactly-once — `ADR-005-ALT-A`
Garantir que cada evento seja processado exatamente uma vez. **Descartada:** "exigiria coordenação dos dois lados e fica muito mais complexo"; at-least-once com `event_id` é o padrão de mercado ("Stripe faz assim, GitHub faz assim") ([09:25] Diego).

### B. At-most-once (sem retentativas) — alternativa plausível, não discutida — `ADR-005-ALT-B`
Enviar uma única vez e aceitar perdas. **Incompatível** com a decisão de retry com backoff e DLQ ([ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md)): clientes com indisponibilidade temporária perderiam eventos ([09:16] Diego).

## Consequências

### Positivas
- **Simplicidade** de implementação, sem protocolo de confirmação entre as partes ([09:25] Diego).
- **Alinhado ao mercado**, o que reduz o atrito de integração dos clientes ([09:25] Diego).
- **Robustez:** combinado ao retry, nenhum evento é perdido silenciosamente.

### Negativas
- **Responsabilidade transferida ao cliente:** "isso joga responsabilidade pro cliente" ([09:25] Sofia). Ele precisa guardar os `event_id` já processados.
- **Dependência de comunicação:** se a semântica não estiver clara no portal ([09:26] Marcos), clientes podem processar duplicatas (por exemplo, disparar uma expedição duas vezes).
- **Não resolve a ordem:** deduplicação não reordena eventos (ver limitações no [ADR-002](./ADR-002-worker-separado-com-polling.md) e no [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md)).

### Trade-off aceito
Prefere-se **simplicidade e robustez do lado da plataforma**, pagando com **deduplicação obrigatória do lado do cliente**, mitigada por documentação no portal ([09:26] Marcos).

## Referências

- Transcrição: [09:16] Diego, [09:18] Diego, [09:24] Diego, [09:25] Bruno, [09:25] Diego, [09:25] Sofia, [09:26] Marcos, [09:26] Larissa, [09:42] Diego
- Código: `package.json` (dependência `uuid` já presente), `prisma/schema.prisma` (convenção de ids `@default(uuid())`)
