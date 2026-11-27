# Diário do processo

Registro cronológico da produção dos documentos com IA. Serve de matéria-prima para o `README.md` final (seções "Ferramentas", "Workflow", "Prompts customizados" e "Iterações e ajustes").

## Ferramentas em uso

- **Claude Code (extensão do VS Code)** — leitura do código e da transcrição, planejamento, geração e revisão dos documentos. Inicialmente o plano era usar o Claude Code no terminal; optei por seguir pela extensão do VS Code (ver entrada "Ajuste de ferramenta").

## Modelo de entrada

```
### [AAAA-MM-DD] Fase N — título curto
**Objetivo:** ...
**Prompt (literal ou resumido):**
    ...
**O que a IA entregou:** ...
**Problemas encontrados:** ... (alucinação, item fora de escopo, duplicação entre docs, superficialidade...)
**Correção aplicada:** ... (novo prompt, edição manual, regra adicionada ao CLAUDE.md...)
**Iteração nº:** ...
```

---

### [2026-11-23] Fase 0 — Setup e plano de execução

**Objetivo:** clonar o repositório do fork e montar uma estratégia de execução antes de gerar qualquer documento.

**Prompts:**

```
vou dar inicio a um novo desafio. para tanto quero que voce baixe o codigo do repositorio abaixo e link com essa pasta que esta aberta.
https://github.com/spbritto/mba-ia-desafio-design-docs-com-ia.git
```

```
ok com base no readme que é a descrição do desafio quero montar com voce a estrategia pra gente seguir e assim cumprir o desafio. Vou usar o claude no terminal para fazer os passos necessarios. portanto analisando a descrição gere pra mim um plano de execução para que possamos entregar o desfio
```

**O que a IA entregou:** clone do repositório na pasta local; leitura do enunciado, da transcrição completa e da estrutura do código; plano em 9 fases (0–8) com uma pré-matriz de decisões, alternativas descartadas, itens fora de escopo e questões em aberto (com timestamps), uma proposta de 7 ADRs e uma lista de armadilhas da transcrição.

**Armadilhas identificadas já no planejamento** (viraram regras no `CLAUDE.md`):
- `customer_id` "implícito do JWT" em `[09:31]` é corrigido em `[09:32]`: não vem do JWT.
- Diego só entra às `[09:05]`.
- "Estamos a uma hora de reunião" em `[09:27]` não bate com o horário.
- Prazo aparece de duas formas (fim do trimestre / fim de novembro).
- Arquivos que a feature vai criar (`src/worker.ts`, `src/modules/webhooks/*`) precisam ser marcados como "a criar" para não violar o critério de "nenhum arquivo inexistente citado".
- Não há biblioteca de tracing no projeto → tracing no FDD é proposta.
- `docs/adrs/README.md` sugere nomenclatura `0001-...`, conflitante com a exigida (`ADR-NNN-...`).

**Correção aplicada / decisão de processo:** criar `CLAUDE.md` com as regras do desafio e as armadilhas, para que cada nova sessão do Claude Code já comece com essas restrições; manter `notas/` como área de trabalho (matriz da transcrição, mapa do código, diário).

**Iteração nº:** 1 (planejamento).

### [2026-11-23] Fase 0 — Ajuste de ferramenta

**Prompt:**

```
eu havia sinalizado que usaria o claude no terminal mas resolvi seguir por aqui mesmo. faça essa adptação antes de seguirmos
```

**Decisão:** em vez do Claude Code no terminal, seguir com o Claude Code na extensão do VS Code. O `CLAUDE.md` continua sendo carregado automaticamente; a vantagem é revisar diffs e abrir documentos lado a lado com a transcrição no próprio editor.

**Ajuste aplicado:** seção "Forma de trabalho" do `notas/plano.md` reescrita para o fluxo na extensão (conversa contínua, nova conversa ao trocar de fase, revisão de diffs no editor).

### [2026-11-23] Fase 0 — Fluxo git

