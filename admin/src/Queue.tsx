import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import { ApiException, bookingPageSize, listBookings, loadBookingCounts, type BookingPage } from "./api";
import { DeskNav } from "./DeskNav";
import { checkLabel, checkTone, prettyDate, prettyMobile, requestLabel, statusLabel, statusTone } from "./labels";

/** The work reception does most comes first. */
const tabs: { status: string; label: string }[] = [
  { status: "requested", label: "New requests" },
  { status: "under_review", label: "In review" },
  { status: "cancellation_requested", label: "Cancellation asked" },
  { status: "confirmed", label: "Confirmed" },
  { status: "completed", label: "Visited" },
  { status: "no_show", label: "Did not come" },
  { status: "cancelled", label: "Cancelled" },
  { status: "rejected", label: "Rejected" },
  { status: "", label: "All" },
];

const emptyText: Record<string, string> = {
  requested: "No new requests. Everything has been looked at.",
  under_review: "Nothing is in review.",
  cancellation_requested: "No patient has asked to cancel.",
  confirmed: "No confirmed appointments.",
};

export function Queue() {
  const navigate = useNavigate();
  const [status, setStatus] = useState("requested");
  const [offset, setOffset] = useState(0);
  const [page, setPage] = useState<BookingPage>({ count: 0, results: [] });
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [total, setTotal] = useState<number | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [refresh, setRefresh] = useState(0);

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
    // The numbers on the tabs are a convenience. The list still works without them.
    loadBookingCounts()
      .then((loaded) => {
        if (active) {
          setCounts(loaded.by_status);
          setTotal(loaded.total);
        }
      })
      .catch(() => undefined);
    return () => {
      active = false;
    };
  }, [navigate, offset, status, refresh]);

  function countFor(tabStatus: string) {
    if (tabStatus === "") {
      return total;
    }
    return total === null ? null : (counts[tabStatus] ?? 0);
  }

  return (
    <>
      <DeskNav title="Appointments" subtitle="Open a request to confirm a time or to reject it." />
      <main className="page">
        <div className="tabs" role="tablist" aria-label="Filter appointments">
          {tabs.map((tab) => {
            const count = countFor(tab.status);
            return (
              <button
                key={tab.status || "all"}
                type="button"
                role="tab"
                aria-selected={status === tab.status}
                className={`tab${status === tab.status ? " active" : ""}`}
                onClick={() => {
                  setStatus(tab.status);
                  setOffset(0);
                }}
              >
                {tab.label}
                {count === null ? null : <span className="count">{count}</span>}
              </button>
            );
          })}
          <button className="secondary" type="button" onClick={() => setRefresh((value) => value + 1)}>
            ↻ Refresh
          </button>
        </div>
        {error ? <p className="error">{error}</p> : null}
        {loading && page.results.length === 0 ? <p className="muted">Loading appointments…</p> : null}
        {!loading && !error && page.count === 0 ? (
          <div className="empty">
            <strong>Nothing here</strong>
            {emptyText[status] ?? "No appointments in this list."}
          </div>
        ) : null}
        {page.results.length > 0 ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Patient</th>
                  <th>Asked for</th>
                  <th>Date and time</th>
                  <th>Status</th>
                  <th>Hospital system</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {page.results.map((booking) => (
                  <tr key={booking.id} className="clickable" onClick={() => navigate(`/bookings/${booking.id}`)}>
                    <td>
                      <span className="strong">{booking.patient_name}</span>
                      <span className="sub">
                        {prettyMobile(booking.patient_mobile_number) || booking.reference}
                      </span>
                    </td>
                    <td>
                      {requestLabel(booking)}
                      <span className="sub">{booking.reference}</span>
                    </td>
                    <td>
                      {prettyDate(booking.requested_date)}
                      <span className="sub">{booking.preferred_time_slot || "No time chosen"}</span>
                    </td>
                    <td>
                      <span className={`badge ${statusTone(booking.status)}`}>{statusLabel(booking.status)}</span>
                    </td>
                    <td>
                      <span className={`badge ${checkTone(booking.hims_reconciliation?.status)}`}>
                        {checkLabel(booking.hims_reconciliation?.status)}
                      </span>
                    </td>
                    <td>
                      <button
                        type="button"
                        className="secondary"
                        onClick={(event) => {
                          event.stopPropagation();
                          navigate(`/bookings/${booking.id}`);
                        }}
                      >
                        Open
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : null}
        {!loading && !error && page.count > 0 ? (
          <div className="actions">
            <span className="muted">
              Showing {offset + 1}–{offset + page.results.length} of {page.count}
            </span>
            {page.count > bookingPageSize ? (
              <>
                <button
                  className="secondary"
                  type="button"
                  disabled={offset === 0}
                  onClick={() => setOffset(Math.max(0, offset - bookingPageSize))}
                >
                  ← Previous
                </button>
                <button
                  className="secondary"
                  type="button"
                  disabled={offset + bookingPageSize >= page.count}
                  onClick={() => setOffset(offset + bookingPageSize)}
                >
                  Next →
                </button>
              </>
            ) : null}
          </div>
        ) : null}
      </main>
    </>
  );
}
