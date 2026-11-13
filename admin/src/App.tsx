import type { ReactNode } from "react";
import { Navigate, Route, Routes } from "react-router-dom";

import { Audit } from "./Audit";
import { BookingDesk } from "./BookingDesk";
import { Catalogue } from "./Catalogue";
import { Patients } from "./Patients";
import { Queue } from "./Queue";
import { Reports } from "./Reports";
import { SignIn } from "./SignIn";
import { readSession } from "./session";

function RequireStaff({ children }: { children: ReactNode }) {
  if (!readSession()) {
    return <Navigate to="/" replace />;
  }
  return children;
}

export function App() {
  return (
    <Routes>
      <Route path="/" element={<SignIn />} />
      <Route
        path="/reports"
        element={
          <RequireStaff>
            <Reports />
          </RequireStaff>
        }
      />
      <Route
        path="/audit"
        element={
          <RequireStaff>
            <Audit />
          </RequireStaff>
        }
      />
      <Route
        path="/patients"
        element={
          <RequireStaff>
            <Patients />
          </RequireStaff>
        }
      />
      <Route
        path="/catalogue"
        element={
          <RequireStaff>
            <Catalogue />
          </RequireStaff>
        }
      />
      <Route
        path="/bookings"
        element={
          <RequireStaff>
            <Queue />
          </RequireStaff>
        }
      />
      <Route
        path="/bookings/:bookingId"
        element={
          <RequireStaff>
            <BookingDesk />
          </RequireStaff>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
