# ADR-006: Reuso dos padrões existentes do projeto no módulo de webhooks

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada na reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Larissa (Tech Lead), Bruno (Pedidos), Diego (Plataforma)
- **Relacionados:** [ADR-001](./ADR-001-outbox-no-mysql.md) · [ADR-002](./ADR-002-worker-separado-com-polling.md) · [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md) · [ADR-004](./ADR-004-autenticacao-hmac-sha256-por-endpoint.md)

## Contexto

A base de código já tem um padrão claro: "cada domínio é um módulo em src/modules com controller, service, repository, routes e schemas" ([09:27] Bruno). Hoje existem `auth`, `users`, `customers`, `products` e `orders`, compostos manualmente em `buildControllers` (`src/app.ts`) e montados sob `/api/v1` (`src/routes/index.ts`).

A infraestrutura transversal também já existe:

| Peça | Onde está | O que faz hoje |
|---|---|---|
| Classe base de erro | `src/shared/errors/app-error.ts` | `AppError(message, statusCode, errorCode, details?)` |
| Erros HTTP e de domínio | `src/shared/errors/http-errors.ts` | `NotFoundError`, `ConflictError`, `UnprocessableEntityError`…; erros de domínio como `InvalidStatusTransitionError` (`INVALID_STATUS_TRANSITION`) e `InsufficientStockError` (`INSUFFICIENT_STOCK`) |
| Error middleware | `src/middlewares/error.middleware.ts` | Converte `AppError`, `ZodError` e erros Prisma no envelope `{ error: { code, message, details } }` |
| Autenticação e autorização | `src/middlewares/auth.middleware.ts` | `authenticate` (JWT) e `requireRole(...roles)` |
| Validação | `src/middlewares/validate.middleware.ts` | `validate({ body, query, params })` com Zod |
| Logger | `src/shared/logger/index.ts` | Pino com `redact` e timestamp ISO |
| Acesso a dados | `src/config/database.ts`, `prisma/schema.prisma` | `createPrismaClient()`; ids UUID `@db.Char(36)` |

A pergunta é se a feature segue esses padrões ou introduz estruturas próprias.

## Decisão

"Reuso máximo do que já existe. AppError, Pino, error middleware, padrão de módulos, padrão de schemas Zod, padrão de códigos de erro. Webhook fica como módulo igual aos outros." ([09:30] Larissa)

1. **Módulo `src/modules/webhooks/` (novo, a criar)** com controller, service, repository, routes e schemas, como os módulos existentes ([09:27] Bruno, [09:28] Diego).
2. **Lógica do worker dentro do módulo** (`webhook.worker.ts` ou `webhook.processor.ts`, **novo, a criar**), com a entry-point `src/worker.ts` **(novo, a criar)** fora dele ([09:28] Bruno; ver [ADR-002](./ADR-002-worker-separado-com-polling.md)).
3. **Erros derivados de `AppError`**, como `InsufficientStockError` e `InvalidStatusTransitionError`, com códigos de prefixo **`WEBHOOK_`** — por exemplo `WEBHOOK_NOT_FOUND`, `WEBHOOK_INVALID_URL`, `WEBHOOK_SECRET_REQUIRED` ([09:28] Bruno, [09:29] Larissa).
4. **Error middleware centralizado sem alteração:** ele "já trata AppError, Zod e Prisma. Vai pegar nossos erros sem precisar mudar nada" ([09:29] Bruno).
5. **Logger Pino existente**, "não vamos botar nada novo" ([09:29] Bruno).
6. **`requireRole('ADMIN')` existente** no endpoint de replay da DLQ ([09:36] Larissa), como já é feito em `src/modules/users/user.routes.ts`.
7. **Schemas Zod + middleware `validate`** para as entradas da API, incluindo a recusa de URLs `http` ([09:23] Sofia).
8. **Prisma com instância por processo**, mesma `DATABASE_URL` ([09:30] Bruno), e **ids UUID** como "o resto do projeto. Tudo é uuid" ([09:51] Larissa).
9. **Integração com pedidos por função**, não por injeção de dependência: `publishWebhookEvent(tx, order, fromStatus, toStatus)` chamada dentro do `changeStatus` em `src/modules/orders/order.service.ts` ([09:41] Bruno, [09:41] Diego).

