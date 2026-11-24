# Matriz da transcrição

Extração de `TRANSCRICAO.md` (reunião, ~09:00–09:53). Cada linha aponta para a fala de origem no formato `[hh:mm] Nome`. Esta matriz é a fonte única para ADRs, RFC, FDD, PRD e Tracker.

**Categorias:** `CTX` contexto de negócio · `DEC` decisão principal · `DEC2` decisão secundária · `RF` requisito funcional · `RNF` requisito não funcional · `RES` restrição · `ALT` alternativa descartada · `OOS` fora de escopo / adiado · `OQ` questão em aberto · `TRD` trade-off aceito · `ARM` armadilha / fala corrigida

**Participantes:** Larissa (Tech Lead), Marcos (PM), Bruno (Eng. Pleno, Pedidos), Diego (Eng. Sênior, Plataforma — entra às [09:05]), Sofia (Eng. Segurança). Marcos e Sofia saem às [09:50]; o trecho [09:50]–[09:53] tem só Larissa, Diego e Bruno.

---

## 1. Contexto e problema

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-001 | CTX | Três clientes B2B (Atlas Comercial, MaxDistribuição, Nova Cargo) pediram formalmente notificação em tempo real quando o status dos pedidos muda | [09:00] Marcos | PRD, RFC |
| T-002 | CTX | Hoje os clientes fazem polling periódico no `GET /orders`; a integração fica lenta e cara para eles | [09:00] Marcos | PRD, RFC |
| T-003 | CTX | Atlas sinalizou que pode migrar para concorrente se não houver entrega até o fim do trimestre | [09:00] Marcos | PRD (risco) |
| T-004 | RNF | "Tempo real" para os clientes = qualquer coisa abaixo de 10 segundos; o importante é não ter que atualizar manualmente | [09:02] Marcos (pergunta de [09:01] Bruno) | PRD (métrica), FDD |
| T-005 | RES | Webhooks só de saída (plataforma → cliente); clientes querem receber, não enviar | [09:02] Marcos, [09:03] Sofia | PRD (escopo), FDD |

## 2. Outbox no MySQL (decisão principal 1)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-006 | ALT | Disparo síncrono no service de orders descartado: a transação de mudança de status já é pesada (update em `orders`, insert em `order_status_history`, decremento de `stock_quantity`); um HTTP lento travaria mudanças de status de outros pedidos | [09:04] Bruno | ADR-001, RFC |
| T-007 | ALT | Síncrono também falha no caso de cliente fora do ar: não dá para dar rollback na mudança de status | [09:04] Bruno | ADR-001, RFC |
| T-008 | DEC | "Síncrono está fora de questão" — usar padrão outbox | [09:06] Diego (concordância [09:04] Larissa) | ADR-001 |
| T-009 | DEC | Outbox: na mesma transação SQL que atualiza `orders` e `order_status_history`, inserir uma linha em `webhook_outbox`; worker separado lê a tabela e dispara HTTP. Commit → evento registrado; rollback → evento some junto | [09:06] Diego | ADR-001, FDD |
| T-010 | ALT | Redis Streams (ou similar) descartado: exigiria subir mais infraestrutura | [09:07] Larissa | ADR-001, RFC |
| T-011 | ALT | Time pequeno; subir Redis Cluster para isso é overengineering; outbox no MySQL existente resolve | [09:07] Diego | ADR-001, RFC |
| T-012 | DEC2 | Performance: índice no campo de status (pendente, processando, falhou, entregue) e em `created_at`; worker lê só pendentes, em batch pequeno, processa e marca como entregue | [09:08] Diego (pergunta de [09:07] Bruno) | ADR-001, FDD |
| T-013 | OOS | Arquivamento de linhas entregues depois de ~30 dias — fora do escopo desta feature | [09:08] Diego | PRD, FDD |
| T-014 | DEC | "Tá decidido então: outbox em MySQL" | [09:08] Larissa | ADR-001 |

