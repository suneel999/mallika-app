from django.db import IntegrityError, transaction

from apps.patients.models import PatientNumberCounter, PatientProfile
from config.exceptions import Conflict


def allocate_patient_number() -> str:
    with transaction.atomic():
        PatientNumberCounter.objects.get_or_create(pk=1, defaults={"last_value": 0})
        counter = PatientNumberCounter.objects.select_for_update().get(pk=1)
        counter.last_value += 1
        counter.save(update_fields=["last_value"])
        return f"MAL-PT-{counter.last_value:06d}"


def create_own_profile(user, data: dict) -> PatientProfile:
    if PatientProfile.objects.filter(user=user).exists():
        raise Conflict("Your profile is already set up. Family members are not available yet.")
    try:
        profile = PatientProfile.objects.create(
            user=user,
            patient_number=allocate_patient_number(),
            mobile_number=user.mobile_number,
            full_name=data["full_name"],
            date_of_birth=data.get("date_of_birth"),
            sex=data.get("sex") or None,
            email=data.get("email") or None,
            preferred_language=data.get("preferred_language") or user.preferred_language,
        )
    except IntegrityError as exc:
        raise Conflict("Your profile is already set up. Family members are not available yet.") from exc
    if profile.preferred_language != user.preferred_language:
        user.preferred_language = profile.preferred_language
        user.save(update_fields=["preferred_language", "updated_at"])
    return profile
