#!/usr/bin/env bash
# Auditoria final do pacote contra os criterios de aceite do enunciado.
# Uso: bash auditoria-final.sh <raiz-do-repo>
cd "$1" || exit 1
ok(){ echo "  [OK]   $*"; }
ko(){ echo "  [FALHA] $*"; FAIL=$((FAIL+1)); }
chk(){ if eval "$2"; then ok "$1"; else ko "$1"; fi; }
FAIL=0
ALLDOCS="README.md docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/*.md"

echo "== CONSISTENCIA GERAL =="
changed=$(git diff --name-only main -- src prisma tests TRANSCRICAO.md package.json package-lock.json 'tsconfig*.json' .eslintrc.json docker-compose.yml vitest.config.ts .env.example .prettierrc .prettierignore .gitignore)
chk "codigo, configs e transcricao inalterados em relacao a main" '[ -z "$changed" ]'
[ -n "$changed" ] && echo "$changed"
bad=$(for p in $(grep -ohE '\[[0-9]{2}:[0-9]{2}\] (Larissa|Marcos|Bruno|Diego|Sofia)' $ALLDOCS | sort -u | tr ' ' '_'); do l="${p/_/ }"; grep -qF "$l:" TRANSCRICAO.md || echo "$l"; done)
n=$(grep -ohE '\[[0-9]{2}:[0-9]{2}\] (Larissa|Marcos|Bruno|Diego|Sofia)' $ALLDOCS | sort -u | wc -l)
chk "todos os $n pares [hh:mm] Nome citados existem na transcricao" '[ -z "$bad" ]'; [ -n "$bad" ] && echo "$bad"
missing=""
for f in $ALLDOCS; do
  while IFS= read -r line; do
    for p in $(echo "$line" | grep -oE '`(src|prisma|tests)/[A-Za-z0-9_./-]+`' | tr -d '`'); do
      [ -e "$p" ] && continue
      echo "$line" | grep -qiE 'novo, a criar|novos, a criar|\(a criar\)|arquivos novos|, novo\)' || missing="$missing\n    $f: $p"
    done
  done < "$f"
