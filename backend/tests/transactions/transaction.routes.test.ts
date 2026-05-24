import request from 'supertest';
import jwt from 'jsonwebtoken';
import { TransactionType, PaymentMethod } from '@prisma/client';
import app from '../../src/app';
import * as txService from '../../src/services/transaction.service';

jest.mock('../../src/services/transaction.service', () => ({
  ...jest.requireActual('../../src/services/transaction.service'),
  getTransactions: jest.fn(),
  createTransaction: jest.fn(),
  updateTransaction: jest.fn(),
  deleteTransaction: jest.fn(),
}));

const mockTxService = txService as jest.Mocked<typeof txService>;

const userId = 'user-uuid-1';
const token = jwt.sign({ userId }, process.env.JWT_SECRET ?? 'test-jwt-secret');
const authHeader = `Bearer ${token}`;

const fakeTx = {
  id: 'tx-uuid-1',
  billingCycleId: 'cycle-uuid-1',
  userId,
  description: 'Mercado',
  amount: 15000,
  date: new Date('2026-05-10'),
  type: 'ESSENTIAL' as TransactionType,
  paymentMethod: 'PIX' as PaymentMethod,
  installmentIndex: null,
  installmentTotal: null,
  createdAt: new Date('2026-05-10'),
  updatedAt: new Date('2026-05-10'),
};

const validCreateBody = {
  description: 'Mercado',
  amount: 15000,
  date: '2026-05-10',
  type: 'ESSENTIAL',
  paymentMethod: 'PIX',
  installmentTotal: 1,
};

// ─── GET /cycles/:cycleId/transactions ────────────────────────────────────────

describe('GET /cycles/:cycleId/transactions', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with transactions list', async () => {
    // given
    mockTxService.getTransactions.mockResolvedValue([fakeTx]);

    // when
    const res = await request(app)
      .get('/cycles/cycle-uuid-1/transactions')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(mockTxService.getTransactions).toHaveBeenCalledWith(userId, 'cycle-uuid-1');
  });

  it('returns 404 when cycle does not exist', async () => {
    // given
    mockTxService.getTransactions.mockResolvedValue(null);

    // when
    const res = await request(app)
      .get('/cycles/nonexistent/transactions')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Cycle not found');
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/cycles/cycle-uuid-1/transactions');
    expect(res.status).toBe(401);
  });
});

// ─── POST /cycles/:cycleId/transactions ───────────────────────────────────────

