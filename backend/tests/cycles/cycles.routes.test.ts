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
}));

const mockCycleService = cycleService as jest.Mocked<typeof cycleService>;

const userId = 'user-uuid-1';
const token = jwt.sign({ userId }, process.env.JWT_SECRET ?? 'test-jwt-secret');
const authHeader = `Bearer ${token}`;

const fakeCycle = {
  id: 'cycle-uuid-1',
  userId,
  startDate: new Date('2026-05-01'),
  endDate: new Date('2026-05-31'),
  cutDay: 10,
  createdAt: new Date('2026-05-01'),
};

const fakeCycleWithTransactions = {
  ...fakeCycle,
  transactions: [],
};

describe('GET /cycles', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with list of cycles', async () => {
    // given
    mockCycleService.getCycles.mockResolvedValue([fakeCycle]);

    // when
    const res = await request(app).get('/cycles').set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(mockCycleService.getCycles).toHaveBeenCalledWith(userId);
  });

  it('returns 401 when no token is provided', async () => {
    // when
    const res = await request(app).get('/cycles');

    // then
    expect(res.status).toBe(401);
    expect(mockCycleService.getCycles).not.toHaveBeenCalled();
  });
});

describe('GET /cycles/current', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with the current cycle when one exists', async () => {
    // given
    mockCycleService.getCurrentCycle.mockResolvedValue(fakeCycleWithTransactions);

    // when
    const res = await request(app).get('/cycles/current').set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(mockCycleService.getCurrentCycle).toHaveBeenCalledWith(userId);
  });

  it('returns 404 when there is no active cycle', async () => {
    // given
    mockCycleService.getCurrentCycle.mockResolvedValue(null);

    // when
    const res = await request(app).get('/cycles/current').set('Authorization', authHeader);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('No active cycle found');
  });

  it('returns 401 when no token is provided', async () => {
    // when
    const res = await request(app).get('/cycles/current');

    // then
    expect(res.status).toBe(401);
  });
});

describe('GET /cycles/:id', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with the cycle when found', async () => {
    // given
    mockCycleService.getCycleById.mockResolvedValue(fakeCycleWithTransactions);

    // when
    const res = await request(app).get('/cycles/cycle-uuid-1').set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(mockCycleService.getCycleById).toHaveBeenCalledWith(userId, 'cycle-uuid-1');
  });

  it('returns 404 when cycle does not exist', async () => {
    // given
    mockCycleService.getCycleById.mockResolvedValue(null);

    // when
    const res = await request(app).get('/cycles/nonexistent-id').set('Authorization', authHeader);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Cycle not found');
  });

  it('returns 401 when no token is provided', async () => {
    // when
    const res = await request(app).get('/cycles/cycle-uuid-1');

    // then
    expect(res.status).toBe(401);
  });
});

describe('POST /cycles', () => {
  beforeEach(() => jest.clearAllMocks());

  const validBody = { startDate: '2026-06-01', endDate: '2026-06-30', cutDay: 10 };

  it('returns 201 with created cycle for valid input', async () => {
    // given
    mockCycleService.createCycle.mockResolvedValue(fakeCycle);

    // when
    const res = await request(app).post('/cycles').set('Authorization', authHeader).send(validBody);

    // then
    expect(res.status).toBe(201);
    expect(mockCycleService.createCycle).toHaveBeenCalledWith(userId, validBody);
  });

  it('returns 400 for missing startDate', async () => {
    // when
    const res = await request(app)
      .post('/cycles')
      .set('Authorization', authHeader)
      .send({ endDate: '2026-06-30', cutDay: 10 });

    // then
    expect(res.status).toBe(400);
    expect(mockCycleService.createCycle).not.toHaveBeenCalled();
  });

  it('returns 400 for cutDay out of range (0)', async () => {
    // when
    const res = await request(app)
      .post('/cycles')
      .set('Authorization', authHeader)
      .send({ startDate: '2026-06-01', endDate: '2026-06-30', cutDay: 0 });

    // then
    expect(res.status).toBe(400);
    expect(mockCycleService.createCycle).not.toHaveBeenCalled();
  });

  it('returns 400 for cutDay out of range (32)', async () => {
    // when
    const res = await request(app)
      .post('/cycles')
      .set('Authorization', authHeader)
      .send({ startDate: '2026-06-01', endDate: '2026-06-30', cutDay: 32 });

    // then
    expect(res.status).toBe(400);
    expect(mockCycleService.createCycle).not.toHaveBeenCalled();
  });

  it('returns 400 for invalid date format', async () => {
    // when
    const res = await request(app)
      .post('/cycles')
      .set('Authorization', authHeader)
      .send({ startDate: '01/06/2026', endDate: '2026-06-30', cutDay: 10 });

    // then
    expect(res.status).toBe(400);
    expect(mockCycleService.createCycle).not.toHaveBeenCalled();
  });

  it('returns 401 when no token is provided', async () => {
    // when
    const res = await request(app).post('/cycles').send(validBody);

    // then
    expect(res.status).toBe(401);
    expect(mockCycleService.createCycle).not.toHaveBeenCalled();
  });
});
