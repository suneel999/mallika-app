from django.urls import path

from apps.accounts.views import (
    LogoutView,
    MeView,
    OtpRequestView,
    OtpVerifyView,
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
]
