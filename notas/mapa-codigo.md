# Mapa do código — pontos de integração do módulo de webhooks

Levantamento feito lendo os arquivos reais do repositório. Cada entrada: caminho verificado → o que existe hoje (com linha) → como o módulo de webhooks se conecta. Arquivos que a feature vai criar aparecem como **(novo, a criar)**.

IDs `C-NN` são usados no Tracker quando a fonte for `CODIGO`.

---

## 1. Visão geral da stack (fatos do código)

| ID | Fato | Onde |
|---|---|---|
| C-01 | Node.js ≥ 20, TypeScript, ESM (`"type": "module"`), Express 4.21, Prisma 5.22 + MySQL, Zod 3.23, Pino 9.5, `uuid` 11, JWT (`jsonwebtoken`) | `package.json` |
| C-02 | Scripts existentes: `dev` (`tsx watch src/server.ts`), `build`, `start` (`node dist/server.js`), `db:migrate`, `db:seed`, `test` (`vitest run`), `lint`. **Não existe** script `worker` | `package.json` |
| C-03 | Node ≥ 20 traz `fetch` global e o módulo `crypto` nativo (HMAC-SHA256, `randomBytes`, `timingSafeEqual`) → envio HTTP e assinatura **sem dependência nova** | `package.json` (`engines.node: ">=20"`) |
| C-04 | MySQL 8.0 via Docker Compose; **não há Redis nem broker** no ambiente | `docker-compose.yml` |
| C-05 | Testes: Vitest + Supertest contra banco MySQL real; `tests/setup.ts` limpa as tabelas com `deleteMany` antes de cada teste; execução serial (`singleFork`, `fileParallelism: false`) | `vitest.config.ts`, `tests/setup.ts` |

