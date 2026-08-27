import express, { type Express, type Request, type Response } from 'express';
import { randomUUID } from 'node:crypto';
import { log } from './logger';
import { MENU, priceCart, type CartLine } from './menu';

export interface Order {
  id: string;
  storeId: string;
  lines: CartLine[];
  subtotalCents: number;
  taxCents: number;
  totalCents: number;
  status: 'received' | 'preparing' | 'ready';
  createdAt: string;
}

export function createApp(): Express {
  const app = express();
  const orders = new Map<string, Order>();

  app.use(express.json());
  app.use((_req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', process.env.CORS_ALLOW_ORIGIN ?? '*');
    res.setHeader('Access-Control-Allow-Headers', 'content-type');
    next();
  });
  app.use((req, _res, next) => {
    log('info', 'request', { method: req.method, path: req.path });
    next();
  });

  app.get('/healthz', (_req: Request, res: Response) => {
    res.json({ status: 'ok', service: 'order-ahead' });
  });

  app.get('/readyz', (_req: Request, res: Response) => {
    res.json({ status: 'ready', orders: orders.size });
  });

  app.get('/api/menu', (_req: Request, res: Response) => {
    res.json({ items: MENU });
  });

  app.post('/api/cart/price', (req: Request, res: Response) => {
    const lines = (req.body?.lines ?? []) as CartLine[];
    try {
      res.json(priceCart(lines));
    } catch (err) {
      res.status(400).json({ error: (err as Error).message });
    }
  });

  app.post('/api/orders', (req: Request, res: Response) => {
    const storeId = String(req.body?.storeId ?? '');
    const lines = (req.body?.lines ?? []) as CartLine[];
    if (!storeId) {
      res.status(400).json({ error: 'storeId is required' });
      return;
    }
    if (!Array.isArray(lines) || lines.length === 0) {
      res.status(400).json({ error: 'at least one line is required' });
      return;
    }
    let totals;
    try {
      totals = priceCart(lines);
    } catch (err) {
      res.status(400).json({ error: (err as Error).message });
      return;
    }
    const order: Order = {
      id: randomUUID(),
      storeId,
      lines,
      ...totals,
      status: 'received',
      createdAt: new Date().toISOString(),
    };
    orders.set(order.id, order);
    log('info', 'order placed', { orderId: order.id, storeId, totalCents: order.totalCents });
    res.status(201).json(order);
  });

  app.get('/api/orders/:id', (req: Request, res: Response) => {
    const order = orders.get(req.params.id);
    if (!order) {
      res.status(404).json({ error: 'order not found' });
      return;
    }
    res.json(order);
  });

  return app;
}
