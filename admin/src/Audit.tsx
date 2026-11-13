import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import { ApiException, bookingPageSize, listAuditLogs, type AuditEntry } from "./api";
import { DeskNav } from "./DeskNav";

const actionLabel: Record<string, string> = {
  "patient.search": "Searched for a patient",
  "patient.view": "Opened a patient",
  "patient.update": "Corrected a patient",
};

export function Audit() {
  const navigate = useNavigate();
  const [action, setAction] = useState("");
  const entityType = "";
  const [offset, setOffset] = useState(0);
  const [count, setCount] = useState(0);
  const [rows, setRows] = useState<AuditEntry[]>([]);
  const [error, setError] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [busy, setBusy] = useState(false);

  async function load(nextOffset: number, filters = { action: action.trim(), entityType: entityType.trim() }) {
    setBusy(true);
    try {
      const page = await listAuditLogs(filters, nextOffset);
      setRows(page.results);
      setCount(page.count);
      setOffset(nextOffset);
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

  useEffect(() => {
    void load(0, { action: "", entityType: "" });
    // The latest rows are loaded once when the screen opens.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <>
      <DeskNav title="Activity log" subtitle="Who searched for or corrected a patient, and when. The search words are not stored." />
      <main className="page">
        <form
          className="toolbar"
          onSubmit={(event) => {
            event.preventDefault();
            void load(0);
          }}
        >
          <label>
            What was done
            <select value={action} onChange={(event) => setAction(event.target.value)}>
              <option value="">Everything</option>
              {Object.entries(actionLabel).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </label>
          <button type="submit" disabled={busy}>
            {busy ? "Loading…" : "Show"}
          </button>
        </form>
        {error ? <p className="error">{error}</p> : null}
        {loaded ? (
          <>
            <p className="muted">
              {count === 0
                ? "No matching rows."
                : `Showing ${offset + 1}–${offset + rows.length} of ${count}`}
            </p>
            {rows.length > 0 ? (
            <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>When</th>
                  <th>What was done</th>
                  <th>Staff mobile</th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td>{new Date(row.created_at).toLocaleString("en-IN", { timeZone: "Asia/Kolkata" })}</td>
                    <td>{actionLabel[row.action] ?? row.action}</td>
                    <td>{row.actor_mobile_number || "—"}</td>
                    <td className="muted small">{detailText(row.details)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            </div>
            ) : null}
            {count > bookingPageSize ? (
              <div className="actions">
                <button className="secondary" type="button" disabled={busy || offset === 0} onClick={() => void load(offset - bookingPageSize)}>
                  Previous
                </button>
                <button
                  className="secondary"
                  type="button"
                  disabled={busy || offset + bookingPageSize >= count}
                  onClick={() => void load(offset + bookingPageSize)}
                >
                  Next
                </button>
              </div>
            ) : null}
          </>
        ) : null}
      </main>
    </>
  );
}

function detailText(details: Record<string, unknown>) {
  const parts = Object.entries(details).map(([key, value]) => {
    const shown = Array.isArray(value) ? value.join(", ") : String(value);
    return `${key.replace(/_/g, " ")}: ${shown}`;
  });
  return parts.length > 0 ? parts.join(" · ") : "—";
}
