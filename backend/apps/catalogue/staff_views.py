from rest_framework.exceptions import NotFound
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.catalogue.models import Department, Doctor, Service
from apps.catalogue.staff import (
    _require_staff,
    create_department,
    create_doctor,
    create_service,
    department_body,
    doctor_body,
    service_body,
    update_department,
    update_doctor,
    update_service,
)
from config.pagination import DefaultPagination


class StaffDepartmentListView(APIView):
    def get(self, request):
        _require_staff(request.user)
        return _page(Department.objects.order_by("display_order", "name"), request, self, department_body)

    def post(self, request):
        department = create_department(request.user, request.data)
        return Response(department_body(department), status=201)


class StaffDepartmentDetailView(APIView):
    def get(self, request, department_id):
        _require_staff(request.user)
        department = Department.objects.filter(pk=department_id).first()
        if department is None:
            raise NotFound()
        return Response(department_body(department))

    def patch(self, request, department_id):
        department = update_department(request.user, department_id, request.data)
        return Response(department_body(department))


class StaffDoctorListView(APIView):
    def get(self, request):
        _require_staff(request.user)
        queryset = Doctor.objects.prefetch_related("department_links__department").order_by("display_order", "full_name")
        return _page(queryset, request, self, doctor_body)

    def post(self, request):
        doctor = create_doctor(request.user, request.data)
        return Response(doctor_body(doctor), status=201)


class StaffDoctorDetailView(APIView):
    def get(self, request, doctor_id):
        _require_staff(request.user)
        doctor = Doctor.objects.filter(pk=doctor_id).first()
        if doctor is None:
            raise NotFound()
        return Response(doctor_body(doctor))

    def patch(self, request, doctor_id):
        doctor = update_doctor(request.user, doctor_id, request.data)
        return Response(doctor_body(doctor))


class StaffServiceListView(APIView):
    def get(self, request):
        _require_staff(request.user)
        return _page(Service.objects.order_by("display_order", "name"), request, self, service_body)

    def post(self, request):
        service = create_service(request.user, request.data)
        return Response(service_body(service), status=201)


class StaffServiceDetailView(APIView):
    def get(self, request, service_id):
        _require_staff(request.user)
        service = Service.objects.filter(pk=service_id).first()
        if service is None:
            raise NotFound()
        return Response(service_body(service))

    def patch(self, request, service_id):
        service = update_service(request.user, service_id, request.data)
        return Response(service_body(service))


def _page(queryset, request, view, present):
    paginator = DefaultPagination()
    page = paginator.paginate_queryset(queryset, request, view=view)
    return paginator.get_paginated_response([present(item) for item in page])
