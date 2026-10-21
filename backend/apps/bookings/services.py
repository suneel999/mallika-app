from datetime import datetime
from zoneinfo import ZoneInfo

from django.db import IntegrityError, transaction
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.accounts.models import UserKind
from apps.bookings.models import (
    Booking,
    BookingEvent,
    BookingNumberCounter,
    BookingStatus,
    BookingType,
    CancellationRequest,
    CancellationRequestStatus,
)
from apps.catalogue.models import Doctor, Service
from apps.patients.services import accessible_profile
from config.exceptions import Conflict

HOSPITAL_ZONE = ZoneInfo("Asia/Kolkata")

# Preference windows for v1. The hospital confirms the visit; these are not live open slots.
PREFERRED_TIME_SLOTS = ("09:00", "10:00", "11:00", "12:00", "16:00", "17:00", "18:00")


def hospital_today():
    return datetime.now(HOSPITAL_ZONE).date()


def allocate_booking_reference() -> str:
    with transaction.atomic():
        BookingNumberCounter.objects.get_or_create(pk=1, defaults={"last_value": 0})
        counter = BookingNumberCounter.objects.select_for_update().get(pk=1)
        counter.last_value += 1
        counter.save(update_fields=["last_value"])
        return f"MAL-BK-{counter.last_value:06d}"


def consultation_doctor():
    """The one v1 consultation doctor. Department choice arrives in a later version."""
    return Doctor.objects.filter(is_active=True).order_by("display_order", "full_name").first()


def visible_bookings(user):
    return Booking.objects.filter(requested_by=user).select_related(
        "patient_profile",
        "doctor",
        "service",
    )


def request_booking(user, data: dict, idempotency_key: str) -> tuple[Booking, bool]:
    key = (idempotency_key or "").strip()
    if not key or len(key) > 80:
        raise ValidationError({"idempotency_key": "Send an Idempotency-Key header of up to 80 characters."})

    profile = accessible_profile(user, data.get("patient_profile_id"))
    if profile is None:
        raise ValidationError({"patient_profile_id": "Choose a profile linked to this account."})

    service_id = data.get("service_id") or None
    doctor = None
    service = None
    if service_id:
        service = Service.objects.filter(pk=service_id, is_active=True).first()
        if service is None:
            raise NotFound("That service is not available to request.")
        booking_type = service.service_type
    else:
        doctor = consultation_doctor()
        if doctor is None:
            raise ValidationError(
                {"doctor": "The hospital has not published the consultation doctor yet."}
            )
        booking_type = BookingType.CONSULTATION

    requested_date = _parse_date(data.get("requested_date"))
    if requested_date < hospital_today():
        raise ValidationError({"requested_date": "Date must be today or later."})

    slot = (data.get("preferred_time_slot") or "").strip()
    if slot not in PREFERRED_TIME_SLOTS:
        raise ValidationError({"preferred_time_slot": "Choose one of the listed times."})
    note = (data.get("patient_note") or "").strip() or None

    existing = Booking.objects.filter(requested_by=user, idempotency_key=key).first()
    if existing is not None:
        if _same_request(existing, profile.id, doctor, service, requested_date, slot, note):
            return existing, False
        raise Conflict("This Idempotency-Key was already used for a different booking request.")

    try:
        with transaction.atomic():
            booking = Booking.objects.create(
                reference=allocate_booking_reference(),
                patient_profile=profile,
                requested_by=user,
                booking_type=booking_type,
                doctor=doctor,
                service=service,
                requested_date=requested_date,
                preferred_time_slot=slot,
                patient_note=note,
                status=BookingStatus.REQUESTED,
                idempotency_key=key,
            )
            BookingEvent.objects.create(
                booking=booking,
                from_status=None,
                to_status=BookingStatus.REQUESTED,
                actor=user,
                metadata={},
            )
    except IntegrityError as exc:
        existing = Booking.objects.filter(requested_by=user, idempotency_key=key).first()
        if existing is not None and _same_request(existing, profile.id, doctor, service, requested_date, slot, note):
            return existing, False
        raise Conflict("This Idempotency-Key was already used for a different booking request.") from exc
    return booking, True


_STAFF_TRANSITIONS = {
    BookingStatus.REQUESTED: {BookingStatus.UNDER_REVIEW, BookingStatus.REJECTED},
    BookingStatus.UNDER_REVIEW: {BookingStatus.CONFIRMED, BookingStatus.REJECTED},
    BookingStatus.CONFIRMED: {BookingStatus.COMPLETED, BookingStatus.NO_SHOW, BookingStatus.CANCELLED},
    BookingStatus.CANCELLATION_REQUESTED: {BookingStatus.CANCELLED, BookingStatus.CONFIRMED},
}

_CANCELLABLE = {BookingStatus.REQUESTED, BookingStatus.UNDER_REVIEW, BookingStatus.CONFIRMED}