describe('POST /cycles/:cycleId/transactions', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 201 with created transactions for a simple transaction', async () => {
    // given
    mockTxService.createTransaction.mockResolvedValue([fakeTx]);

    // when
    const res = await request(app)
      .post('/cycles/cycle-uuid-1/transactions')
      .set('Authorization', authHeader)
      .send(validCreateBody);

    // then
    expect(res.status).toBe(201);
    expect(res.body).toHaveLength(1);
    expect(mockTxService.createTransaction).toHaveBeenCalledWith(
      userId,
      'cycle-uuid-1',
      expect.objectContaining({ description: 'Mercado', installmentTotal: 1 }),
    );
  });

  it('returns 201 with 3 transactions for installmentTotal = 3', async () => {
    // given
    const installments = [1, 2, 3].map(i => ({
      ...fakeTx,
      id: `tx-uuid-${i}`,
      description: `Notebook ${i}/3`,
      installmentIndex: i as number | null,
      installmentTotal: 3 as number | null,
    }));
    mockTxService.createTransaction.mockResolvedValue(installments);

    // when
    const res = await request(app)
      .post('/cycles/cycle-uuid-1/transactions')
      .set('Authorization', authHeader)
      .send({ ...validCreateBody, description: 'Notebook', installmentTotal: 3 });

    // then
    expect(res.status).toBe(201);
    expect(res.body).toHaveLength(3);
  });

  it('returns 404 when cycle does not exist', async () => {
    // given
    mockTxService.createTransaction.mockResolvedValue(null);

    // when
    const res = await request(app)
      .post('/cycles/nonexistent/transactions')
      .set('Authorization', authHeader)
      .send(validCreateBody);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Cycle not found');
  });

  it('returns 400 for missing description', async () => {
    // when
    const res = await request(app)
      .post('/cycles/cycle-uuid-1/transactions')
      .set('Authorization', authHeader)
      .send({ ...validCreateBody, description: '' });

    // then
    expect(res.status).toBe(400);
    expect(mockTxService.createTransaction).not.toHaveBeenCalled();
  });

  it('returns 400 for negative amount', async () => {
    // when
    const res = await request(app)
      .post('/cycles/cycle-uuid-1/transactions')
      .set('Authorization', authHeader)
      .send({ ...validCreateBody, amount: -100 });

    // then
    expect(res.status).toBe(400);
    expect(mockTxService.createTransaction).not.toHaveBeenCalled();
  });

  it('returns 400 for invalid type', async () => {
    // when
    const res = await request(app)
      .post('/cycles/cycle-uuid-1/transactions')
      .set('Authorization', authHeader)
      .send({ ...validCreateBody, type: 'INVALID' });

    // then
    expect(res.status).toBe(400);
    expect(mockTxService.createTransaction).not.toHaveBeenCalled();
  });

  it('returns 401 without token', async () => {
    const res = await request(app)
      .post('/cycles/cycle-uuid-1/transactions')
      .send(validCreateBody);
    expect(res.status).toBe(401);
  });
});

// ─── PUT /transactions/:id ────────────────────────────────────────────────────

describe('PUT /transactions/:id', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with updated transaction', async () => {
    // given
    mockTxService.updateTransaction.mockResolvedValue({ ...fakeTx, description: 'Supermercado' });

    // when
    const res = await request(app)
      .put('/transactions/tx-uuid-1')
      .set('Authorization', authHeader)
      .send({ description: 'Supermercado' });

    // then
    expect(res.status).toBe(200);
    expect(mockTxService.updateTransaction).toHaveBeenCalledWith(
      userId,
      'tx-uuid-1',
      { description: 'Supermercado' },
    );
  });

  it('returns 404 when transaction does not exist', async () => {
    // given
    mockTxService.updateTransaction.mockResolvedValue(null);

    // when
    const res = await request(app)
      .put('/transactions/nonexistent')
      .set('Authorization', authHeader)
      .send({ description: 'X' });

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Transaction not found');
  });

  it('returns 400 for invalid amount', async () => {
    // when
    const res = await request(app)
      .put('/transactions/tx-uuid-1')
      .set('Authorization', authHeader)
      .send({ amount: -50 });

    // then
    expect(res.status).toBe(400);
    expect(mockTxService.updateTransaction).not.toHaveBeenCalled();
  });

  it('returns 401 without token', async () => {
    const res = await request(app)
      .put('/transactions/tx-uuid-1')
      .send({ description: 'X' });
    expect(res.status).toBe(401);
  });
});

// ─── DELETE /transactions/:id ─────────────────────────────────────────────────

describe('DELETE /transactions/:id', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 204 on successful deletion', async () => {
    // given
    mockTxService.deleteTransaction.mockResolvedValue(true);

    // when
    const res = await request(app)
      .delete('/transactions/tx-uuid-1')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(204);
    expect(mockTxService.deleteTransaction).toHaveBeenCalledWith(userId, 'tx-uuid-1');
  });

  it('returns 404 when transaction does not exist', async () => {
    // given
    mockTxService.deleteTransaction.mockResolvedValue(null);

    // when
    const res = await request(app)
      .delete('/transactions/nonexistent')
      .set('Authorization', authHeader);

    // then
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Transaction not found');
  });

  it('returns 401 without token', async () => {
    const res = await request(app).delete('/transactions/tx-uuid-1');
    expect(res.status).toBe(401);
  });
});