## 3. Worker separado com polling (decisão principal 2)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-015 | DEC | Worker lê a outbox por polling em loop: a cada 2 segundos busca os pendentes mais antigos, processa e marca | [09:09] Diego | ADR-002, FDD |
| T-016 | ALT | Trigger de banco descartada: MySQL não tem LISTEN/NOTIFY como o Postgres; trigger só executa SQL e não notifica processo externo; avisar o worker exigiria gambiarra (arquivo, endpoint) | [09:09] Bruno (sugestão), [09:09] Diego (descarte) | ADR-002, RFC |
| T-017 | DEC | Polling de 2 s atende o requisito de < 10 s | [09:09] Diego, [09:10] Marcos | ADR-002, PRD |
| T-018 | TRD | Decisão registrada: worker em polling de 2 s; aceita-se a latência de até 2 s adicionada pelo polling | [09:10] Larissa | ADR-002 |
| T-019 | RES | Worker roda em processo separado, não na mesma instância da API — se a API reinicia, perde o worker | [09:11] Diego | ADR-002, FDD |
| T-020 | ALT | Worker dentro do processo da API descartado (motivo de T-019) | [09:11] Diego | ADR-002 |
| T-021 | DEC2 | Nova entry-point `src/worker.ts` **(novo, a criar)** (análoga a `src/server.ts`) e script `npm run worker` **(novo, a criar)** | [09:11] Larissa | ADR-002, FDD |
| T-022 | RES | Worker usa o mesmo banco e a mesma stack; só não pode ser o mesmo processo | [09:11] Bruno, [09:11] Diego | ADR-002, FDD |

## 4. Ordenação

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-023 | DEC2 | Com um único worker, processamento em ordem de `created_at` da outbox → cliente recebe em ordem; com múltiplos workers em paralelo, perde-se a garantia. Por enquanto: single-worker, ordering implícita por `order_id` | [09:12] Diego (pergunta de [09:12] Larissa) | ADR-002, FDD |
| T-024 | OQ | Escala futura: particionar por `order_id` ou lock pessimista — "problema do futuro" | [09:13] Diego (pergunta de [09:13] Bruno) | RFC (questão em aberto) |
| T-025 | RES | Limitação conhecida documentada: sem ordering global; só por `order_id` e enquanto single-worker | [09:13] Larissa | ADR-002, FDD, PRD |
| T-026 | CTX | Clientes nunca pediram ordering global; só querem saber se cada pedido mudou | [09:14] Marcos | PRD |

## 5. Retry com backoff e DLQ (decisão principal 3)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-027 | DEC | Cliente offline → backoff exponencial; após teto de tentativas, falha permanente → DLQ | [09:15] Diego | ADR-003, FDD |
| T-028 | ALT | Retry indefinido com backoff descartado: evento ficaria pendurado para sempre se o cliente sumiu | [09:15] Diego | ADR-003, RFC |
| T-029 | DEC | 5 tentativas cobrem janela de 12 a 24 h | [09:15] Diego | ADR-003 |
| T-030 | ALT | 3 tentativas (proposta de Bruno, "mais agressivo") descartadas: 3 retentativas em ~30 min matariam o evento; já houve cliente com 2 h de indisponibilidade em manutenção planejada | [09:16] Bruno (proposta), [09:16] Diego (descarte) | ADR-003, RFC |
| T-031 | DEC | Progressão do backoff: 1 min, 5 min, 30 min, 2 h, 12 h — "quase 15 horas entre primeira falha e última tentativa" | [09:17] Diego | ADR-003, FDD |
| T-032 | TRD | Cliente fora por 15 h "já tá com problema sério dele" — janela aceitável | [09:17] Marcos | ADR-003, PRD |
| T-033 | DEC | "Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h" | [09:17] Larissa | ADR-003 |
| T-034 | DEC | DLQ em tabela separada `webhook_dead_letter` com payload, motivo da falha e timestamp; leitura da outbox fica mais limpa e a tabela serve de evidência para debug e reprocessamento | [09:18] Diego (pergunta de [09:17] Larissa) | ADR-003, FDD |
| T-035 | ALT | Marcar como "failed" na própria outbox (opção levantada por Larissa) — preterida em favor da tabela separada | [09:17] Larissa, [09:18] Diego | ADR-003 |
| T-036 | RF | Reprocessamento manual via endpoint admin `POST /admin/webhooks/dead-letter/:id/replay`, que recoloca o evento na outbox como pendente | [09:18] Diego (pergunta de [09:18] Bruno); reafirmado [09:35] Diego | ADR-003, FDD, PRD |

