"""Pricing rules for BurritoWorks catering orders."""

PACKAGES = {
    "burrito-bar": {"name": "Burrito Bar", "per_guest_cents": 1350, "min_guests": 20},
    "taco-bar": {"name": "Taco Bar", "per_guest_cents": 1250, "min_guests": 20},
    "bowl-bar": {"name": "Bowl Bar", "per_guest_cents": 1425, "min_guests": 15},
}

DELIVERY_FEE_CENTS = 2500
LARGE_ORDER_GUESTS = 100
LARGE_ORDER_DISCOUNT = 0.05
TAX_RATE = 0.0825


class PricingError(ValueError):
    """Raised when a catering order cannot be priced."""


def quote(package_id: str, guests: int, delivery: bool = True) -> dict:
    package = PACKAGES.get(package_id)
    if package is None:
        raise PricingError(f"unknown package: {package_id}")
    if not isinstance(guests, int) or isinstance(guests, bool):
        raise PricingError("guests must be an integer")
    if guests < package["min_guests"]:
        raise PricingError(
            f"{package['name']} requires at least {package['min_guests']} guests"
        )

    subtotal_cents = package["per_guest_cents"] * guests
    discount_cents = 0
    if guests >= LARGE_ORDER_GUESTS:
        discount_cents = round(subtotal_cents * LARGE_ORDER_DISCOUNT)
    delivery_cents = DELIVERY_FEE_CENTS if delivery else 0
    taxable = subtotal_cents - discount_cents + delivery_cents
    tax_cents = round(taxable * TAX_RATE)

    return {
        "package_id": package_id,
        "guests": guests,
        "subtotal_cents": subtotal_cents,
        "discount_cents": discount_cents,
        "delivery_cents": delivery_cents,
        "tax_cents": tax_cents,
        "total_cents": taxable + tax_cents,
    }
