"""Short-lived access tokens. The token is a signed payload, not a session row."""

from django.conf import settings
from django.core import signing
from django.utils import timezone
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

from apps.accounts.models import RefreshSession, User

ACCESS_SALT = "mallika.access"


def issue_access_token(user: User, session_id) -> str:
    return signing.dumps({"uid": str(user.id), "sid": str(session_id)}, salt=ACCESS_SALT)


def read_access_token(token: str) -> tuple[str, str]:
    try:
        payload = signing.loads(
            token,
            salt=ACCESS_SALT,
            max_age=settings.ACCESS_TOKEN_SECONDS,
        )
    except signing.SignatureExpired as exc:
        raise AuthenticationFailed("Authentication is required.") from exc
    except signing.BadSignature as exc:
        raise AuthenticationFailed("Authentication is required.") from exc
    if not isinstance(payload, dict):
        raise AuthenticationFailed("Authentication is required.")
    uid = payload.get("uid")
    sid = payload.get("sid")
    if not uid or not sid:
        raise AuthenticationFailed("Authentication is required.")
    return str(uid), str(sid)


class AccessTokenAuthentication(BaseAuthentication):
    def authenticate(self, request):
        header = request.META.get("HTTP_AUTHORIZATION", "")
        if not header:
            return None
        scheme, _, token = header.partition(" ")
        if scheme.lower() != "bearer" or not token.strip():
            return None
        try:
            uid, sid = read_access_token(token.strip())
        except AuthenticationFailed:
            return None
        user = User.objects.filter(pk=uid, is_active=True).first()
        session = RefreshSession.objects.filter(pk=sid, user=user).first() if user else None
        if session is None or session.revoked_at is not None or session.expires_at <= timezone.now():
            return None
        return user, None

    def authenticate_header(self, request):
        return "Bearer"