## 6. Segurança — HMAC e secret por endpoint (decisão principal 4)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-037 | RNF | Eventos com dados de pedido saem da infra; o cliente precisa validar que a requisição veio da plataforma e que o payload não foi adulterado | [09:19] Sofia | ADR-004, PRD |
| T-038 | DEC | Assinatura HMAC do payload com secret compartilhada, enviada em header `X-Signature`; cliente verifica do lado dele | [09:20] Sofia | ADR-004, FDD |
| T-039 | DEC | Algoritmo SHA-256 (HMAC-SHA256, padrão de mercado, todo cliente tem biblioteca) | [09:20] Sofia (pergunta de [09:20] Bruno) | ADR-004 |
| T-040 | ALT | Secret global da plataforma descartada: "se vaza uma, vaza tudo" → secret única por endpoint | [09:21] Sofia | ADR-004, RFC |
| T-041 | DEC2 | Tabela de configuração de webhook armazena url + secret + customer_id + estado ativo | [09:21] Bruno, [09:21] Sofia | FDD |
| T-042 | RF | Secret rotacionável: endpoint para o cliente pedir nova secret pela API; a antiga fica válida por 24 h em paralelo; depois morre | [09:21] Sofia | ADR-004, FDD, PRD |
| T-043 | CTX | Motivação da rotação: um cliente já vazou secret em log da aplicação dele | [09:22] Diego | ADR-004 |
| T-044 | DEC | "Decidido: HMAC-SHA256 sobre o corpo do request, secret por endpoint, suporte a rotação com grace period de 24h" | [09:22] Sofia | ADR-004 |
| T-045 | RNF | TLS obrigatório: URL do webhook tem que ser `https`; `http` é recusado com erro de validação no schema Zod ("nem é decisão arquitetural") | [09:23] Sofia | FDD, PRD |
| T-046 | RNF | Limite de tamanho de payload: 64 KB; se ultrapassar, erro (não truncar — "se chegou nesse tamanho, tem algo errado"); tratado como RNF, não como decisão arquitetural | [09:23] Sofia, [09:24] Diego, [09:24] Larissa | FDD, PRD |

## 7. At-least-once com `X-Event-Id` (decisão principal 5)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-047 | DEC | Garantia at-least-once: o cliente pode receber o mesmo evento duas vezes e deve estar preparado | [09:24] Diego | ADR-005, FDD, PRD |
| T-048 | DEC | Header `X-Event-Id` com UUID gerado quando o evento entra na outbox, único por evento; cliente deduplica por ele | [09:25] Diego (pergunta de [09:25] Bruno) | ADR-005, FDD |
| T-049 | TRD | "Isso joga responsabilidade pro cliente" | [09:25] Sofia | ADR-005, RFC |
| T-050 | ALT | Exactly-once descartado: exigiria coordenação dos dois lados, muito mais complexo; at-least-once + event_id é padrão de mercado (Stripe, GitHub) e "resolve 99% dos casos" | [09:25] Diego | ADR-005, RFC |
| T-051 | DEC2 | PM documenta a semântica at-least-once em destaque no portal de desenvolvedor | [09:26] Marcos | PRD (dependência) |
| T-052 | DEC | "At-least-once com X-Event-Id pra dedup do lado do cliente. Decisão." | [09:26] Larissa | ADR-005 |

