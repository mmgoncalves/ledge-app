import { register, login } from '../../src/services/auth.service';
import prisma from '../../src/lib/prisma';

// Mock the prisma singleton
jest.mock('../../src/lib/prisma', () => ({
  __esModule: true,
  default: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
  },
}));

const mockPrisma = prisma as jest.Mocked<typeof prisma>;

describe('AuthService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '7d';
  });

  // ─── register ──────────────────────────────────────────────────────────────

  describe('register', () => {
    it('creates a user and returns id and email', async () => {
      // given
      (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue(null);
      (mockPrisma.user.create as jest.Mock).mockResolvedValue({
        id: 'uuid-1',
        email: 'user@test.com',
        passwordHash: 'hash',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // when
      const result = await register({ email: 'user@test.com', password: 'senha123' });

      // then
      expect(result).toEqual({ id: 'uuid-1', email: 'user@test.com' });
      expect(mockPrisma.user.create).toHaveBeenCalledTimes(1);
    });

    it('throws EMAIL_TAKEN when email is already in use', async () => {
      // given
      (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue({
        id: 'uuid-1',
        email: 'user@test.com',
      });

      // when / then
      await expect(register({ email: 'user@test.com', password: 'senha123' })).rejects.toMatchObject({
        code: 'EMAIL_TAKEN',
      });
      expect(mockPrisma.user.create).not.toHaveBeenCalled();
    });

    it('hashes the password before storing', async () => {
      // given
      (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue(null);
      (mockPrisma.user.create as jest.Mock).mockImplementation(async ({ data }) => ({
        id: 'uuid-1',
        email: data.email,
        passwordHash: data.passwordHash,
        createdAt: new Date(),
        updatedAt: new Date(),
      }));

      // when
      await register({ email: 'user@test.com', password: 'senha123' });
      const createCall = (mockPrisma.user.create as jest.Mock).mock.calls[0][0];

      // then
      expect(createCall.data.passwordHash).not.toBe('senha123');
      expect(createCall.data.passwordHash).toMatch(/^\$2b\$/); // bcrypt hash prefix
    });
  });

  // ─── login ─────────────────────────────────────────────────────────────────

  describe('login', () => {
    it('returns a JWT token for valid credentials', async () => {
      // given
      const bcrypt = await import('bcrypt');
      const hash = await bcrypt.hash('senha123', 12);
      (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue({
        id: 'uuid-1',
        email: 'user@test.com',
        passwordHash: hash,
      });

      // when
      const result = await login({ email: 'user@test.com', password: 'senha123' });

      // then
      expect(result.token).toBeDefined();
      expect(typeof result.token).toBe('string');
    });

    it('throws for non-existent user', async () => {
      // given
      (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue(null);

      // when / then
      await expect(login({ email: 'no@one.com', password: 'senha123' })).rejects.toThrow('Invalid credentials');
    });

    it('throws for wrong password', async () => {
      // given
      const bcrypt = await import('bcrypt');
      const hash = await bcrypt.hash('correctpassword', 12);
      (mockPrisma.user.findUnique as jest.Mock).mockResolvedValue({
        id: 'uuid-1',
        email: 'user@test.com',
        passwordHash: hash,
      });

      // when / then
      await expect(login({ email: 'user@test.com', password: 'wrongpassword' })).rejects.toThrow(
        'Invalid credentials',
      );
    });
  });
});
