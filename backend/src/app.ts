import express from 'express';
import healthRouter from './routes/health';
import authRouter from './routes/auth';
import cyclesRouter from './routes/billing-cycles';
import transactionsRouter from './routes/transactions';
import exportRouter from './routes/export';

const app = express();

app.use(express.json());

// Routes
app.use('/health', healthRouter);
app.use('/auth', authRouter);
app.use('/cycles', cyclesRouter);
app.use('/transactions', transactionsRouter);
app.use('/export', exportRouter);

export default app;
