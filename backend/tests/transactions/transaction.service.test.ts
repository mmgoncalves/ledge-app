import { findOrCreateNextCycle } from '../../src/services/transaction.service';

// ─── Mock Prisma ──────────────────────────────────────────────────────────────

jest.mock('../../src/lib/prisma', () => ({
  __esModule: true,
  default: {
    billingCycle: {
      findFirst: jest.fn(),
      create: jest.fn(),
    },
    transaction: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  },
}));

import prisma from '../../src/lib/prisma';

const mockPrisma = prisma as jest.Mocked<typeof prisma> & {
  billingCycle: jest.Mocked<typeof prisma.billingCycle>;
  transaction: jest.Mocked<typeof prisma.transaction>;
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const userId = 'user-uuid-1';

function makeCycle(overrides: Partial<{
  id: string;
  startDate: Date;
  endDate: Date;
  cutDay: number;
}> = {}) {
  return {
    id: overrides.id ?? 'cycle-uuid-1',
    userId,
    startDate: overrides.startDate ?? new Date('2026-05-01'),
    endDate: overrides.endDate ?? new Date('2026-05-31'),
    cutDay: overrides.cutDay ?? 10,
    createdAt: new Date('2026-05-01'),
  };
}

// ─── findOrCreateNextCycle ────────────────────────────────────────────────────

describe('findOrCreateNextCycle', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns existing next cycle when one exists', async () => {
    // given
    const currentCycle = makeCycle();
    const nextCycle = makeCycle({
      id: 'cycle-uuid-2',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-06-30'),
    });
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(nextCycle);

    // when
    const result = await findOrCreateNextCycle(userId, currentCycle);

    // then
    expect(result).toEqual(nextCycle);
    expect(mockPrisma.billingCycle.create).not.toHaveBeenCalled();
  });

  it('creates a new cycle when no next cycle exists', async () => {
    // given
    const currentCycle = makeCycle({
      startDate: new Date('2026-05-01'),
      endDate: new Date('2026-05-31'),
      cutDay: 10,
    });
    const createdCycle = makeCycle({
      id: 'cycle-uuid-2',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-06-30'),
    });
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(null);
    (mockPrisma.billingCycle.create as jest.Mock).mockResolvedValue(createdCycle);

    // when
    const result = await findOrCreateNextCycle(userId, currentCycle);

    // then
    expect(result).toEqual(createdCycle);
    expect(mockPrisma.billingCycle.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId,
        cutDay: currentCycle.cutDay,
        // next cycle starts the day after endDate (May 31 → Jun 1)
        startDate: new Date('2026-06-01'),
      }),
    });
  });

  it('preserves the same duration when creating a new cycle', async () => {
    // given — 15-day cycle
    const currentCycle = makeCycle({
      startDate: new Date('2026-05-01'),
      endDate: new Date('2026-05-15'),
    });
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(null);
    (mockPrisma.billingCycle.create as jest.Mock).mockResolvedValue({} as never);

    // when
    await findOrCreateNextCycle(userId, currentCycle);

    // then
    const createCall = (mockPrisma.billingCycle.create as jest.Mock).mock.calls[0][0];
    const { startDate, endDate } = createCall.data;
    const durationMs = endDate.getTime() - startDate.getTime();
    const originalDurationMs =
      currentCycle.endDate.getTime() - currentCycle.startDate.getTime();

    expect(durationMs).toBe(originalDurationMs);
    expect(startDate).toEqual(new Date('2026-05-16')); // day after May 15
  });
});

// ─── installment description format ──────────────────────────────────────────

import {
  createTransaction,
  getTransactions,
  updateTransaction,
  deleteTransaction,
} from '../../src/services/transaction.service';

const baseCycle = makeCycle();

const baseInput = {
  description: 'Notebook',
  amount: 300000,
  date: '2026-05-10',
  type: 'NON_ESSENTIAL' as const,
  paymentMethod: 'CREDIT_CARD' as const,
  installmentTotal: 1,
};

