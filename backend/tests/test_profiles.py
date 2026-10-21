from datetime import date
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.accounts.senders import CapturingOtpSender
from apps.patients.models import PatientProfile
from apps.patients.services import create_own_profile


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
        self.assertEqual(body["relationship"], "self")
        self.assertTrue(body["is_default"])

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

        missing_relationship = self.client.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "Lakshmi Devi"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(missing_relationship.status_code, 400)
        self.assertIn("relationship", missing_relationship.json()["error"]["fields"])

    def test_family_profile_is_a_new_record_linked_only_to_the_owner(self):
        self.client.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "Lakshmi Rao"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        own = PatientProfile.objects.get(user__mobile_number="+919876543210")
        created = self.client.post(
            "/api/v1/me/patient-profiles/",
            {
                "full_name": "Arun Rao",
                "relationship": "child",
                "mobile_number": "9876543299",
                "id": str(own.id),
                "patient_profile_id": str(own.id),
            },
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(created.status_code, 201, created.content)
        body = created.json()
        self.assertNotEqual(body["id"], str(own.id))
        self.assertEqual(body["relationship"], "child")
        self.assertEqual(body["mobile_number"], "+919876543299")
        self.assertEqual(body["patient_number"], "MAL-PT-000002")
        family = PatientProfile.objects.get(pk=body["id"])
        self.assertIsNone(family.user_id)

        listed = self.client.get(
            "/api/v1/me/patient-profiles/",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(
            {item["relationship"] for item in listed.json()["results"]},
            {"self", "child"},
        )

        other_access = self._sign_in("9876543211")
        hidden = self.client.get(
            "/api/v1/me/patient-profiles/",
            HTTP_AUTHORIZATION=f"Bearer {other_access}",
        )
        self.assertEqual(hidden.json()["results"], [])
        stolen = self.client.patch(
            f"/api/v1/me/patient-profiles/{body['id']}/",
            {"full_name": "Not Arun", "relationship": "spouse"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {other_access}",
        )
        self.assertEqual(stolen.status_code, 404)
        self.assertEqual(PatientProfile.objects.get(pk=body["id"]).full_name, "Arun Rao")

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

    def test_family_mobile_can_be_corrected_and_the_member_removed(self):
        self.client.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "Lakshmi Rao"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        created = self.client.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "Arun Rao", "relationship": "child", "mobile_number": "9876543299"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        profile_id = created.json()["id"]
        invalid = self.client.patch(
            f"/api/v1/me/patient-profiles/{profile_id}/",
            {"mobile_number": "123"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(invalid.status_code, 400)
        field = invalid.json()["error"]["fields"]["mobile_number"]
        text = field[0] if isinstance(field, list) else field
        self.assertIn("10-digit", text)
        self.assertEqual(PatientProfile.objects.get(pk=profile_id).mobile_number, "+919876543299")

        corrected = self.client.patch(
            f"/api/v1/me/patient-profiles/{profile_id}/",
            {"mobile_number": "9876543288", "full_name": "Arun Kumar"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(corrected.status_code, 200, corrected.content)
        self.assertEqual(corrected.json()["mobile_number"], "+919876543288")
        self.assertEqual(corrected.json()["full_name"], "Arun Kumar")

        own = PatientProfile.objects.get(user__mobile_number="+919876543210")
        locked = self.client.delete(
            f"/api/v1/me/patient-profiles/{own.id}/",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(locked.status_code, 409)
        self.assertTrue(PatientProfile.objects.filter(pk=own.id).exists())

        removed = self.client.delete(
            f"/api/v1/me/patient-profiles/{profile_id}/",
            HTTP_AUTHORIZATION=f"Bearer {self.access}",
        )
        self.assertEqual(removed.status_code, 204)
        self.assertFalse(PatientProfile.objects.filter(pk=profile_id).exists())

    def test_self_profile_and_link_roll_back_together(self):
        user = User.objects.create_user("+919800000001")

        class LinkFailed(Exception):
            pass

        with patch(
            "apps.patients.services.FamilyRelationship.objects.create",
            side_effect=LinkFailed,
        ):
            with self.assertRaises(LinkFailed):
                create_own_profile(user, {"full_name": "Lakshmi Rao"})
        self.assertFalse(PatientProfile.objects.filter(user=user).exists())

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
