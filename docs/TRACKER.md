# Tracker de Rastreabilidade

Referência cruzada entre cada item registrado no pacote de design docs e a sua origem na reunião (`TRANSCRICAO.md`) ou no código do repositório.

## Como ler

- **ID** — identificador do item, igual ao que aparece no documento (ex.: `PRD-FR-08` está na tabela de requisitos do PRD; `ADR-003-ALT-B` está no título da alternativa B do ADR-003).
- **Fonte** — `TRANSCRICAO` ou `CODIGO`. Quando um item tem as duas origens, a fonte é a que **define o conteúdo**: decisões e requisitos → `TRANSCRICAO`; pontos de integração com arquivos existentes → `CODIGO`.
- **Localização** — para `TRANSCRICAO`, `[hh:mm] Nome` da fala; a **primeira é a principal** (a que propõe ou fecha o item) e as demais, separadas por `;`, são complementares. Para `CODIGO`, caminho do arquivo no repositório.
- **(proposta)** / **(interpretação)** no resumo indicam itens que a reunião não fechou literalmente; a localização aponta a fala ou o arquivo **de onde derivam**. Interpretações aprovadas estão listadas na matriz de trabalho (`notas/matriz-transcricao.md`, seção 16).
- Itens **sem nenhuma origem direta** não estão na tabela principal: ficam no [anexo](#anexo--itens-sem-origem-direta), com justificativa.

## Resumo de cobertura

| Indicador | Valor | Meta do desafio |
|---|---|---|
| IDs identificáveis nos documentos | 232 | — |
| Linhas na tabela principal | 228 | — |
| Itens no anexo (sem origem direta) | 4 | — |
| **Cobertura** (IDs com linha na tabela / IDs nos documentos) | **98,3%** (228/232) | ≥ 80% |
| **Linhas com Fonte = `TRANSCRICAO`** e `[hh:mm] Nome` válido | **204 (89,5%)** | ≥ 70% |
| **Linhas com Fonte = `CODIGO`** e caminho existente | **24** | ≥ 5 |

| Documento | Linhas |
|---|---|
| ADRs (`docs/adrs/`) | 23 (7 decisões + 16 alternativas) |
| RFC (`docs/RFC.md`) | 26 |
| FDD (`docs/FDD.md`) | 103 |
| PRD (`docs/PRD.md`) | 76 |

## Tabela de rastreabilidade

| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |
|---|---|---|---|---|---|
| ADR-001 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Decisão | Outbox no MySQL, gravada na mesma transação da mudança de status | TRANSCRICAO | [09:08] Larissa; [09:06] Diego; [09:40] Bruno |
| ADR-001-ALT-A | `docs/adrs/ADR-001-outbox-no-mysql.md` | Alternativa Descartada | Envio HTTP síncrono dentro do `changeStatus` | TRANSCRICAO | [09:04] Bruno; [09:06] Diego |
| ADR-001-ALT-B | `docs/adrs/ADR-001-outbox-no-mysql.md` | Alternativa Descartada | Redis Streams ou outro broker (infra nova, overengineering) | TRANSCRICAO | [09:07] Larissa; [09:07] Diego |
| ADR-001-ALT-C | `docs/adrs/ADR-001-outbox-no-mysql.md` | Alternativa Descartada | Gravar o evento fora da transação, após o commit | TRANSCRICAO | [09:41] Diego |
| ADR-002 | `docs/adrs/ADR-002-worker-separado-com-polling.md` | Decisão | Worker em processo separado, polling de 2 s, single-worker | TRANSCRICAO | [09:10] Larissa; [09:09] Diego; [09:11] Diego; [09:11] Larissa |
| ADR-002-ALT-A | `docs/adrs/ADR-002-worker-separado-com-polling.md` | Alternativa Descartada | Trigger no banco para acordar o worker | TRANSCRICAO | [09:09] Diego; [09:09] Bruno |
| ADR-002-ALT-B | `docs/adrs/ADR-002-worker-separado-com-polling.md` | Alternativa Descartada | Worker dentro do processo da API | TRANSCRICAO | [09:11] Diego |
| ADR-002-ALT-C | `docs/adrs/ADR-002-worker-separado-com-polling.md` | Alternativa Adiada | Múltiplos workers em paralelo (particionar por `order_id` ou lock) | TRANSCRICAO | [09:13] Diego; [09:12] Diego |
| ADR-003 | `docs/adrs/ADR-003-retry-backoff-exponencial-e-dlq.md` | Decisão | Backoff 1m/5m/30m/2h/12h, DLQ em tabela separada e replay manual (contagem 1 + 5 por interpretação) | TRANSCRICAO | [09:17] Larissa; [09:17] Diego; [09:18] Diego |
| ADR-003-ALT-A | `docs/adrs/ADR-003-retry-backoff-exponencial-e-dlq.md` | Alternativa Descartada | Retry indefinido com backoff | TRANSCRICAO | [09:15] Diego |
| ADR-003-ALT-B | `docs/adrs/ADR-003-retry-backoff-exponencial-e-dlq.md` | Alternativa Descartada | Apenas 3 tentativas | TRANSCRICAO | [09:16] Diego; [09:16] Bruno |
| ADR-003-ALT-C | `docs/adrs/ADR-003-retry-backoff-exponencial-e-dlq.md` | Alternativa Descartada | Marcar como "failed" na própria outbox, sem tabela de DLQ | TRANSCRICAO | [09:18] Diego; [09:17] Larissa |
| ADR-004 | `docs/adrs/ADR-004-autenticacao-hmac-sha256-por-endpoint.md` | Decisão | HMAC-SHA256 sobre o corpo, secret por endpoint, rotação com 24 h | TRANSCRICAO | [09:22] Sofia; [09:20] Sofia; [09:21] Sofia |
| ADR-004-ALT-A | `docs/adrs/ADR-004-autenticacao-hmac-sha256-por-endpoint.md` | Alternativa Descartada | Secret global da plataforma | TRANSCRICAO | [09:21] Sofia |
| ADR-004-ALT-B | `docs/adrs/ADR-004-autenticacao-hmac-sha256-por-endpoint.md` | Alternativa (plausível) | Apenas TLS, sem assinatura — não prova a origem ao cliente | TRANSCRICAO | [09:19] Sofia; [09:23] Sofia |
| ADR-005 | `docs/adrs/ADR-005-entrega-at-least-once-com-event-id.md` | Decisão | At-least-once com deduplicação pelo cliente via `X-Event-Id` | TRANSCRICAO | [09:26] Larissa; [09:24] Diego; [09:25] Diego |
| ADR-005-ALT-A | `docs/adrs/ADR-005-entrega-at-least-once-com-event-id.md` | Alternativa Descartada | Exactly-once | TRANSCRICAO | [09:25] Diego |
| ADR-005-ALT-B | `docs/adrs/ADR-005-entrega-at-least-once-com-event-id.md` | Alternativa (plausível) | At-most-once, sem retentativas — incompatível com o retry decidido | TRANSCRICAO | [09:16] Diego |
| ADR-006 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Decisão | Reuso de módulos, `AppError` + `WEBHOOK_*`, Pino, error middleware, `requireRole`, Zod | TRANSCRICAO | [09:30] Larissa; [09:27] Bruno; [09:28] Bruno; [09:29] Bruno |
| ADR-006-ALT-A | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Alternativa Descartada | Injetar um repository de webhook no `OrderService` | TRANSCRICAO | [09:41] Diego; [09:41] Bruno |
| ADR-006-ALT-B | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Alternativa (plausível) | Estrutura e bibliotecas próprias para o módulo | TRANSCRICAO | [09:29] Bruno; [09:30] Larissa |
| ADR-007 | `docs/adrs/ADR-007-snapshot-do-payload-na-insercao.md` | Decisão | Payload renderizado e gravado na inserção (snapshot) | TRANSCRICAO | [09:52] Larissa; [09:52] Diego; [09:52] Bruno |
| ADR-007-ALT-A | `docs/adrs/ADR-007-snapshot-do-payload-na-insercao.md` | Alternativa Descartada | Guardar só `order_id` e renderizar no envio | TRANSCRICAO | [09:52] Larissa; [09:51] Bruno |
| RFC-PROP-01 | `docs/RFC.md` | Proposta Técnica | Captura do evento: `publishWebhookEvent(tx)` na transação, snapshot, filtro na inserção | TRANSCRICAO | [09:41] Bruno; [09:34] Bruno; [09:40] Bruno |
| RFC-PROP-02 | `docs/RFC.md` | Proposta Técnica | Entrega por worker próprio, polling de 2 s, Prisma próprio, single-worker | TRANSCRICAO | [09:09] Diego; [09:11] Larissa; [09:30] Bruno; [09:12] Diego |
| RFC-PROP-03 | `docs/RFC.md` | Proposta Técnica | Falhas: timeout de 10 s, backoff, DLQ e replay manual | TRANSCRICAO | [09:17] Larissa; [09:42] Diego; [09:18] Diego; [09:36] Sofia |
| RFC-PROP-04 | `docs/RFC.md` | Proposta Técnica | Segurança: secret por endpoint, rotação 24 h, HMAC-SHA256, `https` obrigatório | TRANSCRICAO | [09:22] Sofia; [09:23] Sofia |
| RFC-PROP-05 | `docs/RFC.md` | Proposta Técnica | Semântica at-least-once; ordem só por pedido e single-worker | TRANSCRICAO | [09:26] Larissa; [09:13] Larissa |
| RFC-PROP-06 | `docs/RFC.md` | Proposta Técnica | Novo módulo no padrão existente, erros `WEBHOOK_*` | TRANSCRICAO | [09:30] Larissa |
| RFC-ALT-01 | `docs/RFC.md` | Alternativa Descartada | Envio HTTP síncrono no `changeStatus` | TRANSCRICAO | [09:04] Bruno; [09:06] Diego |
| RFC-ALT-02 | `docs/RFC.md` | Alternativa Descartada | Redis Streams ou outro broker | TRANSCRICAO | [09:07] Larissa; [09:07] Diego |
| RFC-ALT-03 | `docs/RFC.md` | Alternativa Descartada | Trigger no banco | TRANSCRICAO | [09:09] Diego; [09:09] Bruno |
| RFC-ALT-04 | `docs/RFC.md` | Alternativa Descartada | Worker no mesmo processo da API | TRANSCRICAO | [09:11] Diego |
| RFC-ALT-05 | `docs/RFC.md` | Alternativa Descartada | Garantia exactly-once | TRANSCRICAO | [09:25] Diego |
| RFC-ALT-06 | `docs/RFC.md` | Alternativa Descartada | Secret global da plataforma | TRANSCRICAO | [09:21] Sofia |
| RFC-OQ-01 | `docs/RFC.md` | Questão em Aberto | Rate limiting de saída por cliente — observar e decidir depois | TRANSCRICAO | [09:39] Larissa; [09:38] Diego; [09:39] Diego |
| RFC-OQ-02 | `docs/RFC.md` | Questão em Aberto | Escala para múltiplos workers mantendo a ordem por pedido | TRANSCRICAO | [09:13] Diego; [09:13] Larissa |
| RFC-OQ-03 | `docs/RFC.md` | Questão em Aberto | Restringir o CRUD de webhooks; sem vínculo usuário ↔ cliente | TRANSCRICAO | [09:37] Sofia; [09:32] Marcos |
| RFC-OQ-04 | `docs/RFC.md` | Questão em Aberto | Retentativas podem quebrar a ordem por pedido (análise) | TRANSCRICAO | [09:12] Diego; [09:15] Diego |
| RFC-OQ-05 | `docs/RFC.md` | Questão em Aberto | Mecanismo de assinatura na janela de rotação de 24 h (análise) | TRANSCRICAO | [09:21] Sofia; [09:46] Sofia |
| RFC-OQ-06 | `docs/RFC.md` | Questão em Aberto | Onde aplicar o limite de 64 KB sem bloquear a mudança de status (análise) | TRANSCRICAO | [09:24] Larissa; [09:40] Bruno |
| RFC-RISK-01 | `docs/RFC.md` | Risco | Falha na outbox bloqueia a mudança de status | TRANSCRICAO | [09:40] Bruno |
| RFC-RISK-02 | `docs/RFC.md` | Risco | Worker único parado atrasa todas as entregas | TRANSCRICAO | [09:12] Diego |
| RFC-RISK-03 | `docs/RFC.md` | Risco | Eventos presos em "processando" após queda do worker (interpretação) | TRANSCRICAO | [09:08] Diego |
| RFC-RISK-04 | `docs/RFC.md` | Risco | Vazamento de secret; `redact` do logger não cobre secrets | CODIGO | `src/shared/logger/index.ts` |
| RFC-RISK-05 | `docs/RFC.md` | Risco | Cliente não deduplica e processa o mesmo evento duas vezes | TRANSCRICAO | [09:25] Sofia; [09:26] Marcos |
| RFC-RISK-06 | `docs/RFC.md` | Risco | DLQ cresce sem acompanhamento e sem aviso ao cliente | TRANSCRICAO | [09:37] Larissa |
| RFC-RISK-07 | `docs/RFC.md` | Risco | Qualquer usuário autenticado gerencia webhooks de qualquer cliente | TRANSCRICAO | [09:37] Sofia |
| RFC-RISK-08 | `docs/RFC.md` | Risco | Prazo de fim de novembro contra estimativa de três sprints | TRANSCRICAO | [09:45] Marcos; [09:47] Larissa; [09:47] Marcos |
| FDD-OBJ-01 | `docs/FDD.md` | Objetivo | Nenhuma mudança de status sem evento; falha na outbox desfaz a mudança | TRANSCRICAO | [09:40] Bruno; [09:41] Diego |
| FDD-OBJ-02 | `docs/FDD.md` | Objetivo | Latência < 10 s; polling contribui com até ~2 s | TRANSCRICAO | [09:02] Marcos; [09:09] Diego; [09:10] Larissa |
| FDD-OBJ-03 | `docs/FDD.md` | Objetivo | Timeout de 10 s por chamada ao cliente | TRANSCRICAO | [09:42] Diego |
| FDD-OBJ-04 | `docs/FDD.md` | Objetivo | Janela de retentativas de ~14 h 36 min (1 + 5, interpretação) | TRANSCRICAO | [09:17] Larissa; [09:17] Diego |
| FDD-OBJ-05 | `docs/FDD.md` | Objetivo | Payload de no máximo 64 KB | TRANSCRICAO | [09:24] Larissa; [09:24] Diego |
| FDD-OBJ-06 | `docs/FDD.md` | Objetivo | Nenhuma dependência npm nova; reuso de padrões | TRANSCRICAO | [09:30] Larissa; [09:29] Bruno |
| FDD-OBJ-07 | `docs/FDD.md` | Objetivo | Nenhuma quebra nos contratos atuais da API | CODIGO | `src/routes/index.ts` |
| FDD-DADOS-01 | `docs/FDD.md` | Modelo de Dados | `webhook_endpoints` com url, secret, `customerId` e estado ativo | TRANSCRICAO | [09:21] Bruno; [09:21] Sofia |
| FDD-DADOS-02 | `docs/FDD.md` | Modelo de Dados | Uma linha de outbox por webhook interessado, cada uma com seu `eventId` (proposta D-1) | TRANSCRICAO | [09:44] Sofia |
| FDD-DADOS-03 | `docs/FDD.md` | Modelo de Dados | Índices por status e data de criação na outbox | TRANSCRICAO | [09:08] Diego |
| FDD-DADOS-04 | `docs/FDD.md` | Modelo de Dados | Payload gravado como snapshot | TRANSCRICAO | [09:52] Larissa |
| FDD-DADOS-05 | `docs/FDD.md` | Modelo de Dados | `webhook_dead_letter` com payload, motivo, timestamp e campos de replay | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| FDD-DADOS-06 | `docs/FDD.md` | Modelo de Dados | `webhook_deliveries` com cada tentativa, para o histórico (proposta) | TRANSCRICAO | [09:34] Marcos |
| FDD-DADOS-07 | `docs/FDD.md` | Modelo de Dados | `DELETE` lógico preservando histórico e DLQ (proposta D-2) | TRANSCRICAO | [09:18] Diego |
| FDD-DADOS-08 | `docs/FDD.md` | Modelo de Dados | `orderId` sem FK, pois pedidos `PENDING`/`CANCELLED` podem ser apagados | CODIGO | `src/modules/orders/order.service.ts` |
| FDD-FLUXO-01 | `docs/FDD.md` | Fluxo | Criação do evento na outbox dentro do `changeStatus`, com filtro na inserção | TRANSCRICAO | [09:40] Bruno; [09:41] Bruno; [09:34] Bruno |
| FDD-FLUXO-02 | `docs/FDD.md` | Fluxo | Ciclo do worker: recuperação, reivindicação em lote, envio sequencial | TRANSCRICAO | [09:09] Diego; [09:08] Diego; [09:12] Diego |
| FDD-FLUXO-03 | `docs/FDD.md` | Fluxo | Retry com backoff 1m/5m/30m/2h/12h | TRANSCRICAO | [09:17] Larissa; [09:17] Diego |
| FDD-FLUXO-04 | `docs/FDD.md` | Fluxo | Movimentação para a DLQ | TRANSCRICAO | [09:18] Diego |
| FDD-FLUXO-05 | `docs/FDD.md` | Fluxo | Replay manual da DLQ por `ADMIN`, mesmo `eventId` | TRANSCRICAO | [09:18] Diego; [09:36] Sofia; [09:36] Larissa |
| FDD-FLUXO-06 | `docs/FDD.md` | Fluxo | Rotação de secret com 24 h de convivência | TRANSCRICAO | [09:21] Sofia |
| FDD-CONTRATO-01 | `docs/FDD.md` | Contrato | `POST /api/v1/webhooks` — cria webhook e devolve a secret | TRANSCRICAO | [09:31] Marcos; [09:32] Larissa |
| FDD-CONTRATO-02 | `docs/FDD.md` | Contrato | `GET /api/v1/webhooks?customerId=` — lista webhooks de um customer | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-03 | `docs/FDD.md` | Contrato | `PATCH /api/v1/webhooks/:id` — edita url, eventos, ativo | TRANSCRICAO | [09:33] Bruno; [09:21] Bruno |
| FDD-CONTRATO-04 | `docs/FDD.md` | Contrato | `DELETE /api/v1/webhooks/:id` — remove webhook | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-05 | `docs/FDD.md` | Contrato | `POST /api/v1/webhooks/:id/rotate-secret` (caminho proposto) | TRANSCRICAO | [09:21] Sofia |
| FDD-CONTRATO-06 | `docs/FDD.md` | Contrato | `GET /api/v1/webhooks/:id/deliveries` — últimas 100 entregas | TRANSCRICAO | [09:34] Marcos |
| FDD-CONTRATO-07 | `docs/FDD.md` | Contrato | `POST /api/v1/admin/webhooks/dead-letter/:id/replay` — só `ADMIN` | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| FDD-CONTRATO-08 | `docs/FDD.md` | Contrato | Requisição ao cliente: payload, `X-Event-Id`, `X-Webhook-Id`, `X-Timestamp`, `X-Signature` | TRANSCRICAO | [09:44] Diego; [09:43] Diego; [09:44] Sofia; [09:22] Sofia |
| FDD-ERR-01 | `docs/FDD.md` | Erro | `WEBHOOK_NOT_FOUND` (404) | TRANSCRICAO | [09:28] Bruno |
| FDD-ERR-02 | `docs/FDD.md` | Erro | `WEBHOOK_INVALID_URL` (400) — URL inválida ou não-`https` | TRANSCRICAO | [09:28] Bruno; [09:23] Sofia |
| FDD-ERR-03 | `docs/FDD.md` | Erro | `WEBHOOK_INVALID_EVENTS` (400) — lista vazia ou status não emitível (proposta) | TRANSCRICAO | [09:33] Marcos |
| FDD-ERR-04 | `docs/FDD.md` | Erro | `WEBHOOK_SECRET_ROTATION_IN_PROGRESS` (409) (proposta) | TRANSCRICAO | [09:21] Sofia |
| FDD-ERR-05 | `docs/FDD.md` | Erro | `WEBHOOK_DEAD_LETTER_NOT_FOUND` (404) (proposta) | TRANSCRICAO | [09:18] Diego |
| FDD-ERR-07 | `docs/FDD.md` | Erro | `WEBHOOK_DELIVERY_TIMEOUT` — sem resposta em 10 s | TRANSCRICAO | [09:42] Diego |
| FDD-ERR-08 | `docs/FDD.md` | Erro | `WEBHOOK_DELIVERY_FAILED` — não-2xx ou erro de rede (interpretação) | TRANSCRICAO | [09:15] Diego |
| FDD-ERR-09 | `docs/FDD.md` | Erro | `WEBHOOK_MAX_ATTEMPTS_EXCEEDED` — 6º envio falhou, vai para a DLQ | TRANSCRICAO | [09:15] Diego; [09:17] Larissa |
| FDD-ERR-10 | `docs/FDD.md` | Erro | `WEBHOOK_PAYLOAD_TOO_LARGE` — corpo > 64 KB, DLQ sem envio | TRANSCRICAO | [09:24] Larissa; [09:23] Sofia |
| FDD-ERR-11 | `docs/FDD.md` | Erro | `WEBHOOK_SECRET_REQUIRED` — webhook sem secret ao assinar | TRANSCRICAO | [09:28] Bruno |
| FDD-RES-01 | `docs/FDD.md` | Resiliência | Timeout de 10 s com `AbortSignal.timeout` | TRANSCRICAO | [09:42] Diego |
| FDD-RES-02 | `docs/FDD.md` | Resiliência | 1 envio + 5 retentativas com backoff | TRANSCRICAO | [09:17] Larissa; [09:17] Diego |
| FDD-RES-04 | `docs/FDD.md` | Resiliência | Payload > 64 KB e secret ausente vão direto à DLQ | TRANSCRICAO | [09:24] Larissa |
| FDD-RES-05 | `docs/FDD.md` | Resiliência | DLQ em tabela separada + replay manual por `ADMIN` | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| FDD-RES-06 | `docs/FDD.md` | Resiliência | Eventos `PROCESSING` órfãos voltam a `PENDING` (interpretação) | TRANSCRICAO | [09:08] Diego |
| FDD-RES-07 | `docs/FDD.md` | Resiliência | Isolamento por endpoint: retry de um não bloqueia outro (proposta D-1) | TRANSCRICAO | [09:44] Sofia |
| FDD-RES-08 | `docs/FDD.md` | Resiliência | Cliente lento ou fora do ar não afeta a API; eventos seguros na outbox | TRANSCRICAO | [09:04] Bruno; [09:11] Diego |
| FDD-RES-09 | `docs/FDD.md` | Resiliência | Desligamento gracioso do worker no padrão do servidor | CODIGO | `src/server.ts` |
| FDD-RES-11 | `docs/FDD.md` | Resiliência | Crash entre envio e registro gera reenvio, coberto pela deduplicação | TRANSCRICAO | [09:24] Diego |
| FDD-RES-12 | `docs/FDD.md` | Resiliência | Sem canal alternativo ao cliente nesta fase; fallback é DLQ + replay | TRANSCRICAO | [09:37] Larissa |
| FDD-OBS-01 | `docs/FDD.md` | Observabilidade | Logs `worker_started` / `worker_stopped`, na convenção snake_case existente | CODIGO | `src/server.ts` |
| FDD-OBS-02 | `docs/FDD.md` | Observabilidade | Log `webhook_delivery_succeeded` via Pino (proposta) | TRANSCRICAO | [09:29] Bruno |
| FDD-OBS-03 | `docs/FDD.md` | Observabilidade | Log `webhook_delivery_failed` via Pino (proposta) | TRANSCRICAO | [09:29] Bruno |
| FDD-OBS-04 | `docs/FDD.md` | Observabilidade | Log `webhook_moved_to_dlq` via Pino (proposta) | TRANSCRICAO | [09:29] Bruno |
| FDD-OBS-05 | `docs/FDD.md` | Observabilidade | Logs `webhook_event_discarded` / `webhook_events_reclaimed` (proposta) | TRANSCRICAO | [09:29] Bruno |
| FDD-OBS-06 | `docs/FDD.md` | Observabilidade | Log de auditoria `webhook_replayed` com `userId` | TRANSCRICAO | [09:36] Sofia |
| FDD-OBS-07 | `docs/FDD.md` | Observabilidade | Log `webhook_secret_rotated` sem expor a secret | TRANSCRICAO | [09:22] Diego |
| FDD-OBS-08 | `docs/FDD.md` | Observabilidade | Métrica de eventos pendentes na outbox (proposta) | TRANSCRICAO | [09:07] Bruno |
| FDD-OBS-09 | `docs/FDD.md` | Observabilidade | Métrica de idade do evento pendente mais antigo (proposta) | TRANSCRICAO | [09:02] Marcos |
| FDD-OBS-10 | `docs/FDD.md` | Observabilidade | Métrica de latência commit → entrega contra a meta de 10 s | TRANSCRICAO | [09:02] Marcos |
| FDD-OBS-11 | `docs/FDD.md` | Observabilidade | Métrica de taxa de sucesso por webhook (proposta) | TRANSCRICAO | [09:34] Marcos |
| FDD-OBS-12 | `docs/FDD.md` | Observabilidade | Métrica de dead letters criadas e pendentes (proposta) | TRANSCRICAO | [09:18] Diego |
| FDD-OBS-13 | `docs/FDD.md` | Observabilidade | Tempo de resposta dos clientes por webhook | TRANSCRICAO | [09:34] Marcos |
| FDD-INT-01 | `docs/FDD.md` | Integração | Chamada a `publishWebhookEvent(tx, ...)` dentro do `$transaction` do `changeStatus` | CODIGO | `src/modules/orders/order.service.ts` |
| FDD-INT-02 | `docs/FDD.md` | Integração | Status emitíveis derivados de `allowedTransitions` | CODIGO | `src/modules/orders/order.status.ts` |
| FDD-INT-03 | `docs/FDD.md` | Integração | Erros `WEBHOOK_*` derivados de `AppError` e das classes HTTP | CODIGO | `src/shared/errors/http-errors.ts`; `src/shared/errors/app-error.ts` |
| FDD-INT-04 | `docs/FDD.md` | Integração | Error middleware reaproveitado sem alteração | CODIGO | `src/middlewares/error.middleware.ts` |
| FDD-INT-05 | `docs/FDD.md` | Integração | `authenticate` em todas as rotas; `requireRole('ADMIN')` no replay | CODIGO | `src/middlewares/auth.middleware.ts` |
| FDD-INT-06 | `docs/FDD.md` | Integração | `validate` com schemas Zod; regra `https` no service | CODIGO | `src/middlewares/validate.middleware.ts` |
| FDD-INT-07 | `docs/FDD.md` | Integração | Pino reaproveitado; `redact` estendido; `service` parametrizável | CODIGO | `src/shared/logger/index.ts` |
| FDD-INT-08 | `docs/FDD.md` | Integração | Instanciação do módulo em `buildControllers` | CODIGO | `src/app.ts` |
| FDD-INT-09 | `docs/FDD.md` | Integração | Montagem de `/webhooks` e `/admin/webhooks` no router da API | CODIGO | `src/routes/index.ts` |
| FDD-INT-10 | `docs/FDD.md` | Integração | `src/worker.ts` (novo, a criar) modelado no bootstrap e shutdown existentes | CODIGO | `src/server.ts` |
| FDD-INT-11 | `docs/FDD.md` | Integração | Worker com instância própria do Prisma, mesma `DATABASE_URL` | CODIGO | `src/config/database.ts` |
| FDD-INT-12 | `docs/FDD.md` | Integração | Novas variáveis de ambiente opcionais no schema Zod | CODIGO | `src/config/env.ts` |
| FDD-INT-13 | `docs/FDD.md` | Integração | Novos models, enum e relação inversa em `Customer` | CODIGO | `prisma/schema.prisma` |
| FDD-INT-14 | `docs/FDD.md` | Integração | Scripts `worker` e `worker:dev` (novos, a criar) | CODIGO | `package.json` |
| FDD-INT-15 | `docs/FDD.md` | Integração | `paginated(...)` na listagem de webhooks | CODIGO | `src/shared/http/response.ts` |
| FDD-INT-16 | `docs/FDD.md` | Integração | Limpeza das tabelas novas, factory de webhook e novos casos de teste | CODIGO | `tests/setup.ts`; `tests/helpers/factories.ts`; `tests/orders.test.ts` |
| FDD-AC-01 | `docs/FDD.md` | Critério de Aceite | N webhooks interessados geram N linhas `PENDING` com snapshot, na mesma transação | TRANSCRICAO | [09:40] Bruno; [09:52] Larissa |
| FDD-AC-02 | `docs/FDD.md` | Critério de Aceite | Sem webhook interessado, nenhuma linha é criada | TRANSCRICAO | [09:34] Bruno |
| FDD-AC-03 | `docs/FDD.md` | Critério de Aceite | Transição inválida ou estoque insuficiente não gera evento | CODIGO | `src/modules/orders/order.service.ts` |
| FDD-AC-04 | `docs/FDD.md` | Critério de Aceite | Falha na outbox desfaz status, histórico e estoque | TRANSCRICAO | [09:40] Bruno; [09:41] Diego |
| FDD-AC-05 | `docs/FDD.md` | Critério de Aceite | Entrega no ciclo seguinte; latência < 10 s | TRANSCRICAO | [09:02] Marcos; [09:09] Diego |
| FDD-AC-06 | `docs/FDD.md` | Critério de Aceite | Requisição traz os cinco headers e assinatura válida | TRANSCRICAO | [09:44] Diego; [09:44] Sofia; [09:22] Sofia |
| FDD-AC-07 | `docs/FDD.md` | Critério de Aceite | Duas assinaturas válidas por 24 h após a rotação | TRANSCRICAO | [09:21] Sofia |
| FDD-AC-08 | `docs/FDD.md` | Critério de Aceite | Timeout de 10 s gera falha e retentativa | TRANSCRICAO | [09:42] Diego |
| FDD-AC-09 | `docs/FDD.md` | Critério de Aceite | Retentativas em 1m/5m/30m/2h/12h; 6ª falha vai para a DLQ | TRANSCRICAO | [09:17] Larissa; [09:18] Diego |
| FDD-AC-10 | `docs/FDD.md` | Critério de Aceite | Payload > 64 KB vai para a DLQ sem envio | TRANSCRICAO | [09:24] Larissa |
| FDD-AC-11 | `docs/FDD.md` | Critério de Aceite | Replay: `OPERATOR` recebe 403; `ADMIN` recebe 202 e o log registra o autor | TRANSCRICAO | [09:36] Sofia; [09:18] Diego |
| FDD-AC-13 | `docs/FDD.md` | Critério de Aceite | URL `http://` é recusada com `WEBHOOK_INVALID_URL` | TRANSCRICAO | [09:23] Sofia |
| FDD-AC-14 | `docs/FDD.md` | Critério de Aceite | Secret só aparece na criação e na rotação, nunca em logs | TRANSCRICAO | [09:22] Diego |
| FDD-AC-15 | `docs/FDD.md` | Critério de Aceite | Histórico com até 100 tentativas, mais recentes primeiro | TRANSCRICAO | [09:34] Marcos |
| FDD-AC-16 | `docs/FDD.md` | Critério de Aceite | Webhook removido ou inativo não recebe pendentes (proposta D-2) | TRANSCRICAO | [09:21] Bruno |
| FDD-AC-17 | `docs/FDD.md` | Critério de Aceite | Reinício do worker recupera eventos em `PROCESSING` (interpretação) | TRANSCRICAO | [09:08] Diego |
| FDD-AC-18 | `docs/FDD.md` | Critério de Aceite | Testes existentes de pedidos continuam passando | CODIGO | `tests/orders.test.ts` |
| FDD-RISK-01 | `docs/FDD.md` | Risco | Bloqueio de fila: envio sequencial com clientes em timeout | TRANSCRICAO | [09:42] Diego; [09:12] Diego |
| FDD-RISK-02 | `docs/FDD.md` | Risco | Ordem por pedido quebrada por retentativas | TRANSCRICAO | [09:12] Diego |
| FDD-RISK-03 | `docs/FDD.md` | Risco | `X-Timestamp` fora da assinatura enfraquece a proteção contra replay | TRANSCRICAO | [09:22] Sofia; [09:44] Diego |
| FDD-RISK-04 | `docs/FDD.md` | Risco | Secret armazenada de forma recuperável no banco | TRANSCRICAO | [09:22] Diego |
| FDD-RISK-05 | `docs/FDD.md` | Risco | URL apontando para rede interna (SSRF) — não discutido na reunião | TRANSCRICAO | [09:37] Sofia |
| FDD-RISK-06 | `docs/FDD.md` | Risco | Crescimento das tabelas sem arquivamento | TRANSCRICAO | [09:08] Diego |
| FDD-RISK-07 | `docs/FDD.md` | Risco | Falha da outbox bloqueia mudança de status | TRANSCRICAO | [09:40] Bruno |
| FDD-RISK-08 | `docs/FDD.md` | Risco | Autorização ampla do CRUD de webhooks | TRANSCRICAO | [09:37] Sofia |
| PRD-CEN-01 | `docs/PRD.md` | Cenário | Cliente filtra só `SHIPPED` e `DELIVERED` | TRANSCRICAO | [09:33] Marcos |
| PRD-CEN-02 | `docs/PRD.md` | Cenário | Cliente fica 2 h fora em manutenção e recebe depois | TRANSCRICAO | [09:16] Diego |
| PRD-CEN-03 | `docs/PRD.md` | Cenário | Cliente vaza secret e rotaciona sem interromper a integração | TRANSCRICAO | [09:22] Diego; [09:21] Sofia |
| PRD-CEN-04 | `docs/PRD.md` | Cenário | Cliente recebe duplicata e descarta pelo identificador do evento | TRANSCRICAO | [09:24] Diego; [09:25] Diego |
| PRD-CEN-05 | `docs/PRD.md` | Cenário | Suporte investiga entrega pelo histórico | TRANSCRICAO | [09:34] Marcos |
| PRD-CEN-06 | `docs/PRD.md` | Cenário | Administrador reprocessa notificações após queda longa | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| PRD-CEN-07 | `docs/PRD.md` | Cenário | Cliente com vários webhooks identifica a origem de cada envio | TRANSCRICAO | [09:44] Sofia |
| PRD-MET-01 | `docs/PRD.md` | Métrica | Latência da notificação < 10 s (p95 é proposta) | TRANSCRICAO | [09:02] Marcos |
| PRD-MET-02 | `docs/PRD.md` | Métrica | 3 de 3 clientes solicitantes integrados | TRANSCRICAO | [09:00] Marcos |
| PRD-MET-03 | `docs/PRD.md` | Métrica | Zero mudanças de status sem notificação | TRANSCRICAO | [09:40] Bruno |
| PRD-MET-04 | `docs/PRD.md` | Métrica | Redução do polling no `GET /orders` — a medir | TRANSCRICAO | [09:00] Marcos |
| PRD-OOS-01 | `docs/PRD.md` | Fora de Escopo | Aviso por e-mail ao cliente | TRANSCRICAO | [09:37] Larissa; [09:38] Marcos |
| PRD-OOS-02 | `docs/PRD.md` | Fora de Escopo | Dashboard visual | TRANSCRICAO | [09:40] Larissa |
| PRD-OOS-03 | `docs/PRD.md` | Fora de Escopo | Rate limiting de envio | TRANSCRICAO | [09:39] Larissa; [09:39] Diego |
| PRD-OOS-04 | `docs/PRD.md` | Fora de Escopo | Arquivamento de entregues (~30 dias) | TRANSCRICAO | [09:08] Diego |
| PRD-OOS-05 | `docs/PRD.md` | Fora de Escopo | Webhooks de entrada | TRANSCRICAO | [09:02] Marcos; [09:03] Sofia |
| PRD-OOS-06 | `docs/PRD.md` | Fora de Escopo | Ordem global das notificações | TRANSCRICAO | [09:13] Larissa; [09:14] Marcos |
| PRD-OOS-07 | `docs/PRD.md` | Fora de Escopo | Notificação de criação de pedido — `create()` não passa pelo `changeStatus` (interpretação) | CODIGO | `src/modules/orders/order.service.ts` |
| PRD-FR-01 | `docs/PRD.md` | Requisito Funcional | Cadastrar webhook com URL e status de interesse | TRANSCRICAO | [09:31] Marcos |
| PRD-FR-02 | `docs/PRD.md` | Requisito Funcional | Cliente informado na requisição, não inferido do login | TRANSCRICAO | [09:32] Larissa |
| PRD-FR-03 | `docs/PRD.md` | Requisito Funcional | Plataforma gera a secret e a devolve na criação | TRANSCRICAO | [09:31] Marcos |
| PRD-FR-04 | `docs/PRD.md` | Requisito Funcional | Listar webhooks de um cliente | TRANSCRICAO | [09:33] Bruno |
| PRD-FR-05 | `docs/PRD.md` | Requisito Funcional | Editar webhook (URL, status, ativo/inativo) | TRANSCRICAO | [09:33] Bruno; [09:21] Bruno |
| PRD-FR-06 | `docs/PRD.md` | Requisito Funcional | Remover webhook | TRANSCRICAO | [09:33] Bruno |
| PRD-FR-07 | `docs/PRD.md` | Requisito Funcional | Receber apenas os status escolhidos | TRANSCRICAO | [09:33] Marcos; [09:34] Bruno |
| PRD-FR-08 | `docs/PRD.md` | Requisito Funcional | Rotação de secret com 24 h de convivência | TRANSCRICAO | [09:21] Sofia |
| PRD-FR-09 | `docs/PRD.md` | Requisito Funcional | Notificação automática com dados básicos, sem itens | TRANSCRICAO | [09:43] Diego; [09:44] Bruno |
| PRD-FR-10 | `docs/PRD.md` | Requisito Funcional | Assinatura, identificador do evento e do webhook em cada notificação | TRANSCRICAO | [09:20] Sofia; [09:25] Diego; [09:44] Sofia |
| PRD-FR-11 | `docs/PRD.md` | Requisito Funcional | Retentativas automáticas em 1m/5m/30m/2h/12h | TRANSCRICAO | [09:17] Larissa; [09:15] Diego |
| PRD-FR-12 | `docs/PRD.md` | Requisito Funcional | Fila de falhas definitivas com conteúdo, motivo e data | TRANSCRICAO | [09:18] Diego |
| PRD-FR-13 | `docs/PRD.md` | Requisito Funcional | Reprocessamento por administrador, registrado com o autor | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| PRD-FR-14 | `docs/PRD.md` | Requisito Funcional | Histórico das últimas 100 entregas | TRANSCRICAO | [09:34] Marcos |
| PRD-NFR-01 | `docs/PRD.md` | Requisito Não Funcional | Entrega em menos de 10 s | TRANSCRICAO | [09:02] Marcos; [09:09] Diego |
| PRD-NFR-02 | `docs/PRD.md` | Requisito Não Funcional | Nenhuma mudança de status sem notificação | TRANSCRICAO | [09:40] Bruno |
| PRD-NFR-03 | `docs/PRD.md` | Requisito Não Funcional | Cliente lento ou fora do ar não afeta a mudança de status | TRANSCRICAO | [09:04] Bruno |
| PRD-NFR-04 | `docs/PRD.md` | Requisito Não Funcional | At-least-once com deduplicação pelo cliente | TRANSCRICAO | [09:26] Larissa; [09:24] Diego; [09:25] Diego |
| PRD-NFR-05 | `docs/PRD.md` | Requisito Não Funcional | Suporta ~15 h de indisponibilidade do cliente (interpretação 1 + 5) | TRANSCRICAO | [09:17] Diego; [09:17] Marcos |
| PRD-NFR-06 | `docs/PRD.md` | Requisito Não Funcional | Cliente sem resposta em 10 s é tratado como falha | TRANSCRICAO | [09:42] Diego |
| PRD-NFR-07 | `docs/PRD.md` | Requisito Não Funcional | HMAC-SHA256 com secret exclusiva por webhook | TRANSCRICAO | [09:22] Sofia; [09:20] Sofia |
| PRD-NFR-08 | `docs/PRD.md` | Requisito Não Funcional | Somente URLs `https` | TRANSCRICAO | [09:23] Sofia |
| PRD-NFR-09 | `docs/PRD.md` | Requisito Não Funcional | Secret exibida só na criação e na rotação | TRANSCRICAO | [09:22] Diego |
| PRD-NFR-10 | `docs/PRD.md` | Requisito Não Funcional | Replay restrito a `ADMIN` e auditado; cadastro para qualquer autenticado | TRANSCRICAO | [09:36] Sofia; [09:37] Sofia |
| PRD-NFR-11 | `docs/PRD.md` | Requisito Não Funcional | Notificações acima de 64 KB não são enviadas | TRANSCRICAO | [09:24] Larissa; [09:23] Sofia; [09:24] Diego |
| PRD-NFR-12 | `docs/PRD.md` | Requisito Não Funcional | Ordem só por pedido, com um único processo de entrega | TRANSCRICAO | [09:13] Larissa |
| PRD-NFR-13 | `docs/PRD.md` | Requisito Não Funcional | Sem infraestrutura nova | TRANSCRICAO | [09:07] Diego; [09:30] Larissa |
| PRD-DEC-01 | `docs/PRD.md` | Trade-off | Evento registrado junto com a mudança de status (outbox) | TRANSCRICAO | [09:08] Larissa |
| PRD-DEC-02 | `docs/PRD.md` | Trade-off | Processo de entrega separado, verificando a cada 2 s | TRANSCRICAO | [09:10] Larissa |
| PRD-DEC-03 | `docs/PRD.md` | Trade-off | Retentativas por ~15 h e fila de falhas com replay manual | TRANSCRICAO | [09:17] Larissa |
| PRD-DEC-04 | `docs/PRD.md` | Trade-off | Secret por webhook com rotação de 24 h | TRANSCRICAO | [09:22] Sofia |
| PRD-DEC-05 | `docs/PRD.md` | Trade-off | Entrega "pelo menos uma vez" com identificador único | TRANSCRICAO | [09:26] Larissa |
| PRD-DEC-06 | `docs/PRD.md` | Trade-off | Reuso dos padrões e componentes do sistema | TRANSCRICAO | [09:30] Larissa |
| PRD-DEC-07 | `docs/PRD.md` | Trade-off | Conteúdo da notificação congelado no momento da mudança | TRANSCRICAO | [09:52] Larissa |
| PRD-DEP-01 | `docs/PRD.md` | Dependência | Documentação no portal do desenvolvedor | TRANSCRICAO | [09:26] Marcos; [09:40] Marcos |
| PRD-DEP-02 | `docs/PRD.md` | Dependência | Revisão de segurança de pelo menos dois dias úteis | TRANSCRICAO | [09:46] Sofia; [09:49] Sofia |
| PRD-DEP-03 | `docs/PRD.md` | Dependência | Cliente: `https`, resposta em 10 s, verificação e deduplicação | TRANSCRICAO | [09:23] Sofia; [09:42] Diego; [09:25] Diego |
| PRD-DEP-04 | `docs/PRD.md` | Dependência | Operação de um novo processo de entrega | TRANSCRICAO | [09:11] Diego |
| PRD-DEP-05 | `docs/PRD.md` | Dependência | Confirmação do prazo com a Atlas | TRANSCRICAO | [09:47] Marcos |
| PRD-DEP-06 | `docs/PRD.md` | Dependência | Sessão de revisão do desenho antes de codar | TRANSCRICAO | [09:50] Larissa |
| PRD-RISK-01 | `docs/PRD.md` | Risco | Perda da Atlas por atraso (P Média, I Alto) | TRANSCRICAO | [09:45] Marcos; [09:00] Marcos; [09:47] Larissa |
| PRD-RISK-02 | `docs/PRD.md` | Risco | Vazamento de secret do cliente (P Média, I Alto) | TRANSCRICAO | [09:22] Diego |
| PRD-RISK-03 | `docs/PRD.md` | Risco | Cliente processa duplicatas (P Média, I Médio) | TRANSCRICAO | [09:25] Sofia |
| PRD-RISK-04 | `docs/PRD.md` | Risco | Permissão ampla no cadastro de webhooks (P Média, I Alto) | TRANSCRICAO | [09:37] Sofia |
| PRD-RISK-05 | `docs/PRD.md` | Risco | Falhas definitivas sem aviso ao cliente (P Baixa, I Médio) | TRANSCRICAO | [09:37] Larissa; [09:17] Marcos |
| PRD-RISK-06 | `docs/PRD.md` | Risco | Latência acima de 10 s em picos (P Baixa, I Médio) | TRANSCRICAO | [09:09] Diego |
| PRD-RISK-07 | `docs/PRD.md` | Risco | Notificações fora de ordem após retentativas (P Baixa, I Baixo) | TRANSCRICAO | [09:14] Marcos |
| PRD-AC-01 | `docs/PRD.md` | Critério de Aceite | Cadastro `https` com status de interesse; secret exibida uma única vez | TRANSCRICAO | [09:31] Marcos |
| PRD-AC-02 | `docs/PRD.md` | Critério de Aceite | URL `http` recusada | TRANSCRICAO | [09:23] Sofia |
| PRD-AC-03 | `docs/PRD.md` | Critério de Aceite | Notificação em < 10 s, assinada e identificada | TRANSCRICAO | [09:02] Marcos; [09:20] Sofia |
| PRD-AC-04 | `docs/PRD.md` | Critério de Aceite | Status fora do filtro não notifica | TRANSCRICAO | [09:33] Marcos |
| PRD-AC-05 | `docs/PRD.md` | Critério de Aceite | Queda de 2 h recuperada sem ação manual | TRANSCRICAO | [09:16] Diego; [09:17] Diego |
| PRD-AC-06 | `docs/PRD.md` | Critério de Aceite | Após ~15 h vai para a fila de falhas; só `ADMIN` reprocessa, com registro do autor | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| PRD-AC-07 | `docs/PRD.md` | Critério de Aceite | Secret antiga e nova válidas por 24 h após a rotação | TRANSCRICAO | [09:21] Sofia |
| PRD-AC-08 | `docs/PRD.md` | Critério de Aceite | Histórico com até 100 tentativas e detalhes | TRANSCRICAO | [09:34] Marcos |
| PRD-AC-09 | `docs/PRD.md` | Critério de Aceite | Falha do cliente não impede a mudança de status; nenhuma mudança sem notificação | TRANSCRICAO | [09:40] Bruno; [09:04] Bruno |
| PRD-AC-10 | `docs/PRD.md` | Critério de Aceite | Editar, desativar e remover alteram os envios seguintes | TRANSCRICAO | [09:33] Bruno |
| PRD-AC-11 | `docs/PRD.md` | Critério de Aceite | Revisão de segurança concluída antes do deploy | TRANSCRICAO | [09:46] Sofia |

## Anexo — itens sem origem direta

Propostas de implementação deste pacote que **não derivam de nenhuma fala nem de nenhum arquivo** do repositório. Estão sinalizadas como proposta nos documentos e ficam fora da tabela principal e do cálculo de cobertura. Devem ser validadas na sessão de revisão com Bruno e Diego ([09:50] Larissa) antes da implementação.

| ID | Documento | Conteúdo | Por que não tem origem direta |
|---|---|---|---|
| FDD-ERR-06 | `docs/FDD.md` | `WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED` (409) no segundo replay | A reunião não tratou replay repetido; o código protege contra reenvio duplicado causado por clique ou retry do admin |
| FDD-RES-03 | `docs/FDD.md` | Critério de sucesso: 2xx = sucesso; qualquer outro status = falha com retry | A reunião não definiu o que é sucesso nem se 4xx gera retry (lacuna L-05) |
| FDD-RES-10 | `docs/FDD.md` | Falha de banco no ciclo do worker é logada e o worker tenta no ciclo seguinte, sem encerrar | Comportamento operacional não discutido |
| FDD-AC-12 | `docs/FDD.md` | Segundo replay do mesmo dead letter retorna 409 | Critério de aceite de FDD-ERR-06 |

## Como foi verificado

A tabela foi conferida por script ao final da Fase 6 (detalhes em `notas/processo.md`):

1. **Completude** — todo ID definido nos documentos (`docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md`, `docs/adrs/ADR-*.md`) aparece na tabela principal ou no anexo, e nenhum ID da tabela deixa de existir nos documentos.
2. **Documento** — cada ID aparece de fato no arquivo indicado na coluna Documento.
3. **Timestamps** — todo `[hh:mm] Nome` da coluna Localização corresponde a uma fala desse participante naquele minuto em `TRANSCRICAO.md`.
4. **Caminhos** — toda localização `CODIGO` aponta para um arquivo existente no repositório.
5. **Percentuais** — o resumo de cobertura no topo foi calculado a partir da própria tabela.