describe('createTransaction — installments', () => {
  beforeEach(() => jest.clearAllMocks());

  it('creates a single transaction without installment fields when installmentTotal = 1', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(baseCycle);
    (mockPrisma.transaction.create as jest.Mock).mockResolvedValue({ id: 'tx-1' });

    // when
    await createTransaction(userId, baseCycle.id, { ...baseInput, installmentTotal: 1 });

    // then
    const call = (mockPrisma.transaction.create as jest.Mock).mock.calls[0][0];
    expect(call.data.installmentIndex).toBeNull();
    expect(call.data.installmentTotal).toBeNull();
    expect(call.data.description).toBe('Notebook');
    expect(mockPrisma.transaction.create).toHaveBeenCalledTimes(1);
  });

  it('creates 3 transactions with formatted descriptions for installmentTotal = 3', async () => {
    // given
    const cycle1 = makeCycle({ id: 'cycle-1' });
    const cycle2 = makeCycle({ id: 'cycle-2' });
    const cycle3 = makeCycle({ id: 'cycle-3' });

    (mockPrisma.billingCycle.findFirst as jest.Mock)
      .mockResolvedValueOnce(cycle1)   // base cycle lookup
      .mockResolvedValueOnce(cycle2)   // findOrCreateNextCycle for installment 2
      .mockResolvedValueOnce(cycle3);  // findOrCreateNextCycle for installment 3

    (mockPrisma.transaction.create as jest.Mock)
      .mockResolvedValueOnce({ id: 'tx-1', description: 'Notebook 1/3' })
      .mockResolvedValueOnce({ id: 'tx-2', description: 'Notebook 2/3' })
      .mockResolvedValueOnce({ id: 'tx-3', description: 'Notebook 3/3' });

    // when
    const result = await createTransaction(userId, cycle1.id, {
      ...baseInput,
      installmentTotal: 3,
    });

    // then
    expect(result).toHaveLength(3);
    expect(mockPrisma.transaction.create).toHaveBeenCalledTimes(3);

    const calls = (mockPrisma.transaction.create as jest.Mock).mock.calls;
    expect(calls[0][0].data.description).toBe('Notebook 1/3');
    expect(calls[1][0].data.description).toBe('Notebook 2/3');
    expect(calls[2][0].data.description).toBe('Notebook 3/3');
  });

  it('each installment goes to a separate cycle', async () => {
    // given
    const cycle1 = makeCycle({ id: 'cycle-1' });
    const cycle2 = makeCycle({ id: 'cycle-2' });
    const cycle3 = makeCycle({ id: 'cycle-3' });

    (mockPrisma.billingCycle.findFirst as jest.Mock)
      .mockResolvedValueOnce(cycle1)
      .mockResolvedValueOnce(cycle2)
      .mockResolvedValueOnce(cycle3);

    (mockPrisma.transaction.create as jest.Mock).mockResolvedValue({ id: 'tx' });

    // when
    await createTransaction(userId, cycle1.id, { ...baseInput, installmentTotal: 3 });

    // then
    const calls = (mockPrisma.transaction.create as jest.Mock).mock.calls;
    expect(calls[0][0].data.billingCycleId).toBe('cycle-1');
    expect(calls[1][0].data.billingCycleId).toBe('cycle-2');
    expect(calls[2][0].data.billingCycleId).toBe('cycle-3');
  });

  it('returns null when the base cycle does not belong to the user', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(null);

    // when
    const result = await createTransaction(userId, 'nonexistent-cycle', baseInput);

    // then
    expect(result).toBeNull();
    expect(mockPrisma.transaction.create).not.toHaveBeenCalled();
  });
});

describe('getTransactions', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns transactions for a valid cycle', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(baseCycle);
    (mockPrisma.transaction.findMany as jest.Mock).mockResolvedValue([{ id: 'tx-1' }]);

    // when
    const result = await getTransactions(userId, baseCycle.id);

    // then
    expect(result).toHaveLength(1);
  });

  it('returns null when cycle does not belong to user', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(null);

    // when
    const result = await getTransactions(userId, 'nonexistent');

    // then
    expect(result).toBeNull();
    expect(mockPrisma.transaction.findMany).not.toHaveBeenCalled();
  });
});

describe('updateTransaction', () => {
  beforeEach(() => jest.clearAllMocks());

  it('updates only the provided fields', async () => {
    // given
    const existing = { id: 'tx-1', userId, description: 'Old', amount: 100 };
    (mockPrisma.transaction.findFirst as jest.Mock).mockResolvedValue(existing);
    (mockPrisma.transaction.update as jest.Mock).mockResolvedValue({ ...existing, description: 'New' });

    // when
    const result = await updateTransaction(userId, 'tx-1', { description: 'New' });

    // then
    expect(result).not.toBeNull();
    const updateCall = (mockPrisma.transaction.update as jest.Mock).mock.calls[0][0];
    expect(updateCall.data).toEqual({ description: 'New' });
  });

  it('returns null when transaction does not belong to user', async () => {
    // given
    (mockPrisma.transaction.findFirst as jest.Mock).mockResolvedValue(null);

    // when
    const result = await updateTransaction(userId, 'nonexistent', { description: 'X' });

    // then
    expect(result).toBeNull();
    expect(mockPrisma.transaction.update).not.toHaveBeenCalled();
  });
});

describe('deleteTransaction', () => {
  beforeEach(() => jest.clearAllMocks());

  it('deletes only the specified transaction', async () => {
    // given
    (mockPrisma.transaction.findFirst as jest.Mock).mockResolvedValue({ id: 'tx-1', userId });
    (mockPrisma.transaction.delete as jest.Mock).mockResolvedValue({});

    // when
    const result = await deleteTransaction(userId, 'tx-1');

    // then
    expect(result).toBe(true);
    expect(mockPrisma.transaction.delete).toHaveBeenCalledWith({ where: { id: 'tx-1' } });
    expect(mockPrisma.transaction.delete).toHaveBeenCalledTimes(1);
  });

  it('returns null when transaction does not belong to user', async () => {
    // given
    (mockPrisma.transaction.findFirst as jest.Mock).mockResolvedValue(null);

    // when
    const result = await deleteTransaction(userId, 'nonexistent');

    // then
    expect(result).toBeNull();
    expect(mockPrisma.transaction.delete).not.toHaveBeenCalled();
  });
});
