import { Router } from 'express';
import { authenticate } from '../middlewares/authenticate';
import {
  listCycles,
  getCurrentCycle,
  getCycleById,
  createCycle,
} from '../controllers/billing-cycle.controller';

const router = Router();

router.use(authenticate);

router.get('/', listCycles);
router.get('/current', getCurrentCycle);
router.get('/:id', getCycleById);
router.post('/', createCycle);

export default router;
