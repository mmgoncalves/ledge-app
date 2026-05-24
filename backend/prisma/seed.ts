import 'dotenv/config';
import { PrismaClient, TransactionType, PaymentMethod } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';

// Prisma 7: pass a pg Pool to the driver adapter
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🌱 Seeding database...');

  // ─── User ────────────────────────────────────────────────────────────────────
  const passwordHash = await bcrypt.hash('senha123', 12);

  const user = await prisma.user.upsert({
    where: { email: 'mateus@ledge.app' },
    update: {},
    create: {
      email: 'mateus@ledge.app',
      passwordHash,
    },
  });

  console.log(`✅ User: ${user.email}`);

  // ─── Billing cycle (cutDay = 4, cycle: 05/01 → 04/02) ────────────────────────
  const cycle = await prisma.billingCycle.upsert({
    where: { id: 'seed-cycle-jan-2026' },
    update: {},
    create: {
      id: 'seed-cycle-jan-2026',
      userId: user.id,
      startDate: new Date('2026-01-05'),
      endDate: new Date('2026-02-04'),
      cutDay: 4,
    },
  });

  console.log(`✅ BillingCycle: ${cycle.startDate.toDateString()} → ${cycle.endDate.toDateString()}`);

  // ─── Transactions ─────────────────────────────────────────────────────────────
  const transactions = [
    {
      description: 'Salário',
      amount: 1200000,
      date: new Date('2026-01-05'),
      type: TransactionType.INCOME,
      paymentMethod: PaymentMethod.PIX,
    },
    {
      description: 'Aluguel',
      amount: 250000,
      date: new Date('2026-01-10'),
      type: TransactionType.ESSENTIAL,
      paymentMethod: PaymentMethod.PIX,
    },
    {
      description: 'Luz',
      amount: 18500,
      date: new Date('2026-01-12'),
      type: TransactionType.ESSENTIAL,
      paymentMethod: PaymentMethod.DEBIT_CARD,
    },
    {
      description: 'Internet',
      amount: 12000,
      date: new Date('2026-01-15'),
      type: TransactionType.ESSENTIAL,
      paymentMethod: PaymentMethod.CREDIT_CARD,
    },
    {
      description: 'iFood',
      amount: 8500,
      date: new Date('2026-01-18'),
      type: TransactionType.NON_ESSENTIAL,
      paymentMethod: PaymentMethod.CREDIT_CARD,
    },
    {
      description: 'Netflix',
      amount: 4490,
      date: new Date('2026-01-20'),
      type: TransactionType.NON_ESSENTIAL,
      paymentMethod: PaymentMethod.CREDIT_CARD,
    },
    {
      description: 'Notebook 1/6',
      amount: 60000,
      date: new Date('2026-01-22'),
      type: TransactionType.NON_ESSENTIAL,
      paymentMethod: PaymentMethod.CREDIT_CARD,
      installmentIndex: 1,
      installmentTotal: 6,
    },
  ];

  for (const tx of transactions) {
    await prisma.transaction.create({
      data: { ...tx, userId: user.id, billingCycleId: cycle.id },
    });
  }

  console.log(`✅ Transactions: ${transactions.length} created`);
  console.log('🌱 Seed complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
