from rest_framework import serializers

from apps.catalogue.models import Department, Doctor, Service


class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = ["id", "name", "slug", "description"]


class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ["id", "name", "service_type", "description", "preparation_instructions"]


class DoctorSerializer(serializers.ModelSerializer):
    departments = serializers.SerializerMethodField()

    class Meta:
        model = Doctor
        fields = [
            "id",
            "full_name",
            "qualification",
            "specialty_summary",
            "bio",
            "photo_url",
            "departments",
        ]

    def get_departments(self, doctor):
        links = doctor.department_links.select_related("department").order_by(
            "-is_primary",
            "department__display_order",
            "department__name",
        )
        return [
            {
                "id": str(link.department_id),
                "name": link.department.name,
                "slug": link.department.slug,
                "is_primary": link.is_primary,
            }
            for link in links
            if link.department.is_active
        ]
