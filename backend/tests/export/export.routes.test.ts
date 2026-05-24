import request from 'supertest';
import jwt from 'jsonwebtoken';
import app from '../../src/app';
import * as exportService from '../../src/services/export.service';

jest.mock('../../src/services/export.service', () => ({
  ...jest.requireActual('../../src/services/export.service'),
  getUserData: jest.fn(),
}));

const mockExportService = exportService as jest.Mocked<typeof exportService>;

const userId = 'user-uuid-1';
const token = jwt.sign({ userId }, process.env.JWT_SECRET ?? 'test-jwt-secret');
const authHeader = `Bearer ${token}`;

const fakeCycles = [
  {
    id: 'cycle-1',
    startDate: new Date('2026-05-01'),
    endDate: new Date('2026-05-31'),
    cutDay: 10,
    createdAt: new Date('2026-05-01'),
    transactions: [
      {
        id: 'tx-1',
        description: 'Mercado',
        amount: 15000,
        date: new Date('2026-05-10'),
        type: 'ESSENTIAL',
        paymentMethod: 'PIX',
        installmentIndex: null,
        installmentTotal: null,
        createdAt: new Date('2026-05-10'),
      },
    ],
  },
];

describe('GET /export', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 401 without a token', async () => {
    const res = await request(app).get('/export?format=json');
    expect(res.status).toBe(401);
    expect(mockExportService.getUserData).not.toHaveBeenCalled();
  });

  it('returns 400 for an invalid format', async () => {
    const res = await request(app)
      .get('/export?format=xml')
      .set('Authorization', authHeader);
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/format/i);
    expect(mockExportService.getUserData).not.toHaveBeenCalled();
  });

  it('returns 400 when format param is missing', async () => {
    const res = await request(app)
      .get('/export')
      .set('Authorization', authHeader);
    expect(res.status).toBe(400);
    expect(mockExportService.getUserData).not.toHaveBeenCalled();
  });

  describe('format=json', () => {
    it('returns 200 with Content-Type application/json', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      const res = await request(app)
        .get('/export?format=json')
        .set('Authorization', authHeader);

      // then
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toMatch(/application\/json/);
    });

    it('sets Content-Disposition attachment header for download', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      const res = await request(app)
        .get('/export?format=json')
        .set('Authorization', authHeader);

      // then
      expect(res.headers['content-disposition']).toMatch(/attachment/);
      expect(res.headers['content-disposition']).toMatch(/ledge-export\.json/);
    });

    it('returns data only for the authenticated user', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      await request(app).get('/export?format=json').set('Authorization', authHeader);

      // then
      expect(mockExportService.getUserData).toHaveBeenCalledWith(userId);
    });

    it('returns valid parseable JSON body', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      const res = await request(app)
        .get('/export?format=json')
        .set('Authorization', authHeader);

      // then
      expect(() => JSON.parse(res.text)).not.toThrow();
    });
  });

  describe('format=csv', () => {
    it('returns 200 with Content-Type text/csv', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      const res = await request(app)
        .get('/export?format=csv')
        .set('Authorization', authHeader);

      // then
      expect(res.status).toBe(200);
      expect(res.headers['content-type']).toMatch(/text\/csv/);
    });

    it('sets Content-Disposition attachment header for download', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      const res = await request(app)
        .get('/export?format=csv')
        .set('Authorization', authHeader);

      // then
      expect(res.headers['content-disposition']).toMatch(/attachment/);
      expect(res.headers['content-disposition']).toMatch(/ledge-export\.csv/);
    });

    it('returns data only for the authenticated user', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      await request(app).get('/export?format=csv').set('Authorization', authHeader);

      // then
      expect(mockExportService.getUserData).toHaveBeenCalledWith(userId);
    });

    it('response body starts with the CSV header row', async () => {
      // given
      mockExportService.getUserData.mockResolvedValue(fakeCycles);

      // when
      const res = await request(app)
        .get('/export?format=csv')
        .set('Authorization', authHeader);

      // then
      expect(res.text).toMatch(/^cycle_id,cycle_start_date/);
    });
  });
});