done
chk "nenhum arquivo de codigo inexistente citado sem a marca (novo, a criar)" '[ -z "$missing" ]'; [ -n "$missing" ] && echo -e "$missing"
broken=""
for f in $ALLDOCS notas/*.md CLAUDE.md; do d=$(dirname "$f")
  for l in $(grep -oE '\]\((\./|\.\./)?[A-Za-z0-9_./-]+(\.md|/)?\)' "$f" | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^https?:'); do
    [ -e "$d/$l" ] || broken="$broken\n    $f -> $l"; done; done
chk "links relativos resolvem" '[ -z "$broken" ]'; [ -n "$broken" ] && echo -e "$broken"

echo "== PRD =="
f=docs/PRD.md
chk "arquivo existe" '[ -f $f ]'
for s in "Resumo e contexto" "Problema e motivação" "Público-alvo e cenários" "Objetivos e métricas" "Escopo" "Requisitos funcionais" "Requisitos não funcionais" "Decisões e trade-offs" "Dependências" "Riscos e mitigação" "Critérios de aceitação" "Estratégia de testes"; do
  chk "secao: $s" "grep -qE '^## [0-9]+\. $s' $f"; done
chk ">= 8 requisitos funcionais ($(grep -cE '^\| PRD-FR-' $f))" '[ $(grep -cE "^\| PRD-FR-" $f) -ge 8 ]'
chk ">= 1 metrica com meta quantitativa" 'grep -E "^\| PRD-MET-" $f | grep -qE "< 10 s|3 de 3"'
chk ">= 2 itens fora de escopo com origem na reuniao ($(grep -E '^\| PRD-OOS-' $f | grep -c '\[09'))" '[ $(grep -E "^\| PRD-OOS-" $f | grep -c "\[09") -ge 2 ]'
chk ">= 2 riscos com probabilidade, impacto e mitigacao" '[ $(grep -E "^\| PRD-RISK-" $f | grep -cE "\| (Baixa|Média|Alta) \| (Baixo|Médio|Alto) \|") -ge 2 ]'

echo "== RFC =="
f=docs/RFC.md
chk "arquivo existe" '[ -f $f ]'
for s in "Metadados" "Resumo" "Contexto e problema" "Proposta técnica" "Alternativas consideradas" "Questões em aberto" "Impacto e riscos" "Decisões relacionadas"; do
  chk "secao: $s" "grep -qE '^## ([0-9]+\. )?$s' $f"; done
chk "metadados com autor, status, data e revisores" 'grep -q "Autora" $f && grep -q "\*\*Status\*\*" $f && grep -q "\*\*Data\*\*" $f && grep -q "Revisores" $f'
chk ">= 2 alternativas com trade-off e origem ($(grep -E '^\| RFC-ALT-' $f | grep -c '\[09'))" '[ $(grep -E "^\| RFC-ALT-" $f | grep -c "\[09") -ge 2 ]'
chk ">= 2 questoes em aberto da reuniao ($(sed -n '/### 5.1/,/### 5.2/p' $f | grep -cE '^\| RFC-OQ-'))" '[ $(sed -n "/### 5.1/,/### 5.2/p" $f | grep -cE "^\| RFC-OQ-") -ge 2 ]'
chk ">= 2 ADRs linkados ($(grep -oE '\(\./adrs/ADR-[0-9]{3}[^)]*\.md\)' $f | sort -u | wc -l))" '[ $(grep -oE "\(\./adrs/ADR-[0-9]{3}[^)]*\.md\)" $f | sort -u | wc -l) -ge 2 ]'
w=$(sed '/```mermaid/,/```/d' $f | wc -w); chk "tamanho compativel com 2-4 paginas (~$w palavras)" '[ $w -ge 800 -a $w -le 2200 ]'
chk "sem detalhe de FDD (codigos WEBHOOK_, JSON, schema)" '! grep -qE "WEBHOOK_[A-Z]|\{ *\"|@db\." $f'

echo "== FDD =="
f=docs/FDD.md
chk "arquivo existe" '[ -f $f ]'
for s in "Contexto e motivação técnica" "Objetivos técnicos" "Escopo e exclusões" "Fluxos detalhados" "Contratos públicos" "Matriz de erros" "Estratégias de resiliência" "Observabilidade" "Dependências e compatibilidade" "Integração com o sistema existente" "Critérios de aceite técnicos" "Riscos e mitigação"; do
  chk "secao: $s" "grep -qE '^## [0-9]+\. $s' $f"; done
chk "fluxos cobrem outbox, worker, retry e DLQ" 'grep -q "FDD-FLUXO-01 — Criação do evento na outbox" $f && grep -q "FDD-FLUXO-02 — Processamento pelo worker" $f && grep -q "FDD-FLUXO-03 — Retry" $f && grep -q "FDD-FLUXO-04 — Movimentação para a DLQ" $f'
nc=0; for i in 01 02 03 04 05 06 07; do s=$(sed -n "/FDD-CONTRATO-$i —/,/^### /p" $f); echo "$s" | grep -qE '^(POST|GET|PATCH|DELETE) /api' && echo "$s" | grep -qE '^Response `[0-9]{3}' && echo "$s" | grep -qE '^\| [0-9]{3}' && nc=$((nc+1)); done
chk ">= 4 endpoints HTTP com request, response e status codes ($nc)" '[ $nc -ge 4 ]'
chk "matriz de erros: todas as linhas com prefixo WEBHOOK_" '[ $(sed -n "/^## 7\./,/^## 8\./p" $f | grep -E "^\| FDD-ERR-" | grep -vc "WEBHOOK_") -eq 0 ]'
ni=$(sed -n '/^## 11\./,/^## 12\./p' $f | grep -oE '`(src|prisma|tests)/[A-Za-z0-9_./-]+\.(ts|prisma)`|`package\.json`' | tr -d '`' | sort -u | while read -r p; do [ -e "$p" ] && echo "$p"; done | wc -l)
chk "integracao referencia >= 4 caminhos reais ($ni)" '[ $ni -ge 4 ]'
chk "observabilidade cita metricas, logs e tracing" 'grep -q "### 9.1 Logs" $f && grep -q "### 9.2 Métricas" $f && grep -q "### 9.3 Tracing" $f'

echo "== ADRs =="
na=$(ls docs/adrs/ADR-*.md | wc -l)
chk "entre 5 e 8 ADRs ($na)" '[ $na -ge 5 -a $na -le 8 ]'
chk "nomes no formato ADR-NNN-titulo-em-kebab-case.md" '! ls docs/adrs/ADR-*.md | grep -vqE "^docs/adrs/ADR-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$"'
miss=""; for a in docs/adrs/ADR-*.md; do for s in "## Status" "## Contexto" "## Decisão" "## Alternativas Consideradas" "## Consequências"; do grep -qxF "$s" "$a" || miss="$miss $a:$s"; done; done
chk "cada ADR tem Status, Contexto, Decisao, Alternativas, Consequencias" '[ -z "$miss" ]'; [ -n "$miss" ] && echo "$miss"
chk "cada ADR tem >= 1 alternativa e consequencias positivas/negativas" '[ $(grep -lE "^### A\. " docs/adrs/ADR-*.md | wc -l) -eq $na -a $(grep -l "### Positivas" docs/adrs/ADR-*.md | wc -l) -eq $na -a $(grep -l "### Negativas" docs/adrs/ADR-*.md | wc -l) -eq $na ]'
cov=0
ls docs/adrs | grep -q outbox && cov=$((cov+1)); ls docs/adrs | grep -q retry && cov=$((cov+1)); ls docs/adrs | grep -q hmac && cov=$((cov+1))
ls docs/adrs | grep -q at-least-once && cov=$((cov+1)); ls docs/adrs | grep -q worker-separado && cov=$((cov+1)); ls docs/adrs | grep -q reuso && cov=$((cov+1))
chk "cobre >= 5 das 6 decisoes principais ($cov/6)" '[ $cov -ge 5 ]'
nadr=$(for a in docs/adrs/ADR-*.md; do grep -oE "(src|prisma)/[A-Za-z0-9_./-]+.(ts|prisma)" "$a" | sort -u | while read -r p; do [ -e "$p" ] && echo "$a"; done; done | sort -u | wc -l)
chk ">= 1 ADR referencia arquivos reais do codigo ($nadr ADRs)" "[ $nadr -ge 1 ]"

echo "== TRACKER =="
f=docs/TRACKER.md
chk "cabecalho no formato obrigatorio" 'grep -qxF "| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |" $f'
sed -n '/^## Tabela de rastreabilidade/,/^## Anexo/p' $f | grep -E '^\| (PRD|RFC|FDD|ADR)-' > /tmp/tr_rows.txt
tot=$(wc -l < /tmp/tr_rows.txt)
tr=$(awk -F'|' '$6 ~ /TRANSCRICAO/ && $7 ~ /\[[0-9][0-9]:[0-9][0-9]\] [A-Z][a-z]+/' /tmp/tr_rows.txt | wc -l)
co=$(awk -F'|' '$6 ~ /CODIGO/' /tmp/tr_rows.txt | wc -l)
ids_doc=$(grep -ohE '(PRD|RFC|FDD)-[A-Z]+-[0-9]{2}|ADR-[0-9]{3}(-ALT-[A-Z])?' docs/PRD.md docs/RFC.md docs/FDD.md docs/adrs/ADR-*.md | sort -u | wc -l)
pct_tr=$(awk "BEGIN{printf \"%.1f\", $tr*100/$tot}"); pct_cov=$(awk "BEGIN{printf \"%.1f\", $tot*100/$ids_doc}")
chk "cobertura >= 80% ($tot/$ids_doc = $pct_cov%)" "awk 'BEGIN{exit !($pct_cov >= 80)}'"
chk ">= 70% das linhas TRANSCRICAO com [hh:mm] Nome ($tr/$tot = $pct_tr%)" "awk 'BEGIN{exit !($pct_tr >= 70)}'"
cobad=$(awk -F'|' '$6 ~ /CODIGO/ {print $7}' /tmp/tr_rows.txt | tr ';' '\n' | tr -d ' `' | while read -r p; do [ -n "$p" ] && [ ! -e "$p" ] && echo "$p"; done)
chk ">= 5 linhas CODIGO com caminho real ($co)" '[ $co -ge 5 -a -z "$cobad" ]'

echo "== README =="
f=README.md
for s in "Sobre o desafio" "Ferramentas de IA utilizadas" "Workflow adotado" "Prompts customizados" "Iterações e ajustes" "Como navegar a entrega"; do chk "secao: $s" "grep -qxF '## $s' $f"; done
chk ">= 1 ferramenta de IA listada" 'grep -q "Claude Code" $f'
np=$(sed -n '/^## Prompts customizados/,/^## Iterações/p' $f | grep -c '^```$')
chk ">= 2 prompts em blocos de codigo ($(( np )) blocos fechados)" '[ $np -ge 2 ]'
ni=$(sed -n '/^## Iterações e ajustes/,/^## Como navegar/p' $f | grep -cE '^\| [0-9]+ \|')
chk ">= 2 iteracoes concretas descritas ($ni)" '[ $ni -ge 2 ]'

echo; echo "TOTAL DE FALHAS: $FAIL"
