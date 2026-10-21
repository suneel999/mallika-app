from datetime import timedelta

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.bookings.models import Booking, BookingStatus
from apps.bookings.services import hospital_today
from apps.catalogue.models import Doctor
from apps.patients.models import PatientProfile
from apps.reconciliation.models import HimsReconciliation, ReconciliationEvent


class HimsReconciliationTests(TestCase):
    def setUp(self):
        self.patient = User.objects.create_user("+919876543210")
        self.staff = User.objects.create_user("+919800000144", password="staff-secret", user_kind=UserKind.STAFF)
        self.profile = PatientProfile.objects.create(
            user=self.patient,
            patient_number="MAL-PT-000010",
            full_name="Lakshmi Rao",
            mobile_number="+919876543210",
        )
        Doctor.objects.create(full_name="Asha Rao", is_active=True)
        self.when = (hospital_today() + timedelta(days=1)).isoformat()
        self.patient_client = APIClient()
        self.patient_client.force_authenticate(self.patient)
        created = self.patient_client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "requested_date": self.when,
                "preferred_time_slot": "10:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="hims-1",
        )
        self.assertEqual(created.status_code, 201, created.content)
        self.booking_id = created.json()["id"]
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

    def test_a_hospital_system_check_does_not_change_the_booking(self):
        denied = self.patient_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/hims-reconciliation/",
            {"status": "entered_in_hims"},
            format="json",
        )
        self.assertEqual(denied.status_code, 403)
        self.assertFalse(HimsReconciliation.objects.exists())

        checked = self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/hims-reconciliation/",
            {
                "status": "checked_available",
                "hims_patient_id": "HIMS-PT-1",
                "note": "The visit is free in the hospital system.",
            },
            format="json",
        )
        self.assertEqual(checked.status_code, 200, checked.content)
        self.assertEqual(checked.json()["status"], "checked_available")
        self.assertEqual(checked.json()["booking_status"], BookingStatus.REQUESTED)
        self.assertEqual(Booking.objects.get(pk=self.booking_id).status, BookingStatus.REQUESTED)

        entered = self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/hims-reconciliation/",
            {"status": "entered_in_hims", "hims_appointment_id": "HIMS-AP-9"},
            format="json",
        )
        self.assertEqual(entered.status_code, 200, entered.content)
        self.assertEqual(entered.json()["booking_status"], BookingStatus.REQUESTED)
        self.assertEqual(ReconciliationEvent.objects.count(), 2)
        self.assertEqual(ReconciliationEvent.objects.order_by("created_at").last().old_status, "checked_available")

        self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/",
            {"status": "under_review"},
            format="json",
        )
        confirmed = self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/",
            {"status": "confirmed", "confirmed_for": f"{self.when}T10:00:00+05:30"},
            format="json",
        )
        self.assertEqual(confirmed.status_code, 200, confirmed.content)
        self.assertEqual(confirmed.json()["status"], "confirmed")
        self.assertEqual(HimsReconciliation.objects.get().status, "entered_in_hims")
        self.assertNotIn("hims", confirmed.content.decode())

        invalid = self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/hims-reconciliation/",
            {"status": "reconciled"},
            format="json",
        )
        self.assertEqual(invalid.status_code, 400)
        self.assertIn("status", invalid.json()["error"]["fields"])

    def test_staff_can_read_the_saved_check_on_the_booking(self):
        before = self.staff_client.get(f"/api/v1/admin/bookings/{self.booking_id}/")
        self.assertEqual(before.status_code, 200, before.content)
        self.assertIsNone(before.json()["hims_reconciliation"])

        saved = self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/hims-reconciliation/",
            {"status": "mismatch", "hims_appointment_id": "HIMS-AP-3", "note": "Name differs."},
            format="json",
        )
        self.assertEqual(saved.status_code, 200, saved.content)

        detail = self.staff_client.get(f"/api/v1/admin/bookings/{self.booking_id}/")
        check = detail.json()["hims_reconciliation"]
        self.assertEqual(detail.json()["status"], BookingStatus.REQUESTED)
        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["hims_appointment_id"], "HIMS-AP-3")
        self.assertEqual(check["note"], "Name differs.")

        listed = self.staff_client.get("/api/v1/admin/bookings/")
        self.assertEqual(listed.json()["results"][0]["hims_reconciliation"]["status"], "mismatch")

        own = self.patient_client.get(f"/api/v1/bookings/{self.booking_id}/")
        self.assertEqual(own.status_code, 200)
        self.assertNotIn("hims", own.content.decode())
        denied = self.patient_client.get(f"/api/v1/admin/bookings/{self.booking_id}/")
        self.assertEqual(denied.status_code, 403)
