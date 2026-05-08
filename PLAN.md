# PLAN.md — Ledge

Plano de desenvolvimento do MVP, dividido em issues pequenas e sequenciais.

A **primeira tarefa do agente** é criar o repositório `ledge-app` no GitHub,
subir os arquivos `CLAUDE.md` e `PLAN.md` na raiz e cadastrar todas as issues
abaixo com suas labels e descrições.

As issues do **Grupo B** dependem de MacOS + Xcode e serão executadas pelo
desenvolvedor após retornar de viagem.

---

## Grupo A — Agente executa na VPS

---

### Issue #1 — Criar repositório e cadastrar issues

**Tipo:** `chore`
**Label:** `infra`

**Descrição:**
Criar o repositório `ledge-app` no GitHub como privado, inicializar com a
estrutura de pastas do monorepo, subir os arquivos `CLAUDE.md` e `PLAN.md`
e cadastrar todas as issues seguintes com labels e ordem correta.

**Tarefas:**
- Criar repositório privado `ledge-app` via `gh repo create`
- Criar estrutura de pastas: `backend/`, `mobile/`, `shared/`, `docs/`
- Adicionar `CLAUDE.md` e `PLAN.md` na raiz
- Adicionar `.gitignore` adequado para Node.js e KMP
- Criar labels no repositório: `backend`, `mobile`, `infra`, `docs`, `chore`
- Cadastrar todas as issues de #2 em diante com título, descrição e label

**Critérios de aceite:**
- `gh repo view ledge-app` retorna o repositório criado
- Estrutura de pastas existe no commit inicial
- `CLAUDE.md` e `PLAN.md` estão na raiz
- Todas as issues estão cadastradas e visíveis no repositório

---

### Issue #2 — Configurar ambiente Docker na VPS

**Tipo:** `chore`
**Label:** `infra`

**Descrição:**
Garantir que Docker e Docker Compose estão instalados e configurados na VPS.
Configurar usuário para rodar Docker sem sudo.

**Tarefas:**
- Verificar se Docker está instalado (`docker --version`)
- Se não estiver, instalar Docker Engine no Ubuntu
- Verificar se Docker Compose está instalado (`docker compose version`)
- Se não estiver, instalar
- Adicionar usuário atual ao grupo `docker` para rodar sem sudo
- Verificar se a configuração persiste após reconectar

**Critérios de aceite:**
- `docker --version` retorna versão sem erro
- `docker compose version` retorna versão sem erro
- `docker run hello-world` executa com sucesso sem sudo
- `docker ps` funciona sem sudo

---

### Issue #3 — Configurar Docker Compose do backend

**Tipo:** `chore`
**Label:** `infra`

**Descrição:**
Criar o `docker-compose.yml` que orquestra o backend Node.js e o PostgreSQL
na VPS. Configurar variáveis de ambiente e volumes para persistência dos dados.

**Tarefas:**
- Criar `backend/docker-compose.yml` com serviços `api` e `postgres`
- Configurar volume para persistência dos dados do PostgreSQL
- Configurar variáveis de ambiente via `.env` (com `.env.example` no repo)
- Garantir que o PostgreSQL inicia antes da API com healthcheck
- Configurar restart policy `unless-stopped` em ambos os serviços
- Criar script de backup do PostgreSQL via `pg_dump` agendado com cron
  (diário, mantendo os últimos 7 dias)

**Critérios de aceite:**
- `docker compose up -d` sobe os dois serviços sem erro
- `docker compose ps` mostra ambos como `running`
- PostgreSQL aceita conexão (`docker compose exec postgres psql -U ledge -c '\l'`)
- Arquivo `.env.example` existe no repo com todas as variáveis necessárias
- Script de backup existe e roda manualmente sem erro

---

### Issue #4 — Inicializar projeto backend

**Tipo:** `feat`
**Label:** `backend`

**Descrição:**
Inicializar o projeto Node.js + TypeScript com Express, Prisma e Jest.
Configurar estrutura de pastas, scripts de build e lint.

**Tarefas:**
- Inicializar `package.json` em `backend/`
- Instalar dependências: `express`, `typescript`, `prisma`, `@prisma/client`,
  `jsonwebtoken`, `bcrypt`, `zod`
- Instalar dependências de dev: `jest`, `ts-jest`, `@types/*`, `eslint`,
  `prettier`, `ts-node-dev`
