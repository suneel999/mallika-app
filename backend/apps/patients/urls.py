from django.urls import path

from apps.patients.staff_views import StaffPatientDetailView, StaffPatientListView
from apps.patients.views import PatientProfileDetailView, PatientProfileListView

urlpatterns = [
    path("me/patient-profiles/", PatientProfileListView.as_view(), name="patient-profiles"),
    path(
        "me/patient-profiles/<uuid:profile_id>/",
        PatientProfileDetailView.as_view(),
        name="patient-profile-detail",
    ),
    path("admin/patients/", StaffPatientListView.as_view(), name="staff-patients"),
    path("admin/patients/<uuid:profile_id>/", StaffPatientDetailView.as_view(), name="staff-patient-detail"),
]
