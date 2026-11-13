import ipaddress

from apps.audit.models import AuditLog


def record_audit(actor, action, entity_type, entity_id, request, details=None) -> AuditLog:
    return AuditLog.objects.create(
        actor=actor,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        request_id=getattr(request, "request_id", None),
        ip_address=_client_ip(request),
        details=details or {},
    )


def _client_ip(request):
    if request is None:
        return None
    raw = str(request.META.get("REMOTE_ADDR") or "").strip()
    if not raw:
        return None
    try:
        ipaddress.ip_address(raw)
    except ValueError:
        return None
    return raw
