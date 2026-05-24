import request from 'supertest';
import jwt from 'jsonwebtoken';
import app from '../../src/app';
import * as cycleService from '../../src/services/billing-cycle.service';

jest.mock('../../src/services/billing-cycle.service', () => ({
  ...jest.requireActual('../../src/services/billing-cycle.service'),
  getCycles: jest.fn(),
  getCurrentCycle: jest.fn(),
  getCycleById: jest.fn(),
  createCycle: jest.fn(),
  getCycleSummary: jest.fn(),
}));

const mockCycleService = cycleService as jest.Mocked<typeof cycleService>;

const userId = 'user-uuid-1';
const token = jwt.sign({ userId }, process.env.JWT_SECRET ?? 'test-jwt-secret');
const authHeader = `Bearer ${token}`;

const fakeSummary = {
  totalIncome: 1350000,
  totalEssential: 725285,
  totalNonEssential: 89073,
  balance: 535642,
  transactionCount: 24,
};

describe('GET /cycles/:id/summary', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with summary for a valid cycle', async () => {
    // given
    mockCycleService.getCycleSummary.mockResolvedValue(fakeSummary);

    // when
    const res = await request(app)
      .get('/cycles/cycle-uuid-1/summary')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body).toEqual(fakeSummary);
    expect(mockCycleService.getCycleSummary).toHaveBeenCalledWith(userId, 'cycle-uuid-1');
  });

  it('returns 404 for a nonexistent or unauthorized cycle', async () => {
    // given
    mockCycleService.getCycleSummary.mockResolvedValue(null);

    // when
    const res = await request(app)
      .get('/cycles/nonexistent/summary')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Cycle not found');
  });

  it('returns 401 without a token', async () => {
    // when
    const res = await request(app).get('/cycles/cycle-uuid-1/summary');

    // then
    expect(res.status).toBe(401);
    expect(mockCycleService.getCycleSummary).not.toHaveBeenCalled();
  });

  it('includes all expected fields in the response', async () => {
    // given
    mockCycleService.getCycleSummary.mockResolvedValue(fakeSummary);

    // when
    const res = await request(app)
      .get('/cycles/cycle-uuid-1/summary')
      .set('Authorization', authHeader);

    // then
    expect(res.body).toHaveProperty('totalIncome');
    expect(res.body).toHaveProperty('totalEssential');
    expect(res.body).toHaveProperty('totalNonEssential');
    expect(res.body).toHaveProperty('balance');
    expect(res.body).toHaveProperty('transactionCount');
  });
});
