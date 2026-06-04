import { Router } from 'express';
import { authenticate } from '../middlewares/authenticate';
import {
  listCycles,
  getCurrentCycle,
  getCycleById,
  createCycle,
  getCycleSummary,
  getCycleNeighbors,
} from '../controllers/billing-cycle.controller';
import { listTransactions, createTransaction } from '../controllers/transaction.controller';

const router = Router();

router.use(authenticate);

router.get('/', listCycles);
router.get('/current', getCurrentCycle);
router.get('/:id/summary', getCycleSummary);
router.get('/:id/neighbors', getCycleNeighbors);
router.get('/:id', getCycleById);
router.post('/', createCycle);

// Transactions nested under a cycle
router.get('/:cycleId/transactions', listTransactions);
router.post('/:cycleId/transactions', createTransaction);

export default router;
