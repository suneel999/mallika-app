from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.audit.models import AuditLog
from apps.patients.models import PatientProfile


class AuditSearchTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user("+919876543210")
        self.profile = PatientProfile.objects.create(
            user=self.owner,
            patient_number="MAL-PT-000041",
            full_name="Lakshmi Rao",
            mobile_number="+919876543210",
        )
        self.staff = APIClient()
        self.staff.force_authenticate(
            User.objects.create_user("+919800000199", password="staff-secret", user_kind=UserKind.STAFF)
        )
        self.patient = APIClient()
        self.patient.force_authenticate(self.owner)

    def test_staff_can_read_the_log_without_writing_another_row(self):
        self.staff.get("/api/v1/admin/patients/", {"q": "Lakshmi"})
        before = AuditLog.objects.count()

        denied = self.patient.get("/api/v1/admin/audit-logs/")
        self.assertEqual(denied.status_code, 403)
        self.assertEqual(AuditLog.objects.count(), before)

        listed = self.staff.get("/api/v1/admin/audit-logs/", {"action": "patient.search"})
        self.assertEqual(listed.status_code, 200, listed.content)
        self.assertEqual(AuditLog.objects.count(), before)
        row = listed.json()["results"][0]
        self.assertEqual(row["action"], "patient.search")
        self.assertEqual(row["actor_mobile_number"], "+919800000199")
        self.assertEqual(row["details"], {"result_count": 1})
        self.assertNotIn("Lakshmi", listed.content.decode())
        self.assertNotIn("9876543210", listed.content.decode())
