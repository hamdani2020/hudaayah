"""DRF exception handler producing the standard error envelope.

Returns: { "error": { code, message, request_id } }
Never leaks stack traces, SQL, secrets, or raw provider errors.
"""
from __future__ import annotations

import logging

from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_default_handler

from .errors import AppError, error_body, new_request_id

logger = logging.getLogger(__name__)


def api_exception_handler(exc, context):
    request_id = new_request_id()

    # Our own typed errors map to their code/message/status.
    if isinstance(exc, AppError):
        return Response(
            error_body(exc.code, exc.message, request_id),
            status=exc.http_status,
        )

    # Let DRF handle its known exceptions, then wrap them in the envelope.
    response = drf_default_handler(exc, context)
    if response is not None:
        detail = response.data.get("detail") if isinstance(response.data, dict) else None
        message = str(detail) if detail else "Request could not be processed."
        code = getattr(exc, "default_code", "error")
        response.data = error_body(code, message, request_id)
        return response

    # Unhandled -> generic 500, log server-side only.
    logger.exception("Unhandled exception (request_id=%s)", request_id)
    return Response(
        error_body("internal_error", "Something went wrong.", request_id),
        status=500,
    )
