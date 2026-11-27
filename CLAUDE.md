# CLAUDE.md — Desafio Design Docs com IA

Este repositório é uma **entrega puramente documental**. A partir de `TRANSCRICAO.md` (reunião técnica) e do código existente (OMS em Node.js + TypeScript + Prisma/MySQL), produzimos o pacote de design docs da feature **Sistema de Webhooks de Notificação de Pedidos**.

- Enunciado completo: `README.md` (até a Fase 7, quando ele será substituído — o enunciado original fica referenciado lá)
- Plano de execução e status das fases: `notas/plano.md`
- Diário do processo (prompts, erros da IA, correções): `notas/processo.md`

## Regras absolutas

1. **Não alterar** nada em `src/`, `prisma/`, `tests/` nem arquivos de configuração (`package.json`, `tsconfig*.json`, `.eslintrc.json`, `docker-compose.yml`, etc.). O código é só contexto e referência.
2. **Não alterar** `TRANSCRICAO.md`.
3. **Nada sem origem.** Todo requisito, decisão, restrição, número ou trade-off escrito nos documentos precisa ser rastreável a:
   - uma fala da transcrição → citar como `[hh:mm] Nome` (ex.: `[09:17] Diego`), ou
   - um arquivo real do código → citar o caminho (ex.: `src/modules/orders/order.service.ts`).
   Se não houver origem identificável, **não escreva** — ou sinalize explicitamente como lacuna para o usuário decidir.
4. **Antes de citar um timestamp**, confira na transcrição que a fala existe naquele minuto e que o falante está correto.
5. **Antes de citar um arquivo**, confira que ele existe no repositório. Arquivos que a feature vai criar (ex.: `src/worker.ts`, `src/modules/webhooks/*`) devem aparecer sempre marcados como **"(novo, a criar)"** — nunca como se já existissem.
6. **Fluxo git:** todo o trabalho acontece na branch `docs/design-docs-webhooks` (nunca commitar direto na `main`). Um commit ao final de cada fase; ao final da Fase 8, abrir PR da branch para a `main`. Push e PR só quando o usuário pedir.

## Estrutura obrigatória do entregável

```
README.md                 (substituído na Fase 7 pela documentação do processo)
docs/PRD.md
docs/RFC.md
docs/FDD.md
docs/TRACKER.md
docs/adrs/ADR-NNN-titulo-em-kebab-case.md   (entre 5 e 8 ADRs)
```

Atenção: `docs/adrs/README.md` sugere o padrão `0001-titulo.md` — **ignore**; o desafio exige `ADR-NNN-titulo-em-kebab-case.md`.

## Altura de cada documento (não duplicar conteúdo entre eles)

| Documento | Responde | Não deve conter |
|---|---|---|
| PRD | Por que e o quê (produto/negócio) | detalhes de implementação |
| RFC | Como pretendemos resolver + alternativas + questões em aberto (2–4 páginas) | payloads, matriz de erros, schemas — isso é FDD |
| ADR | Por que decidimos exatamente assim (uma decisão por arquivo, formato MADR) | múltiplas decisões misturadas |
| FDD | Como construir em detalhe (fluxos, contratos, erros, integração) | justificativa de negócio extensa |
| TRACKER | De onde veio cada item | — |

## Convenções

- Idioma: português do Brasil.
- Formato: Markdown. Diagramas em Mermaid quando ajudarem (fluxos do FDD).
- Links entre documentos: relativos (ex.: `./adrs/ADR-001-outbox-no-mysql.md`).
- IDs de itens (usados nos documentos e no Tracker):
  - PRD: `PRD-CEN-NN` (cenário), `PRD-MET-NN` (métrica), `PRD-OOS-NN` (fora de escopo), `PRD-FR-NN` (funcional), `PRD-NFR-NN` (não funcional), `PRD-DEC-NN` (decisão/trade-off), `PRD-DEP-NN` (dependência), `PRD-RISK-NN`, `PRD-AC-NN` (aceite)
  - RFC: `RFC-PROP-NN` (pilar da proposta), `RFC-ALT-NN` (alternativa), `RFC-OQ-NN` (questão em aberto), `RFC-RISK-NN`
  - FDD: `FDD-OBJ-NN` (objetivo técnico), `FDD-DADOS-NN` (modelo de dados), `FDD-FLUXO-NN`, `FDD-CONTRATO-NN`, `FDD-ERR-NN`, `FDD-RES-NN` (resiliência), `FDD-OBS-NN`, `FDD-INT-NN` (integração), `FDD-AC-NN`, `FDD-RISK-NN`
  - ADR: `ADR-NNN` (decisão) e `ADR-NNN-ALT-X` (alternativa X do ADR)
