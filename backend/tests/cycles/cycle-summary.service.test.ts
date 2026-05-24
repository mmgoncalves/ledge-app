import { getCycleSummary } from '../../src/services/billing-cycle.service';

jest.mock('../../src/lib/prisma', () => ({
  __esModule: true,
  default: {
    billingCycle: {
      findFirst: jest.fn(),
    },
    transaction: {
      groupBy: jest.fn(),
    },
  },
}));

import prisma from '../../src/lib/prisma';

const mockPrisma = prisma as jest.Mocked<typeof prisma> & {
  billingCycle: jest.Mocked<typeof prisma.billingCycle>;
  transaction: jest.Mocked<typeof prisma.transaction>;
};

const userId = 'user-uuid-1';
const cycleId = 'cycle-uuid-1';

const fakeCycle = { id: cycleId, userId };

describe('getCycleSummary', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns null when cycle does not belong to user', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(null);

    // when
    const result = await getCycleSummary(userId, cycleId);

    // then
    expect(result).toBeNull();
    expect(mockPrisma.transaction.groupBy).not.toHaveBeenCalled();
  });

  it('calculates correct totals with mixed transaction types', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(fakeCycle);
    (mockPrisma.transaction.groupBy as jest.Mock).mockResolvedValue([
      { type: 'INCOME', _sum: { amount: 1350000 }, _count: { id: 10 } },
      { type: 'ESSENTIAL', _sum: { amount: 725285 }, _count: { id: 12 } },
      { type: 'NON_ESSENTIAL', _sum: { amount: 89073 }, _count: { id: 2 } },
    ]);

    // when
    const result = await getCycleSummary(userId, cycleId);

    // then
    expect(result).toEqual({
      totalIncome: 1350000,
      totalEssential: 725285,
      totalNonEssential: 89073,
      balance: 1350000 - 725285 - 89073,
      transactionCount: 24,
    });
  });

  it('returns zero totals for a cycle with no transactions', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(fakeCycle);
    (mockPrisma.transaction.groupBy as jest.Mock).mockResolvedValue([]);

    // when
    const result = await getCycleSummary(userId, cycleId);

    // then
    expect(result).toEqual({
      totalIncome: 0,
      totalEssential: 0,
      totalNonEssential: 0,
      balance: 0,
      transactionCount: 0,
    });
  });

  it('handles cycles with only INCOME transactions', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(fakeCycle);
    (mockPrisma.transaction.groupBy as jest.Mock).mockResolvedValue([
      { type: 'INCOME', _sum: { amount: 500000 }, _count: { id: 1 } },
    ]);

    // when
    const result = await getCycleSummary(userId, cycleId);

    // then
    expect(result).toEqual({
      totalIncome: 500000,
      totalEssential: 0,
      totalNonEssential: 0,
      balance: 500000,
      transactionCount: 1,
    });
  });

  it('computes negative balance correctly', async () => {
    // given
    (mockPrisma.billingCycle.findFirst as jest.Mock).mockResolvedValue(fakeCycle);
    (mockPrisma.transaction.groupBy as jest.Mock).mockResolvedValue([
      { type: 'INCOME', _sum: { amount: 100000 }, _count: { id: 1 } },
      { type: 'ESSENTIAL', _sum: { amount: 200000 }, _count: { id: 5 } },
    ]);

    // when
    const result = await getCycleSummary(userId, cycleId);

    // then
    expect(result!.balance).toBe(-100000);
  });
});