## 8. Reuso dos padrões do projeto (decisão principal 6)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-053 | DEC | Webhook vira módulo `src/modules/webhooks` com controller, service, repository, routes e schemas, igual aos demais domínios | [09:27] Bruno, [09:28] Diego | ADR-006, FDD |
| T-054 | DEC2 | Worker: `src/worker.ts` **(novo, a criar)** como entry separada; lógica de processamento em `src/modules/webhooks/webhook.worker.ts` ou `webhook.processor.ts` **(novos, a criar — nome a escolher no FDD)** | [09:28] Bruno | ADR-006, FDD |
| T-055 | DEC | Erros seguem o padrão `AppError` + classes específicas; códigos com prefixo `WEBHOOK_` (ex.: `WEBHOOK_NOT_FOUND`, `WEBHOOK_INVALID_URL`, `WEBHOOK_SECRET_REQUIRED`) | [09:28] Bruno, [09:29] Larissa | ADR-006, FDD |
| T-056 | DEC | Logger Pino já usado no projeto inteiro — nada novo; error middleware centralizado já trata AppError, Zod e Prisma e vai pegar os erros novos sem mudança | [09:29] Bruno | ADR-006, FDD |
| T-057 | DEC2 | Worker usa instância própria de `PrismaClient` (PrismaClient é por processo), mesmo banco e mesma `DATABASE_URL` | [09:30] Bruno (pergunta de [09:29] Diego) | ADR-006, FDD |
| T-058 | DEC | "Reuso máximo do que já existe": AppError, Pino, error middleware, padrão de módulos, schemas Zod, padrão de códigos de erro | [09:30] Larissa | ADR-006 |

## 9. Requisitos funcionais da API

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-059 | RF | Cadastrar webhook via `POST`; campos: `url` e lista de status que deseja receber; a secret é gerada pela plataforma e devolvida na criação | [09:31] Marcos | FDD, PRD |
| T-060 | ARM | Marcos diz "customer_id implícito do JWT" — **corrigido** logo depois | [09:31] Marcos | — (não usar) |
| T-061 | RES | O JWT atual é do usuário operador, não do cliente | [09:32] Bruno | FDD |
| T-062 | RES | Cadastro é feito pela API da plataforma, autenticado com JWT do sistema; "a gente tem usuários que representam o cliente" | [09:32] Marcos | FDD, PRD |
| T-063 | DEC2 | Endpoint autenticado normal; `customer_id` vai no body ou no path, **não vem do JWT** | [09:32] Larissa | FDD |
| T-064 | RF | `PATCH` para editar, `DELETE` para remover, `GET` para listar os webhooks de um customer | [09:33] Bruno | FDD, PRD |
| T-065 | RF | Filtro de eventos por endpoint: lista dos status que o webhook quer ouvir (ex.: só SHIPPED e DELIVERED) | [09:33] Bruno, [09:33] Marcos | FDD, PRD |
| T-066 | DEC2 | Filtro aplicado na inserção da outbox: se nenhum webhook do customer quer aquele status, nem insere (economiza linhas) | [09:33] Marcos, [09:34] Bruno, [09:34] Diego (pergunta de [09:34] Diego) | FDD |
| T-067 | RF | Histórico de entregas: últimos 100 webhooks enviados, com sucesso/falha, payload, response e tempo de resposta — `GET /webhooks/:id/deliveries` | [09:34] Marcos | FDD, PRD |
| T-068 | RNF | Replay de DLQ exige role `ADMIN` do JWT ("mexer em fila de entrega de notificação não é coisa de operador") | [09:36] Sofia (pergunta de [09:35] Larissa) | FDD, PRD |
| T-069 | RF | O endpoint de replay deve logar quem fez o replay, para auditoria | [09:36] Sofia | FDD, PRD |
| T-070 | DEC2 | Reaproveitar o `requireRole` existente para o replay | [09:36] Larissa | ADR-006, FDD |
| T-071 | OQ | CRUD de configuração liberado para qualquer role autenticada "por enquanto"; "mais pra frente a gente pode endurecer" | [09:37] Sofia (pergunta de [09:36] Marcos) | RFC (questão em aberto), FDD |

## 10. Fora de escopo e pontos em aberto

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-072 | OOS | E-mail para o cliente quando o webhook falha repetidamente (ex.: 3 falhas seguidas) — fora desta fase; talvez próxima, "depois que a gente medir o impacto" | [09:37] Marcos (pedido), [09:37] Larissa (descarte), [09:38] Marcos ("futuro") | PRD, RFC |
| T-073 | OQ | Rate limiting de envio por cliente (ex.: 50 pedidos mudando em 1 min = 50 chamadas) — fora do escopo; "observar e decidir depois" | [09:38] Diego, [09:39] Diego, [09:39] Larissa | RFC (questão em aberto), PRD |
| T-074 | OOS | Dashboard visual para o cliente ver os webhooks — não agora; só endpoints; painel é projeto separado do time de frontend | [09:39] Marcos (pedido), [09:40] Larissa | PRD, RFC |
| T-075 | DEC2 | PM documenta no portal como integrar via API | [09:40] Marcos | PRD (dependência) |

