from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.bookings.models import Booking, BookingStatus, BookingType
from apps.bookings.services import hospital_today
from apps.catalogue.models import Doctor
from apps.patients.models import PatientProfile


class DashboardTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user("+919876543210")
        self.profile = PatientProfile.objects.create(
            user=self.owner,
            patient_number="MAL-PT-000041",
            full_name="Lakshmi Rao",
            mobile_number="+919876543210",
        )
        self.doctor = Doctor.objects.create(full_name="Consultation doctor")
        self.staff_user = User.objects.create_user(
            "+919800000199",
            password="staff-secret",
            user_kind=UserKind.STAFF,
        )
        today = hospital_today()
        self._booking("MAL-BK-000001", today, BookingStatus.REQUESTED, "one")
        self._booking(
            "MAL-BK-000002",
            today - timedelta(days=1),
            BookingStatus.CONFIRMED,
            "two",
            confirmed_for=timezone.now(),
            confirmed_by=self.staff_user,
        )
        self.patient = APIClient()
        self.patient.force_authenticate(self.owner)
        self.staff = APIClient()
        self.staff.force_authenticate(self.staff_user)

    def _booking(self, reference, requested_date, status, key, confirmed_for=None, confirmed_by=None):
        Booking.objects.create(
            reference=reference,
            patient_profile=self.profile,
            requested_by=self.owner,
            booking_type=BookingType.CONSULTATION,
            doctor=self.doctor,
            requested_date=requested_date,
            preferred_time_slot="10:00",
            status=status,
            idempotency_key=key,
            confirmed_for=confirmed_for,
            confirmed_by=confirmed_by,
            patient_note="Bring the old report",
        )

    def test_staff_see_counts_by_status_for_the_requested_date(self):
        denied = self.patient.get("/api/v1/admin/dashboard/")
        self.assertEqual(denied.status_code, 403)

        everything = self.staff.get("/api/v1/admin/dashboard/")
        self.assertEqual(everything.status_code, 200, everything.content)
        body = everything.json()
        self.assertEqual(body["total"], 2)
        self.assertEqual(body["by_status"]["requested"], 1)
        self.assertEqual(body["by_status"]["confirmed"], 1)
        self.assertEqual(body["by_status"]["rejected"], 0)
        self.assertIsNone(body["from"])
        self.assertNotIn("Bring the old report", everything.content.decode())

        today = hospital_today().isoformat()
        limited = self.staff.get("/api/v1/admin/dashboard/", {"from": today, "to": today})
        self.assertEqual(limited.json()["total"], 1)
        self.assertEqual(limited.json()["by_status"]["requested"], 1)
        self.assertEqual(limited.json()["by_status"]["confirmed"], 0)

        invalid = self.staff.get("/api/v1/admin/dashboard/", {"from": "2026-10-22", "to": "2026-10-21"})
        self.assertEqual(invalid.status_code, 400)
        self.assertIn("to", invalid.json()["error"]["fields"])
