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
