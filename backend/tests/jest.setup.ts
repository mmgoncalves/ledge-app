import 'dotenv/config';

// Fallback env vars for test environment
process.env.DATABASE_URL ??= 'postgresql://ledge:ledge_secret_2026@localhost:5432/ledge_db';
process.env.JWT_SECRET ??= 'test-jwt-secret';
process.env.JWT_EXPIRES_IN ??= '7d';
