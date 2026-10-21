import uuid

from django.conf import settings
from django.db import models

from apps.accounts.models import PreferredLanguage


class Relationship(models.TextChoices):
    SELF = "self", "Self"
    SPOUSE = "spouse", "Spouse"
    PARENT = "parent", "Parent"
    CHILD = "child", "Child"
    SIBLING = "sibling", "Sibling"
    OTHER = "other", "Other"


class Sex(models.TextChoices):
    MALE = "male", "Male"
    FEMALE = "female", "Female"
    OTHER = "other", "Other"


class PatientNumberCounter(models.Model):
    id = models.PositiveSmallIntegerField(primary_key=True, default=1)
    last_value = models.PositiveIntegerField(default=0)

    class Meta:
        db_table = "patients_patientnumbercounter"


class PatientProfile(models.Model):
    """The person's hospital record. The account holder's own row sets user."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="patient_profile",
    )
    patient_number = models.CharField(max_length=32, unique=True)
    full_name = models.CharField(max_length=160)
    date_of_birth = models.DateField(null=True, blank=True)
    sex = models.CharField(max_length=16, choices=Sex.choices, null=True, blank=True)
    mobile_number = models.CharField(max_length=20)
    email = models.EmailField(null=True, blank=True)
    preferred_language = models.CharField(
        max_length=8,
        choices=PreferredLanguage.choices,
        default=PreferredLanguage.ENGLISH,
    )
    hims_patient_id = models.CharField(max_length=64, null=True, blank=True, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "patients_patientprofile"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(sex__isnull=True) | models.Q(sex__in=[Sex.MALE, Sex.FEMALE, Sex.OTHER]),
                name="patients_profile_sex_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(
                    preferred_language__in=[PreferredLanguage.ENGLISH, PreferredLanguage.TELUGU]
                ),
                name="patients_profile_language_valid",
            ),
        ]

    def __str__(self):
        return str(self.id)


class FamilyRelationship(models.Model):
    """Links an account to a profile it may book for. Profiles are not shared by id."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="family_relationships",
    )
    patient_profile = models.ForeignKey(
        PatientProfile,
        on_delete=models.CASCADE,
        related_name="family_relationships",
    )
    relationship = models.CharField(max_length=30, choices=Relationship.choices)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "patients_familyrelationship"
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "patient_profile"],
                name="patients_family_owner_profile_uniq",
            ),
            models.CheckConstraint(
                condition=models.Q(relationship__in=[item.value for item in Relationship]),
                name="patients_family_relationship_valid",
            ),
        ]

    def __str__(self):
        return str(self.id)
