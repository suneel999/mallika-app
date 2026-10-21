from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import UserKind
from apps.patients.models import PatientProfile
from apps.patients.serializers import PatientProfileSerializer
from apps.patients.services import create_own_profile


class PatientProfileListView(APIView):
    def get(self, request):
        _require_patient(request.user)
        profiles = PatientProfile.objects.filter(user=request.user).order_by("created_at")
        return Response({"results": PatientProfileSerializer(profiles, many=True).data})

    def post(self, request):
        _require_patient(request.user)
        serializer = PatientProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile = create_own_profile(request.user, serializer.validated_data)
        return Response(PatientProfileSerializer(profile).data, status=201)


class PatientProfileDetailView(APIView):
    def patch(self, request, profile_id):
        _require_patient(request.user)
        profile = PatientProfile.objects.filter(pk=profile_id, user=request.user).first()
        if profile is None:
            from rest_framework.exceptions import NotFound

            raise NotFound()
        serializer = PatientProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        if profile.preferred_language != request.user.preferred_language:
            request.user.preferred_language = profile.preferred_language
            request.user.save(update_fields=["preferred_language", "updated_at"])
        return Response(PatientProfileSerializer(profile).data)


def _require_patient(user):
    if user.user_kind != UserKind.PATIENT:
        raise PermissionDenied("You do not have permission to perform this action.")
