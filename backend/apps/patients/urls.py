from django.urls import path

from apps.patients.views import PatientProfileDetailView, PatientProfileListView

urlpatterns = [
    path("me/patient-profiles/", PatientProfileListView.as_view(), name="patient-profiles"),
    path(
        "me/patient-profiles/<uuid:profile_id>/",
        PatientProfileDetailView.as_view(),
        name="patient-profile-detail",
    ),
]
