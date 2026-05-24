import { Response } from 'express';
import jwt from 'jsonwebtoken';
import { authenticate, AuthRequest } from '../../src/middlewares/authenticate';

const JWT_SECRET = 'test-secret';

function mockReqRes(authHeader?: string): {
  req: Partial<AuthRequest>;
  res: Partial<Response>;
  next: jest.Mock;
} {
  const req: Partial<AuthRequest> = {
    headers: authHeader ? { authorization: authHeader } : {},
  };
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  const next = jest.fn();
  return { req, res, next };
}

describe('authenticate middleware', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = JWT_SECRET;
  });

  it('calls next and sets userId for a valid token', () => {
    // given
    const token = jwt.sign({ userId: 'uuid-1' }, JWT_SECRET);
    const { req, res, next } = mockReqRes(`Bearer ${token}`);

    // when
    authenticate(req as AuthRequest, res as Response, next);

    // then
    expect(next).toHaveBeenCalledTimes(1);
    expect(req.userId).toBe('uuid-1');
  });

  it('returns 401 when authorization header is missing', () => {
    // given
    const { req, res, next } = mockReqRes();

    // when
    authenticate(req as AuthRequest, res as Response, next);

    // then
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(401);
  });

  it('returns 401 for an invalid token', () => {
    // given
    const { req, res, next } = mockReqRes('Bearer invalid.token.here');

    // when
    authenticate(req as AuthRequest, res as Response, next);

    // then
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(401);
  });

  it('returns 401 when header does not start with Bearer', () => {
    // given
    const { req, res, next } = mockReqRes('Token abc123');

    // when
    authenticate(req as AuthRequest, res as Response, next);

    // then
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(401);
  });
});
