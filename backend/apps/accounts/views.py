from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.deletion import (
    DELETION_DAYS,
    complete_account_deletion,
    deletion_body,
    keep_account,
    list_deletion_requests,
    request_account_deletion,
)
from apps.accounts.models import UserKind
from apps.accounts.services import logout_session, refresh_session, request_otp, staff_login, verify_otp
from apps.patients.models import PatientProfile
from apps.patients.serializers import serialize_profile
from config.pagination import DefaultPagination


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


class StaffLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        issued = staff_login(request.data.get("mobile_number"), request.data.get("password"))
        return Response(_session_body(_user_from_access(issued["access"]), issued))


class LogoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        logout_session(request.data.get("refresh"))
        return Response(status=204)


class MeView(APIView):
    def get(self, request):
        return Response(_account_body(request.user))


class AccountDeletionView(APIView):
    """The signed-in patient asks for the account and its data to be deleted."""

    def post(self, request):
        entry = request_account_deletion(request.user)
        return Response(
            {
                "status": entry.status,
                "requested_at": entry.requested_at.isoformat(),
                "delete_within_days": DELETION_DAYS,
            },
            status=202,
        )


class StaffDeletionListView(APIView):
    def get(self, request):
        queryset = list_deletion_requests(request.user, request.query_params.get("status", "pending"))
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response([deletion_body(entry) for entry in page])


class StaffDeletionCompleteView(APIView):
    def post(self, request, request_id):
        return Response(deletion_body(complete_account_deletion(request.user, request_id, request)))


class StaffDeletionKeepView(APIView):
    def post(self, request, request_id):
        return Response(deletion_body(keep_account(request.user, request_id, request)))


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
        "profile": None if profile is None else serialize_profile(profile, user),
    }
