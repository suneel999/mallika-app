"""Redact credentials and one-time codes before log records are emitted."""

import logging
import re

_SENSITIVE_KEY = (
    r"password|otp|refresh_token|access_token|id_token|token|secret|"
    r"authorization|code_hash|api_key"
)
_BEARER = re.compile(r"(?i)(bearer\s+)\S+")
_JSON_FIELD = re.compile(
    rf'(?i)("(?:{_SENSITIVE_KEY})"\s*:\s*")[^"]*"'
)
_REPR_FIELD = re.compile(
    rf"(?i)(['\"])({_SENSITIVE_KEY})\1(\s*:\s*)(['\"])[^'\"]*\4"
)
_ASSIGNMENT = re.compile(
    rf"(?i)\b({_SENSITIVE_KEY})\b(\s*[:=]\s*)(?:bearer\s+)?\S+"
)
_E164_MOBILE = re.compile(r"(?<!\d)\+\d{10,15}(?!\d)")
_INDIAN_MOBILE = re.compile(r"(?<!\d)[6-9]\d{9}(?!\d)")


def redact_text(value: str) -> str:
    value = _JSON_FIELD.sub(r'\1[REDACTED]"', value)
    value = _REPR_FIELD.sub(r"\1\2\1\3\4[REDACTED]\4", value)
    value = _ASSIGNMENT.sub(r"\1\2[REDACTED]", value)
    value = _BEARER.sub(r"\1[REDACTED]", value)
    value = _E164_MOBILE.sub("[REDACTED]", value)
    value = _INDIAN_MOBILE.sub("[REDACTED]", value)
    return value


class SensitiveDataFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        try:
            rendered = record.getMessage()
        except Exception:
            return True
        record.msg = redact_text(rendered)
        record.args = ()
        return True
