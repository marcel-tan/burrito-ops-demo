import pytest

from catering import create_app
from catering.pricing import PricingError, quote


@pytest.fixture()
def client():
    app = create_app()
    app.config.update(TESTING=True)
    with app.test_client() as client:
        yield client


def test_quote_applies_delivery_and_tax():
    result = quote("taco-bar", 20)
    assert result["subtotal_cents"] == 25000
    assert result["delivery_cents"] == 2500
    assert result["discount_cents"] == 0
    assert result["total_cents"] == 29769


def test_quote_discounts_large_orders():
    result = quote("burrito-bar", 100, delivery=False)
    assert result["discount_cents"] == 6750


def test_quote_enforces_minimum_guests():
    with pytest.raises(PricingError):
        quote("burrito-bar", 5)


def test_healthz(client):
    assert client.get("/healthz").json == {"status": "ok", "service": "catering"}


def test_packages_listed(client):
    assert len(client.get("/api/packages").json["packages"]) == 3


def test_order_lifecycle(client):
    created = client.post(
        "/api/orders",
        json={
            "store_id": "0421",
            "event_at": "2026-09-14T18:00:00Z",
            "package_id": "bowl-bar",
            "guests": 40,
        },
    )
    assert created.status_code == 201
    order_id = created.json["id"]
    assert client.get(f"/api/orders/{order_id}").status_code == 200


def test_order_requires_store(client):
    response = client.post("/api/orders", json={"package_id": "bowl-bar", "guests": 40})
    assert response.status_code == 400
