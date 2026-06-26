# CLAUDE.md — chatwoot-opensf

## O que é isto
Fork do Chatwoot (Rails + Vue/Vite + Postgres + Redis/Sidekiq + ActionCable)
para a Open Soluções Financeiras. Vira o CRM de conversas do time de vendas de
crédito consignado. Operação multi-filial, múltiplos WhatsApps oficiais.

## REGRA DE OURO: superfície mínima de contato com o upstream
Este é um fork que precisa continuar rebaseável contra o upstream para sempre.
Toda mudança deve minimizar contato com arquivos do core.
- NUNCA edite componentes/arquivos existentes do core sem necessidade absoluta.
- Funcionalidade nova = arquivos novos, models aditivos, migrations aditivas.
  Nunca altere tabelas do core (ex: `conversations`, `users`); crie tabelas novas.
- Toda alteração inevitável no core deve ser isolada e marcada com `OPENSF:`
  em comentário, para ser localizável no merge.
- `upstream` fica como remote. Trabalhamos na branch `opensf`. Rebase periódico.

## Personalização visual
- SÓ via override de CSS variables. O Chatwoot expõe CSS vars para customização
  em runtime — use isso. Não edite SCSS de componente do core.
- Centralize os overrides num arquivo próprio (ex: `app/javascript/.../opensf-theme`).
- Paleta Open: primária `#004880`. (Restante dos tokens definimos ao longo do dev.)

## Arquitetura em 3 superfícies (onde cada coisa mora)
1. Configuração, zero código: visibilidade por filial, papéis (supervisor/usuário/
   gerente), leads sem dono. Resolvido por Custom Roles (EE) + membership de inbox.
   NÃO implementar isso em código.
2. Fork mínimo (futuro, fora do MVP atual): kanban + valor de negociação.
3. Por fora do core (n8n + Postgres próprio + Dashboard Apps): CPF→propostas,
   disparo de template em massa, tracking de UTM/ctwa_clid, atribuição.

## Fora do escopo agora
- Kanban / pipeline de deals. Não construir ainda.