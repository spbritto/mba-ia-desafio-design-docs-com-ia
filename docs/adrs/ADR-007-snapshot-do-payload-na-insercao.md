# ADR-007: Snapshot do payload do evento no momento da inserção na outbox

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada no fim da reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos) — decisão tomada após a saída de Marcos e Sofia ([09:50])
- **Relacionados:** [ADR-001](./ADR-001-outbox-no-mysql.md) · [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md) · [ADR-005](./ADR-005-entrega-at-least-once-com-event-id.md)

## Contexto

Entre a inserção do evento na outbox e o envio efetivo passa tempo: até um ciclo de polling no caso normal ([ADR-002](./ADR-002-worker-separado-com-polling.md)) e até ~14 h 36 min em caso de retentativas ([ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md)), além de replays manuais da DLQ. Nesse intervalo o pedido pode mudar de novo.

A pergunta: "o evento da outbox guarda o payload renderizado já, ou guarda só order_id e renderiza na hora do envio?" ([09:51] Bruno).

## Decisão

**Renderizar o payload completo no momento da inserção na outbox e gravá-lo como snapshot** ([09:52] Larissa). "Concordo, snapshot na inserção" ([09:52] Diego); "Beleza, snapshot. Decidido" ([09:52] Bruno).

O conteúdo do payload (campos como `order_id`, `order_number`, `from_status`, `to_status`, `customer_id`, `total_cents`, sem itens — [09:43] Diego) é especificado no FDD. Todos esses campos já estão disponíveis no `order` carregado dentro da transação de `changeStatus` (`src/modules/orders/order.service.ts`; model `Order` em `prisma/schema.prisma`).

## Alternativas Consideradas

### A. Guardar só o `order_id` e renderizar no envio — `ADR-007-ALT-A`
Gravar uma referência e montar o payload quando o worker for enviar ([09:51] Bruno). **Descartada:** se o pedido mudar depois, o evento deixaria de refletir o estado do momento da mudança — "senão tem caso esquisito" ([09:52] Larissa). Exemplo: um evento `PAID → PROCESSING` reenviado horas depois, já com o pedido `SHIPPED`, carregaria dados incoerentes com a transição anunciada.

## Consequências

### Positivas
- **Fidelidade histórica:** o evento descreve exatamente o estado do momento da transição ([09:52] Larissa).
- **Consistência entre tentativas:** retentativas e replays da DLQ reenviam o mesmo conteúdo, o que combina com a deduplicação por `X-Event-Id` ([ADR-005](./ADR-005-entrega-at-least-once-com-event-id.md)).
- **Worker mais simples:** não precisa consultar `orders` no envio, só ler a outbox.
- **Tamanho conhecido desde a inserção**, o que facilita verificar o limite de 64 KB ([09:24] Larissa), aplicado no worker conforme a interpretação L-02 (detalhada no FDD).

### Negativas
- **Mais armazenamento por evento** na outbox (mitigado pelo payload enxuto, [09:43] Diego, [09:44] Bruno).
- **O snapshot pode estar desatualizado** em relação ao estado atual do pedido; é intencional — o cliente consulta `GET /orders/:id` se precisar do estado corrente ([09:43] Diego).
- **Mudanças futuras no formato do payload** só afetam eventos novos; eventos já gravados mantêm o formato antigo.
- **Decisão tomada sem PM e Segurança na call** ([09:50]); vale confirmar com Marcos e Sofia na revisão do RFC.

### Trade-off aceito
Paga-se **um pouco mais de armazenamento** para garantir que **cada evento seja imutável e fiel à transição que anuncia**, independentemente de quando for entregue.

## Referências

- Transcrição: [09:43] Diego, [09:44] Bruno, [09:24] Larissa, [09:50] (saída de Marcos e Sofia), [09:51] Bruno, [09:52] Larissa, [09:52] Diego, [09:52] Bruno
- Código: `src/modules/orders/order.service.ts` (`changeStatus`), `prisma/schema.prisma` (model `Order`)
