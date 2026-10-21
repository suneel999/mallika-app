from rest_framework.exceptions import NotFound, PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import UserKind
from apps.bookings.models import Booking
from apps.bookings.serializers import BookingSerializer, StaffBookingSerializer
from apps.bookings.services import (
    PREFERRED_TIME_SLOTS,
    consultation_doctor,
    request_booking,
    request_cancellation,
    review_booking,
    visible_bookings,
)
from apps.catalogue.models import Service
from apps.catalogue.serializers import ServiceSerializer
from apps.reconciliation.services import reconciliation_summary
from config.pagination import DefaultPagination


class BookingOptionsView(APIView):
    def get(self, request):
        _require_patient(request.user)
        doctor = consultation_doctor()
        services = Service.objects.filter(is_active=True).order_by("display_order", "name")
        return Response(
            {
                "consultation_doctor": None
                if doctor is None
                else {
                    "id": str(doctor.id),
                    "full_name": doctor.full_name,
                    "qualification": doctor.qualification,
                    "specialty_summary": doctor.specialty_summary,
                    "photo_url": doctor.photo_url,
                },
                "time_slots": list(PREFERRED_TIME_SLOTS),
                "services": ServiceSerializer(services, many=True).data,
            }
        )


class BookingListView(APIView):
    def get(self, request):
        _require_patient(request.user)
        queryset = visible_bookings(request.user)
        status = request.query_params.get("status", "").strip()
        if status:
            queryset = queryset.filter(status=status)
        requested_date = request.query_params.get("requested_date", "").strip()
        if requested_date:
            queryset = queryset.filter(requested_date=requested_date)
        queryset = queryset.order_by("-created_at")
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response(BookingSerializer(page, many=True).data)

    def post(self, request):
        _require_patient(request.user)
        booking, created = request_booking(
            request.user,
            request.data,
            request.headers.get("Idempotency-Key", ""),
        )
        return Response(BookingSerializer(booking).data, status=201 if created else 200)


class BookingDetailView(APIView):
    def get(self, request, booking_id):
        _require_patient(request.user)
        booking = visible_bookings(request.user).filter(pk=booking_id).first()
        if booking is None:
            raise NotFound()
        return Response(BookingSerializer(booking).data)


class BookingCancellationView(APIView):
    def post(self, request, booking_id):
        _require_patient(request.user)
        booking = request_cancellation(request.user, booking_id, request.data.get("reason"))
        return Response(BookingSerializer(booking).data, status=201)


class StaffBookingListView(APIView):
    def get(self, request):
        _require_staff(request.user)
        queryset = Booking.objects.select_related("patient_profile", "doctor", "service", "hims_reconciliation")
        status = request.query_params.get("status", "").strip()
        if status:
            queryset = queryset.filter(status=status)
        queryset = queryset.order_by("requested_date", "created_at")
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response([_staff_booking_body(booking) for booking in page])


class StaffBookingDetailView(APIView):
    def get(self, request, booking_id):
        _require_staff(request.user)
        booking = _staff_booking(booking_id)
        if booking is None:
            raise NotFound()
        return Response(_staff_booking_body(booking))

    def patch(self, request, booking_id):
        _require_staff(request.user)
        booking = review_booking(
            request.user,
            booking_id,
            str(request.data.get("status") or "").strip(),
            request.data.get("confirmed_for"),
            request.data.get("staff_note"),
        )
        return Response(StaffBookingSerializer(booking).data)


def _staff_booking(booking_id):
    return (
        Booking.objects.select_related("patient_profile", "doctor", "service", "hims_reconciliation")
        .filter(pk=booking_id)
        .first()
    )


def _staff_booking_body(booking):
    body = StaffBookingSerializer(booking).data
    body["hims_reconciliation"] = reconciliation_summary(booking)
    return body


def _require_patient(user):
    if user.user_kind != UserKind.PATIENT:
        raise PermissionDenied()


def _require_staff(user):
    if user.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not user.is_active:
        raise PermissionDenied()
