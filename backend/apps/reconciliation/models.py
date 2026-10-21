import uuid

from django.conf import settings
from django.db import models

from apps.bookings.models import Booking


class ReconciliationStatus(models.TextChoices):
    NOT_CHECKED = "not_checked", "Not checked"
    CHECKED_AVAILABLE = "checked_available", "Checked available"
    ENTERED_IN_HIMS = "entered_in_hims", "Entered in HIMS"
    MISMATCH = "mismatch", "Mismatch"
    NOT_APPLICABLE = "not_applicable", "Not applicable"


class HimsReconciliation(models.Model):
    """Manual hospital-system check. It does not change the booking status."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name="hims_reconciliation")
    status = models.CharField(
        max_length=20,
        choices=ReconciliationStatus.choices,
        default=ReconciliationStatus.NOT_CHECKED,
    )
    hims_appointment_id = models.CharField(max_length=100, null=True, blank=True)
    hims_patient_id = models.CharField(max_length=80, null=True, blank=True)
    checked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="hims_checks",
    )
    checked_at = models.DateTimeField(null=True, blank=True)
    note = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "bookings_himsreconciliation"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(status__in=[choice.value for choice in ReconciliationStatus]),
                name="bookings_hims_status_valid",
            ),
        ]


class ReconciliationEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reconciliation = models.ForeignKey(
        HimsReconciliation,
        on_delete=models.CASCADE,
        related_name="events",
    )
    old_status = models.CharField(max_length=20, null=True, blank=True)
    new_status = models.CharField(max_length=20)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="reconciliation_events",
    )
    note = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "bookings_reconciliationevent"