## 11. Integração com o `changeStatus`

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-076 | RES | Alteração crítica dentro do service de orders, método `changeStatus`: inserir em `webhook_outbox` na mesma transação (que hoje faz update na order, insert no history e atualiza estoque); se a outbox falhar, rollback — não pode existir status mudado sem evento | [09:40] Bruno | ADR-001, FDD |
| T-077 | RES | Fora da transação perde-se a garantia toda | [09:41] Diego | ADR-001 |
| T-078 | DEC2 | Função `publishWebhookEvent(tx, order, fromStatus, toStatus)` que recebe o tx client da transação atual, chamada pelo `order.service` | [09:41] Bruno | FDD, ADR-006 |
| T-079 | ALT | Injetar o repository inteiro de webhook no `OrderService` — preterido: "função pura recebendo o tx" | [09:41] Bruno, [09:41] Diego | FDD |

## 12. Detalhes de entrega (decisões secundárias)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-080 | DEC2 | Timeout do HTTP do worker: 10 s; sem resposta em 10 s = falha, marca para retry | [09:42] Diego (pergunta de [09:42] Sofia), [09:42] Sofia | FDD |
| T-081 | DEC2 | Payload JSON: `event_id`, `event_type` (ex.: `order.status_changed`), `timestamp` ISO 8601, `order_id`, `order_number`, `from_status`, `to_status`, `customer_id` e campos básicos da order como `total_cents`; **sem items** (não inflar); detalhes via `GET /orders/:id` | [09:43] Diego (pergunta de [09:43] Marcos), [09:44] Bruno | FDD |
| T-082 | DEC2 | Headers: `X-Event-Id` (UUID), `X-Signature` (HMAC), `X-Timestamp` (momento do envio — permite ao cliente detectar replay attack), `Content-Type: application/json` | [09:44] Diego (pergunta de [09:44] Marcos) | FDD |
| T-083 | DEC2 | Header adicional `X-Webhook-Id` com o id do endpoint, para cliente com vários cadastros saber qual disparou | [09:44] Sofia, [09:45] Diego | FDD |

## 13. Prazo e planejamento

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-084 | CTX | Atlas quer a entrega para o fim de novembro | [09:45] Marcos | PRD |
| T-085 | CTX | Estimativa: outbox + DLQ = 1 sprint; worker + retry = 1 sprint; CRUD + deliveries = ½ sprint; integração no `order.service` + testes ponta a ponta = ½ sprint; HMAC, schemas, validações = "mais um pouco" → ~3 sprints incluindo revisão | [09:46] Larissa | PRD, RFC |
| T-086 | RES | Reservar ≥ 2 dias úteis para revisão de segurança antes do deploy (HMAC e geração de secret com calma) | [09:46] Sofia; reforçado [09:49] Sofia | PRD, RFC, FDD |
| T-087 | CTX | Fechado: 3 sprints com a revisão da Sofia incluída no fim | [09:47] Larissa | PRD |
| T-088 | CTX | Resumo final de Larissa confirma todas as decisões (outbox, polling 2 s, backoff, DLQ, HMAC, at-least-once, reuso, roles, e-mail futuro, rate limiting observado, dashboard fora, 3 sprints) — validado por Diego, Bruno, Sofia e Marcos | [09:48] Larissa; [09:49] Diego, Bruno, Sofia, Marcos | Todos (validação) |
| T-089 | CTX | Larissa abrirá o doc de design e marcará sessão de revisão com Bruno e Diego antes de codar | [09:50] Larissa | RFC (metadados) |

## 14. Decisões pós-call (só Larissa, Diego e Bruno presentes)

