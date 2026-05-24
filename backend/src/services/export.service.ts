import prisma from '../lib/prisma';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface ExportTransaction {
  id: string;
  description: string;
  amount: number;
  date: Date;
  type: string;
  paymentMethod: string;
  installmentIndex: number | null;
  installmentTotal: number | null;
  createdAt: Date;
}

export interface ExportCycle {
  id: string;
  startDate: Date;
  endDate: Date;
  cutDay: number;
  createdAt: Date;
  transactions: ExportTransaction[];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function escapeCsvField(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

const CSV_HEADERS = [
  'cycle_id',
  'cycle_start_date',
  'cycle_end_date',
  'cut_day',
  'transaction_id',
  'description',
  'amount',
  'date',
  'type',
  'payment_method',
  'installment_index',
  'installment_total',
] as const;

// ─── Service ──────────────────────────────────────────────────────────────────

export async function getUserData(userId: string): Promise<ExportCycle[]> {
  const cycles = await prisma.billingCycle.findMany({
    where: { userId },
    orderBy: { startDate: 'asc' },
    include: {
      transactions: {
        where: { userId },
        orderBy: { date: 'asc' },
      },
    },
  });

  return cycles;
}

export function toJson(cycles: ExportCycle[]): string {
  return JSON.stringify(cycles, null, 2);
}

export function toCsv(cycles: ExportCycle[]): string {
  const rows: string[] = [CSV_HEADERS.join(',')];

  for (const cycle of cycles) {
    if (cycle.transactions.length === 0) {
      // Emit a row for the cycle with no transaction data
      rows.push(
        [
          cycle.id,
          cycle.startDate.toISOString(),
          cycle.endDate.toISOString(),
          cycle.cutDay,
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]
          .map(escapeCsvField)
          .join(','),
      );
    } else {
      for (const tx of cycle.transactions) {
        rows.push(
          [
            cycle.id,
            cycle.startDate.toISOString(),
            cycle.endDate.toISOString(),
            cycle.cutDay,
            tx.id,
            tx.description,
            tx.amount,
            tx.date.toISOString(),
            tx.type,
            tx.paymentMethod,
            tx.installmentIndex,
            tx.installmentTotal,
          ]
            .map(escapeCsvField)
            .join(','),
        );
      }
    }
  }

  return rows.join('\n');
}
