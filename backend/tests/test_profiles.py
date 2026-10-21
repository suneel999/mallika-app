from datetime import date

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.accounts.senders import CapturingOtpSender
from apps.patients.models import PatientProfile


class PatientProfileTests(TestCase):
    def setUp(self):
        CapturingOtpSender.reset()
        self.client = APIClient()
        self.access = self._sign_in("9876543210")

    def test_owner_creates_and_updates_only_their_profile(self):
        created = self.client.post(
            "/api/v1/me/patient-profiles/",
            {
                "full_name": "  Lakshmi   Rao  ",
                "date_of_birth": "1990-04-02",
                "sex": "female",
                "preferred_language": "te",
                "mobile_number": "+910000000000",
                "patient_number": "MAL-PT-999999",
                "hims_patient_id": "HIMS-1",
            },
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(created.status_code, 201, created.content)
        body = created.json()
        self.assertEqual(body["full_name"], "Lakshmi Rao")
        self.assertEqual(body["patient_number"], "MAL-PT-000001")
        self.assertEqual(body["mobile_number"], "+919876543210")
        self.assertIsNone(body["hims_patient_id"])
        self.assertEqual(body["preferred_language"], "te")

        listed = self.client.get(
            "/api/v1/me/patient-profiles/",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(len(listed.json()["results"]), 1)

        me = self.client.get("/api/v1/me/", HTTP_AUTHORIZATION=f"Bearer {self.access}")
        self.assertEqual(me.json()["profile"]["id"], body["id"])
        self.assertEqual(me.json()["preferred_language"], "te")

        patched = self.client.patch(
            f"/api/v1/me/patient-profiles/{body['id']}/",
            {"full_name": "Lakshmi Devi"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(patched.status_code, 200, patched.content)
        self.assertEqual(patched.json()["full_name"], "Lakshmi Devi")

        other_access = self._sign_in("9876543211")
        hidden = self.client.patch(
            f"/api/v1/me/patient-profiles/{body['id']}/",
            {"full_name": "Someone Else"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {other_access}",
        )
        self.assertEqual(hidden.status_code, 404)
        self.assertEqual(PatientProfile.objects.get(pk=body["id"]).full_name, "Lakshmi Devi")

        duplicate = self.client.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "Lakshmi Devi"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(duplicate.status_code, 409)
        self.assertEqual(duplicate.json()["error"]["code"], "CONFLICT")

    def test_profile_validation(self):
        future = self.client.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "A", "date_of_birth": "2999-01-01", "sex": "nope"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(future.status_code, 400)
        self.assertEqual(future.json()["error"]["code"], "VALIDATION_ERROR")
        self.assertFalse(PatientProfile.objects.exists())
        self.assertNotEqual(date.today().year, 2999)

    def _sign_in(self, mobile):
        requested = self.client.post(
            "/api/v1/auth/otp/request/",
            {"mobile_number": mobile},
            format="json",
        )
        self.assertEqual(requested.status_code, 200, requested.content)
        code = CapturingOtpSender.sent[-1][1]
        verified = self.client.post(
            "/api/v1/auth/otp/verify/",
            {"mobile_number": mobile, "code": code},
            format="json",
        )
        self.assertEqual(verified.status_code, 200, verified.content)
        self.assertFalse(User.objects.get(mobile_number=f"+91{mobile}").has_usable_password())
        return verified.json()["access"]
