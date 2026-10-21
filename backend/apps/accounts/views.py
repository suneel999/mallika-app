from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import UserKind
from apps.accounts.services import logout_session, refresh_session, request_otp, verify_otp
from apps.patients.models import PatientProfile
from apps.patients.serializers import PatientProfileSerializer


class OtpRequestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        return Response(request_otp(request.data.get("mobile_number")))


class OtpVerifyView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        issued = verify_otp(request.data.get("mobile_number"), request.data.get("code"))
        return Response(_session_body(_user_from_access(issued["access"]), issued))


class TokenRefreshView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        issued = refresh_session(request.data.get("refresh"))
        user = _user_from_access(issued["access"])
        return Response(_session_body(user, issued))


class LogoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        logout_session(request.data.get("refresh"))
        return Response(status=204)


class MeView(APIView):
    def get(self, request):
        return Response(_account_body(request.user))


def _user_from_access(access: str):
    from apps.accounts.authentication import read_access_token
    from apps.accounts.models import User

    uid, _session_id = read_access_token(access)
    return User.objects.get(pk=uid)


def _session_body(user, issued: dict) -> dict:
    return {
        "access": issued["access"],
        "refresh": issued["refresh"],
        "user": _account_body(user),
    }


def _account_body(user) -> dict:
    if user.user_kind != UserKind.PATIENT:
        profile = None
    else:
        profile = PatientProfile.objects.filter(user=user).first()
    return {
        "id": str(user.id),
        "mobile_number": user.mobile_number,
        "preferred_language": user.preferred_language,
        "user_kind": user.user_kind,
        "profile": None if profile is None else PatientProfileSerializer(profile).data,
    }
