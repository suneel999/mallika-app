"""OTP challenges and rotating refresh sessions."""

import hashlib
import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.db import transaction
from django.utils import timezone
from django.utils.module_loading import import_string
from rest_framework.exceptions import AuthenticationFailed, PermissionDenied, Throttled, ValidationError

from apps.accounts.authentication import issue_access_token
from apps.accounts.models import OtpChallenge, OtpPurpose, RefreshSession, User, UserKind
from apps.accounts.phone import normalize_indian_mobile

_INVALID_CODE = "The code is incorrect or has expired."


def request_otp(raw_mobile: str) -> dict:
    mobile = _mobile_or_validation(raw_mobile)
    now = timezone.now()
    existing = User.objects.filter(mobile_number=mobile).first()
    if existing is not None and (existing.user_kind != UserKind.PATIENT or not existing.is_active):
        _consume_open_challenges(mobile, now)
        return _otp_response(mobile)

    window_start = now - timedelta(hours=1)
    recent = list(
        OtpChallenge.objects.filter(mobile_number=mobile, created_at__gte=window_start).order_by(
            "created_at"
        )
    )
    if len(recent) >= settings.OTP_MAX_PER_HOUR:
        retry_after = int((recent[0].created_at + timedelta(hours=1) - now).total_seconds())
        raise Throttled(wait=max(retry_after, 1))
    if recent:
        elapsed = (now - recent[-1].created_at).total_seconds()
        if elapsed < settings.OTP_RESEND_SECONDS:
            raise Throttled(wait=max(int(settings.OTP_RESEND_SECONDS - elapsed), 1))

    code = f"{secrets.randbelow(1_000_000):06d}"
    with transaction.atomic():
        _consume_open_challenges(mobile, now)
        OtpChallenge.objects.create(
            mobile_number=mobile,
            purpose=OtpPurpose.LOGIN,
            code_hash=make_password(code),
            expires_at=now + timedelta(seconds=settings.OTP_TTL_SECONDS),
        )
    sender = import_string(settings.OTP_SENDER)()
    sender.send(mobile, code)
    return _otp_response(mobile)


def verify_otp(raw_mobile: str, raw_code: str) -> dict:
    mobile = _mobile_or_validation(raw_mobile)
    code = str(raw_code or "").strip()
    if len(code) != 6 or not code.isdigit():
        raise ValidationError({"code": "Enter the 6-digit code."})

    now = timezone.now()
    failure = False
    denial = None
    issued = None
    with transaction.atomic():
        challenge = (
            OtpChallenge.objects.select_for_update()
            .filter(
                mobile_number=mobile,
                purpose=OtpPurpose.LOGIN,
                consumed_at__isnull=True,
            )
            .order_by("-created_at")
            .first()
        )
        if challenge is None:
            failure = True
        else:
            challenge.attempts += 1
            challenge.save(update_fields=["attempts"])
            expired = challenge.expires_at <= now
            too_many = challenge.attempts > settings.OTP_MAX_ATTEMPTS
            matches = (not expired) and (not too_many) and check_password(code, challenge.code_hash)
            if not matches:
                failure = True
            else:
                _consume_open_challenges(mobile, now)
                user = User.objects.filter(mobile_number=mobile).first()
                if user is not None and user.user_kind != UserKind.PATIENT:
                    denial = "staff"
                elif user is not None and not user.is_active:
                    denial = "inactive"
                else:
                    if user is None:
                        user = User.objects.create_user(mobile)
                    user.last_login = now
                    user.save(update_fields=["last_login"])
                    issued = _tokens_for(user)
    if failure:
        raise AuthenticationFailed(_INVALID_CODE)
    if denial == "staff":
        raise PermissionDenied("This number is registered for hospital staff.")
    if denial == "inactive":
        raise PermissionDenied("This account is inactive.")
    return issued


def refresh_session(raw_token: str) -> dict:
    token = str(raw_token or "").strip()
    if not token:
        raise ValidationError({"refresh": "A refresh token is required."})
    now = timezone.now()
    missing = False
    rejected = False
    issued = None
    with transaction.atomic():
        session = (
            RefreshSession.objects.select_for_update()
            .filter(token_hash=_hash_token(token))
            .select_related("user")
            .first()
        )
        if session is None:
            missing = True
        elif session.revoked_at is not None or session.expires_at <= now or not session.user.is_active:
            RefreshSession.objects.filter(user=session.user, revoked_at__isnull=True).update(
                revoked_at=now
            )
            rejected = True
        else:
            session.revoked_at = now
            issued = _tokens_for(session.user)
            session.replaced_by = RefreshSession.objects.get(token_hash=_hash_token(issued["refresh"]))
            session.save(update_fields=["revoked_at", "replaced_by"])
    if missing or rejected:
        raise AuthenticationFailed("Authentication is required.")
    return issued


def logout_session(raw_token: str) -> None:
    token = str(raw_token or "").strip()
    if not token:
        raise ValidationError({"refresh": "A refresh token is required."})
    now = timezone.now()
    updated = RefreshSession.objects.filter(
        token_hash=_hash_token(token),
        revoked_at__isnull=True,
    ).update(revoked_at=now)
    if not updated:
        raise AuthenticationFailed("Authentication is required.")


def staff_login(raw_mobile, raw_password) -> dict:
    invalid = AuthenticationFailed("The mobile number or password is not valid.")
    try:
        mobile = normalize_indian_mobile(raw_mobile)
    except ValueError as exc:
        raise ValidationError({"mobile_number": str(exc)}) from exc
    user = User.objects.filter(mobile_number=mobile).first()
    password = "" if raw_password is None else str(raw_password)
    if (
        user is None
        or user.user_kind == UserKind.PATIENT
        or not user.is_active
        or not user.check_password(password)
    ):
        raise invalid
    return _tokens_for(user)


def _tokens_for(user: User) -> dict:
    raw = secrets.token_urlsafe(32)
    session = RefreshSession.objects.create(
        user=user,
        token_hash=_hash_token(raw),
        expires_at=timezone.now() + timedelta(days=settings.REFRESH_TOKEN_DAYS),
    )
    return {"access": issue_access_token(user, session.id), "refresh": raw}


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _otp_response(mobile: str) -> dict:
    return {
        "mobile_number": mobile,
        "expires_in": settings.OTP_TTL_SECONDS,
        "resend_after": settings.OTP_RESEND_SECONDS,
    }


def _consume_open_challenges(mobile: str, now) -> None:
    OtpChallenge.objects.filter(
        mobile_number=mobile,
        purpose=OtpPurpose.LOGIN,
        consumed_at__isnull=True,
    ).update(consumed_at=now)


def _mobile_or_validation(raw_mobile: str) -> str:
    try:
        return normalize_indian_mobile(raw_mobile)
    except ValueError as exc:
        raise ValidationError({"mobile_number": str(exc)}) from exc