**Prompt:**

```
sim vamos fazer os commits ao final de cada fase. quero que voce crie uma branch nova e depois ao final da construção fazemos um PR para atualizar a main
```

**Decisão:** trabalho isolado na branch `docs/design-docs-webhooks`, um commit por fase, PR para a `main` ao final da Fase 8. Regra registrada no `CLAUDE.md` (regra 6) e no `notas/plano.md` (seção "Fluxo git").

### [2026-11-23] Fase 1 — Matriz da transcrição e mapa do código

**Objetivo:** criar a base rastreável para todos os documentos antes de escrever qualquer um deles.

**Prompts:**

```
me atualize aqui o que será feito na fase 1 antes de seguir
```

```
ok pode seguir com a fase 1
```

**Instrução de trabalho dada à IA (via plano + CLAUDE.md):** classificar cada fala relevante em categorias fechadas (DEC, DEC2, RF, RNF, RES, ALT, OOS, OQ, TRD, CTX, ARM), sempre com `[hh:mm] Nome`, rastreando cada decisão até a fala que a fecha; ler de fato os arquivos de integração e registrar caminho + linha + conexão com a feature; separar explicitamente o que é fato do código do que é proposta.

**O que a IA entregou:**
- `notas/matriz-transcricao.md`: 97 itens (`T-001`…`T-097`) em 15 blocos temáticos, 12 lacunas (`L-01`…`L-12`), checagem dos pisos do desafio e validação da lista de ADRs.
- `notas/mapa-codigo.md`: 49 fatos do código (`C-01`…`C-49`) com linha de referência, 7 lacunas do código (`G-01`…`G-07`) e lista de arquivos verificados.

**Achados relevantes que não estavam no plano inicial:**
- Rotas ficam sob o prefixo `/api/v1` (`src/app.ts:67`) → os contratos do FDD devem usar `/api/v1/webhooks...`, não `/webhooks...` como dito na reunião.
- Ambiguidade "5 tentativas" (L-01): a soma dos 5 intervalos (~14h36) só fecha com envio inicial + 5 retentativas.
- Erro de 64 KB (L-02): se lançado na inserção, a regra de rollback da outbox bloquearia a mudança de status do pedido.
- Rotação com grace period em webhook de saída (L-03): o mecanismo de assinatura dupla não foi discutido.
- `NotFoundError` não aceita código custom (`src/shared/errors/http-errors.ts:27-31`) → `WEBHOOK_NOT_FOUND` exige classe própria.
- `redact` do logger não cobre secrets (`src/shared/logger/index.ts:4-11`).
- Schema não liga `User` a `Customer` (L-10) → risco de autorização no CRUD.
- `PENDING` nunca é emitido via `changeStatus` (`src/modules/orders/order.status.ts`) — só na criação, que fica fora.

**Autoauditoria (script):** 107 pares `[hh:mm] Nome` citados nas notas e no `CLAUDE.md` conferidos contra `TRANSCRICAO.md` → 0 inválidos. Caminhos de arquivo citados conferidos no repositório → só 3 inexistentes, todos arquivos a criar pela feature.

**Problema encontrado e correção:** a primeira versão da matriz citava `src/worker.ts` e `src/modules/webhooks/webhook.worker.ts` (T-021, T-054) sem a marcação "(novo, a criar)" exigida pela regra 5 do `CLAUDE.md`. Detectado pelo script de verificação de caminhos; corrigido na própria matriz.

**Iteração nº:** 1 da Fase 1.

**Revisão humana e fechamento:**

```
estou de acordo. pode fazer o commit. no caso assim fechamos a fase 1 ?
```

Todas as 12 recomendações de lacunas (L-01…L-12) aprovadas.

### [2026-11-23] Fase 2 — ADRs

**Prompts:**

```
ok, vamos dar sequencia na fase 2. me atualize o escopo dessa fase antes de continuar
```

```
ok pode seguir
```

