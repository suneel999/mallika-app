export const bookingStatusLabel: Record<string, string> = {
  requested: "New request",
  under_review: "In review",
  confirmed: "Confirmed",
  rejected: "Rejected",
  cancellation_requested: "Cancellation asked",
  cancelled: "Cancelled",
  completed: "Visited",
  no_show: "Did not come",
};

/** Colour of the status label. The names match the badge classes in styles.css. */
export const bookingStatusTone: Record<string, string> = {
  requested: "amber",
  under_review: "blue",
  confirmed: "green",
  rejected: "red",
  cancellation_requested: "orange",
  cancelled: "red",
  completed: "gray",
  no_show: "red",
};

export const hospitalCheckLabel: Record<string, string> = {
  not_checked: "Not checked yet",
  checked_available: "Time is free",
  entered_in_hims: "Entered",
  mismatch: "Does not match",
  not_applicable: "Not needed",
};

export const hospitalCheckTone: Record<string, string> = {
  not_checked: "gray",
  checked_available: "blue",
  entered_in_hims: "green",
  mismatch: "red",
  not_applicable: "gray",
};

/** The choices on the booking screen, in the order reception works through them. */
export const hospitalCheckChoices: { value: string; label: string; help: string }[] = [
  { value: "not_checked", label: "Not checked yet", help: "Nobody has looked in the hospital system." },
  { value: "checked_available", label: "Time is free", help: "The hospital system shows this time is open." },
  { value: "entered_in_hims", label: "Entered", help: "The appointment is typed into the hospital system." },
  { value: "mismatch", label: "Does not match", help: "The hospital system shows something different." },
  { value: "not_applicable", label: "Not needed", help: "This request does not go into the hospital system." },
];

export function statusLabel(status: string) {
  return bookingStatusLabel[status] ?? status;
}

export function statusTone(status: string) {
  return bookingStatusTone[status] ?? "";
}

export function checkLabel(status: string | null | undefined) {
  if (!status) {
    return "Not checked yet";
  }
  return hospitalCheckLabel[status] ?? status;
}

export function checkTone(status: string | null | undefined) {
  if (!status) {
    return "gray";
  }
  return hospitalCheckTone[status] ?? "gray";
}

export function requestLabel(booking: { doctor_name: string | null; service_name: string | null; booking_type: string }) {
  return booking.service_name || booking.doctor_name || booking.booking_type;
}

/** `2026-11-20` becomes `Fri, 20 Nov 2026`. */
export function prettyDate(isoDate: string | null | undefined) {
  if (!isoDate) {
    return "";
  }
  const parsed = new Date(`${isoDate.slice(0, 10)}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) {
    return isoDate;
  }
  return new Intl.DateTimeFormat("en-IN", {
    timeZone: "UTC",
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(parsed);
}

export function hospitalTime(iso: string | null) {
  if (!iso) {
    return "";
  }
  const parsed = new Date(iso);
  if (Number.isNaN(parsed.getTime())) {
    return iso;
  }
  return new Intl.DateTimeFormat("en-IN", {
    timeZone: "Asia/Kolkata",
    dateStyle: "medium",
    timeStyle: "short",
  }).format(parsed);
}

export function confirmedForPayload(localValue: string) {
  if (!localValue) {
    return "";
  }
  const withSeconds = localValue.length === 16 ? `${localValue}:00` : localValue;
  return `${withSeconds}+05:30`;
}

/** `+919876500001` becomes `+91 98765 00001`. Anything else is shown as stored. */
export function prettyMobile(mobile: string | null | undefined) {
  if (!mobile) {
    return "";
  }
  const digits = mobile.replace(/\D/g, "");
  if (digits.length < 10) {
    return mobile;
  }
  const national = digits.slice(-10);
  return `+91 ${national.slice(0, 5)} ${national.slice(5)}`;
}
