from django.db import IntegrityError, transaction
from django.db.models import Q
from rest_framework.exceptions import ValidationError

from apps.accounts.phone import normalize_indian_mobile
from apps.patients.models import FamilyRelationship, PatientNumberCounter, PatientProfile, Relationship
from config.exceptions import Conflict

_FAMILY_KINDS = {
    Relationship.SPOUSE,
    Relationship.PARENT,
    Relationship.CHILD,
    Relationship.SIBLING,
    Relationship.OTHER,
}


def allocate_patient_number() -> str:
    with transaction.atomic():
        PatientNumberCounter.objects.get_or_create(pk=1, defaults={"last_value": 0})
        counter = PatientNumberCounter.objects.select_for_update().get(pk=1)
        counter.last_value += 1
        counter.save(update_fields=["last_value"])
        return f"MAL-PT-{counter.last_value:06d}"


def create_own_profile(user, data: dict) -> PatientProfile:
    if PatientProfile.objects.filter(user=user).exists():
        raise Conflict("Your profile is already set up.")
    try:
        with transaction.atomic():
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
            FamilyRelationship.objects.create(
                owner=user,
                patient_profile=profile,
                relationship=Relationship.SELF,
                is_default=True,
            )
            if profile.preferred_language != user.preferred_language:
                user.preferred_language = profile.preferred_language
                user.save(update_fields=["preferred_language", "updated_at"])
    except IntegrityError as exc:
        raise Conflict("Your profile is already set up.") from exc
    return profile


def create_family_profile(user, data: dict) -> PatientProfile:
    if not PatientProfile.objects.filter(user=user).exists():
        raise ValidationError({"relationship": "Set up your own profile first."})
    kind = str(data.get("relationship") or "").strip()
    if kind == Relationship.SELF:
        raise Conflict("Your profile is already set up.")
    if kind not in _FAMILY_KINDS:
        raise ValidationError(
            {"relationship": "Choose spouse, parent, child, sibling, or other."}
        )
    mobile = _family_mobile(user, data.get("mobile_number"))
    make_default = bool(data.get("is_default"))
    with transaction.atomic():
        profile = PatientProfile.objects.create(
            user=None,
            patient_number=allocate_patient_number(),
            mobile_number=mobile,
            full_name=data["full_name"],
            date_of_birth=data.get("date_of_birth"),
            sex=data.get("sex") or None,
            email=data.get("email") or None,
            preferred_language=data.get("preferred_language") or user.preferred_language,
        )
        if make_default:
            FamilyRelationship.objects.filter(owner=user, is_default=True).update(is_default=False)
        FamilyRelationship.objects.create(
            owner=user,
            patient_profile=profile,
            relationship=kind,
            is_default=make_default,
        )
    return profile


def accessible_profiles(user):
    linked = FamilyRelationship.objects.filter(owner=user).values("patient_profile_id")
    return (
        PatientProfile.objects.filter(Q(user=user) | Q(pk__in=linked))
        .distinct()
        .order_by("created_at")
    )


def accessible_profile(user, profile_id):
    return accessible_profiles(user).filter(pk=profile_id).first()


def links_for(user, profiles) -> dict:
    profile_ids = [profile.id for profile in profiles]
    return {
        link.patient_profile_id: link
        for link in FamilyRelationship.objects.filter(owner=user, patient_profile_id__in=profile_ids)
    }


def update_profile_mobile(user, profile: PatientProfile, raw_mobile) -> None:
    if profile.user_id == user.id:
        if raw_mobile in ("", None):
            return
        try:
            submitted = normalize_indian_mobile(raw_mobile)
        except ValueError as exc:
            raise ValidationError({"mobile_number": str(exc)}) from exc
        if submitted != profile.mobile_number:
            raise ValidationError(
                {"mobile_number": "The signed-in patient's mobile number stays the verified account number."}
            )
        return
    profile.mobile_number = _family_mobile(user, raw_mobile)
    profile.save(update_fields=["mobile_number", "updated_at"])


def remove_family_profile(user, profile: PatientProfile) -> None:
    if profile.user_id == user.id:
        raise Conflict("Your own profile cannot be removed.")
    profile.delete()


def _family_mobile(user, raw_mobile) -> str:
    if raw_mobile in ("", None):
        return user.mobile_number
    try:
        return normalize_indian_mobile(raw_mobile)
    except ValueError as exc:
        raise ValidationError({"mobile_number": str(exc)}) from exc
