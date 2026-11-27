# Plano de execução — Desafio Design Docs com IA

Legenda de status: ⬜ pendente · 🟨 em andamento · ✅ concluído

| Fase | Entrega | Status |
|---|---|---|
| 0 | Setup: `CLAUDE.md`, `notas/plano.md`, `notas/processo.md` | ✅ |
| 1 | Extração e mapeamento: `notas/matriz-transcricao.md`, `notas/mapa-codigo.md` | ✅ |
| 2 | ADRs em `docs/adrs/` (7 propostos) | ✅ |
| 3 | `docs/RFC.md` | ✅ |
| 4 | `docs/FDD.md` | ⬜ |
| 5 | `docs/PRD.md` | ⬜ |
| 6 | `docs/TRACKER.md` | ⬜ |
| 7 | `README.md` do processo | ⬜ |
| 8 | Revisão final contra a checklist + push | ⬜ |

## Princípios

1. **Toda linha tem origem.** Sem `[hh:mm] Nome` ou caminho de arquivo real → não entra.
2. **Cada documento numa altura.** RFC propõe, ADR decide, FDD detalha, PRD justifica. Repetição = lugar errado.
3. **Registrar o processo durante.** Prompts e iterações vão para `notas/processo.md` no momento em que acontecem.
4. **Não tocar** em `src/`, `prisma/`, `tests/`, configs, `TRANSCRICAO.md`.

---

## Fase 0 — Setup ✅

- `CLAUDE.md` com regras, convenções de IDs, armadilhas e pontos de integração.
- `notas/plano.md` (este arquivo) e `notas/processo.md` (diário).

## Fase 1 — Extração e mapeamento

**1a. `notas/matriz-transcricao.md`** — classificar cada fala relevante em: Decisão principal, Decisão secundária, Requisito funcional, Requisito não funcional, Restrição, Alternativa descartada, Fora de escopo/Adiado, Questão em aberto. Sempre com `[hh:mm] Nome`.

Esqueleto esperado (validar contra a transcrição):

| Categoria | Itens (origem) |
|---|---|
| Decisões principais | Outbox MySQL [09:06–09:08]; worker separado + polling 2s [09:09–09:11]; 5 tentativas, backoff 1m/5m/30m/2h/12h + DLQ em tabela separada [09:15–09:18]; HMAC-SHA256 + secret por endpoint + rotação 24h [09:20–09:22]; at-least-once + `X-Event-Id` [09:24–09:26]; reuso de padrões [09:27–09:30] |
| Decisões secundárias | timeout 10s [09:42]; payload enxuto [09:43]; headers [09:44–09:45]; 64KB [09:23–09:24]; https via Zod [09:23]; filtro na inserção [09:33–09:34]; UUID [09:51]; snapshot [09:52] |
| Alternativas descartadas | síncrono [09:04–09:06]; Redis Streams [09:07]; trigger no banco [09:09]; retry indefinido e 3 tentativas [09:15–09:16]; exactly-once [09:25]; secret global [09:21]; worker no processo da API [09:11]; DLQ como status na outbox [09:17–09:18] |
| Fora de escopo / adiado | e-mail [09:37]; dashboard [09:40]; arquivamento 30 dias [09:08]; inbound [09:02]; ordering global/multi-worker [09:12–09:13] |
| Questões em aberto | rate limiting [09:38–09:39]; endurecer roles do CRUD [09:37]; estratégia de escala [09:13] |

**1b. `notas/mapa-codigo.md`** — para cada ponto de integração: caminho real, trecho/símbolo relevante, como a feature se conecta. Ver lista no `CLAUDE.md`. Ler de fato os arquivos (transação de `changeStatus`, formato de `AppError`, como o error middleware trata erros, schema Prisma com padrão de ids/nomes de tabela).

**Revisão humana:** ler a matriz lado a lado com a transcrição.

## Fase 2 — ADRs (formato MADR)

Seções: Status, Contexto, Decisão, Alternativas Consideradas, Consequências (positivas/negativas, trade-off explícito). Timestamps junto das afirmações.

