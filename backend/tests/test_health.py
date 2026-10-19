from django.test import TestCase
from rest_framework.test import APIClient


class HealthCheckTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_health_remains_public_without_credentials(self):
        # No other API view exists yet. Health opts out of the IsAuthenticated default.
        response = self.client.get("/api/v1/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_health_returns_ok_without_configuration(self):
        with self.assertNumQueries(0):
            response = self.client.get("/api/v1/health/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})
        body = response.content.decode()
        self.assertNotIn("SECRET", body)
        self.assertNotIn("postgres", body.lower())
        self.assertNotIn("password", body.lower())

    def test_request_id_is_echoed(self):
        response = self.client.get("/api/v1/health/", HTTP_X_REQUEST_ID="abc-123")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["X-Request-ID"], "abc-123")

    def test_unsafe_request_id_is_replaced(self):
        response = self.client.get("/api/v1/health/", HTTP_X_REQUEST_ID="x" * 200)
        self.assertEqual(response.status_code, 200)
        self.assertNotEqual(response["X-Request-ID"], "x" * 200)
        self.assertLessEqual(len(response["X-Request-ID"]), 80)

    def test_unsupported_method_uses_error_envelope(self):
        response = self.client.post("/api/v1/health/")
        self.assertEqual(response.status_code, 405)
        self.assertEqual(response.json()["error"]["code"], "METHOD_NOT_ALLOWED")

    def test_unknown_api_path_uses_error_envelope(self):
        response = self.client.get("/api/v1/missing/", HTTP_X_REQUEST_ID="missing-1")
        self.assertEqual(response.status_code, 404)
        payload = response.json()["error"]
        self.assertEqual(payload["code"], "NOT_FOUND")
        self.assertEqual(payload["request_id"], "missing-1")
        self.assertNotIn("Traceback", response.content.decode())
