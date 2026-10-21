import uuid

from django.db import models


class ServiceType(models.TextChoices):
    DIAGNOSTICS = "diagnostics", "Diagnostics"
    HEALTH_CHECKUP = "health_checkup", "Health checkup"
    PROCEDURE = "procedure", "Procedure"
    CONSULTATION = "consultation", "Consultation"


class Department(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    slug = models.SlugField(max_length=140, unique=True)
    description = models.TextField(null=True, blank=True)
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "catalogue_department"
        ordering = ["display_order", "name"]

    def __str__(self):
        return self.name


class Doctor(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    full_name = models.CharField(max_length=160)
    qualification = models.CharField(max_length=200, null=True, blank=True)
    specialty_summary = models.CharField(max_length=250, null=True, blank=True)
    bio = models.TextField(null=True, blank=True)
    photo_url = models.TextField(null=True, blank=True)
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    departments = models.ManyToManyField(
        Department,
        through="DoctorDepartment",
        related_name="doctors",
        blank=True,
    )

    class Meta:
        db_table = "catalogue_doctor"
        ordering = ["display_order", "full_name"]

    def __str__(self):
        return self.full_name


class DoctorDepartment(models.Model):
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name="department_links")
    department = models.ForeignKey(
        Department,
        on_delete=models.CASCADE,
        related_name="doctor_links",
    )
    is_primary = models.BooleanField(default=False)

    class Meta:
        db_table = "catalogue_doctor_department"
        constraints = [
            models.UniqueConstraint(
                fields=["doctor", "department"],
                name="catalogue_doctor_department_uniq",
            ),
        ]


class Service(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=160)
    service_type = models.CharField(max_length=24, choices=ServiceType.choices)
    description = models.TextField(null=True, blank=True)
    preparation_instructions = models.TextField(null=True, blank=True)
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "catalogue_service"
        ordering = ["display_order", "name"]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(service_type__in=[choice.value for choice in ServiceType]),
                name="catalogue_service_type_valid",
            ),
        ]

    def __str__(self):
        return self.name
