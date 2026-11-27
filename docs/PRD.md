# PRD: Sistema de Webhooks de Notificação de Pedidos

| Campo | Valor |
|---|---|
| **Responsável** | Marcos (Product Manager) |
| **Revisão técnica** | Larissa (Tech Lead) |
| **Revisores** | Bruno (Pedidos) · Diego (Plataforma) · Sofia (Segurança) |
| **Status** | Em revisão |
| **Data** | 2026-11-27 |
| **Origem** | Reunião técnica de quinta-feira, 09:00 (`TRANSCRICAO.md`) |
| **Documentos relacionados** | [RFC](./RFC.md) · [FDD](./FDD.md) · [ADRs](./adrs/README.md) · [Tracker](./TRACKER.md) |

> A atribuição de papéis acima (Marcos como responsável, Larissa como revisora técnica) é uma convenção deste pacote; a reunião não define quem escreve o PRD. Classificações marcadas como **(avaliação da equipe)** ou **(proposta)** não vieram da reunião.

---

## 1. Resumo e contexto da feature

Clientes B2B da plataforma querem ser avisados **automaticamente e em menos de 10 segundos** quando o status dos seus pedidos muda. Esta feature entrega **webhooks de saída**: o cliente cadastra uma URL e escolhe quais status quer acompanhar; a cada mudança relevante, a plataforma envia uma notificação assinada para essa URL, com retentativas automáticas se o cliente estiver fora do ar.

O pedido veio formalmente de três clientes — Atlas Comercial, MaxDistribuição e Nova Cargo ([09:00] Marcos). A solução técnica foi definida em reunião com produto, engenharia e segurança e está detalhada no [RFC](./RFC.md) e no [FDD](./FDD.md).

## 2. Problema e motivação

**Problema.** Hoje os clientes descobrem mudanças de status consultando periodicamente a listagem de pedidos (`GET /orders`), o que deixa a integração "lenta e cara pra eles" ([09:00] Marcos): consomem recursos dos dois lados e ainda assim ficam atrasados em relação ao que acontece com o pedido. O sistema atual não oferece nenhum mecanismo de notificação externa.

**Motivação de negócio.**
- **Retenção:** a Atlas sinalizou que pode migrar para um concorrente se a feature não for entregue até o fim do trimestre ([09:00] Marcos).
- **Prazo:** a Atlas pediu a entrega para o fim de novembro ([09:45] Marcos). A estimativa da engenharia é de três sprints, incluindo revisão de segurança ([09:46]–[09:47] Larissa).
- **Expectativa do cliente:** "qualquer coisa abaixo de 10 segundos já é tempo real"; o importante é não precisar atualizar manualmente ([09:02] Marcos).

## 3. Público-alvo e cenários de uso

### 3.1 Personas

| Persona | Quem é | O que precisa |
|---|---|---|
| **Integrador do cliente B2B** | Desenvolvedor da Atlas, MaxDistribuição, Nova Cargo e futuros clientes | Receber notificações confiáveis, verificar que vieram da plataforma e tratar duplicatas ([09:19] Sofia, [09:24] Diego) |
| **Usuário que representa o cliente** | Usuário da plataforma, autenticado com JWT do sistema, que cadastra e mantém os webhooks pela API ([09:32] Marcos) | Cadastrar, ajustar, remover webhooks e consultar o histórico de entregas |
| **Administrador da plataforma** | Usuário com perfil `ADMIN` | Reprocessar notificações que falharam definitivamente, com registro de quem fez ([09:36] Sofia) |

### 3.2 Cenários de uso

