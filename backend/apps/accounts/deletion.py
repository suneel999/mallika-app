"""Account deletion: the patient asks, staff check, and the data is removed."""

from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied

from apps.accounts.models import (
    AccountDeletionRequest,
    DeletionStatus,
    OtpChallenge,
    User,
    UserKind,
)
from apps.audit.services import record_audit
from config.exceptions import Conflict

# The patient is told the data is gone within this many days.
DELETION_DAYS = 7

_OPEN_BOOKING_STATUSES = ("requested", "under_review", "confirmed", "cancellation_requested")


def request_account_deletion(user) -> AccountDeletionRequest:
    """Switch the patient's account off and queue it for deletion."""
    if user.user_kind != UserKind.PATIENT:
        raise PermissionDenied("Staff accounts are closed by the hospital.")
    now = timezone.now()
    with transaction.atomic():
        locked = User.objects.select_for_update().get(pk=user.pk)
        pending = AccountDeletionRequest.objects.filter(user=locked, status=DeletionStatus.PENDING).first()
        if pending is None:
            pending = AccountDeletionRequest.objects.create(user=locked, mobile_number=locked.mobile_number)
        locked.is_active = False
        locked.save(update_fields=["is_active"])
        locked.refresh_sessions.filter(revoked_at__isnull=True).update(revoked_at=now)
    return pending


def pending_deletion_for(mobile_number: str) -> bool:
    return AccountDeletionRequest.objects.filter(
        mobile_number=mobile_number, status=DeletionStatus.PENDING
    ).exists()


def list_deletion_requests(actor, status):
    _require_staff(actor)
    queryset = AccountDeletionRequest.objects.select_related("user").order_by("requested_at")
    if status in DeletionStatus.values:
        queryset = queryset.filter(status=status)
    return queryset


def complete_account_deletion(actor, request_id, request=None) -> AccountDeletionRequest:
    """Delete the patient's account and everything stored for it."""
    from apps.bookings.models import Booking
    from apps.patients.models import FamilyRelationship, PatientProfile

    _require_staff(actor)
    with transaction.atomic():
        entry = AccountDeletionRequest.objects.select_for_update().filter(pk=request_id).first()
        if entry is None:
            raise NotFound()
        if entry.status != DeletionStatus.PENDING:
            raise Conflict("This request was already decided.")
        user = entry.user
        counts = {"profiles": 0, "bookings": 0}
        if user is not None:
            profile_ids = _profile_ids(user)
            bookings = Booking.objects.filter(patient_profile_id__in=profile_ids) | Booking.objects.filter(
                requested_by=user
            )
            counts["bookings"] = bookings.distinct().count()
            # Events, cancellation requests, and the hospital-system check go with each booking.
            bookings.distinct().delete()
            FamilyRelationship.objects.filter(owner=user).delete()
            counts["profiles"] = PatientProfile.objects.filter(pk__in=profile_ids).count()
            PatientProfile.objects.filter(pk__in=profile_ids).delete()
            OtpChallenge.objects.filter(mobile_number=user.mobile_number).delete()
            # Sessions, device tokens, and stored updates are removed with the user.
            user.delete()
        entry.user = None
        entry.mobile_number = ""
        entry.status = DeletionStatus.COMPLETED
        entry.decided_at = timezone.now()
        entry.decided_by = actor
        entry.save(update_fields=["user", "mobile_number", "status", "decided_at", "decided_by"])
        record_audit(actor, "account.delete", "account_deletion_request", entry.id, request, counts)
    return entry


def keep_account(actor, request_id, request=None) -> AccountDeletionRequest:
    """The patient asked to keep the account. Switch it back on."""
    _require_staff(actor)
    with transaction.atomic():
        entry = AccountDeletionRequest.objects.select_for_update().filter(pk=request_id).first()
        if entry is None:
            raise NotFound()
        if entry.status != DeletionStatus.PENDING:
            raise Conflict("This request was already decided.")
        if entry.user is not None:
            entry.user.is_active = True
            entry.user.save(update_fields=["is_active"])
        entry.status = DeletionStatus.KEPT
        entry.decided_at = timezone.now()
        entry.decided_by = actor
        entry.save(update_fields=["status", "decided_at", "decided_by"])
        record_audit(actor, "account.keep", "account_deletion_request", entry.id, request, {})
    return entry


def deletion_body(entry) -> dict:
    from apps.bookings.models import Booking
    from apps.patients.models import PatientProfile

    name = None
    open_bookings = 0
    if entry.user is not None:
        own = PatientProfile.objects.filter(user=entry.user).first()
        name = None if own is None else own.full_name
        open_bookings = (
            Booking.objects.filter(patient_profile_id__in=_profile_ids(entry.user), status__in=_OPEN_BOOKING_STATUSES)
            .distinct()
            .count()
        )
    return {
        "id": str(entry.id),
        "status": entry.status,
        "mobile_number": entry.mobile_number or None,
        "patient_name": name,
        "open_bookings": open_bookings,
        "requested_at": entry.requested_at.isoformat(),
        "delete_by": (entry.requested_at + timedelta(days=DELETION_DAYS)).isoformat(),
        "decided_at": None if entry.decided_at is None else entry.decided_at.isoformat(),
    }


def _profile_ids(user) -> list:
    """The patient's own profile and the family profiles saved on the account."""
    from apps.patients.models import FamilyRelationship, PatientProfile

    own = list(PatientProfile.objects.filter(user=user).values_list("pk", flat=True))
    family = list(
        FamilyRelationship.objects.filter(owner=user, patient_profile__user__isnull=True).values_list(
            "patient_profile_id", flat=True
        )
    )
    return list({*own, *family})


def _require_staff(actor) -> None:
    if actor.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not actor.is_active:
        raise PermissionDenied()
