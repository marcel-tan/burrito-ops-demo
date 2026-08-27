export interface MenuItem {
  id: string;
  name: string;
  category: 'entree' | 'side' | 'drink';
  priceCents: number;
}

export const MENU: MenuItem[] = [
  { id: 'burrito', name: 'Burrito', category: 'entree', priceCents: 1095 },
  { id: 'bowl', name: 'Burrito Bowl', category: 'entree', priceCents: 1095 },
  { id: 'quesadilla', name: 'Quesadilla', category: 'entree', priceCents: 1145 },
  { id: 'chips-guac', name: 'Chips & Guacamole', category: 'side', priceCents: 495 },
  { id: 'agua-fresca', name: 'Agua Fresca', category: 'drink', priceCents: 375 },
];

export function findItem(id: string): MenuItem | undefined {
  return MENU.find((item) => item.id === id);
}

export interface CartLine {
  itemId: string;
  quantity: number;
}

export function priceCart(lines: CartLine[]): { subtotalCents: number; taxCents: number; totalCents: number } {
  const subtotalCents = lines.reduce((sum, line) => {
    const item = findItem(line.itemId);
    if (!item) {
      throw new Error(`unknown menu item: ${line.itemId}`);
    }
    if (!Number.isInteger(line.quantity) || line.quantity < 1) {
      throw new Error(`invalid quantity for ${line.itemId}`);
    }
    return sum + item.priceCents * line.quantity;
  }, 0);
  const taxCents = Math.round(subtotalCents * 0.0825);
  return { subtotalCents, taxCents, totalCents: subtotalCents + taxCents };
}
