"""Test settings on PostgreSQL.

The usual test settings use SQLite, which ignores row locks and some constraints.
This file runs the same tests on PostgreSQL, in a separate database that Django
creates and removes (`test_` and the database name). Use it before a release:

    python manage.py test --settings=config.settings.test_postgres
"""

import os

from config.settings.test import *  # noqa: F401, F403

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "mallika"),
        "USER": os.environ.get("POSTGRES_USER", "mallika"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
        "HOST": os.environ.get("POSTGRES_HOST", "127.0.0.1"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
    }
}
