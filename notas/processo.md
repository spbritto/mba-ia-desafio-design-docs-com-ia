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
