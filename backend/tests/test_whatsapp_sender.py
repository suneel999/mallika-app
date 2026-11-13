import json
from unittest.mock import patch

from django.test import SimpleTestCase, override_settings

from apps.accounts.senders import WhatsAppCloudOtpSender


class _Response:
    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def read(self):
        return b"{}"


@override_settings(
    WHATSAPP_TOKEN="test-token",
    WHATSAPP_PHONE_NUMBER_ID="100",
    WHATSAPP_TEMPLATE="mallika_otp",
    WHATSAPP_GRAPH_VERSION="v21.0",
)
class WhatsAppSenderTests(SimpleTestCase):
    def test_sends_the_code_to_the_approved_template(self):
        captured = {}

        def fake_urlopen(request, timeout):
            captured["url"] = request.full_url
            captured["body"] = json.loads(request.data.decode())
            captured["auth"] = request.get_header("Authorization")
            captured["timeout"] = timeout
            return _Response()

        with patch("apps.accounts.senders.urllib.request.urlopen", fake_urlopen):
            WhatsAppCloudOtpSender().send("+919876543210", "123456")

        self.assertEqual(captured["url"], "https://graph.facebook.com/v21.0/100/messages")
        self.assertEqual(captured["auth"], "Bearer test-token")
        self.assertEqual(captured["body"]["to"], "919876543210")
        self.assertEqual(captured["body"]["template"]["name"], "mallika_otp")
        self.assertEqual(captured["body"]["template"]["components"][0]["parameters"][0]["text"], "123456")
        self.assertNotIn("123456", json.dumps({}))

    def test_missing_token_does_not_call_whatsapp(self):
        with override_settings(WHATSAPP_TOKEN=""):
            with patch("apps.accounts.senders.urllib.request.urlopen") as urlopen:
                with self.assertRaises(Exception):
                    WhatsAppCloudOtpSender().send("+919876543210", "123456")
        urlopen.assert_not_called()
