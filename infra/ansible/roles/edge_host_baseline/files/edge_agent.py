#!/usr/bin/env python3
"""Stand-in for the BurritoWorks store edge agent.

The real agent talks to the KDS / POS hardware. For the demo sandbox it only
needs to read its configuration and answer a health check, so the Ansible
layer has something real to converge on and smoke test.
"""

from __future__ import annotations

import argparse
import json
from http.server import BaseHTTPRequestHandler, HTTPServer


def read_config(path: str) -> dict[str, str]:
    config: dict[str, str] = {}
    try:
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                config[key] = value
    except FileNotFoundError:
        pass
    return config


def make_handler(config: dict[str, str]) -> type[BaseHTTPRequestHandler]:
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802 - http.server API
            if self.path not in ("/healthz", "/"):
                self.send_response(404)
                self.end_headers()
                return
            body = json.dumps(
                {
                    "status": "ok",
                    "role": config.get("role", "unknown"),
                    "site_id": config.get("site_id", "unknown"),
                    "region": config.get("region", "unknown"),
                }
            ).encode()
            self.send_response(200)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, fmt: str, *args: object) -> None:
            print("edge-agent " + fmt % args, flush=True)

    return Handler


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8181)
    parser.add_argument("--config", default="/etc/burritoworks/agent.conf")
    args = parser.parse_args()

    config = read_config(args.config)
    HTTPServer(("0.0.0.0", args.port), make_handler(config)).serve_forever()


if __name__ == "__main__":
    main()
