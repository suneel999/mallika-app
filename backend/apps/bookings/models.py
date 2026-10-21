import uuid

from django.conf import settings
from django.db import models

from apps.catalogue.models import Doctor, Service
from apps.patients.models import PatientProfile


class BookingStatus(models.TextChoices):
    REQUESTED = "requested", "Requested"
    UNDER_REVIEW = "under_review", "Under review"
    CONFIRMED = "confirmed", "Confirmed"
    REJECTED = "rejected", "Rejected"
    CANCELLATION_REQUESTED = "cancellation_requested", "Cancellation requested"
    CANCELLED = "cancelled", "Cancelled"
    COMPLETED = "completed", "Completed"
    NO_SHOW = "no_show", "No show"


class BookingType(models.TextChoices):
    CONSULTATION = "consultation", "Consultation"
    DIAGNOSTICS = "diagnostics", "Diagnostics"
    HEALTH_CHECKUP = "health_checkup", "Health checkup"
    PROCEDURE = "procedure", "Procedure"


class BookingNumberCounter(models.Model):
    id = models.PositiveSmallIntegerField(primary_key=True, default=1)
    last_value = models.PositiveIntegerField(default=0)

    class Meta:
        db_table = "bookings_bookingnumbercounter"


class Booking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reference = models.CharField(max_length=24, unique=True)
    patient_profile = models.ForeignKey(
        PatientProfile,
        on_delete=models.PROTECT,
        related_name="bookings",
    )
    requested_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="booking_requests",
    )
    booking_type = models.CharField(max_length=24, choices=BookingType.choices)
    doctor = models.ForeignKey(
        Doctor,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="bookings",
    )
    service = models.ForeignKey(
        Service,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="bookings",
    )
    requested_date = models.DateField()
    preferred_time_slot = models.CharField(max_length=40, null=True, blank=True)
    patient_note = models.TextField(null=True, blank=True)
    status = models.CharField(max_length=24, choices=BookingStatus.choices, default=BookingStatus.REQUESTED)
    idempotency_key = models.CharField(max_length=80)
    confirmed_for = models.DateTimeField(null=True, blank=True)
    staff_note = models.TextField(null=True, blank=True)
    confirmed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="confirmed_bookings",
    )
    cancelled_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "bookings_booking"
        constraints = [
            models.UniqueConstraint(
                fields=["requested_by", "idempotency_key"],
                name="bookings_booking_idempotency_uniq",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(doctor__isnull=False, service__isnull=True)
                    | models.Q(doctor__isnull=True, service__isnull=False)
                ),
                name="bookings_booking_one_target",
            ),
            models.CheckConstraint(
                condition=models.Q(status__in=[choice.value for choice in BookingStatus]),
                name="bookings_booking_status_valid",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(
                        status__in=[
                            BookingStatus.CONFIRMED,
                            BookingStatus.COMPLETED,
                            BookingStatus.NO_SHOW,
                        ],
                        confirmed_for__isnull=False,
                        confirmed_by__isnull=False,
                    )
                    | models.Q(
                        status=BookingStatus.CANCELLATION_REQUESTED,
                        confirmed_for__isnull=False,
                        confirmed_by__isnull=False,
                    )
                    | models.Q(
                        status=BookingStatus.CANCELLATION_REQUESTED,
                        confirmed_for__isnull=True,
                        confirmed_by__isnull=True,
                    )
                    | models.Q(
                        status__in=[
                            BookingStatus.REQUESTED,
                            BookingStatus.UNDER_REVIEW,
                            BookingStatus.REJECTED,
                            BookingStatus.CANCELLED,
                        ],
                        confirmed_for__isnull=True,
                        confirmed_by__isnull=True,
                    )
                ),
                name="bookings_booking_confirmation_valid",
            ),
        ]
        indexes = [
            models.Index(fields=["status", "requested_date"], name="bookings_status_date_idx"),
            models.Index(fields=["requested_by", "-created_at"], name="bookings_requester_created_idx"),
        ]


class CancellationRequestStatus(models.TextChoices):
    OPEN = "open", "Open"
    ACCEPTED = "accepted", "Accepted"
    DECLINED = "declined", "Declined"


class CancellationRequest(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name="cancellation_requests")
    requested_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="cancellation_requests",
    )
    reason = models.TextField(null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=CancellationRequestStatus.choices,
        default=CancellationRequestStatus.OPEN,
    )
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="reviewed_cancellations",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "bookings_cancellationrequest"
        constraints = [
            models.UniqueConstraint(
                fields=["booking"],
                condition=models.Q(status=CancellationRequestStatus.OPEN),
                name="bookings_one_open_cancellation",
            ),
        ]


class BookingEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name="events")
    from_status = models.CharField(max_length=24, null=True, blank=True)
    to_status = models.CharField(max_length=24)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="booking_events",
    )
    note = models.TextField(null=True, blank=True)
    metadata = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "bookings_bookingevent"
        indexes = [
            models.Index(fields=["booking", "created_at"], name="bookings_event_created_idx"),
        ]