def request_cancellation(user, booking_id, reason) -> Booking:
    note = (reason or "").strip() or None
    try:
        with transaction.atomic():
            booking = (
                Booking.objects.select_for_update()
                .select_related("patient_profile", "doctor", "service")
                .filter(pk=booking_id, requested_by=user)
                .first()
            )
            if booking is None:
                raise NotFound()
            if booking.status not in _CANCELLABLE:
                raise Conflict("This request can no longer be cancelled.")
            if booking.cancellation_requests.filter(status=CancellationRequestStatus.OPEN).exists():
                raise Conflict("A cancellation request is already open.")
            from_status = booking.status
            CancellationRequest.objects.create(
                booking=booking,
                requested_by=user,
                reason=note,
                status=CancellationRequestStatus.OPEN,
            )
            booking.status = BookingStatus.CANCELLATION_REQUESTED
            booking.save(update_fields=["status", "updated_at"])
            BookingEvent.objects.create(
                booking=booking,
                from_status=from_status,
                to_status=BookingStatus.CANCELLATION_REQUESTED,
                actor=user,
                note=note,
                metadata={},
            )
    except IntegrityError as exc:
        raise Conflict("A cancellation request is already open.") from exc
    return booking


def review_booking(actor, booking_id, status, confirmed_for_raw, staff_note) -> Booking:
    if actor.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not actor.is_active:
        raise PermissionDenied()
    note = (staff_note or "").strip() or None
    with transaction.atomic():
        booking = (
            Booking.objects.select_for_update()
            .select_related("patient_profile", "doctor", "service")
            .filter(pk=booking_id)
            .first()
        )
        if booking is None:
            raise NotFound()
        if status not in _STAFF_TRANSITIONS.get(booking.status, set()):
            raise Conflict("That status change is not available.")
        from_status = booking.status
        booking.status = status
        _apply_confirmation(booking, status, confirmed_for_raw, actor)
        if note is not None:
            booking.staff_note = note
        if status == BookingStatus.CANCELLED:
            booking.cancelled_at = timezone.now()
        booking.save()
        open_request = (
            booking.cancellation_requests.filter(status=CancellationRequestStatus.OPEN)
            .order_by("-created_at")
            .first()
        )
        if from_status == BookingStatus.CANCELLATION_REQUESTED and open_request is not None:
            open_request.status = (
                CancellationRequestStatus.ACCEPTED
                if status == BookingStatus.CANCELLED
                else CancellationRequestStatus.DECLINED
            )
            open_request.reviewed_by = actor
            open_request.reviewed_at = timezone.now()
            open_request.save(update_fields=["status", "reviewed_by", "reviewed_at"])
        BookingEvent.objects.create(
            booking=booking,
            from_status=from_status,
            to_status=status,
            actor=actor,
            note=note,
            metadata={},
        )
        from apps.notifications.services import record_booking_update

        record_booking_update(booking)
    return booking


def _apply_confirmation(booking, status, confirmed_for_raw, actor) -> None:
    keeps_agreed_time = {
        BookingStatus.COMPLETED,
        BookingStatus.NO_SHOW,
        BookingStatus.CANCELLATION_REQUESTED,
    }
    if status == BookingStatus.CONFIRMED:
        if isinstance(confirmed_for_raw, str) and confirmed_for_raw.strip():
            booking.confirmed_for = _parse_confirmed_for(confirmed_for_raw)
            booking.confirmed_by = actor
        elif booking.confirmed_for is None or booking.confirmed_by_id is None:
            raise ValidationError({"confirmed_for": "Choose the confirmed date and time."})
        return
    if status in keeps_agreed_time:
        return
    booking.confirmed_for = None
    booking.confirmed_by = None


def _parse_confirmed_for(raw):
    if not isinstance(raw, str) or not raw.strip():
        raise ValidationError({"confirmed_for": "Choose the confirmed date and time."})
    parsed = parse_datetime(raw.strip())
    if parsed is None or timezone.is_naive(parsed):
        raise ValidationError({"confirmed_for": "Send a date and time with a time zone."})
    return parsed


def _parse_date(raw):
    if hasattr(raw, "year") and hasattr(raw, "month") and not isinstance(raw, str):
        return raw
    if isinstance(raw, str) and len(raw) >= 10:
        try:
            return datetime.strptime(raw[:10], "%Y-%m-%d").date()
        except ValueError:
            pass
    raise ValidationError({"requested_date": "Choose a preferred date."})


def _same_request(existing, profile_id, doctor, service, requested_date, slot, note) -> bool:
    return (
        existing.patient_profile_id == profile_id
        and existing.doctor_id == (doctor.id if doctor else None)
        and existing.service_id == (service.id if service else None)
        and existing.requested_date == requested_date
        and (existing.preferred_time_slot or None) == slot
        and (existing.patient_note or None) == note
    )
