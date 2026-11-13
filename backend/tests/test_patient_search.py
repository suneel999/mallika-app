from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.audit.models import AuditLog
from apps.patients.models import PatientProfile


class PatientSearchTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user("+919876543210")
        self.profile = PatientProfile.objects.create(
            user=self.owner,
            patient_number="MAL-PT-000041",
            full_name="Lakshmi Rao",
            mobile_number="+919876543210",
            email="lakshmi@example.com",
            date_of_birth="1990-04-02",
        )
        PatientProfile.objects.create(
            patient_number="MAL-PT-000042",
            full_name="Arun Rao",
            mobile_number="+919800000042",
        )
        self.patient = APIClient()
        self.patient.force_authenticate(self.owner)
        self.staff = APIClient()
        self.staff.force_authenticate(
            User.objects.create_user("+919800000199", password="staff-secret", user_kind=UserKind.STAFF)
        )

    def test_staff_can_search_by_name_number_or_mobile_without_storing_the_query(self):
        denied = self.patient.get("/api/v1/admin/patients/", {"q": "Lakshmi"})
        self.assertEqual(denied.status_code, 403)
        self.assertFalse(AuditLog.objects.exists())

        short = self.staff.get("/api/v1/admin/patients/", {"q": "L"})
        self.assertEqual(short.status_code, 400)
        self.assertIn("q", short.json()["error"]["fields"])

        by_name = self.staff.get("/api/v1/admin/patients/", {"q": "Lakshmi"})
        self.assertEqual(by_name.status_code, 200, by_name.content)
        self.assertEqual(by_name.json()["count"], 1)
        self.assertEqual(by_name.json()["results"][0]["patient_number"], "MAL-PT-000041")
        self.assertNotIn("email", by_name.content.decode())
        self.assertNotIn("lakshmi@example.com", by_name.content.decode())

        by_number = self.staff.get("/api/v1/admin/patients/", {"q": "MAL-PT-000042"})
        self.assertEqual(by_number.json()["results"][0]["full_name"], "Arun Rao")

        by_mobile = self.staff.get("/api/v1/admin/patients/", {"q": "9876543210"})
        self.assertEqual(by_mobile.json()["results"][0]["id"], str(self.profile.id))

        searches = AuditLog.objects.filter(action="patient.search")
        self.assertEqual(searches.count(), 3)
        for search in searches:
            self.assertEqual(set(search.details), {"result_count"})
            self.assertEqual(search.details["result_count"], 1)
            self.assertNotIn("Lakshmi", str(search.details))
            self.assertNotIn("9876543210", str(search.details))
            self.assertIsNone(search.entity_id)

    def test_opening_and_correcting_a_profile_is_audited_without_the_new_value(self):
        opened = self.staff.get(f"/api/v1/admin/patients/{self.profile.id}/")
        self.assertEqual(opened.status_code, 200, opened.content)
        self.assertEqual(opened.json()["email"], "lakshmi@example.com")
        self.assertTrue(AuditLog.objects.filter(action="patient.view", entity_id=self.profile.id).exists())

        locked = self.staff.patch(
            f"/api/v1/admin/patients/{self.profile.id}/",
            {"mobile_number": "+919800000111"},
            format="json",
        )
        self.assertEqual(locked.status_code, 400)
        self.assertEqual(PatientProfile.objects.get(pk=self.profile.id).mobile_number, "+919876543210")
        self.assertFalse(AuditLog.objects.filter(action="patient.update").exists())

        saved = self.staff.patch(
            f"/api/v1/admin/patients/{self.profile.id}/",
            {"email": "desk@example.com"},
            format="json",
        )
        self.assertEqual(saved.status_code, 200, saved.content)
        self.assertEqual(saved.json()["email"], "desk@example.com")
        update = AuditLog.objects.get(action="patient.update")
        self.assertEqual(update.details, {"fields": ["email"]})
        self.assertNotIn("desk@example.com", str(update.details))
