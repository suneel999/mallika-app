from rest_framework.generics import ListAPIView, RetrieveAPIView

from apps.catalogue.models import Department, Doctor, Service
from apps.catalogue.serializers import DepartmentSerializer, DoctorSerializer, ServiceSerializer


def _search(queryset, request, field):
    term = request.query_params.get("search", "").strip()[:80]
    if term:
        return queryset.filter(**{f"{field}__icontains": term})
    return queryset


class DepartmentListView(ListAPIView):
    serializer_class = DepartmentSerializer

    def get_queryset(self):
        return _search(
            Department.objects.filter(is_active=True),
            self.request,
            "name",
        ).order_by("display_order", "name")


class DepartmentDetailView(RetrieveAPIView):
    serializer_class = DepartmentSerializer
    lookup_url_kwarg = "department_id"

    def get_queryset(self):
        return Department.objects.filter(is_active=True)


class DoctorListView(ListAPIView):
    serializer_class = DoctorSerializer

    def get_queryset(self):
        queryset = Doctor.objects.filter(is_active=True).prefetch_related(
            "department_links__department"
        )
        department = self.request.query_params.get("department", "").strip()
        if department:
            queryset = queryset.filter(
                department_links__department__slug=department,
                department_links__department__is_active=True,
            )
        return _search(queryset, self.request, "full_name").order_by("display_order", "full_name").distinct()


class DoctorDetailView(RetrieveAPIView):
    serializer_class = DoctorSerializer
    lookup_url_kwarg = "doctor_id"

    def get_queryset(self):
        return Doctor.objects.filter(is_active=True).prefetch_related("department_links__department")


class ServiceListView(ListAPIView):
    serializer_class = ServiceSerializer

    def get_queryset(self):
        queryset = Service.objects.filter(is_active=True)
        service_type = self.request.query_params.get("service_type", "").strip()
        if service_type:
            queryset = queryset.filter(service_type=service_type)
        return _search(queryset, self.request, "name").order_by("display_order", "name")


class ServiceDetailView(RetrieveAPIView):
    serializer_class = ServiceSerializer
    lookup_url_kwarg = "service_id"

    def get_queryset(self):
        return Service.objects.filter(is_active=True)