## Alternativas Consideradas

### A. Injetar um repository de webhook no `OrderService` — `ADR-006-ALT-A`
Discutida na reunião. **Preterida:** "função pura recebendo o tx. Não precisa injetar repository inteiro" ([09:41] Diego). Mantém o construtor de `OrderService` (`src/modules/orders/order.service.ts`) e a composição em `src/app.ts` inalterados.

### B. Estrutura e bibliotecas próprias para o módulo (alternativa plausível) — `ADR-006-ALT-B`
Por exemplo, um framework de jobs, outro logger ou um tratamento de erro local com middleware próprio. **Rejeitada:** contraria a decisão de reuso ([09:30] Larissa) e o "nada novo" do logger ([09:29] Bruno); produziria envelopes de erro e logs inconsistentes com o resto da API e aumentaria a superfície de revisão de segurança ([09:46] Sofia).

## Consequências

### Positivas
- **Consistência:** erros de webhook saem no mesmo envelope dos demais (`src/middlewares/error.middleware.ts`), e os logs seguem a mesma estrutura.
- **Curva de aprendizado baixa** e revisão mais rápida: o módulo "se parece" com `customers` e `orders`.
- **Sem dependência nova:** HMAC e geração de secret com `crypto` nativo, HTTP com `fetch` nativo (Node ≥ 20, `package.json`) e `uuid` já presente.
- **Mudança mínima no módulo de pedidos:** uma chamada de função dentro da transação existente.

### Negativas (limitações herdadas dos padrões atuais)
- **`NotFoundError` não aceita código customizado** (sempre `NOT_FOUND`, `src/shared/errors/http-errors.ts`) → `WEBHOOK_NOT_FOUND` exige uma classe própria derivada de `AppError`.
- **`redact` do logger não cobre secrets nem assinaturas** (`src/shared/logger/index.ts`) → a configuração precisa ser estendida (ver [ADR-004](./ADR-004-autenticacao-hmac-sha256-por-endpoint.md)).
- **Sem biblioteca de métricas ou tracing** no projeto → a observabilidade parte de logs estruturados e de propostas no FDD.
- **`requireRole` só autoriza por role** (`ADMIN`/`OPERATOR`); não existe relação entre `User` e `Customer` em `prisma/schema.prisma`, então o padrão atual não verifica se o usuário "representa" o customer ([09:32] Marcos). Com o CRUD liberado a qualquer role autenticada "por enquanto" ([09:37] Sofia), isso fica registrado como risco e questão em aberto.

### Trade-off aceito
Aceitam-se as limitações dos padrões atuais em troca de **consistência, velocidade de entrega e menor superfície de revisão**. Onde o padrão não basta (código de `NotFoundError`, `redact`), ele é estendido pontualmente, sem criar estrutura paralela.

## Referências

- Transcrição: [09:23] Sofia, [09:27] Bruno, [09:28] Diego, [09:28] Bruno, [09:29] Larissa, [09:29] Bruno, [09:30] Bruno, [09:30] Larissa, [09:32] Marcos, [09:36] Larissa, [09:37] Sofia, [09:41] Bruno, [09:41] Diego, [09:46] Sofia, [09:51] Larissa
- Código: `src/app.ts`, `src/routes/index.ts`, `src/shared/errors/app-error.ts`, `src/shared/errors/http-errors.ts`, `src/middlewares/error.middleware.ts`, `src/middlewares/auth.middleware.ts`, `src/middlewares/validate.middleware.ts`, `src/shared/logger/index.ts`, `src/config/database.ts`, `src/modules/orders/order.service.ts`, `src/modules/users/user.routes.ts`, `prisma/schema.prisma`, `package.json`
