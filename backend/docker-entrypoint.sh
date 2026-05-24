#!/bin/sh
set -e

echo "[entrypoint] Running prisma generate..."
npx prisma generate

echo "[entrypoint] Starting server..."
exec node dist/index.js
