"""Indian mobile numbers used by patient OTP sign-in."""

import re

_NATIONAL = re.compile(r"^[6-9]\d{9}$")


def normalize_indian_mobile(value) -> str:
    """Return E.164 (+91 and 10 digits) or raise ValueError."""

    raw = re.sub(r"[\s-]", "", "" if value is None else str(value))
    if raw.startswith("0091"):
        raw = "+" + raw[2:]
    if raw.startswith("91") and len(raw) == 12:
        raw = "+" + raw
    if raw.startswith("+91"):
        national = raw[3:]
    elif _NATIONAL.fullmatch(raw):
        national = raw
    else:
        raise ValueError("Enter a 10-digit Indian mobile number.")
    if not _NATIONAL.fullmatch(national):
        raise ValueError("Enter a 10-digit Indian mobile number.")
    return "+91" + national
