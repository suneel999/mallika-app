import uuid

from django.conf import settings
from django.db import models


class AuditLog(models.Model):
    """Append-only record of staff access. Details stay free of clinical text and secrets."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="audit_logs",
    )
    action = models.CharField(max_length=80)
    entity_type = models.CharField(max_length=80)
    entity_id = models.UUIDField(null=True, blank=True)
    request_id = models.CharField(max_length=80, null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    details = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "auditlog_auditlog"
        indexes = [
            models.Index(fields=["entity_type", "entity_id", "created_at"], name="auditlog_entity_created_idx"),
        ]
