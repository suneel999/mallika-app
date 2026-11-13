from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from rest_framework.exceptions import PermissionDenied, ValidationError

from apps.accounts.models import UserKind
from apps.audit.models import AuditLog

HOSPITAL_ZONE = ZoneInfo("Asia/Kolkata")


def search_audit_logs(actor, params):
    if actor.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not actor.is_active:
        raise PermissionDenied()
    start = _optional_date(params.get("from", ""), "from")
    end = _optional_date(params.get("to", ""), "to")
    if start is not None and end is not None and start > end:
        raise ValidationError({"to": "Choose an end date on or after the start date."})
    queryset = AuditLog.objects.select_related("actor").order_by("-created_at")
    action = _short(params.get("action", ""), "action")
    entity_type = _short(params.get("entity_type", ""), "entity_type")
    if action:
        queryset = queryset.filter(action=action)
    if entity_type:
        queryset = queryset.filter(entity_type=entity_type)
    if start is not None:
        queryset = queryset.filter(created_at__gte=_start_of_day(start))
    if end is not None:
        queryset = queryset.filter(created_at__lt=_start_of_day(end + timedelta(days=1)))
    return queryset


def audit_body(entry: AuditLog) -> dict:
    return {
        "id": str(entry.id),
        "action": entry.action,
        "entity_type": entry.entity_type,
        "entity_id": str(entry.entity_id) if entry.entity_id else None,
        "actor_mobile_number": entry.actor.mobile_number if entry.actor_id else None,
        "created_at": entry.created_at,
        "details": entry.details,
    }


def _short(raw, field) -> str:
    text = " ".join(str(raw or "").split())
    if len(text) > 80:
        raise ValidationError({field: "Use a shorter value."})
    return text


def _optional_date(raw, field) -> date | None:
    text = str(raw or "").strip()
    if not text:
        return None
    try:
        return date.fromisoformat(text)
    except ValueError as exc:
        raise ValidationError({field: "Use a date in YYYY-MM-DD."}) from exc


def _start_of_day(day: date) -> datetime:
    return datetime.combine(day, time.min, tzinfo=HOSPITAL_ZONE)
