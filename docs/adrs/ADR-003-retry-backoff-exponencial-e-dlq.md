# ADR-003: Retry com backoff exponencial (1m/5m/30m/2h/12h) e Dead Letter Queue em tabela separada

## Status

**Aceito**

- **Data do registro:** 2026-11-23 — decisão tomada na reunião técnica de quinta-feira, 09:00 (data não registrada na transcrição)
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos); janela validada por Marcos (PM); controle de acesso por Sofia (Segurança)
- **Relacionados:** [ADR-001](./ADR-001-outbox-no-mysql.md) · [ADR-002](./ADR-002-worker-separado-com-polling.md) · [ADR-005](./ADR-005-entrega-at-least-once-com-event-id.md)

## Contexto

O endpoint do cliente pode estar fora do ar, lento ou com erro no momento do envio ([09:14] Larissa). É preciso decidir **quantas vezes e em que intervalos tentar de novo**, e **o que fazer quando desistir**.

- Clientes têm indisponibilidades reais longas: "já tinha cliente nosso com indisponibilidade de duas horas em manutenção planejada" ([09:16] Diego).
- Tentar para sempre deixa eventos "pendurados pra sempre se o cliente sumiu" ([09:15] Diego).
- Eventos que esgotam as tentativas precisam ficar disponíveis para análise e reprocessamento ([09:18] Diego).

## Decisão

1. **Backoff exponencial** com teto de tentativas; esgotado o teto, a falha é considerada permanente e o evento vai para a DLQ ([09:15] Diego).
2. **5 tentativas, com intervalos de 1 min, 5 min, 30 min, 2 h e 12 h** — "Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h" ([09:17] Larissa, proposta de [09:17] Diego).
3. **DLQ em tabela separada** `webhook_dead_letter`, com payload, motivo da falha e timestamp ([09:18] Diego).
4. **Reprocessamento manual** por endpoint administrativo `POST /admin/webhooks/dead-letter/:id/replay`, que recoloca o evento na outbox como pendente ([09:18] Diego), restrito à role `ADMIN` e com registro de quem executou ([09:36] Sofia, [09:36] Larissa).

> **Interpretação aprovada (L-01) — contagem de tentativas.** A reunião fala em "5 tentativas" e cinco intervalos, com "quase 15 horas entre primeira falha e última tentativa" ([09:17] Diego). A soma dos intervalos (1 + 5 + 30 + 120 + 720 min) é **14 h 36 min**, o que só fecha se houver **um envio inicial seguido de 5 retentativas** (6 envios no total). Esta é a leitura adotada:
>
> | Envio | Momento (a partir da 1ª falha) |
> |---|---|
> | Inicial | t0 (falha) |
> | Retentativa 1 | t0 + 1 min |
> | Retentativa 2 | t0 + 6 min |
> | Retentativa 3 | t0 + 36 min |
> | Retentativa 4 | t0 + 2 h 36 min |
> | Retentativa 5 | t0 + 14 h 36 min → se falhar, vai para a DLQ |

> **Interpretação aprovada (L-07) — status "falhou" na outbox.** Diego lista "falhou" entre os status da outbox ([09:08] Diego) e depois decide pela DLQ em tabela separada ([09:18] Diego). Leitura adotada: na outbox, "falhou" representa **falha transitória aguardando a próxima tentativa**; a falha **permanente** sai da outbox e passa a existir em `webhook_dead_letter`.

## Alternativas Consideradas

### A. Retry indefinido com backoff
"Algumas pessoas defendem retry indefinido". **Descartada:** sem teto, o evento fica pendurado para sempre se o cliente sumiu ([09:15] Diego).

### B. 3 tentativas ("mais agressivo")
Proposta de Bruno ([09:16] Bruno). **Descartada:** "3 é pouco" — uma indisponibilidade pela manhã esgotaria as três tentativas em ~30 minutos, e já houve cliente com duas horas de manutenção planejada ([09:16] Diego).

### C. Marcar o evento como "failed" na própria outbox (sem tabela de DLQ)
Opção levantada por Larissa ([09:17] Larissa). **Preterida:** a tabela separada deixa "mais limpa a leitura da outbox principal" e serve como evidência para debug e reprocessamento ([09:18] Diego).

## Consequências

### Positivas
- **Cobre ~15 h de indisponibilidade** do cliente, janela considerada aceitável pelo produto: "se um cliente meu cair por 15 horas, ele já tá com problema sério dele" ([09:17] Marcos).
- **Esforço limitado:** nenhum evento consome tentativas para sempre ([09:15] Diego).
- **Outbox enxuta** e DLQ como trilha de evidência para suporte ([09:18] Diego).
- **Recuperação controlada:** replay manual auditado e restrito a `ADMIN` ([09:36] Sofia).

### Negativas
- **Cliente fora por mais de ~15 h perde a entrega automática** e depende de replay manual por um administrador.
- **Nenhum aviso proativo ao cliente** quando seus eventos vão para a DLQ: notificação por e-mail ficou **fora do escopo** desta fase ([09:37] Larissa).
- **Operação manual** da DLQ (monitorar, decidir e executar o replay).
- **Interação com a ordem por pedido (observação de análise, não discutida na reunião):** enquanto um evento de um pedido aguarda retentativa, um evento posterior do mesmo pedido pode ser entregue antes. A garantia de ordem do [ADR-002](./ADR-002-worker-separado-com-polling.md) precisa ser qualificada no FDD/RFC.

### Trade-off aceito
Prefere-se um **teto finito com janela longa (~15 h)** e reprocessamento manual a **tentar indefinidamente** (eventos eternos) ou **desistir cedo** (perda de eventos em manutenções comuns). O custo é operacional: a DLQ precisa ser acompanhada.

## Referências

- Transcrição: [09:08] Diego, [09:14] Larissa, [09:15] Diego, [09:16] Bruno, [09:16] Diego, [09:17] Diego, [09:17] Marcos, [09:17] Larissa, [09:18] Diego, [09:18] Bruno, [09:35] Diego, [09:36] Sofia, [09:36] Larissa, [09:37] Larissa
- Código: `src/middlewares/auth.middleware.ts` (`requireRole`, usado para restringir o replay)
