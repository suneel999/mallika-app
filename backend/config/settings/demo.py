"""Phone demo when PostgreSQL is not running.

Uses a local SQLite file and the console OTP sender. Production stays on PostgreSQL.
"""

from config.settings.local import *  # noqa: E402, F403

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "demo.sqlite3",
    }
}

# Demo builds accept this code. Production settings do not set it.
OTP_DEMO_CODE = "123456"
