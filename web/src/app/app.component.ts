import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import {
  ApiService,
  CartPrice,
  CateringPackage,
  CateringQuote,
  MenuItem,
  Order,
} from './api.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent implements OnInit {
  menu: MenuItem[] = [];
  quantities: Record<string, number> = {};
  cartPrice: CartPrice | null = null;
  order: Order | null = null;
  storeId = 'store-100';

  packages: CateringPackage[] = [];
  selectedPackage = '';
  guests = 25;
  delivery = true;
  quote: CateringQuote | null = null;

  orderAheadError: string | null = null;
  cateringError: string | null = null;

  constructor(private readonly api: ApiService) {}

  ngOnInit(): void {
    this.api.menu().subscribe({
      next: (response) => {
        this.menu = response.items;
        this.orderAheadError = null;
      },
      error: () => (this.orderAheadError = 'order-ahead is unreachable'),
    });

    this.api.cateringPackages().subscribe({
      next: (response) => {
        this.packages = response.packages;
        this.selectedPackage = response.packages[0]?.id ?? '';
        this.cateringError = null;
      },
      error: () => (this.cateringError = 'catering is unreachable'),
    });
  }

  get cartLines(): { itemId: string; quantity: number }[] {
    return Object.entries(this.quantities)
      .filter(([, quantity]) => quantity > 0)
      .map(([itemId, quantity]) => ({ itemId, quantity }));
  }

  priceCart(): void {
    if (this.cartLines.length === 0) {
      this.cartPrice = null;
      return;
    }
    this.api.priceCart(this.cartLines).subscribe({
      next: (price) => {
        this.cartPrice = price;
        this.orderAheadError = null;
      },
      error: () => (this.orderAheadError = 'could not price the cart'),
    });
  }

  placeOrder(): void {
    if (this.cartLines.length === 0) {
      return;
    }
    this.api.placeOrder(this.cartLines, this.storeId).subscribe({
      next: (order) => {
        this.order = order;
        this.orderAheadError = null;
      },
      error: () => (this.orderAheadError = 'could not place the order'),
    });
  }

  getQuote(): void {
    if (!this.selectedPackage) {
      return;
    }
    this.api.cateringQuote(this.selectedPackage, this.guests, this.delivery).subscribe({
      next: (quote) => {
        this.quote = quote;
        this.cateringError = null;
      },
      error: () => (this.cateringError = 'could not get a catering quote'),
    });
  }

  money(cents: number | undefined): string {
    return cents === undefined ? '-' : `$${(cents / 100).toFixed(2)}`;
  }
}