| ID | Cenário | Origem |
|---|---|---|
| PRD-CEN-01 | Um cliente só quer saber quando o pedido é enviado e quando é entregue; cadastra o webhook filtrando `SHIPPED` e `DELIVERED` e não recebe as demais mudanças | [09:33] Marcos |
| PRD-CEN-02 | O sistema do cliente fica duas horas fora do ar em manutenção planejada; ao voltar, recebe as notificações do período sem ação manual | [09:16] Diego |
| PRD-CEN-03 | O cliente vaza a secret em um log da aplicação dele; pede uma nova secret pela API e tem 24 horas para migrar sem interromper a integração | [09:22] Diego, [09:21] Sofia |
| PRD-CEN-04 | O cliente recebe a mesma notificação duas vezes; identifica a duplicata pelo identificador único do evento e a descarta | [09:24]–[09:25] Diego |
| PRD-CEN-05 | Um cliente reclama que não recebeu uma notificação; o suporte consulta o histórico das últimas entregas e vê sucesso/falha, resposta e tempo de cada tentativa | [09:34] Marcos |
| PRD-CEN-06 | Um cliente ficou fora do ar por mais tempo do que a janela de retentativas; após ele voltar, um administrador reprocessa as notificações pendentes | [09:18] Diego, [09:36] Sofia |
| PRD-CEN-07 | Um cliente com vários webhooks cadastrados identifica qual cadastro originou cada notificação | [09:44] Sofia |

## 4. Objetivos e métricas de sucesso

**Objetivos:** (1) eliminar a necessidade de polling para acompanhar status de pedidos; (2) reter os clientes que pediram a feature, em especial a Atlas; (3) fazer isso sem comprometer a confiabilidade da mudança de status nem a segurança dos dados de pedidos.

| ID | Métrica | Meta | Como medir | Origem |
|---|---|---|---|---|
| PRD-MET-01 | **Latência da notificação** — tempo entre a mudança de status e a entrega ao cliente | **< 10 s** no percentil 95 (o uso do p95 é proposta) | Diferença entre o registro do evento e a entrega confirmada (métrica FDD-OBS-10 do [FDD](./FDD.md)) | [09:02] Marcos |
| PRD-MET-02 | **Adoção pelos clientes solicitantes** | **3 de 3** (Atlas, MaxDistribuição, Nova Cargo) com webhook ativo e recebendo notificações | Webhooks ativos por cliente e entregas com sucesso | Derivada de [09:00] Marcos |
| PRD-MET-03 | **Consistência** — mudanças de status sem notificação para webhooks interessados | **0** | Testes de aceitação e conciliação entre histórico de status e eventos registrados | [09:40] Bruno |
| PRD-MET-04 | **Redução do polling** dos clientes integrados no `GET /orders` | **A medir** — sem meta numérica, pois não há linha de base registrada | Volume de chamadas ao `GET /orders` por cliente, antes e depois da integração | Derivada de [09:00] Marcos |

## 5. Escopo

### 5.1 Incluído

- Cadastro e manutenção de webhooks por cliente, via API autenticada, com filtro por status.
- Notificação automática a cada mudança de status relevante, assinada e com identificador único.
- Retentativas automáticas, fila de falhas definitivas e reprocessamento manual por administrador.
- Rotação de secret com período de convivência.
- Histórico das últimas entregas por webhook.
- Documentação de integração no portal do desenvolvedor ([09:26] Marcos, [09:40] Marcos).

### 5.2 Fora de escopo

| ID | Item | Situação | Origem |
|---|---|---|---|
| PRD-OOS-01 | **Aviso por e-mail** ao cliente quando o webhook falha repetidamente | Adiado — "talvez próxima fase, depois que a gente medir o impacto" | [09:37] Larissa, [09:38] Marcos |
| PRD-OOS-02 | **Dashboard visual** para o cliente gerenciar webhooks | Descartado nesta fase — "só endpoints"; painel é projeto separado do time de frontend | [09:40] Larissa |
| PRD-OOS-03 | **Rate limiting** de envio por cliente | Não entra — "observar e decidir depois" | [09:39] Diego, [09:39] Larissa |
| PRD-OOS-04 | **Arquivamento** de notificações entregues (~30 dias) | Fora do escopo desta feature | [09:08] Diego |
| PRD-OOS-05 | **Webhooks de entrada** (cliente enviando para a plataforma) | Não solicitado — "eles querem receber, não mandar" | [09:02] Marcos, [09:03] Sofia |
| PRD-OOS-06 | **Ordem global** das notificações entre pedidos diferentes | Não garantida; clientes "nunca pediram" | [09:13] Larissa, [09:14] Marcos |
| PRD-OOS-07 | Notificação de **criação** de pedido | Fora: a feature cobre mudanças de status (interpretação L-09, detalhada no [FDD](./FDD.md)) | Interpretação |

