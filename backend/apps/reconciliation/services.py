from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.accounts.models import UserKind
from apps.bookings.models import Booking
from apps.reconciliation.models import HimsReconciliation, ReconciliationEvent, ReconciliationStatus


def update_hims_reconciliation(actor, booking_id, data: dict):
    if actor.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not actor.is_active:
        raise PermissionDenied()
    status = str(data.get("status") or "").strip()
    if status not in ReconciliationStatus.values:
        raise ValidationError({"status": "Choose a hospital-system check status."})
    with transaction.atomic():
        booking = Booking.objects.select_for_update().filter(pk=booking_id).first()
        if booking is None:
            raise NotFound()
        booking_status = booking.status
        reconciliation = HimsReconciliation.objects.select_for_update().filter(booking=booking).first()
        old_status = None if reconciliation is None else reconciliation.status
        if reconciliation is None:
            reconciliation = HimsReconciliation(booking=booking)
        reconciliation.status = status
        if "hims_appointment_id" in data:
            reconciliation.hims_appointment_id = _blank_to_none(
                data.get("hims_appointment_id"), 100, "hims_appointment_id"
            )
        if "hims_patient_id" in data:
            reconciliation.hims_patient_id = _blank_to_none(data.get("hims_patient_id"), 80, "hims_patient_id")
        if "note" in data:
            reconciliation.note = _blank_to_none(data.get("note"), None, "note")
        reconciliation.checked_by = actor
        reconciliation.checked_at = timezone.now()
        reconciliation.save()
        ReconciliationEvent.objects.create(
            reconciliation=reconciliation,
            old_status=old_status,
            new_status=status,
            actor=actor,
            note=reconciliation.note,
        )
        booking.refresh_from_db(fields=["status"])
    reconciliation.booking_status = booking_status
    return reconciliation


def reconciliation_summary(booking):
    """Current hospital-system check, or None when staff have not recorded one."""

    try:
        reconciliation = booking.hims_reconciliation
    except HimsReconciliation.DoesNotExist:
        return None
    return {
        "status": reconciliation.status,
        "hims_appointment_id": reconciliation.hims_appointment_id,
        "hims_patient_id": reconciliation.hims_patient_id,
        "note": reconciliation.note,
        "checked_at": reconciliation.checked_at,
    }


def _blank_to_none(value, max_length, field):
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    if max_length is not None and len(text) > max_length:
        raise ValidationError({field: f"Use {max_length} characters or fewer."})
    return text
