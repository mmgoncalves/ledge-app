import prisma from '../lib/prisma';
import { z } from 'zod';

export const createCycleSchema = z.object({
  startDate: z.string().date(),
  endDate: z.string().date(),
  cutDay: z.number().int().min(1).max(31),
});

export type CreateCycleInput = z.infer<typeof createCycleSchema>;

export async function getCycles(userId: string) {
  return prisma.billingCycle.findMany({
    where: { userId },
    orderBy: { startDate: 'desc' },
  });
}

export async function getCurrentCycle(userId: string) {
  const today = new Date();

  // Find the cycle where today falls between startDate and endDate
  const cycle = await prisma.billingCycle.findFirst({
    where: {
      userId,
      startDate: { lte: today },
      endDate: { gte: today },
    },
    include: { transactions: { orderBy: { date: 'desc' } } },
  });

  return cycle;
}

export async function getCycleById(userId: string, cycleId: string) {
  const cycle = await prisma.billingCycle.findFirst({
    where: { id: cycleId, userId },
    include: { transactions: { orderBy: { date: 'desc' } } },
  });

  return cycle;
}

export async function createCycle(userId: string, input: CreateCycleInput) {
  return prisma.billingCycle.create({
    data: {
      userId,
      startDate: new Date(input.startDate),
      endDate: new Date(input.endDate),
      cutDay: input.cutDay,
    },
  });
}

export interface CycleSummary {
  totalIncome: number;
  totalEssential: number;
  totalNonEssential: number;
  balance: number;
  transactionCount: number;
}

export async function getCycleSummary(
  userId: string,
  cycleId: string,
): Promise<CycleSummary | null> {
  const cycle = await prisma.billingCycle.findFirst({ where: { id: cycleId, userId } });
  if (!cycle) return null;

  const grouped = await prisma.transaction.groupBy({
    by: ['type'],
    where: { billingCycleId: cycleId, userId },
    _sum: { amount: true },
    _count: { id: true },
  });

  let totalIncome = 0;
  let totalEssential = 0;
  let totalNonEssential = 0;
  let transactionCount = 0;

  for (const row of grouped) {
    const sum = row._sum.amount ?? 0;
    const count = row._count.id ?? 0;
    transactionCount += count;

    if (row.type === 'INCOME') totalIncome = sum;
    else if (row.type === 'ESSENTIAL') totalEssential = sum;
    else if (row.type === 'NON_ESSENTIAL') totalNonEssential = sum;
  }

  return {
    totalIncome,
    totalEssential,
    totalNonEssential,
    balance: totalIncome - totalEssential - totalNonEssential,
    transactionCount,
  };
}
