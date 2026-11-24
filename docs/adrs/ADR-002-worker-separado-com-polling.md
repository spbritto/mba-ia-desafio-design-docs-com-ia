# ADR-002: Worker em processo separado, consumindo a outbox por polling de 2 segundos

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada na reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos); latência validada por Marcos (PM)
- **Relacionados:** [ADR-001](./ADR-001-outbox-no-mysql.md) · [ADR-003](./ADR-003-retry-backoff-exponencial-e-dlq.md) · [ADR-006](./ADR-006-reuso-dos-padroes-do-projeto.md)

## Contexto

Com a outbox ([ADR-001](./ADR-001-outbox-no-mysql.md)), alguém precisa ler os eventos pendentes e entregá-los. Duas perguntas: **como o consumidor descobre que há evento novo** e **onde ele roda**.

- O requisito de latência é "qualquer coisa abaixo de 10 segundos" ([09:02] Marcos).
- MySQL não tem um mecanismo nativo de notificação para processos externos como o `NOTIFY/LISTEN` do Postgres; trigger "só executa SQL" ([09:09] Diego).
- A API sobe por `src/server.ts` (bootstrap, `listen`, shutdown em `SIGINT`/`SIGTERM`). Se o consumidor rodar dentro dela, "se a API reinicia, perde o worker" ([09:11] Diego).
- O worker precisa do mesmo banco e da mesma stack ([09:11] Bruno, [09:11] Diego); `PrismaClient` é por processo ([09:30] Bruno), e `src/config/database.ts` já expõe `createPrismaClient()`.

## Decisão

1. **Processo separado:** nova entry-point `src/worker.ts` **(novo, a criar)**, nos moldes de `src/server.ts`, executada por um script `npm run worker` **(novo, a criar)** ([09:11] Larissa). "Mesmo banco, mesma stack. Só não pode ser o mesmo processo" ([09:11] Diego).
2. **Polling em loop a cada 2 segundos:** buscar os eventos pendentes mais antigos, em lote pequeno, processar e marcar ([09:09] Diego, [09:08] Diego).
3. **Instância própria de `PrismaClient`**, com a mesma `DATABASE_URL` da API ([09:30] Bruno).
4. **Um único worker** nesta fase; o processamento segue a ordem de `created_at` da outbox ([09:12] Diego).

Registrado como decisão: "Worker em polling, 2s. A latência mínima vai ser 2 segundos no pior caso. Aceitamos" ([09:10] Larissa) — ou seja, o polling acrescenta até ~2 s ao tempo de entrega, dentro dos 10 s aceitos ([09:09] Diego, [09:10] Marcos).

## Alternativas Consideradas

### A. Trigger no banco para reagir à inserção
Proposta para ser "mais reativo" ([09:09] Bruno). **Descartada:** trigger no MySQL não notifica processo externo; para acordar o worker "a gente teria que improvisar algo tipo escrever em arquivo ou bater num endpoint, fica esquisito" ([09:09] Diego). O polling de 2 s já atende o requisito ([09:09] Diego).

### B. Worker dentro do processo da API
Rodar o loop de entrega na mesma instância Node que serve HTTP. **Descartada:** reinícios e deploys da API derrubariam o worker ([09:11] Diego); além disso, a carga de entrega competiria com o atendimento de requisições.

### C. Múltiplos workers em paralelo
Escalar horizontalmente desde o início. **Adiada:** com vários workers "perde a garantia" de ordem; soluções como particionar por `order_id` ou lock pessimista são "problema do futuro, não agora" ([09:12]–[09:13] Diego). Fica como questão em aberto no RFC.

## Consequências

### Positivas
- **Simplicidade:** um loop com consulta indexada, sem infraestrutura nova ([ADR-001](./ADR-001-outbox-no-mysql.md)).
- **Atende o requisito** de < 10 s com folga ([09:09] Diego, [09:10] Marcos).
- **Isolamento operacional:** API e worker reiniciam e escalam de forma independente ([09:11] Diego).
- **Ordem por pedido** garantida enquanto houver um único worker ([09:12] Diego).

### Negativas
- **Latência de até ~2 s** adicionada a toda entrega ([09:10] Larissa).
- **Consultas contínuas ao banco** mesmo sem eventos (custo baixo com índice em status e `created_at`, [09:08] Diego).
- **Limitação conhecida de ordenação:** não há ordering global; a ordem só vale por `order_id` e enquanto for single-worker ([09:13] Larissa). Os clientes não pediram ordering global ([09:14] Marcos).
- **Throughput limitado e ponto único de falha:** um único worker é o gargalo e, se parar, as entregas param (os eventos continuam seguros na outbox).
- **Novo processo para operar:** deploy, supervisão e logs próprios.
- **Eventos presos em "processando"** se o worker cair no meio de um lote: a reunião não tratou da recuperação. **Interpretação aprovada (L-06):** o FDD propõe um timeout de reivindicação que devolve esses eventos para pendente.

### Trade-off aceito
Aceita-se até ~2 s de latência extra, consultas periódicas ao banco e um único worker em troca de **um mecanismo simples, sem dependência nova e isolado da API**. Escala horizontal e ordering mais forte ficam para quando houver demanda ([09:13] Diego).

## Referências

- Transcrição: [09:02] Marcos, [09:08] Diego, [09:09] Diego, [09:09] Bruno, [09:10] Marcos, [09:10] Larissa, [09:11] Diego, [09:11] Larissa, [09:11] Bruno, [09:12] Diego, [09:13] Diego, [09:13] Larissa, [09:14] Marcos, [09:30] Bruno
- Código: `src/server.ts` (modelo de entry-point e graceful shutdown), `src/config/database.ts` (`createPrismaClient`), `package.json` (scripts existentes; `worker` a criar)