## 6. Requisitos funcionais

| ID | Requisito | Origem |
|---|---|---|
| PRD-FR-01 | O usuário autenticado deve poder **cadastrar um webhook** para um cliente, informando a URL e a lista de status que deseja receber | [09:31] Marcos |
| PRD-FR-02 | O cliente associado ao webhook deve ser **informado explicitamente** na requisição (não é inferido do login) | [09:32] Larissa |
| PRD-FR-03 | A plataforma deve **gerar a secret** do webhook e devolvê-la ao usuário **na criação** | [09:31] Marcos |
| PRD-FR-04 | O usuário deve poder **listar os webhooks** de um cliente | [09:33] Bruno |
| PRD-FR-05 | O usuário deve poder **editar** um webhook (URL, status de interesse, ativo/inativo) | [09:33] Bruno, [09:21] Bruno |
| PRD-FR-06 | O usuário deve poder **remover** um webhook | [09:33] Bruno |
| PRD-FR-07 | Cada webhook deve receber **apenas os status escolhidos**; mudanças para outros status não geram notificação | [09:33] Marcos, [09:34] Bruno |
| PRD-FR-08 | O usuário deve poder **solicitar uma nova secret**; a anterior continua válida por **24 horas** e depois é invalidada | [09:21] Sofia |
| PRD-FR-09 | A cada mudança de status de interesse, a plataforma deve **enviar automaticamente uma notificação** ao endpoint do cliente, com dados básicos do pedido (identificação, status anterior e novo, cliente, valor total) e sem os itens | [09:43] Diego, [09:44] Bruno |
| PRD-FR-10 | Cada notificação deve trazer **assinatura** verificável, **identificador único do evento** e **identificador do webhook** de origem | [09:20] Sofia, [09:25] Diego, [09:44] Sofia |
| PRD-FR-11 | Se a entrega falhar, a plataforma deve **tentar novamente** automaticamente em intervalos crescentes (1 min, 5 min, 30 min, 2 h, 12 h) | [09:15] Diego, [09:17] Larissa |
| PRD-FR-12 | Esgotadas as retentativas, a notificação deve ir para uma **fila de falhas definitivas**, preservando conteúdo, motivo e data | [09:18] Diego |
| PRD-FR-13 | Um **administrador** deve poder **reprocessar** uma notificação da fila de falhas; a ação fica registrada com o autor | [09:18] Diego, [09:36] Sofia |
| PRD-FR-14 | O usuário deve poder consultar o **histórico das últimas 100 entregas** de um webhook, com sucesso/falha, conteúdo enviado, resposta e tempo de resposta | [09:34] Marcos |

## 7. Requisitos não funcionais

