FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production=false

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

RUN npm run prisma:generate

EXPOSE 3000

CMD ["node", "dist/index.js"]
