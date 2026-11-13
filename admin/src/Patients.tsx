import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";

import {
  ApiException,
  bookingPageSize,
  getStaffPatient,
  searchPatients,
  updateStaffPatient,
  type StaffPatient,
  type StaffPatientDetail,
} from "./api";
import { DeskNav } from "./DeskNav";
import { prettyMobile } from "./labels";

export function Patients() {
  const navigate = useNavigate();
  const [query, setQuery] = useState("");
  const [offset, setOffset] = useState(0);
  const [count, setCount] = useState(0);
  const [results, setResults] = useState<StaffPatient[]>([]);
  const [searched, setSearched] = useState(false);
  const [selected, setSelected] = useState<StaffPatientDetail | null>(null);
  const [fullName, setFullName] = useState("");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [sex, setSex] = useState("");
  const [email, setEmail] = useState("");
  const [language, setLanguage] = useState("en");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  async function runSearch(nextOffset: number, term = query) {
    setLoading(true);
    setError("");
    try {
      const page = await searchPatients(term.trim(), nextOffset);
      setCount(page.count);
      setResults(page.results);
      setOffset(nextOffset);
      setSearched(true);
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
      if (caught instanceof ApiException && caught.statusCode === 401) {
        navigate("/");
      }
    } finally {
      setLoading(false);
    }
  }

  async function onSearch(event: FormEvent) {
    event.preventDefault();
    setSelected(null);
    await runSearch(0);
  }

  async function openPatient(patient: StaffPatient) {
    setBusy(true);
    setError("");
    setNotice("");
    try {
      const detail = await getStaffPatient(patient.id);
      setSelected(detail);
      setFullName(detail.full_name);
      setDateOfBirth(detail.date_of_birth ?? "");
      setSex(detail.sex ?? "");
      setEmail(detail.email ?? "");
      setLanguage(detail.preferred_language || "en");
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  async function onSave(event: FormEvent) {
    event.preventDefault();
    if (!selected) {
      return;
    }
    setBusy(true);
    setError("");
    setNotice("");
    try {
      const body: Record<string, unknown> = {};
      if (fullName.trim() !== selected.full_name) {
        body.full_name = fullName.trim();
      }
      if ((dateOfBirth || null) !== (selected.date_of_birth || null)) {
        body.date_of_birth = dateOfBirth || null;
      }
      if ((sex || null) !== (selected.sex || null)) {
        body.sex = sex || null;
      }
      if ((email.trim() || null) !== (selected.email || null)) {
        body.email = email.trim() || null;
      }
      if (language !== selected.preferred_language) {
        body.preferred_language = language;
      }
      if (Object.keys(body).length === 0) {
        return;
      }
      const saved = await updateStaffPatient(selected.id, body);
      setSelected(saved);
      setNotice("Patient details saved.");
      setResults((current) =>
        current.map((item) => (item.id === saved.id ? { ...item, full_name: saved.full_name } : item)),
      );
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <DeskNav title="Patients" subtitle="Find a patient and correct their details." />
      <main className="page">
        <form className="toolbar" onSubmit={onSearch}>
          <label className="grow">
            Find a patient
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Name, patient number, or mobile number"
              minLength={2}
              autoFocus
              required
            />
          </label>
          <button type="submit" disabled={loading}>
            {loading ? "Searching…" : "Search"}
          </button>
        </form>
        {error ? <p className="error">{error}</p> : null}
        {notice ? <p className="notice">✓ {notice}</p> : null}
        {!searched ? (
          <div className="empty">
            <strong>Search for a patient</strong>
            Type at least two letters or digits, then press Search.
          </div>
        ) : null}
        {searched && !loading && count === 0 ? (
          <div className="empty">
            <strong>No matching patient</strong>
            Check the spelling, or try the mobile number.
          </div>
        ) : null}
        {searched && count > 0 ? (
          <p className="muted">
            Showing {offset + 1}–{offset + results.length} of {count}
          </p>
        ) : null}
        {results.length > 0 ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Patient number</th>
                  <th>Name</th>
                  <th>Mobile</th>
                </tr>
              </thead>
              <tbody>
                {results.map((patient) => (
                  <tr key={patient.id} className="clickable" onClick={() => openPatient(patient)}>
                    <td>{patient.patient_number}</td>
                    <td className="strong">{patient.full_name}</td>
                    <td>{prettyMobile(patient.mobile_number)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : null}
        {searched && count > bookingPageSize ? (
          <div className="actions">
            <button
              className="secondary"
              type="button"
              disabled={offset === 0 || loading}
              onClick={() => runSearch(Math.max(0, offset - bookingPageSize))}
            >
              Previous
            </button>
            <button
              className="secondary"
              type="button"
              disabled={loading || offset + bookingPageSize >= count}
              onClick={() => runSearch(offset + bookingPageSize)}
            >
              Next
            </button>
          </div>
        ) : null}
        {selected ? (
          <form className="panel stack" onSubmit={onSave}>
            <div>
              <h2>Correct details for {selected.full_name}</h2>
              <p className="muted small">
                {selected.patient_number} · Mobile {selected.mobile_number}. The mobile number cannot be changed here.
              </p>
            </div>
            <label>
              Full name
              <input value={fullName} onChange={(event) => setFullName(event.target.value)} required />
            </label>
            <label>
              Date of birth
              <input type="date" value={dateOfBirth} onChange={(event) => setDateOfBirth(event.target.value)} />
            </label>
            <label>
              Sex
              <select value={sex} onChange={(event) => setSex(event.target.value)}>
                <option value="">Not recorded</option>
                <option value="female">Female</option>
                <option value="male">Male</option>
                <option value="other">Other</option>
              </select>
            </label>
            <label>
              Email
              <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
            </label>
            <label>
              Language
              <select value={language} onChange={(event) => setLanguage(event.target.value)}>
                <option value="en">English</option>
                <option value="te">Telugu</option>
              </select>
            </label>
            <button type="submit" disabled={busy}>
              {busy ? "Saving…" : "Save patient"}
            </button>
          </form>
        ) : null}
      </main>
    </>
  );
}
