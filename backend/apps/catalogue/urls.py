from django.urls import path

from apps.catalogue.staff_views import (
    StaffDepartmentDetailView,
    StaffDepartmentListView,
    StaffDoctorDetailView,
    StaffDoctorListView,
    StaffServiceDetailView,
    StaffServiceListView,
)
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
    path("admin/departments/", StaffDepartmentListView.as_view(), name="staff-departments"),
    path(
        "admin/departments/<uuid:department_id>/",
        StaffDepartmentDetailView.as_view(),
        name="staff-department-detail",
    ),
    path("admin/doctors/", StaffDoctorListView.as_view(), name="staff-doctors"),
    path("admin/doctors/<uuid:doctor_id>/", StaffDoctorDetailView.as_view(), name="staff-doctor-detail"),
    path("admin/services/", StaffServiceListView.as_view(), name="staff-services"),
    path("admin/services/<uuid:service_id>/", StaffServiceDetailView.as_view(), name="staff-service-detail"),
]
