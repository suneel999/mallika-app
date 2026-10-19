import json

from django.test import RequestFactory, SimpleTestCase
from rest_framework.exceptions import AuthenticationFailed, ValidationError

from config.exceptions import api_exception_handler, server_error


class ApiErrorTests(SimpleTestCase):
    def setUp(self):
        self.factory = RequestFactory()

    def _request(self):
        request = self.factory.get("/api/v1/health/")
        request.request_id = "req-1"
        return request

    def test_validation_error_shape(self):
        exc = ValidationError({"requested_date": ["Date must be today or later."]})
        response = api_exception_handler(exc, {"request": self._request()})

        self.assertEqual(response.status_code, 400)
        error = response.data["error"]
        self.assertEqual(error["code"], "VALIDATION_ERROR")
        self.assertEqual(error["request_id"], "req-1")
        self.assertIn("requested_date", error["fields"])

    def test_authentication_error_code(self):
        response = api_exception_handler(AuthenticationFailed(), {"request": self._request()})
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.data["error"]["code"], "AUTHENTICATION_REQUIRED")

    def test_unhandled_exception_hides_details(self):
        with self.assertLogs("config.exceptions", level="ERROR") as captured:
            response = api_exception_handler(
                RuntimeError("otp=123456"),
                {"request": self._request()},
            )

        self.assertEqual(response.status_code, 500)
        error = response.data["error"]
        self.assertEqual(error["code"], "INTERNAL_ERROR")
        self.assertNotIn("123456", error["message"])
        self.assertNotIn("123456", str(error))
        self.assertNotIn("RuntimeError", str(error))
        self.assertTrue(captured.records[0].exc_info)
        self.assertIs(captured.records[0].exc_info[0], RuntimeError)

    def test_server_error_view_is_generic(self):
        response = server_error(self._request())
        payload = json.loads(response.content)
        self.assertEqual(response.status_code, 500)
        self.assertEqual(payload["error"]["code"], "INTERNAL_ERROR")
        self.assertEqual(payload["error"]["request_id"], "req-1")
