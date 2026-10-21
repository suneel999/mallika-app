"""OTP delivery. The console sender is a local stand-in for SMS."""

import sys


class ConsoleOtpSender:
    """Writes the code to stderr. Production settings refuse this class."""

    def send(self, mobile_number: str, code: str) -> None:
        print(f"Mallika OTP for {mobile_number}: {code}", file=sys.stderr)


class CapturingOtpSender:
    """Test double. Codes stay in this process and are not logged."""

    sent: list[tuple[str, str]] = []

    def send(self, mobile_number: str, code: str) -> None:
        self.sent.append((mobile_number, code))

    @classmethod
    def reset(cls) -> None:
        cls.sent = []
