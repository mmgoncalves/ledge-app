import express from 'express';
import healthRouter from './routes/health';
import authRouter from './routes/auth';
import cyclesRouter from './routes/billing-cycles';

const app = express();

app.use(express.json());

// Routes
app.use('/health', healthRouter);
app.use('/auth', authRouter);
app.use('/cycles', cyclesRouter);

export default app;
