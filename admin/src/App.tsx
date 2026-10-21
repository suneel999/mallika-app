import type { ReactNode } from "react";
import { Navigate, Route, Routes } from "react-router-dom";

import { BookingDesk } from "./BookingDesk";
import { Queue } from "./Queue";
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
