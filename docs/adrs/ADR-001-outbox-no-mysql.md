# ADR-001: Padrão Outbox no MySQL para publicação de eventos de webhook

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada na reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos)
- **Relacionados:** [ADR-002](./ADR-002-worker-separado-com-polling.md) · [ADR-005](./ADR-005-entrega-at-least-once-com-event-id.md) · [ADR-007](./ADR-007-snapshot-do-payload-na-insercao.md)

## Contexto

Três clientes B2B pediram para ser notificados quando o status dos seus pedidos muda; hoje eles fazem polling no `GET /orders` ([09:00] Marcos), com tolerância de até 10 segundos ([09:02] Marcos). O evento nasce dentro de `OrderService.changeStatus` (`src/modules/orders/order.service.ts`), que executa tudo em uma única `this.prisma.$transaction`: valida a transição, debita ou repõe estoque, atualiza `orders` e insere em `order_status_history`.

As forças em jogo:

- **Transação já pesada.** A mudança de status "atualiza orders, insere na order_status_history, decrementa stock_quantity" ([09:04] Bruno). Qualquer I/O externo dentro dela prolonga locks e afeta outros pedidos.
- **Cliente indisponível não pode afetar o pedido.** Não é aceitável desfazer a mudança de status porque o endpoint do cliente está fora do ar ([09:04] Bruno).
- **Consistência obrigatória.** "Não pode ter caso de status mudar e evento não sair" ([09:40] Bruno); "se ficar fora da transação, perde a garantia toda" ([09:41] Diego).
- **Time pequeno e infraestrutura enxuta.** O ambiente tem apenas MySQL 8 (`docker-compose.yml`); não há broker ou fila. Subir infraestrutura nova para isso seria "overengineering" ([09:07] Diego).

## Decisão

Adotar o **padrão Outbox sobre o MySQL existente** ([09:06] Diego; "Tá decidido então: outbox em MySQL", [09:08] Larissa):

1. Dentro da **mesma transação** do `changeStatus`, após o insert em `order_status_history`, inserir uma linha na tabela `webhook_outbox` representando o evento ([09:06] Diego, [09:40] Bruno).
2. Se a inserção na outbox falhar, a transação inteira faz rollback — a mudança de status não acontece sem o evento ([09:40] Bruno).
3. A inserção é feita por uma função que recebe o client transacional (`publishWebhookEvent(tx, order, fromStatus, toStatus)`), chamada pelo `order.service` ([09:41] Bruno, [09:41] Diego).
4. Um worker separado lê a outbox e faz as chamadas HTTP (ver [ADR-002](./ADR-002-worker-separado-com-polling.md)).
5. A tabela é indexada por status (pendente, processando, falhou, entregue) e por `created_at`; o worker lê apenas pendentes, em lotes pequenos ([09:08] Diego).

Commit da transação ⇒ evento registrado; rollback ⇒ evento descartado junto. "Não tem inconsistência possível" ([09:06] Diego).

## Alternativas Consideradas

### A. Disparo HTTP síncrono dentro do `changeStatus` — `ADR-001-ALT-A`
Chamar o endpoint do cliente durante a mudança de status. **Descartada:** um cliente lento "vai travar mudança de status pra outros pedidos" ([09:04] Bruno), e cliente fora do ar forçaria escolher entre rollback do status ou perda do evento ([09:04] Bruno). "Síncrono está fora de questão" ([09:06] Diego).

### B. Redis Streams (ou fila/broker equivalente) — `ADR-001-ALT-B`
Publicar o evento em uma fila externa consumida por um worker. **Descartada:** "a gente acabaria precisando subir mais infra" ([09:07] Larissa); para um time pequeno, "subir Redis Cluster pra isso é overengineering" ([09:07] Diego). Além disso, publicar em um sistema externo não participa da transação MySQL — o problema de consistência voltaria.

### C. Inserir o evento fora da transação (após o commit) — `ADR-001-ALT-C`
Gravar o evento em um passo separado depois da mudança de status. **Descartada:** uma falha entre o commit e a inserção perderia o evento — "se ficar fora da transação, perde a garantia toda" ([09:41] Diego).

## Consequências

### Positivas
- **Atomicidade** entre mudança de status e evento, sem coordenação distribuída ([09:06] Diego).
- **Isolamento de falhas:** lentidão ou indisponibilidade do cliente não afeta a transação de pedidos ([09:04] Bruno).
- **Zero infraestrutura nova:** usa o MySQL e o Prisma já existentes (`prisma/schema.prisma`, `src/config/database.ts`).
- **Rastro persistente** de todo evento emitido, base para histórico de entregas e DLQ ([ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md)).

### Negativas
- **Uma escrita a mais na transação crítica** de pedidos; uma falha na outbox passa a bloquear a mudança de status (comportamento intencional, mas é um novo ponto de falha).
- **Latência adicional** de até um ciclo de polling entre o commit e o envio ([ADR-002](./ADR-002-worker-separado-com-polling.md)).
- **Crescimento contínuo da tabela.** O arquivamento de linhas entregues (~30 dias) foi mencionado e deixado **fora do escopo** desta feature ([09:08] Diego).
- **Acoplamento** do módulo de pedidos ao de webhooks, mitigado por uma função pura recebendo `tx` em vez de injetar um repository ([09:41] Diego).

### Trade-off aceito
Troca-se uma escrita extra na transação de pedidos e alguns segundos de latência por **garantia de consistência sem infraestrutura nova**. Para o requisito de < 10 s ([09:02] Marcos) e o tamanho do time ([09:07] Diego), é o ponto de equilíbrio escolhido.

## Referências

- Transcrição: [09:00] Marcos, [09:02] Marcos, [09:04] Bruno, [09:06] Diego, [09:07] Larissa, [09:07] Diego, [09:08] Diego, [09:08] Larissa, [09:40] Bruno, [09:41] Bruno, [09:41] Diego
- Código: `src/modules/orders/order.service.ts` (`changeStatus`, `$transaction`), `prisma/schema.prisma` (`OrderStatusHistory`), `docker-compose.yml` (apenas MySQL)
