import { Response } from 'express';
import { AuthRequest } from '../middlewares/authenticate';
import * as cycleService from '../services/billing-cycle.service';

export async function listCycles(req: AuthRequest, res: Response): Promise<void> {
  const cycles = await cycleService.getCycles(req.userId!);
  res.json(cycles);
}

export async function getCurrentCycle(req: AuthRequest, res: Response): Promise<void> {
  const cycle = await cycleService.getCurrentCycle(req.userId!);
  if (!cycle) {
    res.status(404).json({ error: 'No active cycle found' });
    return;
  }
  res.json(cycle);
}

export async function getCycleById(req: AuthRequest, res: Response): Promise<void> {
  const cycle = await cycleService.getCycleById(req.userId!, String(req.params.id));
  if (!cycle) {
    res.status(404).json({ error: 'Cycle not found' });
    return;
  }
  res.json(cycle);
}

export async function createCycle(req: AuthRequest, res: Response): Promise<void> {
  const parsed = cycleService.createCycleSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const cycle = await cycleService.createCycle(req.userId!, parsed.data);
  res.status(201).json(cycle);
}

export async function getCycleSummary(req: AuthRequest, res: Response): Promise<void> {
  const summary = await cycleService.getCycleSummary(req.userId!, String(req.params.id));
  if (!summary) {
    res.status(404).json({ error: 'Cycle not found' });
    return;
  }
  res.json(summary);
}
