import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";

import { ApiException, getBooking, reviewBooking, saveHospitalCheck, type StaffBooking } from "./api";
import {
  actionSendsTime,
  checkLabel,
  confirmedForPayload,
  hospitalTime,
  requestLabel,
  reviewActions,
  statusLabel,
} from "./labels";

export function BookingDesk() {
  const { bookingId = "" } = useParams();
  const navigate = useNavigate();
  const [booking, setBooking] = useState<StaffBooking | null>(null);
  const [error, setError] = useState("");
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

  async function changeStatus(status: string, needsTime = false) {
    setBusy(true);
    setError("");
    try {
      await reviewBooking(bookingId, status, needsTime ? confirmedForPayload(confirmedFor) : "", staffNote);
      await reload();
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  async function saveCheck() {
    setBusy(true);
    setError("");
    try {
      await saveHospitalCheck(bookingId, {
        status: checkStatus,
        hims_appointment_id: appointmentId,
        hims_patient_id: patientId,
        note: checkNote,
      });
      await reload();
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  const actions = booking ? (reviewActions[booking.status] ?? []) : [];

  return (
    <>
      <header className="topbar">
        <div>
          <h1>{booking?.reference || "Booking"}</h1>
          <p>{booking ? `${booking.patient_name} · ${statusLabel(booking.status)}` : "Staff desk"}</p>
        </div>
        <Link className="button-link secondary" to="/bookings">
          Back to queue
        </Link>
      </header>
      <main className="page">
        {loading ? <p>Loading booking…</p> : null}
        {error ? <p className="error">{error}</p> : null}
        {booking ? (
          <div className="grid">
            <section className="panel stack">
              <h2>Request</h2>
              <p>
                {requestLabel(booking)}
                <br />
                <span className="muted">
                  {booking.requested_date} {booking.preferred_time_slot || ""}
                </span>
              </p>
              <p>{booking.patient_note || "No note from the patient."}</p>
              <p>
                Agreed time
                <br />
                <span className="muted">{hospitalTime(booking.confirmed_for) || "Not confirmed"}</span>
              </p>
              <label>
                Staff note
                <textarea value={staffNote} onChange={(event) => setStaffNote(event.target.value)} />
              </label>
              {actions.some((action) => actionSendsTime(action, booking.confirmed_for)) ? (
                <label>
                  Confirmed time
                  <input
                    type="datetime-local"
                    value={confirmedFor}
                    onChange={(event) => setConfirmedFor(event.target.value)}
                  />
                </label>
              ) : null}
              <div className="actions">
                {actions.map((action) => (
                  <button
                    key={action.status}
                    type="button"
                    disabled={busy || (actionSendsTime(action, booking.confirmed_for) && !confirmedFor)}
                    onClick={() => changeStatus(action.status, actionSendsTime(action, booking.confirmed_for))}
                  >
                    {action.label}
                  </button>
                ))}
              </div>
            </section>
            <section className="panel stack">
              <h2>Hospital system</h2>
              <p className="muted">
                {checkLabel(booking.hims_reconciliation?.status)}
                {booking.hims_reconciliation?.checked_at
                  ? ` · ${hospitalTime(booking.hims_reconciliation.checked_at)}`
                  : ""}
              </p>
              <label>
                Check
                <select value={checkStatus} onChange={(event) => setCheckStatus(event.target.value)}>
                  <option value="not_checked">Not checked</option>
                  <option value="checked_available">Checked available</option>
                  <option value="entered_in_hims">Entered in the hospital system</option>
                  <option value="mismatch">Mismatch</option>
                  <option value="not_applicable">Not applicable</option>
                </select>
              </label>
              <label>
                Hospital appointment id
                <input value={appointmentId} onChange={(event) => setAppointmentId(event.target.value)} />
              </label>
              <label>
                Hospital patient id
                <input value={patientId} onChange={(event) => setPatientId(event.target.value)} />
              </label>
              <label>
                Note
                <textarea value={checkNote} onChange={(event) => setCheckNote(event.target.value)} />
              </label>
              <button type="button" disabled={busy} onClick={saveCheck}>
                Save check
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
