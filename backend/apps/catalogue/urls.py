from django.urls import path

from apps.catalogue.views import (
    DepartmentDetailView,
    DepartmentListView,
    DoctorDetailView,
    DoctorListView,
    ServiceDetailView,
    ServiceListView,
)

urlpatterns = [
    path("departments/", DepartmentListView.as_view(), name="departments"),
    path("departments/<uuid:department_id>/", DepartmentDetailView.as_view(), name="department-detail"),
    path("doctors/", DoctorListView.as_view(), name="doctors"),
    path("doctors/<uuid:doctor_id>/", DoctorDetailView.as_view(), name="doctor-detail"),
    path("services/", ServiceListView.as_view(), name="services"),
    path("services/<uuid:service_id>/", ServiceDetailView.as_view(), name="service-detail"),
]
