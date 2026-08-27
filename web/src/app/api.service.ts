import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../environments/environment';

export interface MenuItem {
  id: string;
  name: string;
  category: string;
  priceCents: number;
}

export interface CartLine {
  itemId: string;
  quantity: number;
}

export interface CartPrice {
  subtotalCents: number;
  taxCents: number;
  totalCents: number;
}

export interface Order {
  id: string;
  status: string;
  totalCents: number;
}

export interface CateringPackage {
  id: string;
  name: string;
  per_guest_cents: number;
  min_guests: number;
}

export interface CateringQuote {
  package_id: string;
  guests: number;
  subtotal_cents: number;
  delivery_cents: number;
  discount_cents: number;
  tax_cents: number;
  total_cents: number;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  constructor(private readonly http: HttpClient) {}

  menu(): Observable<{ items: MenuItem[] }> {
    return this.http.get<{ items: MenuItem[] }>(`${environment.orderAheadUrl}/api/menu`);
  }

  priceCart(lines: CartLine[]): Observable<CartPrice> {
    return this.http.post<CartPrice>(`${environment.orderAheadUrl}/api/cart/price`, { lines });
  }

  placeOrder(lines: CartLine[], storeId: string): Observable<Order> {
    return this.http.post<Order>(`${environment.orderAheadUrl}/api/orders`, { lines, storeId });
  }

  cateringPackages(): Observable<{ packages: CateringPackage[] }> {
    return this.http.get<{ packages: CateringPackage[] }>(`${environment.cateringUrl}/api/packages`);
  }

  cateringQuote(packageId: string, guests: number, delivery: boolean): Observable<CateringQuote> {
    return this.http.post<CateringQuote>(`${environment.cateringUrl}/api/quotes`, {
      package_id: packageId,
      guests,
      delivery,
    });
  }
}
