"""Local development settings. Loads backend/.env and supplies an insecure fallback key."""

import os
from pathlib import Path

from dotenv import load_dotenv

from config.settings.constants import INSECURE_DEV_SECRET_KEY

BASE_DIR = Path(__file__).resolve().parent.parent.parent
load_dotenv(BASE_DIR / ".env")

os.environ.setdefault("DJANGO_SECRET_KEY", INSECURE_DEV_SECRET_KEY)
os.environ.setdefault("DJANGO_DEBUG", "true")

from config.settings.base import *  # noqa: E402, F403
