import request from 'supertest';
import jwt from 'jsonwebtoken';
import app from '../../src/app';
import * as cycleService from '../../src/services/billing-cycle.service';

jest.mock('../../src/services/billing-cycle.service', () => ({
  ...jest.requireActual('../../src/services/billing-cycle.service'),
  getCycleNeighbors: jest.fn(),
}));

const mockCycleService = cycleService as jest.Mocked<typeof cycleService>;

const userId = 'user-uuid-1';
const token = jwt.sign({ userId }, process.env.JWT_SECRET ?? 'test-jwt-secret');
const authHeader = `Bearer ${token}`;

const fakeCycle = (id: string, startDate: string) => ({
  id,
  userId,
  startDate: new Date(startDate),
  endDate: new Date(startDate),
  cutDay: 10,
  createdAt: new Date(startDate),
});

describe('GET /cycles/:id/neighbors', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with previous and next when cycle is in the middle', async () => {
    // given
    mockCycleService.getCycleNeighbors.mockResolvedValue({
      previous: fakeCycle('cycle-may', '2026-05-01'),
      next: fakeCycle('cycle-july', '2026-07-01'),
    });

    // when
    const res = await request(app)
      .get('/cycles/cycle-june/neighbors')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body.previous.id).toBe('cycle-may');
    expect(res.body.next.id).toBe('cycle-july');
    expect(mockCycleService.getCycleNeighbors).toHaveBeenCalledWith(userId, 'cycle-june');
  });

  it('returns 200 with previous=null when cycle is the oldest', async () => {
    // given
    mockCycleService.getCycleNeighbors.mockResolvedValue({
      previous: null,
      next: fakeCycle('cycle-july', '2026-07-01'),
    });

    // when
    const res = await request(app)
      .get('/cycles/cycle-june/neighbors')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body.previous).toBeNull();
    expect(res.body.next.id).toBe('cycle-july');
  });

  it('returns 200 with next=null when cycle is the most recent', async () => {
    // given
    mockCycleService.getCycleNeighbors.mockResolvedValue({
      previous: fakeCycle('cycle-may', '2026-05-01'),
      next: null,
    });

    // when
    const res = await request(app)
      .get('/cycles/cycle-june/neighbors')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body.previous.id).toBe('cycle-may');
    expect(res.body.next).toBeNull();
  });

  it('returns 200 with both null when there is only one cycle', async () => {
    // given
    mockCycleService.getCycleNeighbors.mockResolvedValue({ previous: null, next: null });

    // when
    const res = await request(app)
      .get('/cycles/cycle-june/neighbors')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ previous: null, next: null });
  });

  it('returns 404 when cycle does not exist or does not belong to user', async () => {
    // given
    mockCycleService.getCycleNeighbors.mockResolvedValue(null);

    // when
    const res = await request(app)
      .get('/cycles/nonexistent-id/neighbors')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Cycle not found');
  });

  it('returns 401 when no token is provided', async () => {
    // when
    const res = await request(app).get('/cycles/cycle-june/neighbors');

    // then
    expect(res.status).toBe(401);
    expect(mockCycleService.getCycleNeighbors).not.toHaveBeenCalled();
  });
});
