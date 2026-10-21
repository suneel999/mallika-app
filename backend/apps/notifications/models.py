import uuid

from django.conf import settings
from django.db import models

from apps.bookings.models import Booking


class DevicePlatform(models.TextChoices):
    ANDROID = "android", "Android"
    IOS = "ios", "iOS"


class NotificationChannel(models.TextChoices):
    PUSH = "push", "Push"
    SMS = "sms", "SMS"


class NotificationStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    SENT = "sent", "Sent"
    FAILED = "failed", "Failed"


class AttemptStatus(models.TextChoices):
    SKIPPED = "skipped", "Skipped"
    SENT = "sent", "Sent"
    FAILED = "failed", "Failed"


class DeviceToken(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    platform = models.CharField(max_length=12, choices=DevicePlatform.choices)
    token = models.TextField(unique=True)
    is_active = models.BooleanField(default=True)
    last_seen_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications_devicetoken"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(platform__in=[choice.value for choice in DevicePlatform]),
                name="notifications_device_platform_valid",
            ),
        ]


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    booking = models.ForeignKey(
        Booking,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="notifications",
    )
    channel = models.CharField(max_length=12, choices=NotificationChannel.choices)
    template_key = models.CharField(max_length=80)
    payload = models.JSONField(default=dict)
    status = models.CharField(
        max_length=20,
        choices=NotificationStatus.choices,
        default=NotificationStatus.PENDING,
    )
    scheduled_at = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications_notification"
        indexes = [
            models.Index(fields=["user", "-created_at"], name="notifications_user_created_idx"),
        ]


class NotificationAttempt(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name="attempts")
    provider = models.CharField(max_length=40)
    provider_message_id = models.CharField(max_length=120, null=True, blank=True)
    attempt_number = models.PositiveIntegerField()
    status = models.CharField(max_length=20, choices=AttemptStatus.choices)
    error_code = models.CharField(max_length=80, null=True, blank=True)
    attempted_at = models.DateTimeField()

    class Meta:
        db_table = "notifications_notificationattempt"