| # | Arquivo | Alternativas |
|---|---|---|
| 001 | `ADR-001-outbox-no-mysql.md` | síncrono, Redis Streams |
| 002 | `ADR-002-worker-separado-com-polling.md` | trigger no banco, worker dentro da API |
| 003 | `ADR-003-retry-backoff-exponencial-e-dlq.md` | 3 tentativas, retry indefinido, "failed" na outbox |
| 004 | `ADR-004-autenticacao-hmac-sha256-por-endpoint.md` | secret global |
| 005 | `ADR-005-entrega-at-least-once-com-event-id.md` | exactly-once |
| 006 | `ADR-006-reuso-dos-padroes-do-projeto.md` | libs/padrões novos — **ADR que referencia o código** |
| 007 | `ADR-007-snapshot-do-payload-na-insercao.md` | renderizar no envio |

## Fase 3 — RFC (2–4 páginas)

- Metadados: autora Larissa ([09:50]); revisores Marcos, Bruno, Diego, Sofia.
- TL;DR, contexto/problema, proposta (visão geral), alternativas (≥ 2, com trade-off), questões em aberto (≥ 2), impacto e riscos, decisões relacionadas (links para ≥ 2 ADRs).
- Sem payloads, matriz de erros ou schemas.

## Fase 4 — FDD

- Contexto técnico, objetivos, escopo/exclusões.
- Fluxos (Mermaid): inserção na outbox no `changeStatus` → worker → retry → DLQ → replay.
- Contratos (≥ 4, com request/response/status codes): `POST /webhooks`, `GET /webhooks`, `PATCH /webhooks/:id`, `DELETE /webhooks/:id`, rotação de secret [09:21], `GET /webhooks/:id/deliveries` [09:34], `POST /admin/webhooks/dead-letter/:id/replay` [09:18].
- Payload de evento [09:43] e headers [09:44–09:45].
- Matriz de erros `WEBHOOK_*` (WEBHOOK_NOT_FOUND, WEBHOOK_INVALID_URL, WEBHOOK_SECRET_REQUIRED [09:28] + derivados das regras).
- Resiliência: timeout 10s, retries, backoff, DLQ, fallback.
- Observabilidade: métricas, logs (Pino), tracing (proposta).
- Dependências e compatibilidade, critérios de aceite técnicos, riscos.
- **Integração com o sistema existente**: ≥ 4 caminhos reais.

## Fase 5 — PRD

Resumo, problema (polling no `GET /orders`, risco de churn da Atlas [09:00]), público e cenários, objetivos com métrica (< 10s [09:02]), escopo (≥ 2 fora de escopo), ≥ 8 RFs, RNFs, decisões e trade-offs, dependências, riscos (≥ 2 com probabilidade/impacto/mitigação), critérios de aceitação, estratégia de testes.

## Fase 6 — Tracker

Varrer os documentos prontos e gerar uma linha por item com ID. Metas: ≥ 80% de cobertura, ≥ 70% `TRANSCRICAO`, ≥ 5 `CODIGO`.

## Fase 7 — README do processo

A partir de `notas/processo.md`: Sobre o desafio, Ferramentas de IA, Workflow, Prompts customizados (≥ 2, em blocos de código), Iterações e ajustes (≥ 2 concretas), Como navegar a entrega.

## Fase 8 — Revisão final

- Auditoria item a item contra os Critérios de Aceite do enunciado.
- Checagens automáticas: caminhos citados existem; timestamps citados existem e o falante confere; contagens (ADRs, endpoints, linhas do tracker, % de fontes).
- Commit e push para o fork.

## Forma de trabalho com o Claude Code na extensão do VS Code

- Trabalho feito no painel do Claude Code dentro do VS Code, com o repositório aberto como workspace. O `CLAUDE.md` é carregado automaticamente em cada conversa.
- Conversa contínua enquanto o contexto estiver saudável; ao trocar de fase (ou se a conversa ficar longa), abrir uma nova conversa — o contexto persiste via `CLAUDE.md` + `notas/`.
- Revisão no próprio editor: abrir os documentos gerados lado a lado com `TRANSCRICAO.md` e conferir os diffs de cada edição antes de aprovar.
- Ao fim de cada documento: "liste toda afirmação deste documento sem fonte identificável".
- Commit ao fim de cada fase (o histórico também é evidência das iterações).

## Fluxo git

- Branch de trabalho: `docs/design-docs-webhooks`, criada a partir da `main`.
- Um commit por fase, no padrão `docs(fase-N): ...` (ou `chore(fase-0): ...` para o setup).
- Ao final da Fase 8: push da branch e PR para a `main` do fork.
