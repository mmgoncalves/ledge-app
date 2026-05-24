import { Router } from 'express';
import { authenticate } from '../middlewares/authenticate';
import { exportData } from '../controllers/export.controller';

const router = Router();

router.use(authenticate);

router.get('/', exportData);

export default router;
