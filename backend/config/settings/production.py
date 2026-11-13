"""Production settings. Requires a real secret and refuses debug mode."""

import os

from django.core.exceptions import ImproperlyConfigured

from config.settings.base import *  # noqa: F403
from config.settings.constants import INSECURE_DEV_SECRET_KEY
from config.settings.guards import require_sms_sender

if DEBUG:  # noqa: F405
    raise ImproperlyConfigured(
        "Refusing to start production settings with DJANGO_DEBUG enabled."
    )

if SECRET_KEY == INSECURE_DEV_SECRET_KEY:  # noqa: F405
    raise ImproperlyConfigured("Set a unique DJANGO_SECRET_KEY for production.")

if not os.environ.get("POSTGRES_PASSWORD", "").strip():
    raise ImproperlyConfigured("Set POSTGRES_PASSWORD for production.")

require_sms_sender()

# The first load balancer listens on HTTP. Set DJANGO_SSL_REDIRECT=true after the certificate exists.
SECURE_SSL_REDIRECT = env_bool("DJANGO_SSL_REDIRECT", True)
SECURE_REDIRECT_EXEMPT = [r"^api/v1/health/$"]
if SECURE_SSL_REDIRECT:
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
else:
    SECURE_HSTS_SECONDS = 0
# The TLS-terminating proxy must overwrite X-Forwarded-Proto.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
