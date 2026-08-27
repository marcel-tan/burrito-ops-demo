import json
import logging
import os
import sys
import uuid
from datetime import datetime, timezone

from flask import Flask, jsonify, request

from .pricing import PACKAGES, PricingError, quote

SERVICE_NAME = os.environ.get("SERVICE_NAME", "catering")
SERVICE_VERSION = os.environ.get("SERVICE_VERSION", "dev")


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname.lower(),
            "service": SERVICE_NAME,
            "version": SERVICE_VERSION,
            "message": record.getMessage(),
        }
        extra = getattr(record, "fields", None)
        if extra:
            payload.update(extra)
        return json.dumps(payload)


def _configure_logging(app: Flask) -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    app.logger.handlers = [handler]
    app.logger.setLevel(logging.INFO)


def create_app() -> Flask:
    app = Flask(__name__)
    _configure_logging(app)
    orders: dict[str, dict] = {}

    @app.after_request
    def add_cors_headers(response):
        response.headers["Access-Control-Allow-Origin"] = os.environ.get(
            "CORS_ALLOW_ORIGIN", "*"
        )
        response.headers["Access-Control-Allow-Headers"] = "content-type"
        return response

    @app.get("/healthz")
    def healthz():
        return jsonify(status="ok", service="catering")

    @app.get("/readyz")
    def readyz():
        return jsonify(status="ready", orders=len(orders))

    @app.get("/api/packages")
    def packages():
        return jsonify(
            packages=[{"id": key, **value} for key, value in PACKAGES.items()]
        )

    @app.post("/api/quotes")
    def create_quote():
        body = request.get_json(silent=True) or {}
        try:
            return jsonify(
                quote(
                    body.get("package_id", ""),
                    body.get("guests", 0),
                    bool(body.get("delivery", True)),
                )
            )
        except PricingError as err:
            return jsonify(error=str(err)), 400

    @app.post("/api/orders")
    def create_order():
        body = request.get_json(silent=True) or {}
        store_id = str(body.get("store_id", ""))
        event_at = str(body.get("event_at", ""))
        if not store_id or not event_at:
            return jsonify(error="store_id and event_at are required"), 400
        try:
            totals = quote(
                body.get("package_id", ""),
                body.get("guests", 0),
                bool(body.get("delivery", True)),
            )
        except PricingError as err:
            return jsonify(error=str(err)), 400

        order = {
            "id": str(uuid.uuid4()),
            "store_id": store_id,
            "event_at": event_at,
            "status": "received",
            "created_at": datetime.now(timezone.utc).isoformat(),
            **totals,
        }
        orders[order["id"]] = order
        app.logger.info(
            "catering order placed",
            extra={"fields": {"order_id": order["id"], "store_id": store_id}},
        )
        return jsonify(order), 201

    @app.get("/api/orders/<order_id>")
    def get_order(order_id: str):
        order = orders.get(order_id)
        if order is None:
            return jsonify(error="order not found"), 404
        return jsonify(order)

    return app
