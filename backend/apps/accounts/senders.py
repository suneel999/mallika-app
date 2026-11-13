"""OTP delivery. The console sender is a local stand-in for WhatsApp."""

import json
import sys
import urllib.error
import urllib.request

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured


class ConsoleOtpSender:
    """Writes the code to stderr. Production settings refuse this class."""

    def send(self, mobile_number: str, code: str) -> None:
        print(f"Mallika OTP for {mobile_number}: {code}", file=sys.stderr)


class CapturingOtpSender:
    """Test double. Codes stay in this process and are not logged."""

    sent: list[tuple[str, str]] = []

    def send(self, mobile_number: str, code: str) -> None:
        self.sent.append((mobile_number, code))

    @classmethod
    def reset(cls) -> None:
        cls.sent = []


class WhatsAppCloudOtpSender:
    """Sends the code with an approved WhatsApp authentication template."""

    def send(self, mobile_number: str, code: str) -> None:
        token = str(getattr(settings, "WHATSAPP_TOKEN", "") or "").strip()
        phone_number_id = str(getattr(settings, "WHATSAPP_PHONE_NUMBER_ID", "") or "").strip()
        template = str(getattr(settings, "WHATSAPP_TEMPLATE", "") or "mallika_otp").strip()
        version = str(getattr(settings, "WHATSAPP_GRAPH_VERSION", "") or "v21.0").strip()
        if not token or not phone_number_id:
            raise ImproperlyConfigured("Set WHATSAPP_TOKEN and WHATSAPP_PHONE_NUMBER_ID.")
        recipient = mobile_number.lstrip("+")
        payload = {
            "messaging_product": "whatsapp",
            "to": recipient,
            "type": "template",
            "template": {
                "name": template,
                "language": {"code": "en"},
                "components": [
                    {"type": "body", "parameters": [{"type": "text", "text": code}]},
                    {
                        "type": "button",
                        "sub_type": "url",
                        "index": "0",
                        "parameters": [{"type": "text", "text": code}],
                    },
                ],
            },
        }
        request = urllib.request.Request(
            f"https://graph.facebook.com/{version}/{phone_number_id}/messages",
            data=json.dumps(payload).encode(),
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                response.read()
        except urllib.error.URLError as error:
            raise ImproperlyConfigured("WhatsApp did not accept the sign-in code.") from error