(Aprovadas junto: data dos ADRs = 2026-11-23 com a observação "data não registrada na transcrição"; substituir `docs/adrs/README.md` por um índice.)

**Instrução de trabalho:** um ADR por decisão principal, formato MADR adaptado (Status, Contexto, Decisão, Alternativas Consideradas, Consequências com Positivas/Negativas/Trade-off aceito, Referências); timestamp junto de cada afirmação; lacunas aprovadas em bloco "Interpretação"/"Proposta" separado das falas; alternativas "plausíveis, não discutidas" sinalizadas como tal; nada de nível FDD (contratos, schemas).

**O que a IA entregou:** 7 ADRs (`ADR-001` a `ADR-007`) + `docs/adrs/README.md` reescrito como índice com a convenção correta de nomes.

**Problemas encontrados e correções:**
1. **Seção Status como metadado.** A primeira versão trazia `- **Status:** Aceito` como linha de metadado; o critério de aceite pede a *seção* Status. Convertido em `## Status` em todos os ADRs antes da auditoria.
2. **Observação de análise nova (não estava na matriz):** ao escrever o ADR-003, ficou evidente que retentativas podem quebrar a ordem por pedido prometida no ADR-002 (evento posterior do mesmo pedido entregue antes de um que aguarda retry). Registrado no ADR-003 como "observação de análise, não discutida na reunião", para ser tratado no FDD/RFC — sem inventar decisão.
3. **Interpretação adicional:** replay da DLQ preserva o `event_id` original (ADR-005), derivada de "recoloca na outbox" ([09:18] Diego); sinalizada como interpretação.

**Autoauditoria (script):** 7 arquivos com nome no padrão `ADR-NNN-kebab-case`; 5 seções obrigatórias presentes em todos; 71 pares `[hh:mm] Nome` únicos → 0 inválidos; caminhos citados existem, exceto `src/worker.ts` e `src/modules/webhooks/`, ambos marcados "(novo, a criar)" em todas as ocorrências; links relativos entre ADRs → 0 quebrados; e-mail, dashboard e arquivamento aparecem apenas como fora de escopo.

**Iteração nº:** 1 da Fase 2.

**Revisão humana e fechamento:**

```
ok, fiz a revisão do texto das ADRs e estou de acordo. Pode seguir com o commit e fechamos a fase 2.
```

ADRs aprovados sem alterações. Pendência levada para a Fase 3: incluir no RFC, como questão em aberto, a interação entre retentativas e a ordem por pedido (observação do ADR-003).

### [2026-11-27] Fase 3 — RFC

**Prompts:**

```
vamos dar sequencia na proxima fase. faça a anlise do que ja foi feito e me confirme a proxima fase antes de começar
```

```
pode seguir com a fase 3. ao final faça o commit e marque como finalizada no plano
```

(Aprovados junto: autora Larissa — por [09:50] "vou abrir o doc de design" —, status "Em revisão", data 2026-11-27, revisores = demais participantes com o papel de cada um na revisão.)

**Instrução de trabalho:** RFC de 2–4 páginas em nível de arquitetura; proposta resumida por pilar com link para o ADR correspondente (sem repetir o ADR); só alternativas arquiteturais (variações de parâmetro ficam nos ADRs); questões em aberto separadas entre "levantadas na reunião" e "identificadas na análise"; itens adiados num bloco próprio para não serem confundidos com questões em aberto; nada de payload, headers detalhados, matriz de erros ou schema.

**O que a IA entregou:** `docs/RFC.md` com 9 seções (Metadados, TL;DR, Contexto, Proposta com diagrama Mermaid, Alternativas, Questões em aberto, Impacto e riscos, Decisões relacionadas, Próximos passos); 6 alternativas (`RFC-ALT-01..06`), 6 questões em aberto (`RFC-OQ-01..06` — 3 da reunião + 3 da análise, incluindo a pendência da Fase 2), 3 itens adiados, 8 riscos (`RFC-RISK-01..08`), links para os 7 ADRs.

