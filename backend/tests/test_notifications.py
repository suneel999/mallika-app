from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.bookings.services import hospital_today
from apps.catalogue.models import Doctor
from apps.content.models import Banner
from apps.notifications.models import Notification, NotificationAttempt
from apps.patients.models import PatientProfile


class NotificationTests(TestCase):
    def setUp(self):
        self.patient = User.objects.create_user("+919876543210")
        self.staff = User.objects.create_user("+919800000155", password="staff-secret", user_kind=UserKind.STAFF)
        self.profile = PatientProfile.objects.create(
            user=self.patient,
            patient_number="MAL-PT-000020",
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
            HTTP_IDEMPOTENCY_KEY="notice-1",
        )
        self.booking_id = created.json()["id"]
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

    def test_a_status_change_is_stored_for_the_patient_and_not_sent(self):
        self.staff_client.patch(
            f"/api/v1/admin/bookings/{self.booking_id}/",
            {"status": "under_review", "staff_note": "Desk only"},
            format="json",
        )
        listed = self.patient_client.get("/api/v1/notifications/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.json()["count"], 1)
        item = listed.json()["results"][0]
        self.assertEqual(item["status"], "pending")
        self.assertIn("reviewing", item["body"])
        self.assertNotIn("Desk only", item["body"])
        self.assertNotIn("token", listed.content.decode())
        stored = Notification.objects.get()
        self.assertIsNone(stored.sent_at)
        attempt = NotificationAttempt.objects.get()
        self.assertEqual(attempt.status, "skipped")
        self.assertEqual(attempt.error_code, "NO_PROVIDER")

        other = APIClient()
        other.force_authenticate(User.objects.create_user("+919800000166"))
        hidden = other.get("/api/v1/notifications/")
        self.assertEqual(hidden.json()["count"], 0)

    def test_a_device_token_belongs_to_the_signed_in_patient(self):
        registered = self.patient_client.post(
            "/api/v1/devices/",
            {"platform": "android", "token": "device-secret"},
            format="json",
        )
        self.assertEqual(registered.status_code, 201, registered.content)
        self.assertNotIn("device-secret", registered.content.decode())
        device_id = registered.json()["id"]

        moved = APIClient()
        moved.force_authenticate(User.objects.create_user("+919800000177"))
        again = moved.post(
            "/api/v1/devices/",
            {"platform": "ios", "token": "device-secret"},
            format="json",
        )
        self.assertEqual(again.status_code, 201, again.content)
        self.assertEqual(again.json()["id"], device_id)
        self.assertEqual(again.json()["platform"], "ios")

        removed = self.patient_client.delete(f"/api/v1/devices/{device_id}/")
        self.assertEqual(removed.status_code, 404)
        gone = moved.delete(f"/api/v1/devices/{device_id}/")
        self.assertEqual(gone.status_code, 204)

    def test_only_current_banners_are_listed(self):
        now = timezone.now()
        Banner.objects.create(title="Open now", display_order=1, is_active=True)
        Banner.objects.create(title="Hidden", is_active=False)
        Banner.objects.create(title="Not yet", starts_at=now + timedelta(days=2), is_active=True)
        Banner.objects.create(title="Finished", ends_at=now - timedelta(hours=1), is_active=True)
        listed = self.patient_client.get("/api/v1/banners/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual([item["title"] for item in listed.json()["results"]], ["Open now"])
        self.assertIsNone(listed.json()["results"][0]["image_url"])
