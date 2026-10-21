from zoneinfo import ZoneInfo

from django.utils import timezone
from rest_framework import serializers

from apps.accounts.models import PreferredLanguage
from apps.patients.models import PatientProfile, Sex

HOSPITAL_ZONE = ZoneInfo("Asia/Kolkata")


class PatientProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientProfile
        fields = [
            "id",
            "patient_number",
            "full_name",
            "date_of_birth",
            "sex",
            "mobile_number",
            "email",
            "preferred_language",
            "hims_patient_id",
        ]
        read_only_fields = [
            "id",
            "patient_number",
            "mobile_number",
            "hims_patient_id",
        ]

    def validate_full_name(self, value):
        name = " ".join(str(value or "").split())
        if len(name) < 2:
            raise serializers.ValidationError(
                "Enter your full name as it appears on an identity document."
            )
        return name

    def validate_date_of_birth(self, value):
        if value is None:
            return value
        today = timezone.now().astimezone(HOSPITAL_ZONE).date()
        if value > today or value.year < 1900:
            raise serializers.ValidationError("Enter a valid date of birth.")
        return value

    def validate_sex(self, value):
        if value in ("", None):
            return None
        if value not in Sex.values:
            raise serializers.ValidationError("Choose male, female, or other.")
        return value

    def validate_preferred_language(self, value):
        if value not in PreferredLanguage.values:
            raise serializers.ValidationError("Choose English or Telugu.")
        return value

    def validate_email(self, value):
        if value in ("", None):
            return None
        return value
