import { Response } from 'express';
import { AuthRequest } from '../middlewares/authenticate';
import * as txService from '../services/transaction.service';

export async function listTransactions(req: AuthRequest, res: Response): Promise<void> {
  const transactions = await txService.getTransactions(req.userId!, String(req.params.cycleId));
  if (transactions === null) {
    res.status(404).json({ error: 'Cycle not found' });
    return;
  }
  res.json(transactions);
}

export async function createTransaction(req: AuthRequest, res: Response): Promise<void> {
  const parsed = txService.createTransactionSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const transactions = await txService.createTransaction(
    req.userId!,
    String(req.params.cycleId),
    parsed.data,
  );

  if (transactions === null) {
    res.status(404).json({ error: 'Cycle not found' });
    return;
  }

  res.status(201).json(transactions);
}

export async function updateTransaction(req: AuthRequest, res: Response): Promise<void> {
  const parsed = txService.updateTransactionSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const transaction = await txService.updateTransaction(
    req.userId!,
    String(req.params.id),
    parsed.data,
  );

  if (transaction === null) {
    res.status(404).json({ error: 'Transaction not found' });
    return;
  }

  res.json(transaction);
}

export async function deleteTransaction(req: AuthRequest, res: Response): Promise<void> {
  const result = await txService.deleteTransaction(req.userId!, String(req.params.id));
  if (result === null) {
    res.status(404).json({ error: 'Transaction not found' });
    return;
  }
  res.status(204).send();
}
