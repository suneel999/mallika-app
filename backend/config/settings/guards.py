"""Checks that must pass before production settings finish loading."""

import os

from django.core.exceptions import ImproperlyConfigured


def require_sms_sender() -> None:
    sender = os.environ.get("OTP_SENDER", "apps.accounts.senders.ConsoleOtpSender")
    if sender.endswith("ConsoleOtpSender"):
        raise ImproperlyConfigured(
            "Set OTP_SENDER to the hospital SMS provider before using production settings."
        )
