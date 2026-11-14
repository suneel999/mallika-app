from django.urls import path

from apps.accounts.views import (
    AccountDeletionView,
    LogoutView,
    MeView,
    OtpRequestView,
    OtpVerifyView,
    StaffDeletionCompleteView,
    StaffDeletionKeepView,
    StaffDeletionListView,
    StaffLoginView,
    TokenRefreshView,
)

urlpatterns = [
    path("auth/otp/request/", OtpRequestView.as_view(), name="otp-request"),
    path("auth/otp/verify/", OtpVerifyView.as_view(), name="otp-verify"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/staff/login/", StaffLoginView.as_view(), name="staff-login"),
    path("me/", MeView.as_view(), name="me"),
    path("me/account-deletion/", AccountDeletionView.as_view(), name="account-deletion"),
    path("admin/account-deletions/", StaffDeletionListView.as_view(), name="staff-account-deletions"),
    path(
        "admin/account-deletions/<uuid:request_id>/complete/",
        StaffDeletionCompleteView.as_view(),
        name="staff-account-deletion-complete",
    ),
    path(
        "admin/account-deletions/<uuid:request_id>/keep/",
        StaffDeletionKeepView.as_view(),
        name="staff-account-deletion-keep",
    ),
]
