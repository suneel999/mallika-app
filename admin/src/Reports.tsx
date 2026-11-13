import { useEffect, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";

import { ApiException, loadBookingCounts, type BookingCounts } from "./api";
import { DeskNav } from "./DeskNav";
import { prettyDate, statusLabel } from "./labels";

const emptyCounts: BookingCounts = { from: null, to: null, total: 0, by_status: {} };

export function Reports() {
  const navigate = useNavigate();
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [counts, setCounts] = useState<BookingCounts>(emptyCounts);
  const [error, setError] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void show("", "");
    // The all-time counts are loaded once when the screen opens.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function onShow(event: FormEvent) {
    event.preventDefault();
    await show(from, to);
  }

  async function show(from: string, to: string) {
    setBusy(true);
    try {
      setCounts(await loadBookingCounts(from, to));
      setError("");
      setLoaded(true);
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
      if (caught instanceof ApiException && caught.statusCode === 401) {
        navigate("/");
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <DeskNav title="Reports" subtitle="How many appointments, counted by the date the patient asked for." />
      <main className="page">
        <form className="toolbar" onSubmit={onShow}>
          <label>
            From
            <input type="date" value={from} onChange={(event) => setFrom(event.target.value)} />
          </label>
          <label>
            To
            <input type="date" value={to} onChange={(event) => setTo(event.target.value)} />
          </label>
          <button type="submit" disabled={busy}>
            {busy ? "Loading…" : "Show"}
          </button>
        </form>
        {error ? <p className="error">{error}</p> : null}
        {loaded ? (
          <>
            <p className="muted">
              {counts.from || counts.to
                ? `From ${counts.from ? prettyDate(counts.from) : "the start"} to ${counts.to ? prettyDate(counts.to) : "the latest"}.`
                : "All dates. Choose dates above to narrow it."}
            </p>
            <div className="stats">
              <div className="stat total">
                <strong>{counts.total}</strong>
                <span>All appointments</span>
              </div>
              {Object.entries(counts.by_status).map(([status, count]) => (
                <div className="stat" key={status}>
                  <strong>{count}</strong>
                  <span>{statusLabel(status)}</span>
                </div>
              ))}
            </div>
          </>
        ) : null}
      </main>
    </>
  );
}
