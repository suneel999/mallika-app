from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.catalogue.models import Department, Doctor, DoctorDepartment, Service


class CatalogueApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user("+919876543210")
        self.client.force_authenticate(self.user)
        self.heart = Department.objects.create(name="Heart care", slug="heart-care", display_order=1)
        self.hidden = Department.objects.create(
            name="Hidden wing",
            slug="hidden-wing",
            display_order=0,
            is_active=False,
        )
        self.doctor = Doctor.objects.create(
            full_name="Asha Rao",
            qualification="MD",
            specialty_summary="Heart",
            display_order=1,
        )
        DoctorDepartment.objects.create(doctor=self.doctor, department=self.heart, is_primary=True)
        Doctor.objects.create(full_name="Hidden Doctor", is_active=False, display_order=0)
        self.service = Service.objects.create(
            name="Heart checkup",
            service_type="health_checkup",
            description="A planned checkup.",
            preparation_instructions="Come fasting if the hospital asks you to.",
            display_order=2,
        )
        Service.objects.create(
            name="Hidden scan",
            service_type="diagnostics",
            display_order=0,
            is_active=False,
        )

    def test_catalogue_requires_sign_in(self):
        response = APIClient().get("/api/v1/departments/")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["error"]["code"], "AUTHENTICATION_REQUIRED")

    def test_lists_active_records_in_display_order_without_prices(self):
        Department.objects.create(name="Earlier wing", slug="earlier-wing", display_order=0)
        departments = self.client.get("/api/v1/departments/")
        self.assertEqual(departments.status_code, 200)
        names = [item["name"] for item in departments.json()["results"]]
        self.assertEqual(names, ["Earlier wing", "Heart care"])
        self.assertNotIn("price", departments.content.decode())
        self.assertNotIn("fee", departments.content.decode())

        doctors = self.client.get("/api/v1/doctors/")
        self.assertEqual([item["full_name"] for item in doctors.json()["results"]], ["Asha Rao"])
        self.assertEqual(doctors.json()["results"][0]["departments"][0]["slug"], "heart-care")
        self.assertTrue(doctors.json()["results"][0]["departments"][0]["is_primary"])
        self.assertNotIn("price", doctors.content.decode())

        services = self.client.get("/api/v1/services/")
        self.assertEqual([item["name"] for item in services.json()["results"]], ["Heart checkup"])
        self.assertNotIn("price", services.content.decode())
        self.assertNotIn("fee", services.content.decode())

    def test_filters_and_hides_inactive_details(self):
        by_department = self.client.get("/api/v1/doctors/", {"department": "heart-care", "search": "asha"})
        self.assertEqual(by_department.json()["count"], 1)
        missed = self.client.get("/api/v1/doctors/", {"department": "hidden-wing"})
        self.assertEqual(missed.json()["count"], 0)

        by_type = self.client.get("/api/v1/services/", {"service_type": "health_checkup", "search": "heart"})
        self.assertEqual(by_type.json()["results"][0]["id"], str(self.service.id))

        hidden_doctor = self.client.get(f"/api/v1/doctors/{Doctor.objects.get(full_name='Hidden Doctor').id}/")
        self.assertEqual(hidden_doctor.status_code, 404)
        self.assertEqual(hidden_doctor.json()["error"]["code"], "NOT_FOUND")

        visible = self.client.get(f"/api/v1/services/{self.service.id}/")
        self.assertEqual(visible.status_code, 200)
        self.assertEqual(
            visible.json()["preparation_instructions"],
            "Come fasting if the hospital asks you to.",
        )
        self.assertNotIn("price", visible.json())