| ID | Categoria | Requisito | Origem |
|---|---|---|---|
| PRD-NFR-01 | Desempenho | Notificação entregue em **menos de 10 segundos** após a mudança de status, em operação normal | [09:02] Marcos, [09:09] Diego |
| PRD-NFR-02 | Confiabilidade | **Nenhuma mudança de status** sem a notificação correspondente para os webhooks interessados | [09:40] Bruno |
| PRD-NFR-03 | Confiabilidade | Lentidão ou indisponibilidade de um cliente **não pode afetar** a mudança de status de pedidos | [09:04] Bruno |
| PRD-NFR-04 | Confiabilidade | Garantia **at-least-once**: o cliente pode receber duplicatas e deve deduplicar pelo identificador do evento | [09:24]–[09:25] Diego, [09:26] Larissa |
| PRD-NFR-05 | Resiliência | Suportar indisponibilidade do cliente por cerca de **15 horas** antes de desistir (1 envio + 5 retentativas, interpretação L-01) | [09:17] Diego, [09:17] Marcos |
| PRD-NFR-06 | Desempenho | Cliente que não responder em **10 segundos** é tratado como falha e entra em retentativa | [09:42] Diego |
| PRD-NFR-07 | Segurança | Autenticidade e integridade por **HMAC-SHA256**, com **secret exclusiva por webhook** | [09:20]–[09:22] Sofia |
| PRD-NFR-08 | Segurança | Apenas URLs **`https`**; cadastro com `http` é recusado | [09:23] Sofia |
| PRD-NFR-09 | Segurança | A secret só é exibida na criação e na rotação; nunca em listagens ou logs | Derivada de [09:22] Diego (vazamento em log) |
| PRD-NFR-10 | Segurança | Reprocessamento da fila de falhas **restrito a `ADMIN`** e **auditado**; o cadastro de webhooks aceita qualquer usuário autenticado nesta fase | [09:36] Sofia, [09:37] Sofia |
| PRD-NFR-11 | Limites | Notificações com mais de **64 KB** não são enviadas (tratadas como erro) | [09:23] Sofia, [09:24] Diego, [09:24] Larissa |
| PRD-NFR-12 | Ordenação | Ordem garantida **por pedido**, enquanto houver um único processo de entrega; sem ordem global | [09:13] Larissa |
| PRD-NFR-13 | Operação | Sem infraestrutura nova: solução sobre o banco e a stack existentes | [09:07] Diego, [09:30] Larissa |

## 8. Decisões e trade-offs principais

Resumo em linguagem de produto; a justificativa completa está em cada ADR.

| ID | Decisão | O que o produto ganha | O que o produto aceita | ADR |
|---|---|---|---|---|
| PRD-DEC-01 | Registrar o evento junto com a mudança de status (outbox) | Nenhuma mudança fica sem notificação | Uma etapa a mais na mudança de status | [ADR-001](./adrs/ADR-001-outbox-no-mysql.md) |
| PRD-DEC-02 | Processo de entrega separado, verificando novos eventos a cada 2 s | Entrega dentro de 10 s sem infraestrutura nova | Até ~2 s de atraso adicional; ordem só por pedido | [ADR-002](./adrs/ADR-002-worker-separado-com-polling.md) |
| PRD-DEC-03 | Retentativas por ~15 h e fila de falhas com reprocessamento manual | Cobre manutenções e quedas comuns do cliente | Quedas mais longas exigem ação de um administrador | [ADR-003](./adrs/ADR-003-retry-backoff-exponencial-e-dlq.md) |
| PRD-DEC-04 | Assinatura com secret por webhook e rotação com 24 h | Vazamento afeta só um webhook; troca sem interrupção | Cliente precisa implementar a verificação | [ADR-004](./adrs/ADR-004-autenticacao-hmac-sha256-por-endpoint.md) |
| PRD-DEC-05 | Entrega "pelo menos uma vez" com identificador único | Nenhuma notificação perdida silenciosamente | Cliente precisa tratar duplicatas | [ADR-005](./adrs/ADR-005-entrega-at-least-once-com-event-id.md) |
| PRD-DEC-06 | Reuso dos padrões e componentes do sistema | Entrega mais rápida e consistente | Limitações atuais herdadas (ex.: autorização só por perfil) | [ADR-006](./adrs/ADR-006-reuso-dos-padroes-do-projeto.md) |
| PRD-DEC-07 | Conteúdo da notificação "congelado" no momento da mudança | Retentativas e reprocessamentos enviam exatamente o que aconteceu | Para o estado atual, o cliente consulta o pedido | [ADR-007](./adrs/ADR-007-snapshot-do-payload-na-insercao.md) |

## 9. Dependências

