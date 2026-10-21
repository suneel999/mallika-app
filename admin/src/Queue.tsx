import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { ApiException, bookingPageSize, listBookings, staffLogout, type BookingPage } from "./api";
import { checkLabel, requestLabel, statusLabel } from "./labels";

export function Queue() {
  const navigate = useNavigate();
  const [status, setStatus] = useState("");
  const [offset, setOffset] = useState(0);
  const [page, setPage] = useState<BookingPage>({ count: 0, results: [] });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    setLoading(true);
    listBookings(status, offset)
      .then((loaded) => {
        if (active) {
          setPage(loaded);
          setError("");
        }
      })
      .catch((caught) => {
        if (!active) {
          return;
        }
        setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
        if (caught instanceof ApiException && caught.statusCode === 401) {
          navigate("/");
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
  }, [navigate, offset, status]);

  function signOut() {
    staffLogout();
    navigate("/");
  }

  return (
    <>
      <header className="topbar">
        <div>
          <h1>Booking queue</h1>
          <p>Requests stay pending until a time is confirmed.</p>
        </div>
        <div className="actions">
          <Link className="button-link secondary" to="/catalogue">
            Catalogue
          </Link>
          <button className="secondary" type="button" onClick={signOut}>
            Sign out
          </button>
        </div>
      </header>
      <main className="page">
        <div className="toolbar">
          <label>
            Status
            <select
              value={status}
              onChange={(event) => {
                setStatus(event.target.value);
                setOffset(0);
              }}
            >
              <option value="">All</option>
              <option value="requested">Pending</option>
              <option value="under_review">Under review</option>
              <option value="confirmed">Confirmed</option>
              <option value="cancellation_requested">Cancellation requested</option>
              <option value="rejected">Rejected</option>
              <option value="cancelled">Cancelled</option>
              <option value="completed">Completed</option>
              <option value="no_show">Missed visit</option>
            </select>
          </label>
        </div>
        {error ? <p className="error">{error}</p> : null}
        {loading ? <p>Loading bookings…</p> : null}
        {!loading && !error && page.count === 0 ? <p>No booking requests.</p> : null}
        {!loading && !error && page.count > 0 ? (
          <p className="muted">
            Showing {offset + 1}–{offset + page.results.length} of {page.count}
          </p>
        ) : null}
        {page.results.length > 0 ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Reference</th>
                  <th>Patient</th>
                  <th>Request</th>
                  <th>Date</th>
                  <th>Time</th>
                  <th>Status</th>
                  <th>Hospital system</th>
                </tr>
              </thead>
              <tbody>
                {page.results.map((booking) => (
                  <tr key={booking.id} className="clickable" onClick={() => navigate(`/bookings/${booking.id}`)}>
                    <td>{booking.reference}</td>
                    <td>{booking.patient_name}</td>
                    <td>{requestLabel(booking)}</td>
                    <td>{booking.requested_date}</td>
                    <td>{booking.preferred_time_slot || ""}</td>
                    <td>{statusLabel(booking.status)}</td>
                    <td>{checkLabel(booking.hims_reconciliation?.status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : null}
        {!loading && !error && page.count > bookingPageSize ? (
          <div className="actions">
            <button
              className="secondary"
              type="button"
              disabled={offset === 0}
              onClick={() => setOffset(Math.max(0, offset - bookingPageSize))}
            >
              Previous
            </button>
            <button
              className="secondary"
              type="button"
              disabled={offset + bookingPageSize >= page.count}
              onClick={() => setOffset(offset + bookingPageSize)}
            >
              Next
            </button>
          </div>
        ) : null}
      </main>
    </>
  );
}
