# CLAUDE.md — Ledge

Este arquivo é o contexto vivo do projeto Ledge.
Todo agente de IA ou desenvolvedor deve ler este arquivo antes de qualquer sessão.

---

## O que é o Ledge

Ledge é um app pessoal de finanças que elimina o atrito de registrar gastos
e transforma dados financeiros em decisões reais. O objetivo não é cortar
o estilo de vida do usuário — é entender e sustentar ele.

Hoje o controle financeiro é feito em Google Sheets. O Ledge substitui essa
planilha com uma experiência mobile-first, com captura rápida de lançamentos,
controle por ciclo de fatura e, futuramente, insights via IA.

---

## Usuário

Desenvolvedor mobile, renda mensal com componentes variáveis (salário + bônus),
tem reserva de emergência e quer mantê-la, viaja e consome cultura sem culpa.
Perde controle por falta de visibilidade, não por falta de disciplina.

---

## Problemas que o Ledge resolve

1. Registro manual tem muito atrito (planilha no computador)
2. Só consegue registrar gastos na frente do PC — não no momento em que gasta
3. Dados existem mas não geram insight
4. Sem categorização inteligente (tudo vira "cartão")
5. Sem projeção futura

---

## Roadmap

- **MVP** — Mobile (KMP, iOS primeiro) + Backend (Node.js/TS). Substitui a planilha.
- **V2** — Web + migração dos dados da planilha + OAuth (Google + Apple)
- **V3** — Categorização inteligente, gráficos, dashboards
- **V4** — IA, projeções, insights

---

## Domínio — conceitos importantes

### Ciclo de fatura

A unidade de tempo do Ledge **não é o mês calendário** — é o ciclo de fatura
do cartão de crédito. O ciclo vai da data de corte do mês anterior até a data
de corte do mês atual.

Exemplo: se o cartão fecha dia 4, o ciclo de "fevereiro" vai de 05/01 até 04/02.

Cada ciclo tem uma data de corte configurável pelo usuário.

### Lançamentos

Todo lançamento pertence a um ciclo e tem os seguintes campos:

- `description` — texto livre (ex: "iFood", "Aluguel")
- `amount` — valor em centavos (inteiro, evita problemas de float)
- `date` — data do gasto
- `type` — `ESSENTIAL`, `NON_ESSENTIAL` ou `INCOME`
- `paymentMethod` — `CREDIT_CARD`, `DEBIT_CARD`, `PIX` ou `CASH`
- `installmentIndex` — número da parcela atual (ex: 1). Null se não for parcelado.
- `installmentTotal` — total de parcelas (ex: 10). Null se não for parcelado.

### Parcelas

Compras parceladas são representadas como lançamentos independentes em cada
ciclo, no formato "Nome 1/10". Ao cadastrar uma compra parcelada, o app cria
automaticamente os lançamentos nos ciclos futuros, criando os ciclos se ainda
não existirem. O mesmo se aplica a receitas parceladas (ex: alguém pagando
uma dívida em parcelas).

### Tipos de lançamento

- **ESSENTIAL** — gastos fixos que não podem deixar de ser pagos (aluguel, luz, etc.)
- **NON_ESSENTIAL** — gastos variáveis e opcionais (streaming, delivery, etc.)
- **INCOME** — receitas (salário, freelance, reembolsos, etc.)

---

## Stack

### Backend

- Runtime: Node.js
- Linguagem: TypeScript
- Framework: Express
- Banco de dados: PostgreSQL
- ORM: Prisma
- Auth: JWT + bcrypt
- Validação: Zod
- Testes: Jest

### Mobile

- KMP (Kotlin Multiplatform)
- iOS: SwiftUI
- Android: Jetpack Compose
- iOS prioritizado no MVP — Android vem na V2

### Infra

- VPS Contabo — Ubuntu, 4 CPUs, 8GB RAM, 75GB NVMe (Europa)
- Docker + Docker Compose para orquestrar backend e banco na VPS
- GitHub Actions para CI/CD

---

## Repositório

- Nome: `ledge-app`
- Tipo: monorepo privado no GitHub
- Estrutura:

```
ledge-app/
├── backend/        # Node.js + TypeScript
├── mobile/         # KMP (iOS + Android)
├── shared/         # Tipos e contratos compartilhados
├── docs/           # Documentação adicional
├── CLAUDE.md       # Este arquivo
└── PLAN.md         # Plano de desenvolvimento e issues
```

---

## Padrões de desenvolvimento

### Branches

- `main` — código pronto para produção. Todo merge na main pode ir a deploy.
- Feature branches — criadas a partir da main, nomeadas como `feat/nome-da-feature`
- Nunca commitar direto na main

### Commits

Seguir Conventional Commits:

- `feat:` nova funcionalidade
- `fix:` correção de bug
- `chore:` configuração, dependências, infra
- `docs:` documentação
- `test:` testes

### Pull Requests

- Título em inglês
- Corpo em português
- PRs devem ser pequenos e focados — um PR por issue
- Todo PR precisa passar no CI antes de ser mergeado
- Code review feito pelo dono do projeto antes do merge

### Idioma

- Código, commits e título de PRs: inglês
- Issues, corpo de PRs e comentários: português

### Critérios de aceite

Todo PR deve incluir no corpo uma seção **"Critérios de aceite"** listando
os comandos ou passos executados para validar a entrega. O agente deve rodar
todos os critérios antes de abrir o PR.

---

## CI/CD

### GitHub Actions

- Jobs condicionais por pasta:
  - `backend/**` alterado → roda testes, lint e build do backend
  - `mobile/**` alterado → roda build do mobile
- A cada push: testes + lint + build
- A cada merge na main: tudo acima + deploy automático na VPS via SSH

### Deploy na VPS

- Docker Compose orquestra backend + PostgreSQL
- Deploy = pull do código novo + `docker compose up -d`
- Zero downtime não é requisito no MVP

---

## Segurança dos dados

- Backup automático do PostgreSQL via `pg_dump` agendado com cron na VPS
  (diário, mantendo os últimos 7 dias)
- Export manual pelo app em JSON ou CSV (feature do MVP)

---

## O que está fora do MVP

- Status de pagamento (pago/pendente)
- OAuth (Google + Apple) — entra na V2 junto com a web
- Categorização automática — V3
- Gráficos e dashboards — V3
- IA e projeções — V4
- Android — V2
