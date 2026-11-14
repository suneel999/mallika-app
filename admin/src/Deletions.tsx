import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import {
  ApiException,
  decideAccountDeletion,
  listAccountDeletions,
  type AccountDeletion,
} from "./api";
import { DeskNav } from "./DeskNav";
import { hospitalTime, prettyMobile } from "./labels";

export function Deletions() {
  const navigate = useNavigate();
  const [rows, setRows] = useState<AccountDeletion[]>([]);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState("");

  async function load() {
    setLoading(true);
    try {
      setRows(await listAccountDeletions());
      setError("");
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
      if (caught instanceof ApiException && caught.statusCode === 401) {
        navigate("/");
      }
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
    // The list is loaded once when the screen opens.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function decide(row: AccountDeletion, decision: "complete" | "keep") {
    const who = row.patient_name || prettyMobile(row.mobile_number) || "this patient";
    const question =
      decision === "complete"
        ? `Delete the account of ${who}? Their profile, family members, bookings and updates are removed. This cannot be undone.`
        : `Keep the account of ${who}? They will be able to sign in again.`;
    if (!window.confirm(question)) {
      return;
    }
    setBusy(row.id);
    setError("");
    setNotice("");
    try {
      await decideAccountDeletion(row.id, decision);
      setNotice(decision === "complete" ? `The account of ${who} was deleted.` : `The account of ${who} was kept.`);
      await load();
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy("");
    }
  }

  return (
    <>
      <DeskNav
        title="Delete requests"
        subtitle="Patients who asked in the app to delete their account. Finish each one within 7 days."
      />
      <main className="page">
        {error ? <p className="error">{error}</p> : null}
        {notice ? <p className="notice">✓ {notice}</p> : null}
        {loading ? <p className="muted">Loading requests…</p> : null}
        {!loading && !error && rows.length === 0 ? (
          <div className="empty">
            <strong>No delete requests</strong>
            Nobody is waiting to have their account deleted.
          </div>
        ) : null}
        {rows.length > 0 ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Patient</th>
                  <th>Asked on</th>
                  <th>Delete by</th>
                  <th>Open bookings</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => {
                  const late = new Date(row.delete_by).getTime() < Date.now();
                  return (
                    <tr key={row.id}>
                      <td>
                        <span className="strong">{row.patient_name || "No profile yet"}</span>
                        <span className="sub">{prettyMobile(row.mobile_number)}</span>
                      </td>
                      <td>{hospitalTime(row.requested_at)}</td>
                      <td>
                        <span className={`badge ${late ? "red" : "amber"}`}>{hospitalTime(row.delete_by)}</span>
                      </td>
                      <td>{row.open_bookings === 0 ? "None" : row.open_bookings}</td>
                      <td>
                        <div className="actions">
                          <button
                            type="button"
                            className="danger"
                            disabled={busy === row.id}
                            onClick={() => decide(row, "complete")}
                          >
                            Delete now
                          </button>
                          <button
                            type="button"
                            className="secondary"
                            disabled={busy === row.id}
                            onClick={() => decide(row, "keep")}
                          >
                            Keep account
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : null}
        <p className="muted small">
          The patient is signed out as soon as they ask. Call them first if they have an open booking. "Keep account"
          is for a patient who changed their mind.
        </p>
      </main>
    </>
  );
}
