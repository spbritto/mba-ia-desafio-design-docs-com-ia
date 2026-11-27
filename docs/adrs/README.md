# Architectural Decision Records

Este diretório armazena os ADRs (Architectural Decision Records) da feature **Sistema de Webhooks de Notificação de Pedidos**. Cada decisão arquitetural fica em um arquivo próprio, no formato MADR (Status, Contexto, Decisão, Alternativas Consideradas, Consequências).

**Convenção de nomes:** `ADR-NNN-titulo-em-kebab-case.md` (numeração sequencial com três dígitos).

## Índice

| ADR | Decisão | Status |
|---|---|---|
| [ADR-001](./ADR-001-outbox-no-mysql.md) | Padrão Outbox no MySQL, na mesma transação do `changeStatus` | Aceito |
| [ADR-002](./ADR-002-worker-separado-com-polling.md) | Worker em processo separado, polling de 2 s, single-worker | Aceito |
| [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md) | Retry com backoff 1m/5m/30m/2h/12h e DLQ em tabela separada | Aceito |
| [ADR-004](./ADR-004-autenticacao-hmac-sha256-por-endpoint.md) | HMAC-SHA256 com secret por endpoint e rotação com grace period de 24 h | Aceito |
| [ADR-005](./ADR-005-entrega-at-least-once-com-event-id.md) | Entrega at-least-once com deduplicação via `X-Event-Id` | Aceito |
| [ADR-006](./ADR-006-reuso-dos-padroes-do-projeto.md) | Reuso dos padrões existentes (módulos, `AppError`, Pino, error middleware, `requireRole`, Zod) | Aceito |
| [ADR-007](./ADR-007-snapshot-do-payload-na-insercao.md) | Snapshot do payload na inserção da outbox | Aceito |

Origem das decisões: `TRANSCRICAO.md` (reunião técnica) e código do repositório. A rastreabilidade item a item está em [`docs/TRACKER.md`](../TRACKER.md).
