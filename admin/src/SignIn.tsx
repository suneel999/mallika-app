import { useState, type FormEvent } from "react";
import { Navigate, useNavigate } from "react-router-dom";

import { ApiException, staffLogin } from "./api";
import { readSession } from "./session";

export function SignIn() {
  const navigate = useNavigate();
  const [mobileNumber, setMobileNumber] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  if (readSession()) {
    return <Navigate to="/bookings" replace />;
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      await staffLogin(mobileNumber.trim(), password);
      navigate("/bookings");
    } catch (caught) {
      setError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="card">
      <h1>Mallika Hospitals</h1>
      <p className="muted">Staff desk</p>
      <form className="stack" onSubmit={onSubmit}>
        <label>
          Mobile number
          <input
            value={mobileNumber}
            onChange={(event) => setMobileNumber(event.target.value)}
            autoComplete="username"
            inputMode="tel"
            required
          />
        </label>
        <label>
          Password
          <input
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            autoComplete="current-password"
            required
          />
        </label>
        {error ? <p className="error">{error}</p> : null}
        <button type="submit" disabled={busy}>
          {busy ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </main>
  );
}