| ID | Dependência | Responsável | Origem |
|---|---|---|---|
| PRD-DEP-01 | Documentação no portal do desenvolvedor: como integrar via API, verificação de assinatura e semântica "pelo menos uma vez" em destaque | Marcos | [09:26] Marcos, [09:40] Marcos |
| PRD-DEP-02 | Revisão de segurança (assinatura e geração de secret) com pelo menos dois dias úteis antes do deploy | Sofia | [09:46] Sofia, [09:49] Sofia |
| PRD-DEP-03 | Lado do cliente: endpoint `https`, resposta em até 10 s, verificação da assinatura e deduplicação | Clientes integradores | [09:23] Sofia, [09:42] Diego, [09:25] Diego |
| PRD-DEP-04 | Operação de um novo processo de entrega, separado da API | Engenharia (Plataforma) | [09:11] Diego |
| PRD-DEP-05 | Confirmação do prazo com a Atlas | Marcos | [09:47] Marcos |
| PRD-DEP-06 | Sessão de revisão do desenho antes de começar a codar | Larissa, Bruno, Diego | [09:50] Larissa |

## 10. Riscos e mitigação

Probabilidade e impacto são **(avaliação da equipe)**: a reunião não classificou riscos. A justificativa indica a fala em que a avaliação se apoia.

| ID | Risco | Probabilidade | Impacto | Justificativa | Mitigação |
|---|---|---|---|---|---|
| PRD-RISK-01 | **Perda da Atlas** por atraso na entrega | Média | Alto | Pedido para o fim de novembro ([09:45] Marcos) contra estimativa de três sprints ([09:47] Larissa); ameaça de migração ([09:00] Marcos) | Marcos confirma o prazo com a Atlas ([09:47] Marcos); escopo enxuto, com itens adiados (seção 5.2) |
| PRD-RISK-02 | **Vazamento de secret** do cliente | Média | Alto | "Já teve cliente que vazou secret em log" ([09:22] Diego); com a secret, um terceiro forjaria notificações | Secret por webhook, rotação com 24 h ([09:21] Sofia), secret nunca exibida após a criação, revisão de segurança ([09:46] Sofia) |
| PRD-RISK-03 | **Cliente processa duplicatas** (ex.: dispara uma expedição duas vezes) | Média | Médio | At-least-once "joga responsabilidade pro cliente" ([09:25] Sofia) | Destaque no portal do desenvolvedor ([09:26] Marcos); identificador do evento estável inclusive no reprocessamento |
| PRD-RISK-04 | **Permissão ampla no cadastro**: qualquer usuário autenticado gerencia webhooks de qualquer cliente | Média | Alto | Cadastro aberto a qualquer perfil "por enquanto" ([09:37] Sofia); não há vínculo entre usuário e cliente no sistema | Endurecer permissões em fase seguinte ([09:37] Sofia); questão RFC-OQ-03 do [RFC](./RFC.md) |
| PRD-RISK-05 | **Notificações não entregues sem o cliente saber**: falhas definitivas não geram aviso | Baixa | Médio | Janela de ~15 h considerada aceitável ([09:17] Marcos); aviso por e-mail adiado ([09:37] Larissa) | Fila de falhas com reprocessamento por administrador; monitoramento da fila; e-mail na próxima fase |
| PRD-RISK-06 | **Latência acima de 10 s** em picos ou com clientes lentos | Baixa | Médio | Polling de 2 s atende "tranquilo" ([09:09] Diego), mas clientes lentos (até 10 s cada) podem atrasar a fila | Monitorar a latência (PRD-MET-01); evolução de escala em aberto (RFC-OQ-02) |
| PRD-RISK-07 | **Notificações fora de ordem** para o mesmo pedido após retentativas | Baixa | Baixo | Clientes "só querem saber se cada pedido deles mudou" ([09:14] Marcos) | Notificação traz status anterior e novo; tratamento em RFC-OQ-04 |

## 11. Critérios de aceitação