**Problemas encontrados e correções:**
1. **Metadados sem título de seção.** A tabela de metadados estava logo abaixo do título, sem `## Metadados`; o enunciado lista "Metadados" como seção obrigatória. Título adicionado.
2. **Controle de altura:** o diagrama da proposta foi mantido em nível de componentes (sem nomes de tabela propostos, endpoints só o já existente `PATCH /api/v1/orders/:id/status`); nomes de tabelas, contratos e erros foram deixados explicitamente para o FDD. O script de verificação de "conteúdo de FDD" (códigos `WEBHOOK_*`, JSON, headers secundários, schema Prisma) não encontrou ocorrências.

**Autoauditoria (script):** 42 pares `[hh:mm] Nome` → 0 inválidos; caminhos citados existem (exceto `src/modules/webhooks/`, marcado "(novo, a criar)"); links relativos → 0 quebrados; 7 ADRs linkados; ~1.860 palavras incluindo marcação (dentro de 2–4 páginas).

**Iteração nº:** 1 da Fase 3. Usuário autorizou commit direto ao final da fase.

### [2026-11-27] Fase 4 — FDD

**Prompts:**

```
sim me detalhe antes de seguir
```

```
aprovo D-1 a D-6, pode seguir e fazer o commit no final
```

**Decisões de design levadas ao usuário antes de escrever (todas aprovadas):**
- D-1: uma linha de outbox por webhook interessado, cada uma com seu `event_id` (retry/DLQ independentes por endpoint).
- D-2: `DELETE` lógico (`deletedAt`), preservando histórico e DLQ; worker descarta pendentes.
- D-3: schema Zod da URL aplicado no service, para emitir `WEBHOOK_INVALID_URL` em vez do `VALIDATION_ERROR` genérico do `validate.middleware`.
- D-4: `X-Signature: sha256=<hex>`, duas assinaturas separadas por vírgula na janela de rotação; conteúdo assinado = só o corpo.
- D-5: sem endpoint de listagem da DLQ; `deadLetterId` exposto no histórico de entregas.
- D-6: filtro de eventos aceita só os 5 status emitíveis via `changeStatus` (sem `PENDING`).

**Instrução de trabalho:** 13 seções (as 11 obrigatórias + modelo de dados + objetivos); toda escolha não fechada na reunião marcada como **(proposta)** ou **(interpretação)**; números só com origem — onde a reunião não deu número (tamanho do lote, tempo de recuperação de órfãos), o FDD diz "a definir"/"configurável" em vez de inventar; arquivos novos sempre "(novo, a criar)".

**O que a IA entregou:** `docs/FDD.md` (~6.100 palavras): 7 objetivos, modelo Prisma proposto (4 models + enum, 8 decisões de modelagem), 6 fluxos (3 com diagrama de sequência Mermaid), 8 contratos (7 da API + requisição de saída ao cliente, com exemplos JSON, headers e tabelas de status), 11 códigos `WEBHOOK_*` (6 de API + 5 internos do worker), 12 estratégias de resiliência, 13 itens de observabilidade (logs, métricas e tracing como proposta sem dependência nova), 16 pontos de integração com 21 arquivos reais, 18 critérios de aceite e 8 riscos.

**Problemas encontrados e correções:**
1. **Arquivo novo sem marcação** em dois lugares (participante do diagrama Mermaid e script `worker:dev`) — detectado pelo script; corrigido.
2. **CONTRATO-03 (PATCH) sem JSON de response** — só referenciava o formato de outro contrato; o critério pede payload de exemplo de request *e* response. JSON explícito adicionado.
3. **Achados novos durante a escrita** (registrados como risco, sem virar requisito): `X-Timestamp` fica fora da assinatura por decorrência literal de "HMAC sobre o corpo" ([09:22] Sofia) → enfraquece a proteção contra replay (FDD-RISK-03); risco de SSRF por URL apontando para rede interna, não discutido na reunião (FDD-RISK-05); `orderId` sem FK na outbox porque `OrderService.delete` pode apagar pedidos `PENDING`/`CANCELLED` (FDD-DADOS-08); bloqueio de fila (head-of-line) pelo envio sequencial (FDD-RISK-01).