| ID | Cat. | Conteúdo | Origem | Destino |
|---|---|---|---|---|
| T-090 | DEC2 | IDs da outbox em UUID (não auto-incremento), seguindo o padrão do projeto ("tudo é uuid") | [09:51] Diego (pergunta), [09:51] Larissa | FDD |
| T-091 | DEC | Payload renderizado e gravado na inserção (snapshot), não só `order_id` renderizado no envio: o evento reflete o estado do momento da mudança | [09:51] Bruno (pergunta), [09:52] Larissa, [09:52] Diego, [09:52] Bruno | ADR-007, FDD |
| T-092 | ALT | Guardar só `order_id` e renderizar no envio — descartado ("senão tem caso esquisito" se o pedido mudar depois) | [09:52] Larissa | ADR-007 |

## 15. Armadilhas (não usar como fato)

| ID | Conteúdo | Origem | Tratamento |
|---|---|---|---|
| T-060 | customer_id "implícito do JWT" | [09:31] Marcos | Corrigido em [09:32]; usar T-063 |
| T-093 | "Estamos a uma hora de reunião" | [09:27] Larissa | Contradiz o horário (27 min); ignorar |
| T-094 | Prazo aparece de duas formas: "fim do trimestre" ([09:00] Marcos) e "fim de novembro" ([09:45] Marcos) | — | Citar ambos com a fala de origem; não fundir |
| T-095 | Diego só entra às [09:05] | [09:05] | Nada antes disso é atribuível a ele |
| T-096 | "Mesmo Prisma client" ([09:11] Bruno) vs. "Separado... instância nova" ([09:30] Bruno) | — | Leitura consistente: mesma lib/schema/banco, instância própria por processo (T-057) |
| T-097 | "Resolve 99% dos casos" | [09:25] Diego | Força de expressão sobre at-least-once; não é SLA nem métrica |

---

## 16. Lacunas e ambiguidades — decisões pendentes

A transcrição não fecha estes pontos. A coluna "Recomendação" traz o tratamento proposto.

> **Status: todas as 12 recomendações aprovadas pelo usuário em 2026-11-23.** Nos documentos, cada uma aparece como **interpretação** ou **proposta** explícita (nunca como fala da reunião), e as marcadas para o RFC entram como questões em aberto.

| ID | Lacuna | Evidência | Recomendação |
|---|---|---|---|
| L-01 | **"5 tentativas" é ambíguo.** São 5 intervalos (1m/5m/30m/2h/12h) e "quase 15 horas entre primeira falha e última tentativa" (1+5+30+120+720 min = 14h36) — isso implica envio inicial + 5 retentativas = 6 envios. Se fossem 5 envios no total, só caberiam 4 intervalos | [09:17] Diego, [09:17] Larissa, [09:48] Larissa | Adotar **1 envio inicial + 5 retentativas** (única leitura compatível com a soma de ~15 h) e registrar a interpretação explicitamente no ADR-003 |
| L-02 | **Momento do erro de 64 KB.** "Erra" não diz onde. Se o erro for lançado na inserção da outbox, a regra de T-076 (falha da outbox → rollback) bloquearia a mudança de status do pedido por causa do webhook | [09:23] Sofia, [09:24] Larissa, [09:40] Bruno | Validar o tamanho no worker, antes do envio: evento vai direto para a DLQ com motivo `WEBHOOK_PAYLOAD_TOO_LARGE`, sem retry. Registrar como questão em aberto no RFC |
| L-03 | **Rotação com grace period em webhook de saída.** Quem verifica a assinatura é o cliente; "a antiga fica válida por 24 h" exige que a plataforma assine de forma que ambas as secrets validem durante a janela. O mecanismo não foi discutido | [09:21] Sofia, [09:22] Sofia | FDD propõe enviar a assinatura das duas secrets durante a janela (ex.: duas assinaturas no `X-Signature`), marcado como proposta; RFC lista como questão em aberto para a revisão da Sofia ([09:46]) |
| L-04 | **Caminho do endpoint de rotação** não foi nomeado | [09:21] Sofia | Propor `POST /webhooks/:id/rotate-secret` no FDD, marcado como proposta |
| L-05 | **O que é "sucesso"** na entrega e se 4xx do cliente também gera retry | — | Propor: 2xx = sucesso; qualquer outro status, erro de rede ou timeout = falha com retry. Marcar como proposta |
| L-06 | **Evento "processando" órfão.** Se o worker cair com evento em status "processando" (T-012), nada foi dito sobre recuperação | [09:08] Diego | Propor timeout de reivindicação (evento volta a pendente) no FDD; risco no RFC |
| L-07 | **Status "falhou" na outbox vs. DLQ separada.** Diego lista "falhou" como status da outbox ([09:08]) e depois decide DLQ em tabela separada ([09:18]) | [09:08] Diego, [09:18] Diego | Interpretar "falhou" como falha transitória aguardando retry; falha permanente sai da outbox para `webhook_dead_letter` |
| L-08 | **Tabela de histórico de entregas** não foi nomeada; precisa existir para `GET /webhooks/:id/deliveries` (T-067) | [09:34] Marcos | Propor tabela `webhook_deliveries` (uma linha por tentativa) no FDD, marcada como proposta |
| L-09 | **Evento na criação do pedido.** A criação grava histórico `null → PENDING` em `create()`, não em `changeStatus`; a reunião só fala em "mudança de status" no `changeStatus` | [09:40] Bruno; `src/modules/orders/order.service.ts` | Não emitir evento na criação; registrar como exclusão explícita no FDD |
| L-10 | **Vínculo usuário ↔ customer.** "Usuários que representam o cliente" ([09:32] Marcos), mas o schema não tem relação entre `User` e `Customer`; com "qualquer role autenticada" ([09:37]), qualquer operador pode gerenciar webhook de qualquer customer | [09:32] Marcos, [09:37] Sofia; `prisma/schema.prisma` | Não inventar o vínculo; registrar como risco (FDD/PRD) e questão em aberto (RFC), ligado a T-071 |
| L-11 | **Métricas de observabilidade** não foram discutidas (só "a gente observa" sobre rate limiting) | [09:39] Diego | FDD propõe métricas (eventos pendentes, idade do mais antigo, taxa de sucesso, tamanho da DLQ, latência) marcadas como proposta, sem metas numéricas inventadas |
| L-12 | **DELETE com eventos pendentes** — o que acontece com eventos já na outbox de um webhook removido não foi discutido | — | Propor no FDD: eventos pendentes de webhook removido/inativo são descartados no processamento; marcar como proposta |

