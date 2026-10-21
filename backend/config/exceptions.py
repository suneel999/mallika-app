"""Consistent JSON error responses for the versioned API."""

import logging

from django.http import JsonResponse
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import exception_handler

from config.logging_utils import redact_text

logger = logging.getLogger(__name__)


class Conflict(APIException):
    status_code = 409
    default_detail = "The request conflicts with the current state."
    default_code = "conflict"

STATUS_CODES = {
    400: "VALIDATION_ERROR",
    401: "AUTHENTICATION_REQUIRED",
    403: "PERMISSION_DENIED",
    404: "NOT_FOUND",
    405: "METHOD_NOT_ALLOWED",
    409: "CONFLICT",
    429: "RATE_LIMITED",
}

DEFAULT_MESSAGES = {
    400: "Please check the submitted fields.",
    401: "Authentication is required.",
    403: "You do not have permission to perform this action.",
    404: "The requested resource was not found.",
    405: "This method is not allowed.",
    409: "The request conflicts with the current state.",
    429: "Too many requests. Please try again later.",
    500: "Something went wrong. Please try again.",
}


def error_payload(code, message, request, fields=None, retry_after=None):
    error = {
        "code": code,
        "message": message,
        "request_id": getattr(request, "request_id", None) if request is not None else None,
    }
    if fields is not None:
        error["fields"] = fields
    if retry_after is not None:
        error["retry_after"] = retry_after
    return {"error": error}


def _detail_message(detail):
    if isinstance(detail, list):
        return " ".join(str(item) for item in detail)
    if isinstance(detail, dict):
        return DEFAULT_MESSAGES[400]
    return str(detail)


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    request = context.get("request")

    if response is None:
        logger.error(
            "Unhandled API exception: %s: %s",
            type(exc).__name__,
            redact_text(str(exc)),
            exc_info=exc,
        )
        return Response(
            error_payload("INTERNAL_ERROR", DEFAULT_MESSAGES[500], request),
            status=500,
        )

    http_status = response.status_code
    code = STATUS_CODES.get(http_status, "REQUEST_ERROR")
    message = DEFAULT_MESSAGES.get(http_status, "The request could not be completed.")
    fields = None
    data = response.data

    if isinstance(data, dict):
        if http_status == 400 and "detail" not in data:
            fields = data
        elif "detail" in data:
            message = _detail_message(data["detail"])
    elif isinstance(data, list):
        message = _detail_message(data)

    retry_after = None
    if http_status == 429:
        header = response.headers.get("Retry-After")
        if header is not None:
            try:
                retry_after = int(header)
            except (TypeError, ValueError):
                retry_after = header

    response.data = error_payload(
        code,
        message,
        request,
        fields=fields,
        retry_after=retry_after,
    )
    return response


def not_found(request, exception):
    return JsonResponse(
        error_payload("NOT_FOUND", DEFAULT_MESSAGES[404], request),
        status=404,
    )


def server_error(request):
    return JsonResponse(
        error_payload("INTERNAL_ERROR", DEFAULT_MESSAGES[500], request),
        status=500,
    )