| ID | Critério | Requisitos |
|---|---|---|
| PRD-AC-01 | Um usuário autenticado cadastra um webhook `https` para um cliente, escolhendo os status de interesse, e recebe a secret **uma única vez** | PRD-FR-01, 02, 03 |
| PRD-AC-02 | Um cadastro com URL `http` é recusado com mensagem de erro de validação | PRD-NFR-08 |
| PRD-AC-03 | Ao mudar um pedido para um status de interesse, o endpoint do cliente recebe a notificação em **menos de 10 s**, com assinatura verificável, identificador do evento e do webhook | PRD-FR-09, 10; PRD-NFR-01, 07 |
| PRD-AC-04 | Mudanças para status fora do filtro **não** geram notificação | PRD-FR-07 |
| PRD-AC-05 | Com o endpoint do cliente fora do ar por **2 horas**, as notificações do período chegam após o retorno, sem ação manual | PRD-FR-11; PRD-NFR-05 |
| PRD-AC-06 | Após esgotar as retentativas (~15 h), a notificação aparece na fila de falhas; um **administrador** a reprocessa e a ação fica registrada com o autor; um usuário sem perfil `ADMIN` é impedido | PRD-FR-12, 13; PRD-NFR-10 |
| PRD-AC-07 | Após solicitar nova secret, notificações das próximas **24 h** podem ser verificadas com a secret antiga ou a nova; depois disso, só com a nova | PRD-FR-08 |
| PRD-AC-08 | O histórico mostra até as **100** últimas tentativas de um webhook, com sucesso/falha, conteúdo, resposta e tempo de resposta | PRD-FR-14 |
| PRD-AC-09 | Uma falha do endpoint do cliente **não impede** a mudança de status do pedido, e nenhuma mudança de status ocorre sem a notificação correspondente | PRD-NFR-02, 03; PRD-MET-03 |
| PRD-AC-10 | Editar, desativar e remover um webhook altera o que é enviado a partir desse momento | PRD-FR-05, 06 |
| PRD-AC-11 | A revisão de segurança foi concluída antes do deploy | PRD-DEP-02 |

Os critérios técnicos detalhados (contratos, códigos de erro, fluxos) estão na seção 12 do [FDD](./FDD.md).

## 12. Estratégia de testes e validação

| Nível | O que valida | Como |
|---|---|---|
| **Testes unitários** | Filtro de status, cálculo dos intervalos de retentativa, geração e verificação de assinatura, limite de 64 KB | Vitest, já usado no projeto (`vitest.config.ts`) |
| **Testes de integração da API** | Cadastro, edição, remoção, rotação, histórico, reprocessamento e permissões (`ADMIN` vs. demais) | Vitest + Supertest contra MySQL real, no padrão de `tests/orders.test.ts` |
| **Testes de consistência** | Mudança de status gera notificação; falha no registro do evento desfaz a mudança; transição inválida não gera notificação | Extensão dos testes de pedidos existentes (PRD-MET-03) |
| **Testes ponta a ponta** | Fluxo completo: mudança de status → processo de entrega → endpoint simulado do cliente; timeouts, erros, retentativas e fila de falhas | Endpoint de cliente simulado; previstos na estimativa da Larissa ("integração no order.service e testes ponta a ponta", [09:46] Larissa) |
| **Revisão de segurança** | Assinatura, geração e armazenamento de secret, exposição em logs | Revisão dedicada da Sofia, pelo menos dois dias úteis antes do deploy ([09:46] Sofia) |
| **Piloto com clientes (proposta)** | Integração real com Atlas, MaxDistribuição e Nova Cargo: verificação de assinatura, deduplicação, filtro de status | Liberação inicial para os três clientes solicitantes, coordenada por Marcos, que já mantém contato com eles ([09:47] Marcos, [09:49] Marcos) |
| **Validação pós-lançamento** | Metas de latência, adoção e consistência (seção 4) e linha de base do polling | Métricas propostas no FDD (seção 9.2) e volume de chamadas ao `GET /orders` |