---

## 17. Checagem de pisos do desafio

| Exigência | Mínimo | Encontrado na transcrição | OK |
|---|---|---|---|
| Requisitos funcionais (PRD) | 8 | Cadastro (T-059), secret gerada na criação (T-059), listar (T-064), editar (T-064), remover (T-064), filtro por status (T-065), rotação de secret (T-042), histórico de entregas (T-067), replay de DLQ (T-036), auditoria do replay (T-069), envio assinado (T-038), retry + DLQ automáticos (T-027/T-034) → **12** | ✅ |
| Alternativas descartadas (RFC) | 2 | Síncrono (T-006), Redis Streams (T-010), trigger (T-016), worker na API (T-020), retry indefinido (T-028), 3 tentativas (T-030), "failed" na outbox (T-035), secret global (T-040), exactly-once (T-050), injetar repository (T-079), renderizar no envio (T-092) → **11** | ✅ |
| Questões em aberto (RFC) | 2 | Escala/multi-worker (T-024), endurecer roles do CRUD (T-071), rate limiting (T-073), + lacunas L-02, L-03, L-10 → **3 da reunião + 3 lacunas** | ✅ |
| Fora de escopo (PRD) | 2 | E-mail (T-072), dashboard (T-074), arquivamento 30 dias (T-013), inbound (T-005), ordering global (T-025) → **5** | ✅ |
| Decisões principais cobertas (ADRs) | 5 de 6 | Outbox, polling/worker, retry/DLQ, HMAC, at-least-once, reuso → **6 de 6** | ✅ |
| Métrica quantitativa (PRD) | 1 | Latência < 10 s (T-004); janela de retry ~15 h (T-031); timeout 10 s (T-080); 64 KB (T-046) | ✅ |

## 18. Validação da lista de ADRs

A lista de 7 ADRs do plano se mantém. O filtro na inserção (T-066) e o padrão `publishWebhookEvent(tx)` (T-078/T-079) têm alternativa e trade-off, mas são detalhes de implementação → ficam no **FDD**, não viram ADR próprio. Se quisermos um 8º ADR, o candidato mais forte é o filtro na inserção.
