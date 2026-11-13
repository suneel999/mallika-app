from datetime import date

from django.db.models import Count
from rest_framework.exceptions import PermissionDenied, ValidationError

from apps.accounts.models import UserKind
from apps.bookings.models import Booking, BookingStatus


def booking_counts(actor, raw_from, raw_to) -> dict:
    if actor.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not actor.is_active:
        raise PermissionDenied()
    start = _optional_date(raw_from, "from")
    end = _optional_date(raw_to, "to")
    if start is not None and end is not None and start > end:
        raise ValidationError({"to": "Choose an end date on or after the start date."})
    queryset = Booking.objects.all()
    if start is not None:
        queryset = queryset.filter(requested_date__gte=start)
    if end is not None:
        queryset = queryset.filter(requested_date__lte=end)
    totals = {row["status"]: row["total"] for row in queryset.values("status").annotate(total=Count("id"))}
    by_status = {status.value: totals.get(status.value, 0) for status in BookingStatus}
    return {
        "from": start.isoformat() if start else None,
        "to": end.isoformat() if end else None,
        "total": sum(by_status.values()),
        "by_status": by_status,
    }


def _optional_date(raw, field) -> date | None:
    text = str(raw or "").strip()
    if not text:
        return None
    try:
        return date.fromisoformat(text)
    except ValueError as exc:
        raise ValidationError({field: "Use a date in YYYY-MM-DD."}) from exc
