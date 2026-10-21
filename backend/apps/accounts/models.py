import uuid

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models


class UserKind(models.TextChoices):
    PATIENT = "patient", "Patient"
    STAFF = "staff", "Staff"
    ADMIN = "admin", "Admin"


class PreferredLanguage(models.TextChoices):
    ENGLISH = "en", "English"
    TELUGU = "te", "Telugu"


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, mobile_number, password=None, **extra_fields):
        if mobile_number is None or not str(mobile_number).strip():
            raise ValueError("A mobile number is required.")
        mobile_number = str(mobile_number).strip()
        extra_fields.setdefault("user_kind", UserKind.PATIENT)
        extra_fields.setdefault("preferred_language", PreferredLanguage.ENGLISH)
        user = self.model(mobile_number=mobile_number, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, mobile_number, password, **extra_fields):
        if not password:
            raise ValueError("A superuser password is required.")
        extra_fields.setdefault("user_kind", UserKind.ADMIN)
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self.create_user(mobile_number, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """Authentication identity. Product roles use Django groups, not user_kind alone."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    mobile_number = models.CharField(max_length=20, unique=True)
    user_kind = models.CharField(
        max_length=16,
        choices=UserKind.choices,
        default=UserKind.PATIENT,
    )
    preferred_language = models.CharField(
        max_length=8,
        choices=PreferredLanguage.choices,
        default=PreferredLanguage.ENGLISH,
    )
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "mobile_number"
    REQUIRED_FIELDS = []

    class Meta:
        db_table = "accounts_user"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(user_kind__in=[UserKind.PATIENT, UserKind.STAFF, UserKind.ADMIN]),
                name="accounts_user_kind_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(
                    preferred_language__in=[PreferredLanguage.ENGLISH, PreferredLanguage.TELUGU]
                ),
                name="accounts_user_language_valid",
            ),
        ]

    def __str__(self):
        return str(self.id)


class OtpPurpose(models.TextChoices):
    LOGIN = "login", "Login"


class OtpChallenge(models.Model):
    """One SMS code challenge. Only the hash is stored."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    mobile_number = models.CharField(max_length=20)
    purpose = models.CharField(max_length=16, choices=OtpPurpose.choices)
    code_hash = models.CharField(max_length=128)
    expires_at = models.DateTimeField()
    attempts = models.PositiveSmallIntegerField(default=0)
    consumed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "accounts_otpchallenge"
        indexes = [
            models.Index(fields=["mobile_number", "created_at"], name="accounts_otp_mobile_created"),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(purpose__in=[OtpPurpose.LOGIN]),
                name="accounts_otp_purpose_valid",
            ),
        ]

    def __str__(self):
        return str(self.id)


class RefreshSession(models.Model):
    """Rotating refresh token. The raw token is never stored."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="refresh_sessions",
    )
    token_hash = models.CharField(max_length=64, unique=True)
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)
    replaced_by = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="replaces",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "accounts_refreshsession"

    def __str__(self):
        return str(self.id)
