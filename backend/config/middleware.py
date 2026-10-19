"""Request correlation and a JSON envelope for unmatched API responses."""

import re
import uuid

from django.conf import settings
from django.http import JsonResponse

from config.exceptions import DEFAULT_MESSAGES, error_payload

_REQUEST_ID = re.compile(r"^[A-Za-z0-9_-]{1,80}$")


class RequestIdMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        incoming = request.headers.get("X-Request-ID", "")
        if _REQUEST_ID.fullmatch(incoming):
            request.request_id = incoming
        else:
            request.request_id = str(uuid.uuid4())
        response = self.get_response(request)
        response["X-Request-ID"] = request.request_id
        return response


class ApiErrorEnvelopeMiddleware:
    """Replace non-JSON 404/500 responses under /api/ with the standard error body."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        if not request.path.startswith("/api/"):
            return response
        if response.status_code not in {404, 500}:
            return response
        content_type = response.get("Content-Type", "")
        if "application/json" in content_type:
            return response
        if response.status_code == 500 and settings.DEBUG:
            return response
        if response.status_code == 404:
            payload = error_payload("NOT_FOUND", DEFAULT_MESSAGES[404], request)
            status_code = 404
        else:
            payload = error_payload("INTERNAL_ERROR", DEFAULT_MESSAGES[500], request)
            status_code = 500
        return JsonResponse(payload, status=status_code)
