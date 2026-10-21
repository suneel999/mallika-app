from datetime import timedelta

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.bookings.models import Booking, BookingEvent, BookingStatus
from apps.bookings.services import hospital_today
from apps.catalogue.models import Doctor, Service
from apps.patients.models import PatientProfile


class BookingRequestTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user("+919876543210")
        self.client.force_authenticate(self.user)
        self.profile = PatientProfile.objects.create(
            user=self.user,
            patient_number="MAL-PT-000001",
            full_name="Lakshmi Rao",
            mobile_number="+919876543210",
        )
        self.other = PatientProfile.objects.create(
            patient_number="MAL-PT-000002",
            full_name="Someone Else",
            mobile_number="+919800000099",
        )
        self.doctor = Doctor.objects.create(full_name="Asha Rao", is_active=True)
        self.service = Service.objects.create(name="Heart checkup", service_type="health_checkup")
        self.when = (hospital_today() + timedelta(days=1)).isoformat()

    def test_request_stays_pending_and_a_retry_returns_the_same_booking(self):
        payload = {
            "patient_profile_id": str(self.profile.id),
            "service_id": str(self.service.id),
            "requested_date": self.when,
            "preferred_time_slot": "10:00",
            "patient_note": "Morning if possible",
        }
        created = self.client.post(
            "/api/v1/bookings/",
            payload,
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-1",
        )
        self.assertEqual(created.status_code, 201, created.content)
        body = created.json()
        self.assertEqual(body["status"], BookingStatus.REQUESTED)
        self.assertEqual(body["reference"], "MAL-BK-000001")
        self.assertEqual(body["booking_type"], "health_checkup")
        self.assertIsNone(body["doctor_id"])
        self.assertNotIn("price", created.content.decode())
        booking = Booking.objects.get(pk=body["id"])
        self.assertIsNone(booking.confirmed_for)
        self.assertIsNone(booking.confirmed_by_id)
        self.assertEqual(BookingEvent.objects.filter(booking=booking).count(), 1)

        replay = self.client.post(
            "/api/v1/bookings/",
            payload,
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-1",
        )
        self.assertEqual(replay.status_code, 200, replay.content)
        self.assertEqual(replay.json()["id"], body["id"])
        self.assertEqual(Booking.objects.count(), 1)

        changed = self.client.post(
            "/api/v1/bookings/",
            {**payload, "patient_note": "Evening"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-1",
        )
        self.assertEqual(changed.status_code, 409)
        self.assertEqual(Booking.objects.count(), 1)

    def test_rejects_a_past_date_a_missing_key_and_another_persons_profile(self):
        missing = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "doctor_id": str(self.doctor.id),
                "requested_date": self.when,
            },
            format="json",
        )
        self.assertEqual(missing.status_code, 400)
        self.assertIn("idempotency_key", missing.json()["error"]["fields"])

        past = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "doctor_id": str(self.doctor.id),
                "requested_date": "2000-01-01",
                "preferred_time_slot": "10:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-2",
        )
        self.assertEqual(past.status_code, 400)
        self.assertIn("requested_date", past.json()["error"]["fields"])

        foreign = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.other.id),
                "requested_date": self.when,
                "preferred_time_slot": "10:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-3",
        )
        self.assertEqual(foreign.status_code, 400)
        self.assertFalse(Booking.objects.exists())

        both = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "doctor_id": str(self.doctor.id),
                "service_id": str(self.service.id),
                "requested_date": self.when,
                "preferred_time_slot": "10:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-4",
        )
        self.assertEqual(both.status_code, 201, both.content)
        self.assertIsNone(both.json()["doctor_id"])
        self.assertEqual(both.json()["service_id"], str(self.service.id))

    def test_a_patient_sees_only_their_own_requests(self):
        self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "doctor_id": str(self.doctor.id),
                "requested_date": self.when,
                "preferred_time_slot": "10:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="request-5",
        )
        listed = self.client.get("/api/v1/bookings/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.json()["count"], 1)
        self.assertEqual(listed.json()["results"][0]["doctor_name"], "Asha Rao")

        other_user = User.objects.create_user("+919800000088")
        other_client = APIClient()
        other_client.force_authenticate(other_user)
        booking_id = listed.json()["results"][0]["id"]
        hidden = other_client.get(f"/api/v1/bookings/{booking_id}/")
        self.assertEqual(hidden.status_code, 404)

        staff = User.objects.create_user("+919800000077", user_kind=UserKind.STAFF)
        staff_client = APIClient()
        staff_client.force_authenticate(staff)
        denied = staff_client.get("/api/v1/bookings/")
        self.assertEqual(denied.status_code, 403)

    def test_consultation_uses_the_one_doctor_and_a_listed_time(self):
        other = Doctor.objects.create(full_name="Other Doctor", display_order=5, is_active=True)
        created = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "doctor_id": str(other.id),
                "requested_date": self.when,
                "preferred_time_slot": "16:00",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="consult-1",
        )
        self.assertEqual(created.status_code, 201, created.content)
        self.assertEqual(created.json()["doctor_id"], str(self.doctor.id))
        self.assertEqual(created.json()["doctor_name"], "Asha Rao")
        self.assertEqual(created.json()["preferred_time_slot"], "16:00")
        self.assertIsNone(created.json()["service_id"])

        missing_time = self.client.post(
            "/api/v1/bookings/",
            {
                "patient_profile_id": str(self.profile.id),
                "requested_date": self.when,
                "preferred_time_slot": "15:30",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="consult-2",
        )
        self.assertEqual(missing_time.status_code, 400)
        self.assertIn("preferred_time_slot", missing_time.json()["error"]["fields"])

        options = self.client.get("/api/v1/booking-options/")
        self.assertEqual(options.status_code, 200)
        self.assertEqual(options.json()["consultation_doctor"]["full_name"], "Asha Rao")
        self.assertIn("10:00", options.json()["time_slots"])
        self.assertNotIn("departments", options.json())
        self.assertNotIn("price", options.content.decode())
