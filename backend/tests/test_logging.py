import logging

from django.test import SimpleTestCase

from config.logging_utils import SensitiveDataFilter, redact_text


class RedactionTests(SimpleTestCase):
    def test_redacts_bearer_tokens(self):
        self.assertEqual(
            redact_text("Authorization: Bearer abc.def.ghi"),
            "Authorization: [REDACTED]",
        )
        self.assertEqual(redact_text("Bearer abc.def.ghi"), "Bearer [REDACTED]")

    def test_redacts_json_otp(self):
        self.assertEqual(redact_text('{"otp":"123456"}'), '{"otp":"[REDACTED]"}')

    def test_redacts_password_assignment(self):
        self.assertEqual(redact_text("password=hunter2 extra"), "password=[REDACTED] extra")

    def test_redacts_python_repr_values(self):
        self.assertEqual(redact_text("{'otp': '123456'}"), "{'otp': '[REDACTED]'}")
        self.assertEqual(
            redact_text('{"password": "secret"}'),
            '{"password": "[REDACTED]"}',
        )

    def test_redacts_mobile_numbers(self):
        self.assertEqual(redact_text("call +919876543210 now"), "call [REDACTED] now")
        self.assertEqual(redact_text("mobile 9876543210"), "mobile [REDACTED]")

    def test_keeps_error_code(self):
        self.assertEqual(
            redact_text('{"code":"VALIDATION_ERROR"}'),
            '{"code":"VALIDATION_ERROR"}',
        )

    def test_filter_redacts_formatted_arguments(self):
        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname=__file__,
            lineno=1,
            msg="otp=%s",
            args=("999999",),
            exc_info=None,
        )
        self.assertTrue(SensitiveDataFilter().filter(record))
        rendered = record.getMessage()
        self.assertIn("[REDACTED]", rendered)
        self.assertNotIn("999999", rendered)
