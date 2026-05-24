# Ledge

Aplicativo pessoal de finanças — controle de ciclos de fatura, lançamentos parcelados e exportação de dados.

## Stack

| Camada | Tecnologias |
|--------|-------------|
| **Backend** | Node.js · TypeScript · Express · Prisma 7 · PostgreSQL · Zod · JWT |
| **Mobile** | iOS (Swift · SwiftUI) · Android (Kotlin · Jetpack Compose) |
| **Infra** | Docker Compose · GitHub Actions (CI + deploy) |

## Estrutura do monorepo

```
ledge-app/
├── backend/        # API REST (Node.js + Express)
├── mobile/         # Apps iOS e Android
├── shared/         # Tipos e contratos compartilhados
├── docs/           # Documentação do projeto
└── CLAUDE.md       # Contexto completo do projeto (arquitetura, decisões, roadmap)
```

## Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- [Node.js 22+](https://nodejs.org/) (apenas para desenvolvimento local sem Docker)

## Subindo o ambiente

```bash
# 1. Clone o repositório
git clone https://github.com/mmgoncalves/ledge-app.git
cd ledge-app/backend

# 2. Configure as variáveis de ambiente
cp .env.example .env
# Edite .env com suas credenciais

# 3. Suba os containers (API + PostgreSQL)
docker compose up -d

# 4. Rode as migrations
npx prisma migrate deploy

# 5. (Opcional) Popule com dados de exemplo
npm run prisma:seed
```

A API estará disponível em `http://localhost:3000`.

```bash
# Verificar saúde da API
curl http://localhost:3000/health
# → {"status":"ok"}
```

## Desenvolvimento local (sem Docker)

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev
npm run dev          # hot reload em http://localhost:3000
```

## Testes

```bash
cd backend
npm test             # Jest — 92 testes
npm run test:coverage
```

## CI / Deploy

- **Backend CI** — dispara em push/PR em `backend/**` ou `.github/workflows/**`: lint → build → test (PostgreSQL em serviço)
- **Deploy** — dispara em push na `main` em `backend/**`: SSH na VPS → `git fetch + reset --hard` → `docker compose up -d --build` → health check

## Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/auth/register` | Cadastro |
| `POST` | `/auth/login` | Login (retorna JWT) |
| `GET` | `/cycles` | Lista ciclos de fatura |
| `GET` | `/cycles/current` | Ciclo atual |
| `GET` | `/cycles/:id/summary` | Resumo financeiro do ciclo |
| `GET` | `/cycles/:id/transactions` | Lançamentos do ciclo |
| `POST` | `/cycles/:id/transactions` | Novo lançamento (suporta parcelamento) |
| `PUT` | `/transactions/:id` | Editar lançamento |
| `DELETE` | `/transactions/:id` | Remover lançamento |
| `GET` | `/export?format=json\|csv` | Exportar todos os dados |

Para contexto completo sobre arquitetura, decisões técnicas e roadmap, veja [CLAUDE.md](CLAUDE.md).
