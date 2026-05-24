import { Router } from 'express';
import { authenticate } from '../middlewares/authenticate';
import { updateTransaction, deleteTransaction } from '../controllers/transaction.controller';

const router = Router();

router.use(authenticate);

router.put('/:id', updateTransaction);
router.delete('/:id', deleteTransaction);

export default router;
