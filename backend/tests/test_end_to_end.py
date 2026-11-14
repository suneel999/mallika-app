"""One patient and one receptionist go through everything the app does.

Run this on PostgreSQL before a release (see config/settings/test_postgres.py).
It is the test that catches a query PostgreSQL refuses and SQLite accepts.
"""

from datetime import timedelta

from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.accounts.senders import CapturingOtpSender
from apps.bookings.services import hospital_today


class WholeFlowTests(TestCase):
    def setUp(self):
        CapturingOtpSender.reset()
        call_command("publish_launch_catalogue", verbosity=0)
        User.objects.create_superuser("9800000111", "desk-secret-1")
        self.when = (hospital_today() + timedelta(days=2)).isoformat()

    def _patient(self):
        client = APIClient()
        asked = client.post("/api/v1/auth/otp/request/", {"mobile_number": "9876543210"}, format="json")
        self.assertEqual(asked.status_code, 200, asked.content)
        code = CapturingOtpSender.sent[-1][1]
        signed_in = client.post(
            "/api/v1/auth/otp/verify/", {"mobile_number": "9876543210", "code": code}, format="json"
        )
        self.assertEqual(signed_in.status_code, 200, signed_in.content)
        tokens = signed_in.json()
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        return client, tokens

    def _staff(self):
        client = APIClient()
        signed_in = client.post(
            "/api/v1/auth/staff/login/",
            {"mobile_number": "9800000111", "password": "desk-secret-1"},
            format="json",
        )
        self.assertEqual(signed_in.status_code, 200, signed_in.content)
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {signed_in.json()['access']}")
        return client

    def _request(self, patient, profile_id, key, service_id=None, slot="10:00"):
        body = {"patient_profile_id": profile_id, "requested_date": self.when, "preferred_time_slot": slot}
        if service_id:
            body["service_id"] = service_id
        created = patient.post("/api/v1/bookings/", body, format="json", HTTP_IDEMPOTENCY_KEY=key)
        self.assertEqual(created.status_code, 201, created.content)
        return created.json()["id"]

    def _review(self, staff, booking_id, status, confirmed_for=None, expect=200):
        body = {"status": status}
        if confirmed_for:
            body["confirmed_for"] = confirmed_for
        done = staff.patch(f"/api/v1/admin/bookings/{booking_id}/", body, format="json")
        self.assertEqual(done.status_code, expect, done.content)
        return done

    def test_sign_in_request_confirm_reject_cancel_updates_and_delete(self):
        patient, tokens = self._patient()
        profile = patient.post(
            "/api/v1/me/patient-profiles/",
            {"full_name": "Mr Suneel Kumar", "preferred_language": "en"},
            format="json",
        )
        self.assertEqual(profile.status_code, 201, profile.content)
        profile_id = profile.json()["id"]

        options = patient.get("/api/v1/booking-options/").json()
        self.assertEqual(options["consultation_doctor"]["full_name"], "Dr. J Mahesh Babu")
        services = {item["name"]: item["id"] for item in options["services"]}
        self.assertEqual(sorted(services), ["4D Echo", "CT Angio", "CT Calcium"])

        consultation = self._request(patient, profile_id, "flow-consultation")
        echo = self._request(patient, profile_id, "flow-echo", services["4D Echo"], "11:00")
        calcium = self._request(patient, profile_id, "flow-calcium", services["CT Calcium"], "12:00")
        angio = self._request(patient, profile_id, "flow-angio", services["CT Angio"], "16:00")
        again = patient.post(
            "/api/v1/bookings/",
            {"patient_profile_id": profile_id, "requested_date": self.when, "preferred_time_slot": "10:00"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="flow-consultation",
        )
        self.assertEqual(again.json()["id"], consultation)

        staff = self._staff()
        queue = staff.get("/api/v1/admin/bookings/?status=requested").json()
        self.assertEqual(queue["count"], 4)
        self.assertEqual(queue["results"][0]["patient_mobile_number"], "+919876543210")
        self.assertEqual(staff.get(f"/api/v1/admin/bookings/{echo}/").status_code, 200)

        # Consultation: review, then confirm a time. This is the one-step confirm on the desk.
        self._review(staff, consultation, "under_review")
        confirmed = self._review(staff, consultation, "confirmed", f"{self.when}T10:30:00+05:30")
        self.assertIsNotNone(confirmed.json()["confirmed_for"])
        # 4D Echo: confirmed, then the patient comes.
        self._review(staff, echo, "under_review")
        self._review(staff, echo, "confirmed", f"{self.when}T11:00:00+05:30")
        self._review(staff, echo, "completed")
        # CT Calcium: rejected straight from the new request.
        self._review(staff, calcium, "rejected")
        self._review(staff, calcium, "confirmed", f"{self.when}T12:00:00+05:30", expect=409)
        # CT Angio: confirmed, the patient asks to cancel, staff accept.
        self._review(staff, angio, "under_review")
        self._review(staff, angio, "confirmed", f"{self.when}T16:00:00+05:30")
        asked = patient.post(
            f"/api/v1/bookings/{angio}/cancellation-requests/", {"reason": "Travelling"}, format="json"
        )
        self.assertEqual(asked.status_code, 201, asked.content)
        self._review(staff, angio, "cancelled")

        check = staff.patch(
            f"/api/v1/admin/bookings/{consultation}/hims-reconciliation/",
            {"status": "entered_in_hims", "hims_appointment_id": "H-1001"},
            format="json",
        )
        self.assertEqual(check.status_code, 200, check.content)

        mine = {row["id"]: row["status"] for row in patient.get("/api/v1/bookings/").json()["results"]}
        self.assertEqual(
            mine,
            {consultation: "confirmed", echo: "completed", calcium: "rejected", angio: "cancelled"},
        )
        updates = patient.get("/api/v1/notifications/").json()["results"]
        self.assertGreaterEqual(len(updates), 8)
        self.assertTrue(all(row["title"] for row in updates))

        counts = staff.get("/api/v1/admin/dashboard/").json()
        self.assertEqual(counts["total"], 4)
        self.assertEqual(counts["by_status"]["confirmed"], 1)
        found = staff.get("/api/v1/admin/patients/?q=Suneel").json()
        self.assertEqual(found["count"], 1)
        self.assertGreaterEqual(staff.get("/api/v1/admin/audit-logs/").json()["count"], 1)

        refreshed = APIClient().post("/api/v1/auth/token/refresh/", {"refresh": tokens["refresh"]}, format="json")
        self.assertEqual(refreshed.status_code, 200, refreshed.content)
        # The refresh token is used once. The old access token stops with it.
        self.assertEqual(patient.get("/api/v1/bookings/").status_code, 401)
        patient.credentials(HTTP_AUTHORIZATION=f"Bearer {refreshed.json()['access']}")
        self.assertEqual(patient.get("/api/v1/bookings/").status_code, 200)

        gone = patient.post("/api/v1/me/account-deletion/")
        self.assertEqual(gone.status_code, 202, gone.content)
        self.assertEqual(patient.get("/api/v1/bookings/").status_code, 401)
        waiting = staff.get("/api/v1/admin/account-deletions/").json()["results"]
        self.assertEqual(len(waiting), 1)
        self.assertEqual(waiting[0]["open_bookings"], 1)
        finished = staff.post(f"/api/v1/admin/account-deletions/{waiting[0]['id']}/complete/")
        self.assertEqual(finished.status_code, 200, finished.content)
        self.assertEqual(staff.get("/api/v1/admin/bookings/").json()["count"], 0)
        self.assertFalse(User.objects.filter(user_kind=UserKind.PATIENT).exists())
