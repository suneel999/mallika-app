import os
from datetime import timedelta

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import OtpChallenge, RefreshSession, User, UserKind
from apps.accounts.senders import CapturingOtpSender


class OtpSessionTests(TestCase):
    def setUp(self):
        CapturingOtpSender.reset()
        self.client = APIClient()

    def test_verify_creates_a_patient_and_hides_the_code(self):
        requested = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": "98765 43210"},
            format="json",
        )
        self.assertEqual(requested.status_code, 200, requested.content)
        code = CapturingOtpSender.sent[-1][1]
        body = requested.json()
        self.assertEqual(body["mobile_number"], "+919876543210")
        self.assertNotIn(code, requested.content.decode())
        challenge = OtpChallenge.objects.get()
        self.assertNotEqual(challenge.code_hash, code)
        self.assertNotIn(code, challenge.code_hash)

        verified = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "+91 9876543210", "code": code},
            format="json",
        )
        self.assertEqual(verified.status_code, 200, verified.content)
        payload = verified.json()
        self.assertNotIn(code, verified.content.decode())
        self.assertEqual(payload["user"]["mobile_number"], "+919876543210")
        self.assertEqual(payload["user"]["user_kind"], "patient")
        self.assertIsNone(payload["user"]["profile"])
        self.assertTrue(payload["access"])
        self.assertNotEqual(payload["refresh"], RefreshSession.objects.get().token_hash)

        me = self.client.get(
            "/api/v1/me/",
            HTTP_AUTHORIZATION=f"Bearer {payload['access']}",
        )
        self.assertEqual(me.status_code, 200, me.content)
        self.assertEqual(me.json()["id"], payload["user"]["id"])

    def test_me_and_unknown_routes_keep_the_error_envelope(self):
        anonymous = self.client.get("/api/v1/me/")
        self.assertEqual(anonymous.status_code, 401)
        self.assertEqual(anonymous.json()["error"]["code"], "AUTHENTICATION_REQUIRED")
        health = self.client.get("/api/v1/health/", HTTP_AUTHORIZATION="Bearer not-a-token")
        self.assertEqual(health.status_code, 200)
        self.assertEqual(health.json(), {"status": "ok"})

    def test_wrong_code_does_not_create_a_user(self):
        self._request("9876543210")
        rejected = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": "000000"},
            format="json",
        )
        self.assertEqual(rejected.status_code, 401)
        self.assertEqual(rejected.json()["error"]["code"], "AUTHENTICATION_REQUIRED")
        self.assertFalse(User.objects.exists())
        self.assertEqual(OtpChallenge.objects.get().attempts, 1)

    def test_attempt_limit_sticks(self):
        code = self._request("9876543210")
        with override_settings(OTP_MAX_ATTEMPTS=1):
            self.client.post(
                "/api/v1/auth/otp/verify/",
                {"mobile_number": "9876543210", "code": "000000"},
                format="json",
            )
            blocked = self.client.post(
                "/api/v1/auth/otp/verify/",
                {"mobile_number": "9876543210", "code": code},
                format="json",
            )
        self.assertEqual(blocked.status_code, 401)
        self.assertFalse(User.objects.exists())

    def test_expired_code_is_rejected(self):
        code = self._request("9876543210")
        challenge = OtpChallenge.objects.get()
        challenge.expires_at = timezone.now() - timedelta(seconds=1)
        challenge.save(update_fields=["expires_at"])
        rejected = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": code},
            format="json",
        )
        self.assertEqual(rejected.status_code, 401)
        self.assertFalse(User.objects.exists())

    def test_resend_and_hourly_limits(self):
        self._request("9876543210")
        limited = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": "9876543210"},
            format="json",
        )
        self.assertEqual(limited.status_code, 429)
        self.assertEqual(limited.json()["error"]["code"], "RATE_LIMITED")
        self.assertGreaterEqual(limited.json()["error"]["retry_after"], 1)

        CapturingOtpSender.reset()
        with override_settings(OTP_RESEND_SECONDS=0, OTP_MAX_PER_HOUR=2):
            again = self.client.post(
                "/api/v1/auth/otp/request/",
                {"mobile_number": "9876543210"},
                format="json",
            )
            capped = self.client.post(
                "/api/v1/auth/otp/request/",
                {"mobile_number": "9876543210"},
                format="json",
            )
        self.assertEqual(again.status_code, 200, again.content)
        self.assertEqual(capped.status_code, 429)

    def test_invalid_mobile_is_a_field_error(self):
        response = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": "123"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["error"]["code"], "VALIDATION_ERROR")
        self.assertIn("mobile_number", response.json()["error"]["fields"])
        self.assertEqual(CapturingOtpSender.sent, [])

    def test_staff_and_inactive_numbers_look_like_a_normal_request(self):
        User.objects.create_user("+919876543210", password="staff-secret", user_kind=UserKind.STAFF)
        staff = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": "9876543210"},
            format="json",
        )
        self.assertEqual(staff.status_code, 200, staff.content)
        self.assertEqual(
            set(staff.json()),
            {"mobile_number", "expires_in", "resend_after"},
        )
        self.assertEqual(staff.json()["mobile_number"], "+919876543210")
        self.assertEqual(staff.json()["expires_in"], settings.OTP_TTL_SECONDS)
        self.assertEqual(CapturingOtpSender.sent, [])

        patient = User.objects.create_user("+919876543211")
        patient.is_active = False
        patient.save(update_fields=["is_active"])
        inactive = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": "9876543211"},
            format="json",
        )
        self.assertEqual(inactive.status_code, 200, inactive.content)
        self.assertEqual(inactive.json()["mobile_number"], "+919876543211")
        self.assertEqual(inactive.json()["resend_after"], staff.json()["resend_after"])
        self.assertEqual(CapturingOtpSender.sent, [])

    @override_settings(OTP_RESEND_SECONDS=0)
    def test_a_newer_code_retires_the_previous_one(self):
        from django.contrib.auth.hashers import make_password

        first = self._request("9876543210")
        second = self._request("9876543210")
        self.assertNotEqual(first, second)
        self.assertEqual(
            OtpChallenge.objects.filter(consumed_at__isnull=True).count(),
            1,
        )
        retired = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": first},
            format="json",
        )
        self.assertEqual(retired.status_code, 401)
        self.assertFalse(User.objects.exists())

        planted = OtpChallenge.objects.create(
            mobile_number="+919876543210",
            purpose="login",
            code_hash=make_password("111111"),
            expires_at=timezone.now() + timedelta(minutes=5),
        )
        OtpChallenge.objects.filter(pk=planted.pk).update(
            created_at=timezone.now() - timedelta(minutes=2)
        )
        verified = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": second},
            format="json",
        )
        self.assertEqual(verified.status_code, 200, verified.content)
        planted.refresh_from_db()
        self.assertIsNotNone(planted.consumed_at)
        reused = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": "111111"},
            format="json",
        )
        self.assertEqual(reused.status_code, 401)
        self.assertEqual(User.objects.count(), 1)

    def test_refresh_rotates_and_reuse_revokes_the_replacement(self):
        code = self._request("9876543210")
        first = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": code},
            format="json",
        ).json()
        second = self.client.post(
            "/api/v1/auth/token/refresh/",
            {"refresh": first["refresh"]},
            format="json",
        )
        self.assertEqual(second.status_code, 200, second.content)
        self.assertNotEqual(second.json()["refresh"], first["refresh"])
        stale_access = self.client.get(
            "/api/v1/me/",
            HTTP_AUTHORIZATION=f"Bearer {first['access']}",
        )
        self.assertEqual(stale_access.status_code, 401)
        reused = self.client.post(
            "/api/v1/auth/token/refresh/",
            {"refresh": first["refresh"]},
            format="json",
        )
        self.assertEqual(reused.status_code, 401)
        replacement = self.client.post(
            "/api/v1/auth/token/refresh/",
            {"refresh": second.json()["refresh"]},
            format="json",
        )
        self.assertEqual(replacement.status_code, 401)

    def test_logout_revokes_access_and_refresh(self):
        code = self._request("9876543210")
        verified = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": "9876543210", "code": code},
            format="json",
        ).json()
        logged_out = self.client.post(
            "/api/v1/auth/logout/",
            {"refresh": verified["refresh"]},
            format="json",
        )
        self.assertEqual(logged_out.status_code, 204)
        me = self.client.get(
            "/api/v1/me/",
            HTTP_AUTHORIZATION=f"Bearer {verified['access']}",
        )
        self.assertEqual(me.status_code, 401)
        refresh = self.client.post(
            "/api/v1/auth/token/refresh/",
            {"refresh": verified["refresh"]},
            format="json",
        )
        self.assertEqual(refresh.status_code, 401)

    def test_production_settings_refuse_the_console_otp_sender(self):
        from config.settings.guards import require_sms_sender

        previous = os.environ.get("OTP_SENDER")
        os.environ["OTP_SENDER"] = "apps.accounts.senders.ConsoleOtpSender"
        try:
            with self.assertRaises(ImproperlyConfigured) as caught:
                require_sms_sender()
        finally:
            if previous is None:
                os.environ.pop("OTP_SENDER", None)
            else:
                os.environ["OTP_SENDER"] = previous
        self.assertIn("OTP_SENDER", str(caught.exception))

    def _request(self, mobile):
        response = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": mobile},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.content)
        return CapturingOtpSender.sent[-1][1]
