from django.db.models import Q
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.accounts.models import UserKind
from apps.accounts.phone import normalize_indian_mobile
from apps.audit.services import record_audit
from apps.patients.models import PatientProfile
from apps.patients.serializers import PatientProfileSerializer

_EDITABLE = {"full_name", "date_of_birth", "sex", "email", "preferred_language"}


def search_patients(actor, raw_query, request):
    _require_staff(actor)
    term = " ".join(str(raw_query or "").split())
    if len(term) < 2:
        raise ValidationError({"q": "Enter at least two characters."})
    if len(term) > 80:
        term = term[:80]
    query = Q(patient_number__iexact=term) | Q(full_name__icontains=term)
    mobile = _mobile_query(term)
    if mobile is not None:
        query = query | Q(mobile_number=mobile)
    queryset = PatientProfile.objects.filter(query).order_by("full_name", "patient_number")
    record_audit(
        actor,
        "patient.search",
        "patient_profile",
        None,
        request,
        {"result_count": queryset.count()},
    )
    return queryset


def get_patient(actor, profile_id, request) -> PatientProfile:
    _require_staff(actor)
    profile = PatientProfile.objects.filter(pk=profile_id).first()
    if profile is None:
        raise NotFound()
    record_audit(actor, "patient.view", "patient_profile", profile.id, request, {})
    return profile


def update_patient(actor, profile_id, data, request) -> PatientProfile:
    _require_staff(actor)
    if not isinstance(data, dict):
        raise ValidationError({"full_name": "Choose a field to update."})
    unknown = [field for field in data if field not in _EDITABLE]
    if unknown:
        raise ValidationError({field: "This field cannot be changed here." for field in unknown})
    if not data:
        raise ValidationError({"full_name": "Choose a field to update."})
    profile = PatientProfile.objects.filter(pk=profile_id).first()
    if profile is None:
        raise NotFound()
    serializer = PatientProfileSerializer(profile, data=data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    record_audit(
        actor,
        "patient.update",
        "patient_profile",
        profile.id,
        request,
        {"fields": sorted(data)},
    )
    return profile


def search_body(profile: PatientProfile) -> dict:
    return {
        "id": str(profile.id),
        "patient_number": profile.patient_number,
        "full_name": profile.full_name,
        "mobile_number": profile.mobile_number,
    }


def detail_body(profile: PatientProfile) -> dict:
    return {
        **search_body(profile),
        "date_of_birth": profile.date_of_birth,
        "sex": profile.sex,
        "email": profile.email,
        "preferred_language": profile.preferred_language,
    }


def _require_staff(user) -> None:
    if user.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not user.is_active:
        raise PermissionDenied()


def _mobile_query(term):
    try:
        return normalize_indian_mobile(term)
    except ValueError:
        return None
