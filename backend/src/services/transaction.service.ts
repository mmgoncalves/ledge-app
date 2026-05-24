import { z } from 'zod';
import prisma from '../lib/prisma';
import { BillingCycle } from '@prisma/client';

// ─── Schemas ──────────────────────────────────────────────────────────────────

export const createTransactionSchema = z.object({
  description: z.string().min(1),
  amount: z.number().int().positive(),
  date: z.string().date(),
  type: z.enum(['ESSENTIAL', 'NON_ESSENTIAL', 'INCOME']),
  paymentMethod: z.enum(['CREDIT_CARD', 'DEBIT_CARD', 'PIX', 'CASH']),
  installmentTotal: z.number().int().min(1).default(1),
});

export const updateTransactionSchema = z.object({
  description: z.string().min(1).optional(),
  amount: z.number().int().positive().optional(),
  date: z.string().date().optional(),
  type: z.enum(['ESSENTIAL', 'NON_ESSENTIAL', 'INCOME']).optional(),
  paymentMethod: z.enum(['CREDIT_CARD', 'DEBIT_CARD', 'PIX', 'CASH']).optional(),
});

export type CreateTransactionInput = z.infer<typeof createTransactionSchema>;
export type UpdateTransactionInput = z.infer<typeof updateTransactionSchema>;

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Returns the next cycle for a user, or creates one if it doesn't exist.
 * The next cycle starts the day after `currentCycle.endDate` and has
 * the same duration and cutDay as the current cycle.
 */
export async function findOrCreateNextCycle(
  userId: string,
  currentCycle: Pick<BillingCycle, 'id' | 'startDate' | 'endDate' | 'cutDay'>,
): Promise<BillingCycle> {
  const existing = await prisma.billingCycle.findFirst({
    where: { userId, startDate: { gt: currentCycle.endDate } },
    orderBy: { startDate: 'asc' },
  });

  if (existing) return existing;

  const durationMs = currentCycle.endDate.getTime() - currentCycle.startDate.getTime();
  const nextStart = new Date(currentCycle.endDate.getTime() + 24 * 60 * 60 * 1000);
  const nextEnd = new Date(nextStart.getTime() + durationMs);

  return prisma.billingCycle.create({
    data: {
      userId,
      startDate: nextStart,
      endDate: nextEnd,
      cutDay: currentCycle.cutDay,
    },
  });
}

// ─── Service functions ────────────────────────────────────────────────────────

export async function getTransactions(userId: string, cycleId: string) {
  const cycle = await prisma.billingCycle.findFirst({ where: { id: cycleId, userId } });
  if (!cycle) return null;

  return prisma.transaction.findMany({
    where: { billingCycleId: cycleId, userId },
    orderBy: { date: 'desc' },
  });
}

export async function createTransaction(
  userId: string,
  cycleId: string,
  input: CreateTransactionInput,
) {
  const baseCycle = await prisma.billingCycle.findFirst({ where: { id: cycleId, userId } });
  if (!baseCycle) return null;

  const { installmentTotal, description, amount, date, type, paymentMethod } = input;
  const isInstallment = installmentTotal > 1;

  const created: Awaited<ReturnType<typeof prisma.transaction.create>>[] = [];
  let currentCycle = baseCycle;

  for (let i = 1; i <= installmentTotal; i++) {
    const desc = isInstallment ? `${description} ${i}/${installmentTotal}` : description;

    const tx = await prisma.transaction.create({
      data: {
        userId,
        billingCycleId: currentCycle.id,
        description: desc,
        amount,
        date: new Date(date),
        type,
        paymentMethod,
        installmentIndex: isInstallment ? i : null,
        installmentTotal: isInstallment ? installmentTotal : null,
      },
    });

    created.push(tx);

    if (i < installmentTotal) {
      currentCycle = await findOrCreateNextCycle(userId, currentCycle);
    }
  }

  return created;
}

export async function updateTransaction(
  userId: string,
  transactionId: string,
  input: UpdateTransactionInput,
) {
  const existing = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
  });
  if (!existing) return null;

  return prisma.transaction.update({
    where: { id: transactionId },
    data: {
      ...(input.description !== undefined && { description: input.description }),
      ...(input.amount !== undefined && { amount: input.amount }),
      ...(input.date !== undefined && { date: new Date(input.date) }),
      ...(input.type !== undefined && { type: input.type }),
      ...(input.paymentMethod !== undefined && { paymentMethod: input.paymentMethod }),
    },
  });
}

export async function deleteTransaction(userId: string, transactionId: string) {
  const existing = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
  });
  if (!existing) return null;

  await prisma.transaction.delete({ where: { id: transactionId } });
  return true;
}
