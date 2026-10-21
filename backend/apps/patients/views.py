from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import UserKind
from apps.patients.models import Relationship
from apps.patients.serializers import PatientProfileSerializer, serialize_profile, serialize_profiles
from apps.patients.services import (
    accessible_profile,
    accessible_profiles,
    create_family_profile,
    create_own_profile,
    remove_family_profile,
    update_profile_mobile,
)


class PatientProfileListView(APIView):
    def get(self, request):
        _require_patient(request.user)
        profiles = list(accessible_profiles(request.user))
        return Response({"results": serialize_profiles(profiles, request.user)})

    def post(self, request):
        _require_patient(request.user)
        serializer = PatientProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = dict(serializer.validated_data)
        kind = str(request.data.get("relationship") or "").strip()
        payload["relationship"] = kind
        payload["is_default"] = request.data.get("is_default") is True
        payload["mobile_number"] = request.data.get("mobile_number")
        has_self = accessible_profiles(request.user).filter(user=request.user).exists()
        if has_self or kind not in ("", Relationship.SELF):
            profile = create_family_profile(request.user, payload)
        else:
            profile = create_own_profile(request.user, payload)
        return Response(serialize_profile(profile, request.user), status=201)


class PatientProfileDetailView(APIView):
    def patch(self, request, profile_id):
        _require_patient(request.user)
        profile = accessible_profile(request.user, profile_id)
        if profile is None:
            from rest_framework.exceptions import NotFound

            raise NotFound()
        serializer = PatientProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        if "mobile_number" in request.data:
            update_profile_mobile(request.user, profile, request.data.get("mobile_number"))
        _update_relationship(request, profile)
        if profile.user_id == request.user.id and profile.preferred_language != request.user.preferred_language:
            request.user.preferred_language = profile.preferred_language
            request.user.save(update_fields=["preferred_language", "updated_at"])
        return Response(serialize_profile(profile, request.user))

    def delete(self, request, profile_id):
        _require_patient(request.user)
        profile = accessible_profile(request.user, profile_id)
        if profile is None:
            from rest_framework.exceptions import NotFound

            raise NotFound()
        remove_family_profile(request.user, profile)
        return Response(status=204)


def _update_relationship(request, profile):
    if "relationship" not in request.data:
        return
    from apps.patients.models import FamilyRelationship
    from rest_framework.exceptions import ValidationError

    kind = str(request.data.get("relationship") or "").strip()
    link = FamilyRelationship.objects.filter(owner=request.user, patient_profile=profile).first()
    if link is None:
        return
    if link.relationship == Relationship.SELF or kind == Relationship.SELF:
        raise ValidationError({"relationship": "Your own profile stays marked as self."})
    if kind not in {Relationship.SPOUSE, Relationship.PARENT, Relationship.CHILD, Relationship.SIBLING, Relationship.OTHER}:
        raise ValidationError({"relationship": "Choose spouse, parent, child, sibling, or other."})
    link.relationship = kind
    link.save(update_fields=["relationship"])


def _require_patient(user):
    if user.user_kind != UserKind.PATIENT:
        raise PermissionDenied("You do not have permission to perform this action.")
