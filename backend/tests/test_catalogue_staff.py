from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User, UserKind
from apps.catalogue.models import Department, Doctor, Service


class CatalogueStaffTests(TestCase):
    def setUp(self):
        self.patient = APIClient()
        self.patient.force_authenticate(User.objects.create_user("+919876543210"))
        self.staff = APIClient()
        self.staff.force_authenticate(
            User.objects.create_user("+919800000188", password="staff-secret", user_kind=UserKind.STAFF)
        )

    def test_staff_publish_a_doctor_and_a_service_without_a_price(self):
        denied = self.patient.post("/api/v1/admin/doctors/", {"full_name": "Asha Rao"}, format="json")
        self.assertEqual(denied.status_code, 403)
        self.assertFalse(Doctor.objects.exists())

        wing = self.staff.post("/api/v1/admin/departments/", {"name": "Heart care"}, format="json")
        self.assertEqual(wing.status_code, 201, wing.content)
        self.assertEqual(wing.json()["slug"], "heart-care")

        created = self.staff.post(
            "/api/v1/admin/doctors/",
            {
                "full_name": "Asha Rao",
                "qualification": "MD",
                "photo_url": "https://hospital.example/asha.jpg",
                "display_order": 0,
                "departments": [{"id": wing.json()["id"], "is_primary": True}],
                "price": "500",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201, created.content)
        self.assertEqual(created.json()["full_name"], "Asha Rao")
        self.assertEqual(created.json()["departments"][0]["slug"], "heart-care")
        self.assertNotIn("price", created.content.decode())

        visible = self.patient.get("/api/v1/doctors/")
        self.assertEqual([item["full_name"] for item in visible.json()["results"]], ["Asha Rao"])
        self.assertNotIn("is_active", visible.content.decode())

        service = self.staff.post(
            "/api/v1/admin/services/",
            {"name": "Heart checkup", "service_type": "health_checkup", "price": "900"},
            format="json",
        )
        self.assertEqual(service.status_code, 201, service.content)
        self.assertNotIn("price", service.content.decode())
        listed = self.patient.get("/api/v1/services/")
        self.assertEqual(listed.json()["results"][0]["name"], "Heart checkup")

    def test_an_unpublished_doctor_stays_on_the_staff_list_and_off_the_patient_list(self):
        created = self.staff.post("/api/v1/admin/doctors/", {"full_name": "Asha Rao"}, format="json")
        doctor_id = created.json()["id"]
        hidden = self.staff.patch(
            f"/api/v1/admin/doctors/{doctor_id}/",
            {"is_active": False, "photo_url": ""},
            format="json",
        )
        self.assertEqual(hidden.status_code, 200, hidden.content)
        self.assertFalse(hidden.json()["is_active"])
        self.assertIsNone(hidden.json()["photo_url"])

        staff_list = self.staff.get("/api/v1/admin/doctors/")
        self.assertEqual(staff_list.json()["count"], 1)
        patient_list = self.patient.get("/api/v1/doctors/")
        self.assertEqual(patient_list.json()["count"], 0)
        self.assertEqual(self.patient.get(f"/api/v1/doctors/{doctor_id}/").status_code, 404)

    def test_department_links_change_only_when_the_staff_send_them(self):
        wing = self.staff.post("/api/v1/admin/departments/", {"name": "Heart care"}, format="json").json()
        other = self.staff.post("/api/v1/admin/departments/", {"name": "Heart care"}, format="json")
        self.assertEqual(other.status_code, 400)
        self.assertIn("slug", other.json()["error"]["fields"])

        doctor = self.staff.post(
            "/api/v1/admin/doctors/",
            {"full_name": "Asha Rao", "departments": [{"id": wing["id"], "is_primary": True}]},
            format="json",
        ).json()
        kept = self.staff.patch(f"/api/v1/admin/doctors/{doctor['id']}/", {"qualification": "MD"}, format="json")
        self.assertEqual(kept.json()["departments"][0]["id"], wing["id"])

        cleared = self.staff.patch(
            f"/api/v1/admin/doctors/{doctor['id']}/",
            {"departments": []},
            format="json",
        )
        self.assertEqual(cleared.json()["departments"], [])

        duplicate = self.staff.patch(
            f"/api/v1/admin/doctors/{doctor['id']}/",
            {"departments": [{"id": wing["id"], "is_primary": True}, {"id": wing["id"], "is_primary": True}]},
            format="json",
        )
        self.assertEqual(duplicate.status_code, 400)

        invalid = self.staff.post(
            "/api/v1/admin/services/",
            {"name": "Scan", "service_type": "imaging"},
            format="json",
        )
        self.assertEqual(invalid.status_code, 400)
        self.assertIn("service_type", invalid.json()["error"]["fields"])
        self.assertFalse(Service.objects.exists())
        self.assertEqual(Department.objects.count(), 1)
