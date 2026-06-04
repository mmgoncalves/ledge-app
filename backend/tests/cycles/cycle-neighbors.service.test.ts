import { getCycleNeighbors } from '../../src/services/billing-cycle.service';

jest.mock('../../src/lib/prisma', () => ({
  __esModule: true,
  default: {
    billingCycle: {
      findFirst: jest.fn(),
    },
  },
}));

import prisma from '../../src/lib/prisma';

const mockFindFirst = prisma.billingCycle.findFirst as jest.Mock;

const userId = 'user-uuid-1';
const cycleId = 'cycle-uuid-current';

const fakeCurrent = {
  id: cycleId,
  userId,
  startDate: new Date('2026-06-01'),
  endDate: new Date('2026-06-30'),
  cutDay: 10,
  createdAt: new Date('2026-06-01'),
};

const fakePrevious = {
  id: 'cycle-uuid-may',
  userId,
  startDate: new Date('2026-05-01'),
  endDate: new Date('2026-05-31'),
  cutDay: 10,
  createdAt: new Date('2026-05-01'),
};

const fakeNext = {
  id: 'cycle-uuid-july',
  userId,
  startDate: new Date('2026-07-01'),
  endDate: new Date('2026-07-31'),
  cutDay: 10,
  createdAt: new Date('2026-07-01'),
};

describe('getCycleNeighbors', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns null when cycle does not belong to user', async () => {
    // given
    mockFindFirst.mockResolvedValueOnce(null);

    // when
    const result = await getCycleNeighbors(userId, cycleId);

    // then
    expect(result).toBeNull();
    expect(mockFindFirst).toHaveBeenCalledTimes(1);
  });

  it('returns both neighbors when cycle is in the middle', async () => {
    // given
    mockFindFirst
      .mockResolvedValueOnce(fakeCurrent)  // ownership check
      .mockResolvedValueOnce(fakePrevious) // previous
      .mockResolvedValueOnce(fakeNext);    // next

    // when
    const result = await getCycleNeighbors(userId, cycleId);

    // then
    expect(result).toEqual({ previous: fakePrevious, next: fakeNext });
  });

  it('returns previous=null when cycle is the oldest', async () => {
    // given
    mockFindFirst
      .mockResolvedValueOnce(fakeCurrent)
      .mockResolvedValueOnce(null)      // no previous
      .mockResolvedValueOnce(fakeNext);

    // when
    const result = await getCycleNeighbors(userId, cycleId);

    // then
    expect(result!.previous).toBeNull();
    expect(result!.next).toEqual(fakeNext);
  });

  it('returns next=null when cycle is the most recent', async () => {
    // given
    mockFindFirst
      .mockResolvedValueOnce(fakeCurrent)
      .mockResolvedValueOnce(fakePrevious)
      .mockResolvedValueOnce(null);       // no next

    // when
    const result = await getCycleNeighbors(userId, cycleId);

    // then
    expect(result!.previous).toEqual(fakePrevious);
    expect(result!.next).toBeNull();
  });

  it('returns both null when there is only one cycle', async () => {
    // given
    mockFindFirst
      .mockResolvedValueOnce(fakeCurrent)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null);

    // when
    const result = await getCycleNeighbors(userId, cycleId);

    // then
    expect(result).toEqual({ previous: null, next: null });
  });

  it('queries previous with startDate lt and desc order', async () => {
    // given
    mockFindFirst
      .mockResolvedValueOnce(fakeCurrent)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null);

    // when
    await getCycleNeighbors(userId, cycleId);

    // then — second call is previous query
    expect(mockFindFirst).toHaveBeenNthCalledWith(2, {
      where: { userId, startDate: { lt: fakeCurrent.startDate } },
      orderBy: { startDate: 'desc' },
    });
  });

  it('queries next with startDate gt and asc order', async () => {
    // given
    mockFindFirst
      .mockResolvedValueOnce(fakeCurrent)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null);

    // when
    await getCycleNeighbors(userId, cycleId);

    // then — third call is next query
    expect(mockFindFirst).toHaveBeenNthCalledWith(3, {
      where: { userId, startDate: { gt: fakeCurrent.startDate } },
      orderBy: { startDate: 'asc' },
    });
  });
});