- Tracker: tabela `| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |`, Fonte = `TRANSCRICAO` ou `CODIGO`. Metas: ≥ 80% de cobertura, ≥ 70% das linhas `TRANSCRICAO`, ≥ 5 linhas `CODIGO`.

## Armadilhas conhecidas da transcrição

1. **customer_id NÃO vem do JWT.** Marcos sugere isso em `[09:31]`, mas é corrigido: o JWT é do usuário operador (`[09:32] Bruno`) e o customer_id vai no body ou no path (`[09:32] Larissa`).
2. **Diego só entra na call às `[09:05]`.** Nenhuma fala anterior pode ser atribuída a ele.
3. **"Estamos a uma hora de reunião" (`[09:27] Larissa`)** não bate com o horário real — não use como fato.
4. **Prazo:** pedido inicial "até fim do trimestre" (`[09:00] Marcos`); depois "fim de novembro" (`[09:45] Marcos`); estimativa de 3 sprints incluindo revisão de segurança (`[09:46]`–`[09:47] Larissa`), com ≥ 2 dias úteis reservados para a Sofia (`[09:46] Sofia`).
5. **Fora de escopo / adiado — não podem virar requisito:** e-mail de alerta ao cliente (`[09:37] Larissa`), dashboard visual (`[09:40] Larissa`), arquivamento de entregues após ~30 dias (`[09:08] Diego`), webhooks de entrada (`[09:02] Marcos`), ordering global / múltiplos workers (`[09:12]`–`[09:13] Diego`).
6. **Rate limiting de saída** é questão em aberto ("observar e decidir depois", `[09:39] Larissa`), não requisito.
7. **CRUD de configuração aceita qualquer role autenticada "por enquanto"** (`[09:37] Sofia`); só o replay de DLQ exige `ADMIN` (`[09:36]`).
8. **Tracing:** o projeto não tem biblioteca de tracing. No FDD, tracing é *proposta* (ex.: correlação por `event_id` nos logs Pino), não algo existente.
9. **Não inventar métricas.** O "99% dos casos" (`[09:25] Diego`) é sobre at-least-once resolver a maioria dos cenários, não um SLA. Métrica quantitativa com origem: latência < 10 s (`[09:02] Marcos`).
10. **Latência do polling:** Larissa diz "latência mínima vai ser 2 segundos no pior caso" (`[09:10]`) — a ideia é que o polling adiciona até ~2 s; ao redigir, não distorça a fala.

## Pontos de integração no código (verificados)

- `src/modules/orders/order.service.ts` — `changeStatus` (transação `$transaction` onde entra `publishWebhookEvent(tx, …)`)
- `src/modules/orders/order.status.ts` — máquina de estados do pedido
- `src/shared/errors/app-error.ts`, `src/shared/errors/http-errors.ts` — `AppError`, `InvalidStatusTransitionError`, `InsufficientStockError`
- `src/middlewares/auth.middleware.ts` — `authenticate`, `requireRole`
- `src/middlewares/error.middleware.ts` — error middleware centralizado
- `src/middlewares/validate.middleware.ts` — validação com Zod
- `src/shared/logger/index.ts` — logger Pino
- `src/server.ts`, `src/app.ts`, `src/routes/index.ts` — entry-point e registro de rotas
- `src/config/database.ts`, `src/config/env.ts` — Prisma client e variáveis de ambiente
- `prisma/schema.prisma` — modelos (novas tabelas `webhook_*` serão propostas, não criadas)
- `package.json` — scripts (`npm run worker` será proposto, não criado)

## Ao trabalhar em cada fase

- Consulte `notas/plano.md` para saber a fase atual e o que já foi feito.
- Ao terminar uma tarefa relevante, **registre no `notas/processo.md`**: prompt usado (resumido ou literal), o que a IA entregou, o que estava errado e como foi corrigido. Isso alimenta o README final.
- Ao final de cada documento, faça uma autoauditoria: liste toda afirmação sem fonte identificável.
