from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, ValidationError

from apps.notifications.models import (
    AttemptStatus,
    DevicePlatform,
    DeviceToken,
    Notification,
    NotificationAttempt,
    NotificationChannel,
    NotificationStatus,
)

_BOOKING_BODIES = {
    "under_review": "The hospital is reviewing {reference}.",
    "confirmed": "The hospital confirmed {reference}.",
    "rejected": "The hospital could not accept {reference}.",
    "cancelled": "The hospital cancelled {reference}.",
    "completed": "The hospital marked {reference} completed.",
    "no_show": "The hospital marked {reference} as a missed visit.",
}


def record_booking_update(booking) -> None:
    """Store an in-app update. No push or SMS provider is called."""

    body = _BOOKING_BODIES.get(booking.status)
    if body is None:
        return
    notification = Notification.objects.create(
        user_id=booking.requested_by_id,
        booking=booking,
        channel=NotificationChannel.PUSH,
        template_key=f"booking_{booking.status}",
        payload={
            "title": "Mallika Hospitals",
            "body": body.format(reference=booking.reference),
        },
        status=NotificationStatus.PENDING,
    )
    NotificationAttempt.objects.create(
        notification=notification,
        provider="unconfigured",
        attempt_number=1,
        status=AttemptStatus.SKIPPED,
        error_code="NO_PROVIDER",
        attempted_at=timezone.now(),
    )


def register_device(user, raw_platform, raw_token) -> DeviceToken:
    platform = str(raw_platform or "").strip()
    token = str(raw_token or "").strip()
    if platform not in DevicePlatform.values:
        raise ValidationError({"platform": "Choose android or ios."})
    if not token or len(token) > 4096:
        raise ValidationError({"token": "A device token is required."})
    now = timezone.now()
    for _attempt in range(2):
        try:
            with transaction.atomic():
                existing = DeviceToken.objects.select_for_update().filter(token=token).first()
                if existing is not None:
                    existing.user = user
                    existing.platform = platform
                    existing.is_active = True
                    existing.last_seen_at = now
                    existing.save(update_fields=["user", "platform", "is_active", "last_seen_at"])
                    return existing
                return DeviceToken.objects.create(
                    user=user,
                    platform=platform,
                    token=token,
                    is_active=True,
                    last_seen_at=now,
                )
        except IntegrityError:
            continue
    raise ValidationError({"token": "That device token could not be saved."})


def unregister_device(user, device_id) -> None:
    deleted, _details = DeviceToken.objects.filter(pk=device_id, user=user).delete()
    if not deleted:
        raise NotFound()
