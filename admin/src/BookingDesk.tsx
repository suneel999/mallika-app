import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import { ApiException, getBooking, reviewBooking, saveHospitalCheck, type StaffBooking } from "./api";
import { DeskNav } from "./DeskNav";
import {
  checkLabel,
  checkTone,
  confirmedForPayload,
  hospitalCheckChoices,
  hospitalTime,
  prettyDate,
  prettyMobile,
  requestLabel,
  statusLabel,
  statusTone,
} from "./labels";

/** What reception should do next, in one sentence. */
const nextStep: Record<string, string> = {
  requested: "Check the time with the doctor or the department, then confirm it or reject the request.",
  under_review: "Set the agreed time and confirm, or reject the request.",
  confirmed: "After the visit time, record whether the patient came.",
  cancellation_requested: "The patient asked to cancel. Accept it, or keep the appointment.",
  rejected: "This request was rejected. Nothing more to do.",
  cancelled: "This appointment was cancelled. Nothing more to do.",
  completed: "The patient visited. Nothing more to do.",
  no_show: "The patient did not come. Nothing more to do.",
};

export function BookingDesk() {
  const { bookingId = "" } = useParams();
  const navigate = useNavigate();
  const [booking, setBooking] = useState<StaffBooking | null>(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [confirmedFor, setConfirmedFor] = useState("");
  const [staffNote, setStaffNote] = useState("");
  const [checkStatus, setCheckStatus] = useState("not_checked");
  const [appointmentId, setAppointmentId] = useState("");
  const [patientId, setPatientId] = useState("");
  const [checkNote, setCheckNote] = useState("");

  useEffect(() => {
    let active = true;
    setLoading(true);
    getBooking(bookingId)
      .then((loaded) => {
        if (!active) {
          return;
        }
        applyBooking(loaded);
        setError("");
      })
      .catch((caught) => {
        if (!active) {
          return;
        }
        setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
        if (caught instanceof ApiException && (caught.statusCode === 401 || caught.statusCode === 404)) {
          navigate(caught.statusCode === 401 ? "/" : "/bookings");
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });
    return () => {
      active = false;
    };
  }, [bookingId, navigate]);

  function applyBooking(loaded: StaffBooking) {
    setBooking(loaded);
    setStaffNote(loaded.staff_note || "");
    setConfirmedFor(localConfirmedFor(loaded));
    setCheckStatus(loaded.hims_reconciliation?.status || "not_checked");
    setAppointmentId(loaded.hims_reconciliation?.hims_appointment_id || "");
    setPatientId(loaded.hims_reconciliation?.hims_patient_id || "");
    setCheckNote(loaded.hims_reconciliation?.note || "");
  }

  async function reload() {
    applyBooking(await getBooking(bookingId));
  }

  /** Runs one or more status changes in order, then shows what was saved. */
  async function change(steps: { status: string; sendsTime?: boolean }[], saved: string, ask = "") {
    if (ask && !window.confirm(ask)) {
      return;
    }
    setBusy(true);
    setError("");
    setNotice("");
    try {
      for (const step of steps) {
        await reviewBooking(bookingId, step.status, step.sendsTime ? confirmedForPayload(confirmedFor) : "", staffNote);
      }
      await reload();
      setNotice(saved);
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
      await reload().catch(() => undefined);
    } finally {
      setBusy(false);
    }
  }

  async function saveCheck() {
    setBusy(true);
    setError("");
    setNotice("");
    try {
      await saveHospitalCheck(bookingId, {
        status: checkStatus,
        hims_appointment_id: appointmentId,
        hims_patient_id: patientId,
        note: checkNote,
      });
      await reload();
      setNotice("Hospital system entry saved.");
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  const status = booking?.status ?? "";
  const canConfirm = status === "requested" || status === "under_review";
  const keepNeedsTime = status === "cancellation_requested" && !booking?.confirmed_for;
  const showsTime = canConfirm || keepNeedsTime;
  const showsIds = checkStatus === "entered_in_hims" || appointmentId !== "" || patientId !== "";

  return (
    <>
      <DeskNav
        title={booking ? booking.patient_name : "Appointment"}
        subtitle={booking ? `${requestLabel(booking)} · ${booking.reference}` : "Reception desk"}
        backTo="/bookings"
        backLabel="Appointments"
      />
      <main className="page">
        {loading ? <p className="muted">Loading appointment…</p> : null}
        {error ? <p className="error">{error}</p> : null}
        {notice ? <p className="notice">✓ {notice}</p> : null}
        {booking ? (
          <div className="grid wide-left">
            <section className="panel stack">
              <div className="actions">
                <span className={`badge ${statusTone(status)}`}>{statusLabel(status)}</span>
                <span className="muted">{nextStep[status] ?? ""}</span>
              </div>
              <div className="facts">
                <div className="fact">
                  <span>Patient</span>
                  <strong>{booking.patient_name}</strong>
                  {booking.patient_number ? <div className="muted small">{booking.patient_number}</div> : null}
                </div>
                <div className="fact">
                  <span>Mobile</span>
                  {booking.patient_mobile_number ? (
                    <strong>
                      <a href={`tel:${booking.patient_mobile_number}`}>{prettyMobile(booking.patient_mobile_number)}</a>
                    </strong>
                  ) : (
                    <strong>Not recorded</strong>
                  )}
                </div>
                <div className="fact">
                  <span>Asked for</span>
                  <strong>{requestLabel(booking)}</strong>
                </div>
                <div className="fact">
                  <span>Date and time asked</span>
                  <strong>{prettyDate(booking.requested_date)}</strong>
                  <div className="muted small">{booking.preferred_time_slot || "No time chosen"}</div>
                </div>
                <div className="fact">
                  <span>Agreed time</span>
                  <strong>{hospitalTime(booking.confirmed_for) || "Not confirmed yet"}</strong>
                </div>
              </div>
              <div>
                <h3>Note from the patient</h3>
                <p className="quote">{booking.patient_note || "The patient did not write a note."}</p>
              </div>
              {showsTime ? (
                <label>
                  Appointment time
                  <span className="hint">Filled in with the time the patient asked for. Change it if the hospital agreed another time.</span>
                  <input
                    type="datetime-local"
                    value={confirmedFor}
                    onChange={(event) => setConfirmedFor(event.target.value)}
                  />
                </label>
              ) : null}
              <label>
                Note for staff
                <span className="hint">Optional. The patient does not see this.</span>
                <textarea value={staffNote} onChange={(event) => setStaffNote(event.target.value)} />
              </label>
              <div className="actions">
                {canConfirm ? (
                  <button
                    type="button"
                    className="big good"
                    disabled={busy || !confirmedFor}
                    onClick={() =>
                      change(
                        status === "requested"
                          ? [{ status: "under_review" }, { status: "confirmed", sendsTime: true }]
                          : [{ status: "confirmed", sendsTime: true }],
                        "Appointment confirmed. The patient can see it in the app.",
                      )
                    }
                  >
                    ✓ Confirm appointment
                  </button>
                ) : null}
                {status === "requested" ? (
                  <button
                    type="button"
                    className="secondary"
                    disabled={busy}
                    onClick={() => change([{ status: "under_review" }], "Marked as in review.")}
                  >
                    Mark as in review
                  </button>
                ) : null}
                {canConfirm ? (
                  <button
                    type="button"
                    className="danger"
                    disabled={busy}
                    onClick={() =>
                      change([{ status: "rejected" }], "Request rejected.", "Reject this request? The patient will see it as rejected.")
                    }
                  >
                    Reject request
                  </button>
                ) : null}
                {status === "confirmed" ? (
                  <>
                    <button
                      type="button"
                      className="big good"
                      disabled={busy}
                      onClick={() => change([{ status: "completed" }], "Recorded: the patient visited.")}
                    >
                      ✓ Patient visited
                    </button>
                    <button
                      type="button"
                      className="secondary"
                      disabled={busy}
                      onClick={() =>
                        change([{ status: "no_show" }], "Recorded: the patient did not come.", "Record that the patient did not come?")
                      }
                    >
                      Patient did not come
                    </button>
                    <button
                      type="button"
                      className="danger"
                      disabled={busy}
                      onClick={() =>
                        change([{ status: "cancelled" }], "Appointment cancelled.", "Cancel this appointment? This cannot be undone.")
                      }
                    >
                      Cancel appointment
                    </button>
                  </>
                ) : null}
                {status === "cancellation_requested" ? (
                  <>
                    <button
                      type="button"
                      className="big"
                      disabled={busy}
                      onClick={() =>
                        change([{ status: "cancelled" }], "Cancellation accepted.", "Accept the cancellation? This cannot be undone.")
                      }
                    >
                      Accept cancellation
                    </button>
                    <button
                      type="button"
                      className="secondary"
                      disabled={busy || (keepNeedsTime && !confirmedFor)}
                      onClick={() =>
                        change([{ status: "confirmed", sendsTime: keepNeedsTime }], "The appointment is kept.")
                      }
                    >
                      Keep the appointment
                    </button>
                  </>
                ) : null}
              </div>
            </section>
            <section className="panel stack">
              <div>
                <h2>Hospital system entry</h2>
                <p className="muted small">
                  Record here what you did in the hospital system. This does not change the appointment status.
                </p>
              </div>
              <p>
                <span className={`badge ${checkTone(booking.hims_reconciliation?.status)}`}>
                  {checkLabel(booking.hims_reconciliation?.status)}
                </span>
                {booking.hims_reconciliation?.checked_at ? (
                  <span className="muted small"> · saved {hospitalTime(booking.hims_reconciliation.checked_at)}</span>
                ) : null}
              </p>
              <div className="choices" role="radiogroup" aria-label="Hospital system entry">
                {hospitalCheckChoices.map((choice) => (
                  <label key={choice.value} className={`choice${checkStatus === choice.value ? " selected" : ""}`}>
                    <input
                      type="radio"
                      name="hospital-check"
                      checked={checkStatus === choice.value}
                      onChange={() => setCheckStatus(choice.value)}
                    />
                    <span>
                      {choice.label}
                      <small>{choice.help}</small>
                    </span>
                  </label>
                ))}
              </div>
              {showsIds ? (
                <>
                  <label>
                    Appointment number in the hospital system
                    <input value={appointmentId} onChange={(event) => setAppointmentId(event.target.value)} />
                  </label>
                  <label>
                    Patient number in the hospital system
                    <input value={patientId} onChange={(event) => setPatientId(event.target.value)} />
                  </label>
                </>
              ) : null}
              <label>
                Note
                <span className="hint">Optional.</span>
                <textarea value={checkNote} onChange={(event) => setCheckNote(event.target.value)} />
              </label>
              <button type="button" disabled={busy} onClick={saveCheck}>
                Save hospital system entry
              </button>
            </section>
          </div>
        ) : null}
      </main>
    </>
  );
}

function localConfirmedFor(booking: StaffBooking) {
  if (booking.confirmed_for) {
    const parsed = new Date(booking.confirmed_for);
    if (!Number.isNaN(parsed.getTime())) {
      const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Asia/Kolkata",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        hourCycle: "h23",
      }).formatToParts(parsed);
      const pick = (type: string) => parts.find((part) => part.type === type)?.value ?? "";
      return `${pick("year")}-${pick("month")}-${pick("day")}T${pick("hour")}:${pick("minute")}`;
    }
  }
  if (booking.requested_date && booking.preferred_time_slot) {
    return `${booking.requested_date}T${booking.preferred_time_slot}`;
  }
  return "";
}
