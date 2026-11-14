from datetime import timedelta

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import AccountDeletionRequest, RefreshSession, User, UserKind
from apps.audit.models import AuditLog
from apps.bookings.models import Booking
from apps.bookings.services import hospital_today
from apps.catalogue.models import Doctor
from apps.patients.models import FamilyRelationship, PatientProfile


class AccountDeletionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user("+919876543210")
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.profile = PatientProfile.objects.create(
            user=self.user,
            patient_number="MAL-PT-000001",
            full_name="Lakshmi Rao",
            mobile_number="+919876543210",
        )
        self.child = PatientProfile.objects.create(
            patient_number="MAL-PT-000002",
            full_name="Arun Rao",
            mobile_number="+919876543210",
        )
        FamilyRelationship.objects.create(owner=self.user, patient_profile=self.child, relationship="child")
        Doctor.objects.create(full_name="Asha Rao", is_active=True)
        created = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "requested_date": (hospital_today() + timedelta(days=1)).isoformat(),
                "preferred_time_slot": "10:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="delete-1",
        )
        self.assertEqual(created.status_code, 201, created.content)
        self.staff = User.objects.create_user("+919800000111", password="staff-secret", user_kind=UserKind.STAFF)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

    def test_a_request_switches_the_account_off_and_staff_delete_everything(self):
        signed_in = APIClient().post(
            "/api/v1/auth/otp/request/", {"mobile_number": "9876543210"}, format="json"
        )
        self.assertEqual(signed_in.status_code, 200, signed_in.content)

        asked = self.client.post("/api/v1/me/account-deletion/")
        self.assertEqual(asked.status_code, 202, asked.content)
        self.assertEqual(asked.json()["delete_within_days"], 7)
        again = self.client.post("/api/v1/me/account-deletion/")
        self.assertEqual(again.status_code, 202)
        self.assertEqual(AccountDeletionRequest.objects.count(), 1)

        self.user.refresh_from_db()
        self.assertFalse(self.user.is_active)
        self.assertFalse(RefreshSession.objects.filter(user=self.user, revoked_at__isnull=True).exists())
        refused = APIClient().post("/api/v1/auth/otp/request/", {"mobile_number": "9876543210"}, format="json")
        self.assertEqual(refused.status_code, 403)
        self.assertIn("being deleted", refused.json()["error"]["message"])

        blocked = self.client.get("/api/v1/admin/account-deletions/")
        self.assertEqual(blocked.status_code, 403)
        listed = self.staff_client.get("/api/v1/admin/account-deletions/")
        self.assertEqual(listed.status_code, 200)
        row = listed.json()["results"][0]
        self.assertEqual(row["patient_name"], "Lakshmi Rao")
        self.assertEqual(row["mobile_number"], "+919876543210")
        self.assertEqual(row["open_bookings"], 1)

        done = self.staff_client.post(f"/api/v1/admin/account-deletions/{row['id']}/complete/")
        self.assertEqual(done.status_code, 200, done.content)
        self.assertEqual(done.json()["status"], "completed")
        self.assertIsNone(done.json()["mobile_number"])
        self.assertFalse(User.objects.filter(mobile_number="+919876543210").exists())
        self.assertEqual(PatientProfile.objects.count(), 0)
        self.assertEqual(Booking.objects.count(), 0)
        self.assertEqual(FamilyRelationship.objects.count(), 0)
        entry = AccountDeletionRequest.objects.get()
        self.assertEqual(entry.mobile_number, "")
        audit = AuditLog.objects.get(action="account.delete")
        self.assertEqual(audit.details, {"profiles": 2, "bookings": 1})
        self.assertNotIn("9876543210", str(audit.details))

        twice = self.staff_client.post(f"/api/v1/admin/account-deletions/{row['id']}/complete/")
        self.assertEqual(twice.status_code, 409)
        fresh = APIClient().post("/api/v1/auth/otp/request/", {"mobile_number": "9876543210"}, format="json")
        self.assertEqual(fresh.status_code, 200, fresh.content)

    def test_staff_can_keep_the_account_and_staff_cannot_delete_their_own(self):
        self.client.post("/api/v1/me/account-deletion/")
        entry = AccountDeletionRequest.objects.get()

        kept = self.staff_client.post(f"/api/v1/admin/account-deletions/{entry.id}/keep/")
        self.assertEqual(kept.status_code, 200, kept.content)
        self.assertEqual(kept.json()["status"], "kept")
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_active)
        self.assertEqual(PatientProfile.objects.count(), 2)
        self.assertEqual(Booking.objects.count(), 1)
        pending = self.staff_client.get("/api/v1/admin/account-deletions/")
        self.assertEqual(pending.json()["count"], 0)

        own = self.staff_client.post("/api/v1/me/account-deletion/")
        self.assertEqual(own.status_code, 403)
        self.staff.refresh_from_db()
        self.assertTrue(self.staff.is_active)
