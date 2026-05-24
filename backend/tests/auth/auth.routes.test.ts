import request from 'supertest';
import app from '../../src/app';
import * as authService from '../../src/services/auth.service';

jest.mock('../../src/services/auth.service');

const mockAuthService = authService as jest.Mocked<typeof authService>;

describe('POST /auth/register', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 201 with user data for valid input', async () => {
    // given
    mockAuthService.register.mockResolvedValue({ id: 'uuid-1', email: 'user@test.com' });

    // when
    const res = await request(app).post('/auth/register').send({ email: 'user@test.com', password: 'senha123' });

    // then
    expect(res.status).toBe(201);
    expect(res.body).toEqual({ id: 'uuid-1', email: 'user@test.com' });
  });

  it('returns 409 when email is already in use', async () => {
    // given
    const err = Object.assign(new Error('Email already in use'), { code: 'EMAIL_TAKEN' });
    mockAuthService.register.mockRejectedValue(err);

    // when
    const res = await request(app).post('/auth/register').send({ email: 'user@test.com', password: 'senha123' });

    // then
    expect(res.status).toBe(409);
    expect(res.body.error).toBe('Email already in use');
  });

  it('returns 400 for invalid email', async () => {
    // when
    const res = await request(app).post('/auth/register').send({ email: 'not-an-email', password: 'senha123' });

    // then
    expect(res.status).toBe(400);
    expect(mockAuthService.register).not.toHaveBeenCalled();
  });

  it('returns 400 for password shorter than 6 characters', async () => {
    // when
    const res = await request(app).post('/auth/register').send({ email: 'user@test.com', password: '123' });

    // then
    expect(res.status).toBe(400);
    expect(mockAuthService.register).not.toHaveBeenCalled();
  });
});

describe('POST /auth/login', () => {
  beforeEach(() => jest.clearAllMocks());

  it('returns 200 with JWT token for valid credentials', async () => {
    // given
    mockAuthService.login.mockResolvedValue({ token: 'jwt.token.here' });

    // when
    const res = await request(app).post('/auth/login').send({ email: 'user@test.com', password: 'senha123' });

    // then
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ token: 'jwt.token.here' });
  });

  it('returns 401 for invalid credentials', async () => {
    // given
    mockAuthService.login.mockRejectedValue(new Error('Invalid credentials'));

    // when
    const res = await request(app).post('/auth/login').send({ email: 'user@test.com', password: 'wrong' });

    // then
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('Invalid credentials');
  });

  it('returns 400 for missing fields', async () => {
    // when
    const res = await request(app).post('/auth/login').send({ email: 'user@test.com' });

    // then
    expect(res.status).toBe(400);
    expect(mockAuthService.login).not.toHaveBeenCalled();
  });
});

