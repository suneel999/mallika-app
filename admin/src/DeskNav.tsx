import { Link, NavLink, useNavigate } from "react-router-dom";

import { staffLogout } from "./api";

const links = [
  ["/bookings", "Appointments", "📅"],
  ["/patients", "Patients", "👤"],
  ["/catalogue", "Doctors & services", "🩺"],
  ["/reports", "Reports", "📊"],
  ["/audit", "Activity log", "🕘"],
] as const;

export function DeskNav({
  title,
  subtitle,
  backTo,
  backLabel = "Back",
}: {
  title: string;
  subtitle: string;
  backTo?: string;
  backLabel?: string;
}) {
  const navigate = useNavigate();

  return (
    <>
      <aside className="sidebar">
        <div className="brand">
          <img src="/mallika_logo.png" alt="" />
          <div>
            <strong>Mallika Hospitals</strong>
            <span>Reception desk</span>
          </div>
        </div>
        {links.map(([to, label, icon]) => (
          <NavLink key={to} to={to} className={({ isActive }) => `nav-link${isActive ? " active" : ""}`}>
            <span className="nav-icon" aria-hidden="true">
              {icon}
            </span>
            {label}
          </NavLink>
        ))}
        <div className="nav-spacer" />
        <button
          className="signout"
          type="button"
          onClick={() => {
            staffLogout();
            navigate("/");
          }}
        >
          Sign out
        </button>
      </aside>
      <header className="page-head">
        {backTo ? (
          <Link className="button-link secondary" to={backTo}>
            ← {backLabel}
          </Link>
        ) : null}
        <div>
          <h1>{title}</h1>
          <p>{subtitle}</p>
        </div>
      </header>
    </>
  );
}
