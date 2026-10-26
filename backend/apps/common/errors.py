"""Shared error envelope + helpers.

Envelope (django-conventions):
    { "error": { "code": "...", "message": "...", "request_id": "..." } }
Never leak stack traces, SQL, secrets, or raw provider errors to the client.
"""
from __future__ import annotations

import uuid


class AppError(Exception):
    """Base application error carrying a stable machine-readable code."""

    code = "internal_error"
    message = "Something went wrong."
    http_status = 500

    def __init__(self, message: str | None = None, *, code: str | None = None):
        if message:
            self.message = message
        if code:
            self.code = code
        super().__init__(self.message)


class UpstreamError(AppError):
    code = "upstream_unavailable"
    message = "An upstream service is unavailable. Please try again."
    http_status = 502


def new_request_id() -> str:
    return uuid.uuid4().hex


def error_body(code: str, message: str, request_id: str | None = None) -> dict:
    return {
        "error": {
            "code": code,
            "message": message,
            "request_id": request_id or new_request_id(),
        }
    }
