export const bookingStatusLabel: Record<string, string> = {
  requested: "Pending",
  under_review: "Under review",
  confirmed: "Confirmed",
  rejected: "Rejected",
  cancellation_requested: "Cancellation requested",
  cancelled: "Cancelled",
  completed: "Completed",
  no_show: "Missed visit",
};

export const hospitalCheckLabel: Record<string, string> = {
  not_checked: "Not checked",
  checked_available: "Checked available",
  entered_in_hims: "Entered in the hospital system",
  mismatch: "Mismatch",
  not_applicable: "Not applicable",
};

export const reviewActions: Record<string, { status: string; label: string; needsTime?: boolean }[]> = {
  requested: [
    { status: "under_review", label: "Start review" },
    { status: "rejected", label: "Reject" },
  ],
  under_review: [
    { status: "confirmed", label: "Confirm time", needsTime: true },
    { status: "rejected", label: "Reject" },
  ],
  confirmed: [
    { status: "completed", label: "Mark completed" },
    { status: "no_show", label: "Mark missed visit" },
    { status: "cancelled", label: "Cancel booking" },
  ],
  cancellation_requested: [
    { status: "cancelled", label: "Accept cancellation" },
    { status: "confirmed", label: "Keep the booking" },
  ],
};

export function actionSendsTime(
  action: { status: string; needsTime?: boolean },
  agreedTime: string | null,
) {
  if (action.needsTime) {
    return true;
  }
  return action.status === "confirmed" && !agreedTime;
}

export function statusLabel(status: string) {
  return bookingStatusLabel[status] ?? status;
}

export function checkLabel(status: string | null | undefined) {
  if (!status) {
    return "Not recorded";
  }
  return hospitalCheckLabel[status] ?? status;
}

export function requestLabel(booking: { doctor_name: string | null; service_name: string | null; booking_type: string }) {
  return booking.service_name || booking.doctor_name || booking.booking_type;
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
