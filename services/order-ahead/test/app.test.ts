import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app';
import { priceCart } from '../src/menu';
import type { Server } from 'node:http';

async function withServer(fn: (baseUrl: string) => Promise<void>): Promise<void> {
  const server: Server = createApp().listen(0);
  try {
    const address = server.address();
    if (address === null || typeof address === 'string') {
      throw new Error('server did not bind a port');
    }
    await fn(`http://127.0.0.1:${address.port}`);
  } finally {
    server.close();
  }
}

test('priceCart applies tax to the subtotal', () => {
  const totals = priceCart([{ itemId: 'burrito', quantity: 2 }]);
  assert.equal(totals.subtotalCents, 2190);
  assert.equal(totals.taxCents, 181);
  assert.equal(totals.totalCents, 2371);
});

test('priceCart rejects unknown items', () => {
  assert.throws(() => priceCart([{ itemId: 'taco-salad', quantity: 1 }]), /unknown menu item/);
});

test('healthz reports ok', async () => {
  await withServer(async (baseUrl) => {
    const res = await fetch(`${baseUrl}/healthz`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { status: 'ok', service: 'order-ahead' });
  });
});

test('menu is served', async () => {
  await withServer(async (baseUrl) => {
    const res = await fetch(`${baseUrl}/api/menu`);
    const body = (await res.json()) as { items: unknown[] };
    assert.ok(body.items.length >= 5);
  });
});

test('an order can be placed and fetched', async () => {
  await withServer(async (baseUrl) => {
    const created = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ storeId: '0421', lines: [{ itemId: 'bowl', quantity: 1 }] }),
    });
    assert.equal(created.status, 201);
    const order = (await created.json()) as { id: string; totalCents: number };
    assert.equal(order.totalCents, 1185);

    const fetched = await fetch(`${baseUrl}/api/orders/${order.id}`);
    assert.equal(fetched.status, 200);
  });
});

test('orders require a store', async () => {
  await withServer(async (baseUrl) => {
    const res = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ lines: [{ itemId: 'bowl', quantity: 1 }] }),
    });
    assert.equal(res.status, 400);
  });
});
