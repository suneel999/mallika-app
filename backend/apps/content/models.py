import uuid

from django.db import models


class BannerDestination(models.TextChoices):
    NONE = "none", "None"
    BOOKING = "booking", "Booking"
    SERVICE = "service", "Service"


class Banner(models.Model):
    """Hospital-published home or updates banner. Image files wait for storage."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=160)
    image_url = models.TextField(null=True, blank=True)
    alt_text = models.CharField(max_length=250, null=True, blank=True)
    destination_type = models.CharField(
        max_length=20,
        choices=BannerDestination.choices,
        default=BannerDestination.NONE,
    )
    destination_id = models.UUIDField(null=True, blank=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "contentops_banner"
        constraints = [
            models.CheckConstraint(
                condition=(
                    models.Q(starts_at__isnull=True)
                    | models.Q(ends_at__isnull=True)
                    | models.Q(starts_at__lt=models.F("ends_at"))
                ),
                name="content_banner_window_valid",
            ),
        ]