**Autoauditoria (script):** 59 pares `[hh:mm] Nome` → 0 inválidos; links → 0 quebrados; 8 contratos com request e tabela de status; 0 linhas da matriz de erros sem prefixo `WEBHOOK_`; 9.1 Logs, 9.2 Métricas e 9.3 Tracing presentes; 21 caminhos reais na seção de integração; caminhos inexistentes = apenas arquivos novos marcados; termos fora de escopo só em exclusões/riscos.

**Iteração nº:** 1 da Fase 4. Usuário autorizou commit direto ao final da fase.

### [2026-11-27] Fase 5 — PRD

**Prompts:**

```
sim me detalhe a fase 5 antes de seguir
```

```
aprovo P-1 a P-4, pode seguir e fazer o commit no final
```

**Pontos levados ao usuário antes de escrever (todos aprovados):**
- P-1: responsável Marcos (PM), revisão técnica Larissa — registrado como convenção do pacote, não como fala.
- P-2: métricas — só a latência < 10 s tem número na reunião; uso do p95 marcado como proposta; adoção "3 de 3" derivada do pedido dos três clientes; consistência = 0 derivada de [09:40]; redução do polling **sem meta numérica** ("a medir"), para não inventar número sem linha de base.
- P-3: probabilidade/impacto dos riscos como **avaliação da equipe**, com justificativa ancorada em fala sempre que possível.
- P-4: piloto com os três clientes solicitantes na estratégia de testes, marcado como proposta.

**Instrução de trabalho:** linguagem de produto; nada de payload, tabela, header ou código `WEBHOOK_*` (apontar para o FDD); decisões em tabela curta "o que ganha / o que aceita" com link para o ADR, sem repetir a justificativa; os dois prazos citados com suas falas, sem fundir.

**O que a IA entregou:** `docs/PRD.md` (~3.260 palavras) com as 12 seções obrigatórias: 3 personas, 7 cenários (`PRD-CEN`), 4 métricas (`PRD-MET`, 3 com meta numérica), 7 itens fora de escopo (`PRD-OOS`), 14 requisitos funcionais (`PRD-FR`), 13 não funcionais (`PRD-NFR`), 7 decisões/trade-offs (`PRD-DEC`), 6 dependências (`PRD-DEP`), 7 riscos com probabilidade/impacto/justificativa/mitigação (`PRD-RISK`), 11 critérios de aceitação (`PRD-AC`) e estratégia de testes em 7 níveis.

**Problemas encontrados e correções:**
1. **Título da seção 1** ("Resumo e contexto") diferente do nome do enunciado ("Resumo e contexto da feature") — alinhado.
2. **Prefixos de ID novos** (`PRD-CEN`, `PRD-DEC`, `PRD-DEP`) adicionados às convenções do `CLAUDE.md` para manter o Tracker consistente.
3. **Tentação de métrica inventada evitada:** a primeira ideia para o objetivo de "reduzir polling" era uma meta percentual; sem linha de base na reunião, ficou como "a medir" (decisão P-2).

**Autoauditoria (script):** 12 seções; 58 pares `[hh:mm] Nome` → 0 inválidos; links → 0 quebrados; 7/7 riscos com probabilidade e impacto; 0 ocorrências de conteúdo de nível FDD; termos fora de escopo só na seção 5.2 e em riscos.

**Iteração nº:** 1 da Fase 5. Usuário autorizou commit direto ao final da fase. Destaques: L-01 → 1 envio inicial + 5 retentativas; L-02 → limite de 64 KB validado no worker, evento vai direto à DLQ; L-03 → assinatura dupla durante o grace period como proposta + questão em aberto; L-10 → ausência de vínculo User↔Customer vira risco/questão em aberto, sem inventar o vínculo.
