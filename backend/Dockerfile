FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production=false

# Generate Prisma client before tsc so @prisma/client types are available
COPY prisma ./prisma
COPY prisma.config.ts ./
RUN npx prisma generate

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ─── Production image ─────────────────────────────────────────────────────────
FROM node:22-alpine AS runner

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist
COPY prisma ./prisma
COPY prisma.config.ts ./
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 3000

# prisma generate runs at startup (needs DATABASE_URL from .env)
ENTRYPOINT ["./docker-entrypoint.sh"]