- Configurar `tsconfig.json`
- Configurar ESLint + Prettier
- Configurar Jest com `ts-jest`
- Criar estrutura de pastas:
  ```
  backend/
  ├── src/
  │   ├── routes/
  │   ├── controllers/
  │   ├── services/
  │   ├── middlewares/
  │   └── index.ts
  ├── prisma/
  │   └── schema.prisma
  └── tests/
  ```
- Criar `GET /health` que retorna `{ status: "ok" }`
- Configurar script `npm run dev` com hot reload

**Critérios de aceite:**
- `npm run build` compila sem erros
- `npm run lint` passa sem erros
- `npm test` roda sem erros
- `npm run dev` sobe o servidor
- `curl http://localhost:3000/health` retorna `{ "status": "ok" }`

---

### Issue #5 — Modelagem do banco de dados

**Tipo:** `chore`
**Label:** `backend`

**Descrição:**
Criar o schema Prisma com todos os modelos do MVP. Rodar a primeira migration.

**Modelos:**

`User`
- id, email, passwordHash, createdAt, updatedAt

`BillingCycle`
- id, userId, startDate, endDate, cutDay, createdAt

`Transaction`
- id, billingCycleId, userId, description, amount (Int — valores em centavos),
  date, type (enum: ESSENTIAL / NON_ESSENTIAL / INCOME),
  paymentMethod (enum: CREDIT_CARD / DEBIT_CARD / PIX / CASH),
  installmentIndex (Int?), installmentTotal (Int?), createdAt, updatedAt

**Tarefas:**
- Escrever schema Prisma com os três modelos e seus relacionamentos
- Rodar `prisma migrate dev --name init`
- Gerar Prisma Client
- Escrever seed básico com um usuário e alguns lançamentos de exemplo

**Critérios de aceite:**
- `prisma migrate dev` roda sem erros
- As três tabelas existem no banco (`\dt` no psql)
- Seed popula o banco sem erros
- Relacionamentos estão corretos (Transaction → BillingCycle → User)

---

### Issue #6 — Autenticação: registro e login

**Tipo:** `feat`
**Label:** `backend`

**Descrição:**
Implementar endpoints de registro e login com JWT. Criar middleware de
autenticação para proteger rotas.

**Endpoints:**
- `POST /auth/register` — cria usuário com email + senha
- `POST /auth/login` — retorna JWT
- Middleware `authenticate` — valida JWT e injeta `userId` no request

**Tarefas:**
- Implementar `POST /auth/register` com validação via Zod
- Hash da senha com bcrypt (salt rounds: 12)
- Implementar `POST /auth/login` retornando JWT com expiração de 7 dias
- Criar middleware `authenticate`
- Escrever testes unitários para o service de auth
- Escrever testes de integração para os endpoints

**Critérios de aceite:**
- `POST /auth/register` com email e senha válidos retorna `201`
- `POST /auth/register` com email duplicado retorna `409`
- `POST /auth/login` com credenciais corretas retorna JWT
- `POST /auth/login` com credenciais erradas retorna `401`
- Rota protegida sem token retorna `401`
- `npm test` passa com todos os testes de auth

---

### Issue #7 — CRUD de ciclos de fatura

**Tipo:** `feat`
**Label:** `backend`

**Descrição:**
Implementar endpoints para gerenciar ciclos de fatura.

**Endpoints:**
- `GET /cycles` — lista todos os ciclos do usuário
- `GET /cycles/current` — retorna o ciclo ativo no momento
- `GET /cycles/:id` — retorna um ciclo com seus lançamentos
- `POST /cycles` — cria um ciclo manualmente

**Tarefas:**
- Implementar os quatro endpoints com autenticação obrigatória
- Validação de dados via Zod
- Escrever testes unitários e de integração

**Critérios de aceite:**
- Todos os endpoints retornam `401` sem token
- `GET /cycles` retorna apenas ciclos do usuário autenticado
- `GET /cycles/current` retorna o ciclo correto baseado na data atual e no `cutDay`
- `npm test` passa com todos os testes de ciclos

---

### Issue #8 — CRUD de lançamentos

**Tipo:** `feat`
**Label:** `backend`

**Descrição:**
Implementar endpoints para gerenciar lançamentos dentro de um ciclo.
Ao criar um lançamento parcelado, o sistema cria automaticamente os
lançamentos nos ciclos futuros.

