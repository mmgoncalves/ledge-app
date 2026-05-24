import { defineConfig } from 'prisma/config';
import { readFileSync } from 'fs';
import { resolve } from 'path';

// Prisma 7 loads this config before injecting .env vars,
// so we read .env manually to ensure DATABASE_URL is available.
function loadEnvVar(key: string): string | undefined {
  try {
    const envPath = resolve(__dirname, '.env');
    const content = readFileSync(envPath, 'utf-8');
    const match = content.match(new RegExp(`^${key}="?([^"\n]+)"?`, 'm'));
    return match?.[1] ?? process.env[key];
  } catch {
    return process.env[key];
  }
}

export default defineConfig({
  datasource: {
    url: loadEnvVar('DATABASE_URL'),
  },
});
