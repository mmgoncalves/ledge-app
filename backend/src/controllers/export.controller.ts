import { Response } from 'express';
import { AuthRequest } from '../middlewares/authenticate';
import * as exportService from '../services/export.service';

export async function exportData(req: AuthRequest, res: Response): Promise<void> {
  const format = req.query.format as string;

  if (format !== 'json' && format !== 'csv') {
    res.status(400).json({ error: 'Invalid format. Use ?format=json or ?format=csv' });
    return;
  }

  const cycles = await exportService.getUserData(req.userId!);

  if (format === 'csv') {
    const csv = exportService.toCsv(cycles);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="ledge-export.csv"');
    res.send(csv);
    return;
  }

  const json = exportService.toJson(cycles);
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Disposition', 'attachment; filename="ledge-export.json"');
  res.send(json);
}