**Endpoints:**
- `GET /cycles/:id/transactions` — lista lançamentos do ciclo
- `POST /cycles/:id/transactions` — cria lançamento (simples ou parcelado)
- `PUT /transactions/:id` — edita lançamento
- `DELETE /transactions/:id` — remove lançamento

**Tarefas:**
- Implementar os quatro endpoints com autenticação obrigatória
- Lógica de propagação de parcelas: ao criar com `installmentTotal > 1`,
  criar lançamentos para os ciclos seguintes automaticamente,
  criando os ciclos futuros se ainda não existirem
- Descrição gerada automaticamente no formato "Nome 1/3", "Nome 2/3", "Nome 3/3"
- Validação via Zod
- Escrever testes unitários para a lógica de parcelas
- Escrever testes de integração para os endpoints

**Critérios de aceite:**
- `POST` com `installmentTotal: 3` cria 3 lançamentos em 3 ciclos distintos
- Descrições seguem o formato "Nome 1/3", "Nome 2/3", "Nome 3/3"
- `DELETE` em uma parcela remove apenas aquela, não as demais
- `GET /cycles/:id/transactions` retorna apenas lançamentos do ciclo correto
- `npm test` passa com todos os testes de lançamentos

---

### Issue #9 — Endpoint de resumo do ciclo

**Tipo:** `feat`
**Label:** `backend`

**Descrição:**
Implementar endpoint que retorna o resumo financeiro de um ciclo — os
totais que aparecem na tela principal do app.

**Endpoint:**
- `GET /cycles/:id/summary`

**Resposta esperada:**
```json
{
  "totalIncome": 1350000,
  "totalEssential": 725285,
  "totalNonEssential": 89073,
  "balance": 535642,
  "transactionCount": 24
}
```
*(valores em centavos)*

**Tarefas:**
- Implementar o endpoint com autenticação obrigatória
- Calcular os totais agrupando por `type`
- `balance` = `totalIncome` - `totalEssential` - `totalNonEssential`
- Escrever testes unitários e de integração

**Critérios de aceite:**
- Retorna `401` sem token
- Retorna `404` para ciclo inexistente ou de outro usuário
- Totais batem com a soma manual dos lançamentos do seed
- `npm test` passa com todos os testes de resumo

---

### Issue #10 — Endpoint de export de dados

**Tipo:** `feat`
**Label:** `backend`

**Descrição:**
Implementar endpoint que exporta todos os dados do usuário em JSON ou CSV.
Essa é a feature de segurança dos dados do MVP.

**Endpoints:**
- `GET /export?format=json` — exporta em JSON
- `GET /export?format=csv` — exporta em CSV

**Tarefas:**
- Implementar exportação de todos os ciclos e lançamentos do usuário autenticado
- JSON: estrutura aninhada (ciclos com lançamentos dentro)
- CSV: planilha flat com todas as colunas relevantes
- Setar headers corretos para download (`Content-Disposition`)
- Escrever testes

**Critérios de aceite:**
- `GET /export?format=json` retorna arquivo JSON válido com header de download
- `GET /export?format=csv` retorna arquivo CSV com header de download
- Export contém todos os dados do usuário autenticado
- Export não contém dados de outros usuários
- `npm test` passa

---

### Issue #11 — Configurar GitHub Actions (CI)

**Tipo:** `chore`
**Label:** `infra`

**Descrição:**
Configurar pipeline de CI no GitHub Actions com jobs condicionais por pasta.

**Tarefas:**
- Criar `.github/workflows/backend.yml`
  - Trigger: push ou PR que altere `backend/**`
  - Steps: instalar deps, lint, build, testes com PostgreSQL de serviço
- Criar `.github/workflows/mobile.yml`
  - Trigger: push ou PR que altere `mobile/**`
  - Steps: build (testes virão junto com o desenvolvimento mobile)
- Configurar PostgreSQL como service no job de backend
- Configurar variáveis de ambiente de teste via GitHub Secrets

**Critérios de aceite:**
- Push em `backend/` dispara apenas o job de backend
- Push em `mobile/` dispara apenas o job de mobile
- Job de backend passa com todos os testes
- PR com testes falhando bloqueia o merge (branch protection)

---

### Issue #12 — Configurar deploy automático na VPS

**Tipo:** `chore`
**Label:** `infra`

**Descrição:**
Configurar deploy automático via GitHub Actions a cada merge na main.
O deploy conecta na VPS via SSH, atualiza o código e reinicia os containers.

