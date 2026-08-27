import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { AppComponent } from './app.component';

describe('AppComponent', () => {
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppComponent],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
    httpMock = TestBed.inject(HttpTestingController);
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should render the brand header', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('BurritoWorks');
  });

  it('should load the menu and the catering packages', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();

    httpMock.expectOne((req) => req.url.endsWith('/api/menu')).flush({
      items: [{ id: 'burrito', name: 'Burrito', category: 'entree', priceCents: 1095 }],
    });
    httpMock.expectOne((req) => req.url.endsWith('/api/packages')).flush({
      packages: [{ id: 'taco-bar', name: 'Taco Bar', per_guest_cents: 1250, min_guests: 20 }],
    });
    fixture.detectChanges();

    expect(fixture.componentInstance.menu.length).toBe(1);
    expect(fixture.componentInstance.selectedPackage).toBe('taco-bar');
  });

  it('should surface an error when a service is unreachable', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();

    httpMock
      .expectOne((req) => req.url.endsWith('/api/menu'))
      .error(new ProgressEvent('error'), { status: 503, statusText: 'Service Unavailable' });
    httpMock.expectOne((req) => req.url.endsWith('/api/packages')).flush({ packages: [] });

    expect(fixture.componentInstance.orderAheadError).toBe('order-ahead is unreachable');
  });
});
