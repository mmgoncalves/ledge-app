import { toJson, toCsv, ExportCycle } from '../../src/services/export.service';

const cycle1: ExportCycle = {
  id: 'cycle-1',
  startDate: new Date('2026-05-01T00:00:00.000Z'),
  endDate: new Date('2026-05-31T00:00:00.000Z'),
  cutDay: 10,
  createdAt: new Date('2026-05-01T00:00:00.000Z'),
  transactions: [
    {
      id: 'tx-1',
      description: 'Mercado',
      amount: 15000,
      date: new Date('2026-05-10T00:00:00.000Z'),
      type: 'ESSENTIAL',
      paymentMethod: 'PIX',
      installmentIndex: null,
      installmentTotal: null,
      createdAt: new Date('2026-05-10T00:00:00.000Z'),
    },
    {
      id: 'tx-2',
      description: 'Notebook 1/3',
      amount: 100000,
      date: new Date('2026-05-15T00:00:00.000Z'),
      type: 'NON_ESSENTIAL',
      paymentMethod: 'CREDIT_CARD',
      installmentIndex: 1,
      installmentTotal: 3,
      createdAt: new Date('2026-05-15T00:00:00.000Z'),
    },
  ],
};

const cycle2: ExportCycle = {
  id: 'cycle-2',
  startDate: new Date('2026-06-01T00:00:00.000Z'),
  endDate: new Date('2026-06-30T00:00:00.000Z'),
  cutDay: 10,
  createdAt: new Date('2026-06-01T00:00:00.000Z'),
  transactions: [],
};

// ─── toJson ───────────────────────────────────────────────────────────────────

describe('toJson', () => {
  it('returns valid JSON string', () => {
    const result = toJson([cycle1]);
    expect(() => JSON.parse(result)).not.toThrow();
  });

  it('includes all cycles and their transactions', () => {
    const result = JSON.parse(toJson([cycle1, cycle2]));
    expect(result).toHaveLength(2);
    expect(result[0].transactions).toHaveLength(2);
    expect(result[1].transactions).toHaveLength(0);
  });

  it('does not include data from other cycles', () => {
    const result = JSON.parse(toJson([cycle1]));
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('cycle-1');
  });
});

// ─── toCsv ────────────────────────────────────────────────────────────────────

describe('toCsv', () => {
  it('starts with the correct header row', () => {
    const result = toCsv([cycle1]);
    const lines = result.split('\n');
    expect(lines[0]).toBe(
      'cycle_id,cycle_start_date,cycle_end_date,cut_day,transaction_id,description,amount,date,type,payment_method,installment_index,installment_total',
    );
  });

  it('emits one row per transaction', () => {
    const result = toCsv([cycle1]);
    const lines = result.split('\n');
    // header + 2 transactions
    expect(lines).toHaveLength(3);
  });

  it('emits one row for a cycle with no transactions', () => {
    const result = toCsv([cycle2]);
    const lines = result.split('\n');
    // header + 1 empty row
    expect(lines).toHaveLength(2);
    expect(lines[1]).toContain('cycle-2');
  });

  it('includes cycle and transaction data on each row', () => {
    const result = toCsv([cycle1]);
    const lines = result.split('\n');
    expect(lines[1]).toContain('cycle-1');
    expect(lines[1]).toContain('tx-1');
    expect(lines[1]).toContain('Mercado');
    expect(lines[1]).toContain('15000');
    expect(lines[1]).toContain('ESSENTIAL');
    expect(lines[1]).toContain('PIX');
  });

  it('escapes description fields containing commas', () => {
    const cycleWithComma: ExportCycle = {
      ...cycle1,
      transactions: [
        {
          ...cycle1.transactions[0],
          description: 'Café, pão e leite',
        },
      ],
    };

    const result = toCsv([cycleWithComma]);
    expect(result).toContain('"Café, pão e leite"');
  });

  it('escapes description fields containing double quotes', () => {
    const cycleWithQuote: ExportCycle = {
      ...cycle1,
      transactions: [
        {
          ...cycle1.transactions[0],
          description: 'Item com "aspas"',
        },
      ],
    };

    const result = toCsv([cycleWithQuote]);
    expect(result).toContain('"Item com ""aspas"""');
  });

  it('includes installment data when present', () => {
    const result = toCsv([cycle1]);
    const lines = result.split('\n');
    // tx-2 is installment 1/3
    expect(lines[2]).toContain('1');
    expect(lines[2]).toContain('3');
    expect(lines[2]).toContain('Notebook 1/3');
  });
});
