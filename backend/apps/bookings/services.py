from datetime import datetime
from zoneinfo import ZoneInfo

from django.db import IntegrityError, transaction
from rest_framework.exceptions import NotFound, ValidationError

from apps.bookings.models import Booking, BookingEvent, BookingNumberCounter, BookingStatus, BookingType
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