**Tarefas:**
- Criar `.github/workflows/deploy.yml`
  - Trigger: push na `main`
  - Steps: SSH na VPS → git pull → `docker compose up -d --build`
- Configurar chave SSH como GitHub Secret
- Configurar branch protection na main:
  - Require PR antes de merge
  - Require CI passar antes de merge
  - Bloquear push direto na main
- Testar deploy de ponta a ponta com uma mudança pequena

**Critérios de aceite:**
- Merge na main dispara o workflow de deploy automaticamente
- `curl http://<ip-vps>:3000/health` retorna `{ "status": "ok" }` após deploy
- Push direto na main é bloqueado (branch protection ativo)
- Rollback manual é possível via `git revert` + novo merge

---

## Grupo B — Desenvolvedor executa após retornar de viagem

> As issues abaixo dependem de MacOS + Xcode e serão detalhadas
> quando o desenvolvimento mobile começar.

---

### Issue #13 — Inicializar projeto KMP

**Tipo:** `chore`
**Label:** `mobile`

**Descrição:**
Inicializar o projeto Kotlin Multiplatform em `mobile/` com suporte a iOS
(SwiftUI) e Android (Compose). Configurar shared module com estrutura base,
camada de rede e injeção de dependências.

*(detalhes serão refinados quando o desenvolvedor retornar)*

---

### Issue #14 — Tela de login (iOS)

**Tipo:** `feat`
**Label:** `mobile`

**Descrição:**
Implementar tela de login e registro em SwiftUI, integrada com os endpoints
de auth do backend (`POST /auth/login` e `POST /auth/register`).
Armazenar JWT no Keychain.

*(detalhes serão refinados quando o desenvolvedor retornar)*

---

### Issue #15 — Tela principal: resumo do ciclo (iOS)

**Tipo:** `feat`
**Label:** `mobile`

**Descrição:**
Implementar tela principal com o resumo do ciclo atual consumindo
`GET /cycles/current` e `GET /cycles/:id/summary`. Exibir totais de
receita, essencial, não essencial e saldo.

*(detalhes serão refinados quando o desenvolvedor retornar)*

---

### Issue #16 — Tela de lançamentos do ciclo (iOS)

**Tipo:** `feat`
**Label:** `mobile`

**Descrição:**
Implementar lista de lançamentos do ciclo consumindo
`GET /cycles/:id/transactions`. Permitir navegação entre ciclos anteriores.

*(detalhes serão refinados quando o desenvolvedor retornar)*

---

### Issue #17 — Quick add: adicionar lançamento (iOS)

**Tipo:** `feat`
**Label:** `mobile`

**Descrição:**
Implementar fluxo de adição de lançamento com foco em velocidade — acessível
em menos de 10 segundos a partir da tela principal. Suporte a lançamentos
simples e parcelados. Consome `POST /cycles/:id/transactions`.

*(detalhes serão refinados quando o desenvolvedor retornar)*

---

### Issue #18 — Export de dados (iOS)

**Tipo:** `feat`
**Label:** `mobile`

**Descrição:**
Implementar botão de export no app que consome `GET /export?format=json`
ou `GET /export?format=csv` e permite salvar ou compartilhar o arquivo
via share sheet do iOS.

*(detalhes serão refinados quando o desenvolvedor retornar)*

---

## Ordem de execução

| #  | Issue                          | Grupo | Depende de |
|----|-------------------------------|-------|------------|
| 1  | Criar repositório e issues     | A     | —          |
| 2  | Configurar Docker na VPS       | A     | 1          |
| 3  | Configurar Docker Compose      | A     | 2          |
| 4  | Inicializar projeto backend    | A     | 3          |
| 5  | Modelagem do banco             | A     | 4          |
| 6  | Auth: registro e login         | A     | 5          |
| 7  | CRUD de ciclos                 | A     | 6          |
| 8  | CRUD de lançamentos            | A     | 7          |
| 9  | Resumo do ciclo                | A     | 8          |
| 10 | Export de dados                | A     | 9          |
| 11 | GitHub Actions CI              | A     | 10         |
| 12 | Deploy automático              | A     | 11         |
| 13 | Inicializar KMP                | B     | 12         |
| 14 | Tela de login                  | B     | 13         |
| 15 | Tela principal                 | B     | 14         |
| 16 | Tela de lançamentos            | B     | 15         |
| 17 | Quick add                      | B     | 16         |
| 18 | Export mobile                  | B     | 17         |