## 2. Estrutura modular

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-06 | Cada domínio em `src/modules/<dominio>/` com `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `*.routes.ts`, `*.schemas.ts` (ex.: `customers`, `orders`, `products`) | `src/modules/customers/*`, `src/modules/orders/*` | `src/modules/webhooks/` **(novo, a criar)** com `webhook.controller.ts`, `webhook.service.ts`, `webhook.repository.ts`, `webhook.routes.ts`, `webhook.schemas.ts`, mais `webhook.publisher.ts` (`publishWebhookEvent`) e `webhook.processor.ts` (lógica do worker) **(novos, a criar)** — [09:27] Bruno, [09:28] Bruno |
| C-07 | Controllers são classes com handlers `RequestHandler` em arrow function, `try/catch` e `next(err)`; respostas `res.status(200).json(...)`, `201` na criação, `204` no delete | `src/modules/orders/order.controller.ts` | `WebhookController` segue o mesmo formato |
| C-08 | Repositories recebem `PrismaClient` no construtor; listagens usam `prisma.$transaction([findMany, count])` | `src/modules/customers/customer.repository.ts:26` | `WebhookRepository` idem |
| C-09 | Services lançam erros de domínio (`NotFoundError('Customer')`, `ConflictError(..., 'EMAIL_ALREADY_USED')`) e retornam `paginated(...)` | `src/modules/customers/customer.service.ts` | `WebhookService` lança erros `WEBHOOK_*` |
| C-10 | Composição manual de dependências em `buildControllers(prisma)`; tipo `Controllers` agrega os controllers | `src/app.ts:26-53`, `src/routes/index.ts:13-19` | Adicionar `WebhookRepository/Service/Controller` em `buildControllers` e `webhooks` em `Controllers` |
| C-11 | Rotas montadas sob prefixo **`/api/v1`**: `router.use('/orders', buildOrderRouter(...))` etc. | `src/app.ts:67`, `src/routes/index.ts:21-31` | Montar `router.use('/webhooks', ...)` e `router.use('/admin/webhooks', ...)` → caminhos efetivos `/api/v1/webhooks...` e `/api/v1/admin/webhooks...` |

## 3. Orders — o ponto crítico de integração

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-12 | `OrderService.changeStatus(id, input, userId)` abre `this.prisma.$transaction(async (tx) => {...})` | `src/modules/orders/order.service.ts:126-131` | `publishWebhookEvent(tx, order, from, to)` é chamada **dentro** deste callback — [09:40] Bruno, [09:41] Bruno |
| C-13 | Sequência dentro da transação: `findUnique` com items (l.132) → valida mesmo status, lança `ConflictError` `INVALID_STATUS_TRANSITION` (l.140-146) → `canTransition` ou `InvalidStatusTransitionError` (l.147-149) → `debitStock` se PENDING→PAID (l.151-153) → `replenishStock` se cancelamento de PAID/PROCESSING (l.154-156) → `tx.order.update` (l.158) → `tx.orderStatusHistory.create` (l.159-167) → `findUnique` de retorno (l.169-177) | `src/modules/orders/order.service.ts:131-178` | Ponto de inserção: **após `orderStatusHistory.create` (l.167) e antes do refresh (l.169)**. Validações falham antes → nenhum evento é gerado para transição inválida. Exceção lançada por `publishWebhookEvent` → rollback de tudo (T-076) |
| C-14 | Tipo `TxClient = Prisma.TransactionClient` já declarado no service | `src/modules/orders/order.service.ts:24` | Assinatura `publishWebhookEvent(tx: Prisma.TransactionClient, ...)` |
| C-15 | O `order` carregado no `changeStatus` tem `id`, `orderNumber`, `customerId`, `status`, `totalCents` etc. (model `Order`) | `src/modules/orders/order.service.ts:132`, `prisma/schema.prisma:74-97` | Fornece todos os campos do payload decidido em [09:43]: `order_id`, `order_number`, `customer_id`, `from_status`, `to_status`, `total_cents` |
| C-16 | `OrderService` recebe `(OrderRepository, PrismaClient)` no construtor | `src/modules/orders/order.service.ts:26-30`, `src/app.ts:43` | Como `publishWebhookEvent` é função pura recebendo `tx` ([09:41] Diego), **não precisa mudar o construtor** — só um `import` |
| C-17 | `create()` grava histórico `fromStatus: null → PENDING` dentro de outra transação (l.58-123) | `src/modules/orders/order.service.ts:106-113` | **Não** emite evento (lacuna L-09) — criação não é mudança de status via `changeStatus` |
| C-18 | Rota `PATCH /api/v1/orders/:id/status` com `authenticate` + `validate` | `src/modules/orders/order.routes.ts:19-23` | Nenhuma mudança na rota; o efeito é interno ao service |
| C-19 | `GET /api/v1/orders` com filtros `status`, `customerId`, `from`, `to` — é o endpoint que os clientes usam hoje em polling | `src/modules/orders/order.routes.ts:16`, `src/modules/orders/order.schemas.ts:23-30` | Problema que a feature resolve ([09:00] Marcos); `GET /orders/:id` (l.17) é onde o cliente busca detalhes após o webhook ([09:43] Diego) |

## 4. Máquina de estados

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-20 | Enum `OrderStatus`: PENDING, PAID, PROCESSING, SHIPPED, DELIVERED, CANCELLED | `prisma/schema.prisma:16-23` | Valores válidos para o filtro de eventos (lista de status do webhook) — validar com `z.nativeEnum(OrderStatus)` como já feito em `order.schemas.ts:19` |
| C-21 | Transições: PENDING→PAID/CANCELLED; PAID→PROCESSING/CANCELLED; PROCESSING→SHIPPED/CANCELLED; SHIPPED→DELIVERED; DELIVERED e CANCELLED terminais | `src/modules/orders/order.status.ts:3-10` | Via `changeStatus`, `to_status` só pode ser PAID, PROCESSING, SHIPPED, DELIVERED ou CANCELLED — **PENDING nunca é emitido** (só na criação) |
| C-22 | `canTransition`, `allowedTransitions`, `isTerminal`, `shouldDebitStock`, `shouldReplenishStock` | `src/modules/orders/order.status.ts:12-37` | Não muda; o evento só é publicado depois que `canTransition` aprovou |

## 5. Erros

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-23 | `AppError(message, statusCode, errorCode, details?)` com `statusCode`, `errorCode`, `details` | `src/shared/errors/app-error.ts:3-16` | Base de todos os erros `WEBHOOK_*` |
| C-24 | Subclasses HTTP: `BadRequestError` 400, `ValidationError` 400 `VALIDATION_ERROR`, `UnauthorizedError` 401, `ForbiddenError` 403, `NotFoundError` 404 `NOT_FOUND`, `ConflictError` 409, `UnprocessableEntityError` 422; códigos customizáveis em Bad/Conflict/Unprocessable | `src/shared/errors/http-errors.ts:3-43` | Erros de webhook estendem estas, como `InsufficientStockError extends UnprocessableEntityError` |
| C-25 | Padrão de erro de domínio: classe específica estendendo uma HTTP com código SCREAMING_SNAKE_CASE e `details` estruturado — `InvalidStatusTransitionError` (409, `INVALID_STATUS_TRANSITION`, `{from, to}`), `InsufficientStockError` (422, `INSUFFICIENT_STOCK`, `{unavailable}`) | `src/shared/errors/http-errors.ts:45-63` | Modelo direto para `WebhookNotFoundError` (404, `WEBHOOK_NOT_FOUND`), `WebhookInvalidUrlError` (400, `WEBHOOK_INVALID_URL`) etc. — [09:28] Bruno |
| C-26 | `NotFoundError` hoje sempre usa código genérico `NOT_FOUND` (não aceita código custom) | `src/shared/errors/http-errors.ts:27-31` | `WebhookNotFoundError` precisa chamar `AppError` direto (ou estender com código próprio) para ter `WEBHOOK_NOT_FOUND` — detalhe para o FDD |
| C-27 | Barrel `src/shared/errors/index.ts` reexporta todas as classes | `src/shared/errors/index.ts` | Erros de webhook ficam no próprio módulo (`src/modules/webhooks/webhook.errors.ts`, **novo, a criar**) ou são adicionados ao barrel — decidir no FDD |
| C-28 | Códigos de erro já usados no projeto: `VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `INVALID_STATUS_TRANSITION`, `INSUFFICIENT_STOCK`, `INACTIVE_PRODUCT`, `EMAIL_ALREADY_USED`, `INVALID_ORDER_STATE_FOR_DELETE`, `INTERNAL_SERVER_ERROR` | `http-errors.ts`, `order.service.ts:70,143,187`, `customer.service.ts:32`, `error.middleware.ts:63` | Prefixo `WEBHOOK_` evita colisão com os existentes |

## 6. Middlewares

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-29 | `errorMiddleware`: `AppError` → `res.status(statusCode).json({ error: { code, message, details? } })`; `ZodError` → 400 `VALIDATION_ERROR`; Prisma `P2002` → 409 `CONFLICT`; `P2025` → 404 `NOT_FOUND`; resto → log `Unhandled error in request` + 500 | `src/middlewares/error.middleware.ts:14-65` | Erros `WEBHOOK_*` saem no mesmo envelope **sem alterar o middleware** ([09:29] Bruno). Formato de erro dos contratos do FDD = `{ "error": { "code", "message", "details" } }` |
| C-30 | `authenticate`: exige `Authorization: Bearer <jwt>`, valida com `JWT_SECRET`, popula `req.user = { id, email, role }` | `src/middlewares/auth.middleware.ts:27-47` | Todas as rotas de webhook usam `authenticate` (`router.use(authenticate)`, como em `customer.routes.ts:14`) |
| C-31 | `AuthUser.role` é `'ADMIN' \| 'OPERATOR'`; o JWT carrega `sub`, `email`, `role` — **não carrega customer** | `src/middlewares/auth.middleware.ts:6-10,19-25` | Confirma [09:32] Bruno: o JWT é do operador → `customer_id` vem do body/path ([09:32] Larissa) |
| C-32 | `requireRole(...roles)`: 401 sem usuário, 403 `FORBIDDEN` ("Insufficient permissions") se a role não bate | `src/middlewares/auth.middleware.ts:49-61` | Replay: `authenticate, requireRole('ADMIN')` — uso idêntico a `src/modules/users/user.routes.ts:12-18` ([09:36] Larissa) |
| C-33 | `validate({ body, query, params })` com Zod; falha → `ValidationError` com `details: [{ path, message }]` | `src/middlewares/validate.middleware.ts:11-37` | Schemas de webhook: `url` com refinamento `https` ([09:23] Sofia), `events` como `z.array(z.nativeEnum(OrderStatus))`, `customerId` `z.string().uuid()`, params `id` uuid |
| C-34 | `requestLogger`: usa `X-Request-Id` recebido ou gera UUID; devolve no header; loga `http_request` com `requestId`, `method`, `path`, `statusCode`, `durationMs`, `userId` | `src/middlewares/request-logger.middleware.ts:5-28` | Base da correlação: logar `requestId` junto do `event_id` gerado no `changeStatus` → liga requisição de origem e entrega (proposta de tracing) |

## 7. Logger

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-35 | `createLogger()` Pino com `level` de env, `base: { service: 'order-management-api', env }`, timestamp ISO, `pino-pretty` em dev | `src/shared/logger/index.ts:13-30` | Worker usa o mesmo logger ([09:29] Bruno); pode criar instância com `service` próprio (ex.: `order-management-worker`) — proposta |
| C-36 | `redact` de `authorization`, `cookie`, `*.password`, `*.passwordHash`, `*.token`, `*.accessToken` | `src/shared/logger/index.ts:4-11` | **Lacuna:** não cobre `*.secret` nem `X-Signature`. Proposta no FDD: incluir esses caminhos para não vazar secret de webhook em log (motivação: [09:22] Diego) |
| C-37 | Eventos de log nomeados em snake_case: `server_started`, `shutdown_initiated`, `http_server_closed`, `bootstrap_failed`, `http_request` | `src/server.ts:10-25`, `request-logger.middleware.ts:23` | Seguir a convenção: `worker_started`, `webhook_delivery_succeeded`, `webhook_delivery_failed`, `webhook_moved_to_dlq`, `webhook_replayed` (propostas) |

## 8. Entry-point e configuração

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-38 | `server.ts`: `bootstrap()` cria app com `prisma`, `listen`, graceful shutdown em `SIGINT`/`SIGTERM` com `prisma.$disconnect()`, `logger.fatal` + `exit(1)` se o bootstrap falhar | `src/server.ts:6-27` | `src/worker.ts` **(novo, a criar)** replica a estrutura: bootstrap → loop de polling → shutdown gracioso (termina o batch em curso, `$disconnect`) — [09:11] Larissa |
| C-39 | `database.ts` exporta `createPrismaClient()` e um singleton `prisma` | `src/config/database.ts:4-11` | Worker importa o módulo no próprio processo → instância própria de `PrismaClient`, mesma `DATABASE_URL` ([09:30] Bruno) |
| C-40 | `env.ts`: schema Zod com `NODE_ENV`, `PORT`, `LOG_LEVEL`, `DATABASE_URL`, `JWT_SECRET`, `JWT_EXPIRES_IN`; falha → `exit(1)` | `src/config/env.ts:3-27` | Proposta: novas variáveis opcionais com default nos valores da reunião (ex.: intervalo de polling 2 s, timeout 10 s, tamanho do batch) — marcar como proposta no FDD |
| C-41 | `app.ts`: `express.json({ limit: '1mb' })`, `requestLogger`, `/health`, `/api/v1`, 404 de rota via `NotFoundError`, `errorMiddleware` por último | `src/app.ts:55-76` | Webhooks entram só pelo router; nada muda na ordem dos middlewares |

## 9. Persistência (Prisma)

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-42 | Convenções: `id String @id @default(uuid()) @db.Char(36)`; `createdAt @default(now())`; `updatedAt @updatedAt`; models PascalCase mapeados para tabela snake_case plural via `@@map`; `@@index` explícitos; FKs `Char(36)` | `prisma/schema.prisma:25-138` | Novos models **(novos, a criar)**: `WebhookEndpoint` → `webhook_endpoints`, `WebhookOutbox` → `webhook_outbox`, `WebhookDelivery` → `webhook_deliveries`, `WebhookDeadLetter` → `webhook_dead_letter` ([09:06], [09:18] Diego usam `webhook_outbox` e `webhook_dead_letter`) — UUID por [09:51] Larissa |
| C-43 | `Json` já é usado (`Customer.address`) | `prisma/schema.prisma:46` | Payload snapshot ([09:52]) e lista de eventos podem ser `Json` |
| C-44 | `OrderStatusHistory` registra `fromStatus`, `toStatus`, `changedById`, `reason` — auditoria de mudança de status | `prisma/schema.prisma:116-131` | Fonte conceitual do evento; o replay de DLQ precisa de auditoria análoga (quem fez — [09:36] Sofia) |
| C-45 | `Customer` sem relação com `User`; `Order.customerId` FK para `Customer` | `prisma/schema.prisma:40-54,74-97` | `WebhookEndpoint.customerId` FK para `Customer`. **Lacuna L-10:** não há como verificar se o usuário autenticado "representa" o customer |
| C-46 | Migração inicial única | `prisma/migrations/20260519182739_init/migration.sql` | Feature exige nova migração (a criar na implementação) |

## 10. Testes

| ID | O que existe | Onde | Conexão com webhooks |
|---|---|---|---|
| C-47 | `tests/orders.test.ts` testa criação e transições via Supertest, ex.: "transitions PENDING -> PAID and decrements stock" | `tests/orders.test.ts:59` | Estender com: transição gera linha na outbox; transição inválida não gera; falha na outbox faz rollback do status |
| C-48 | `tests/helpers/factories.ts`: `getTestApp`, `createTestUser`, `bootstrapAuthenticatedUser(role)`, `createTestCustomer`, `createTestProduct` | `tests/helpers/factories.ts` | Reuso direto; `bootstrapAuthenticatedUser('ADMIN')` para testar o replay |
| C-49 | `tests/setup.ts` apaga tabelas em ordem de dependência | `tests/setup.ts:8-16` | Incluir as tabelas `webhook_*` na limpeza (antes de `order` e `customer`) |

---

## 11. Lacunas do código (o que a feature precisa e não existe)

| ID | Lacuna | Tratamento nos documentos |
|---|---|---|
| G-01 | Nenhum mecanismo de fila, eventos ou HTTP de saída | Esperado (README do desafio); a feature cria tudo |
| G-02 | Nenhuma biblioteca de tracing (OpenTelemetry etc.) | Tracing no FDD = **proposta**: correlação por `requestId` (C-34) + `event_id` nos logs Pino |
| G-03 | Nenhuma biblioteca de métricas (Prometheus etc.) | Métricas no FDD = **proposta**; alternativa sem dependência nova: derivar de logs estruturados e de queries nas tabelas `webhook_*` |
| G-04 | Sem relação `User` ↔ `Customer` | Risco e questão em aberto (L-10) |
| G-05 | Sem cliente HTTP dedicado | `fetch` nativo do Node ≥ 20 com `AbortSignal.timeout(10_000)` (C-03) |
| G-06 | `redact` do logger não cobre secrets/assinaturas | Proposta de incluir caminhos (C-36) |
| G-07 | Sem script `worker` | Proposta `"worker": "tsx --env-file=.env src/worker.ts"` / build equivalente (C-02, [09:11] Larissa) |

## 12. Arquivos citados neste mapa (todos verificados como existentes)

`package.json` · `docker-compose.yml` · `vitest.config.ts` · `prisma/schema.prisma` · `prisma/migrations/20260519182739_init/migration.sql` · `src/app.ts` · `src/server.ts` · `src/routes/index.ts` · `src/config/database.ts` · `src/config/env.ts` · `src/middlewares/auth.middleware.ts` · `src/middlewares/error.middleware.ts` · `src/middlewares/validate.middleware.ts` · `src/middlewares/request-logger.middleware.ts` · `src/shared/errors/app-error.ts` · `src/shared/errors/http-errors.ts` · `src/shared/errors/index.ts` · `src/shared/logger/index.ts` · `src/shared/http/response.ts` · `src/modules/orders/order.service.ts` · `src/modules/orders/order.status.ts` · `src/modules/orders/order.routes.ts` · `src/modules/orders/order.schemas.ts` · `src/modules/orders/order.controller.ts` · `src/modules/customers/customer.repository.ts` · `src/modules/customers/customer.service.ts` · `src/modules/customers/customer.routes.ts` · `src/modules/users/user.routes.ts` · `tests/orders.test.ts` · `tests/setup.ts` · `tests/helpers/factories.ts`

Arquivos **(novos, a criar)** mencionados: `src/worker.ts`, `src/modules/webhooks/*` (controller, service, repository, routes, schemas, publisher, processor, errors).
