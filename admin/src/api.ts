import { clearSession, readSession, writeSession, type StaffSession } from "./session";

const apiBase = (import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api/v1").replace(/\/$/, "");

export class ApiException extends Error {
  statusCode: number;
  code: string;
  fields?: Record<string, unknown>;

  constructor(statusCode: number, code: string, message: string, fields?: Record<string, unknown>) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.fields = fields;
  }

  displayMessage() {
    const fields = this.fields;
    if (fields) {
      const parts = Object.values(fields)
        .flatMap((value) => (Array.isArray(value) ? value : [value]))
        .map((value) => String(value))
        .filter(Boolean);
      if (parts.length > 0) {
        return parts.join(" ");
      }
    }
    return this.message;
  }
}

export type HospitalCheck = {
  status: string;
  hims_appointment_id: string | null;
  hims_patient_id: string | null;
  note: string | null;
  checked_at: string | null;
};

export type StaffBooking = {
  id: string;
  reference: string;
  patient_name: string;
  booking_type: string;
  doctor_name: string | null;
  service_name: string | null;
  requested_date: string;
  preferred_time_slot: string | null;
  patient_note: string | null;
  status: string;
  confirmed_for: string | null;
  staff_note: string | null;
  hims_reconciliation: HospitalCheck | null;
};

type Page<T> = {
  count: number;
  results: T[];
};

async function request(path: string, init: RequestInit = {}, retry = true): Promise<Response> {
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  const session = readSession();
  if (session && !headers.has("Authorization")) {
    headers.set("Authorization", `Bearer ${session.access}`);
  }
  let response: Response;
  try {
    response = await fetch(`${apiBase}${path}`, { ...init, headers });
  } catch {
    throw new ApiException(0, "NETWORK", "The hospital service could not be reached.");
  }
  if (response.status === 401 && retry && session && !path.startsWith("/auth/")) {
    const refreshed = await refreshSession(session);
    if (refreshed) {
      return request(path, init, false);
    }
  }
  return response;
}

async function decode(response: Response): Promise<unknown> {
  const text = await response.text();
  let body: unknown = {};
  if (text) {
    try {
      body = JSON.parse(text);
    } catch {
      throw new ApiException(0, "NETWORK", "The hospital service sent an unexpected response.");
    }
  }
  if (response.status >= 400) {
    const error =
      body && typeof body === "object" && "error" in body
        ? (body as { error?: { code?: string; message?: string; fields?: Record<string, unknown> } }).error
        : undefined;
    throw new ApiException(
      response.status,
      error?.code || "REQUEST_ERROR",
      error?.message || "The request could not be completed.",
      error?.fields,
    );
  }
  return body;
}

async function refreshSession(session: StaffSession): Promise<boolean> {
  try {
    const response = await fetch(`${apiBase}/auth/token/refresh/`, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({ refresh: session.refresh }),
    });
    if (!response.ok) {
      clearSession();
      return false;
    }
    const body = (await response.json()) as Partial<StaffSession>;
    if (!body.access || !body.refresh) {
      clearSession();
      return false;
    }
    writeSession({ access: body.access, refresh: body.refresh });
    return true;
  } catch {
    clearSession();
    return false;
  }
}

export async function staffLogin(mobileNumber: string, password: string) {
  const response = await request(
    "/auth/staff/login/",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mobile_number: mobileNumber, password }),
    },
    false,
  );
  const body = (await decode(response)) as Partial<StaffSession> & { user?: { user_kind?: string } };
  if (!body.access || !body.refresh || (body.user?.user_kind !== "staff" && body.user?.user_kind !== "admin")) {
    throw new ApiException(401, "AUTHENTICATION_FAILED", "The mobile number or password is not valid.");
  }
  writeSession({ access: body.access, refresh: body.refresh });
}

export function staffLogout() {
  const session = readSession();
  clearSession();
  if (!session) {
    return;
  }
  void fetch(`${apiBase}/auth/logout/`, {
    method: "POST",
    headers: { Accept: "application/json", "Content-Type": "application/json" },
    body: JSON.stringify({ refresh: session.refresh }),
  }).catch(() => undefined);
}

export const bookingPageSize = 20;

export type BookingPage = {
  count: number;
  results: StaffBooking[];
};

export async function listBookings(status = "", offset = 0): Promise<BookingPage> {
  const params = new URLSearchParams({
    limit: String(bookingPageSize),
    offset: String(offset),
  });
  if (status) {
    params.set("status", status);
  }
  const body = (await decode(await request(`/admin/bookings/?${params}`))) as Page<StaffBooking>;
  return { count: body.count ?? 0, results: body.results ?? [] };
}

export async function getBooking(bookingId: string): Promise<StaffBooking> {
  return (await decode(await request(`/admin/bookings/${bookingId}/`))) as StaffBooking;
}

export async function reviewBooking(
  bookingId: string,
  status: string,
  confirmedFor: string,
  staffNote: string,
) {
  const payload: Record<string, string> = { status };
  if (confirmedFor) {
    payload.confirmed_for = confirmedFor;
  }
  if (staffNote.trim()) {
    payload.staff_note = staffNote.trim();
  }
  await decode(
    await request(`/admin/bookings/${bookingId}/`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }),
  );
}

export type StaffDepartment = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  display_order: number;
  is_active: boolean;
};

export type StaffService = {
  id: string;
  name: string;
  service_type: string;
  description: string | null;
  preparation_instructions: string | null;
  display_order: number;
  is_active: boolean;
};

export type StaffDoctor = {
  id: string;
  full_name: string;
  qualification: string | null;
  specialty_summary: string | null;
  bio: string | null;
  photo_url: string | null;
  display_order: number;
  is_active: boolean;
  departments: { id: string; name: string; is_primary: boolean }[];
};

async function listAll<T>(path: string): Promise<T[]> {
  const rows: T[] = [];
  const limit = 100;
  let offset = 0;
  for (let page = 0; page < 20; page += 1) {
    const body = (await decode(await request(`${path}?limit=${limit}&offset=${offset}`))) as Page<T>;
    const results = body.results ?? [];
    rows.push(...results);
    offset += limit;
    if (results.length < limit || offset >= (body.count ?? 0)) {
      break;
    }
  }
  return rows;
}

export function listStaffDepartments() {
  return listAll<StaffDepartment>("/admin/departments/");
}

export function listStaffDoctors() {
  return listAll<StaffDoctor>("/admin/doctors/");
}

export function listStaffServices() {
  return listAll<StaffService>("/admin/services/");
}

export async function saveStaffDepartment(record: StaffDepartment | null, body: Record<string, unknown>) {
  const path = record ? `/admin/departments/${record.id}/` : "/admin/departments/";
  await decode(
    await request(path, {
      method: record ? "PATCH" : "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }),
  );
}

export async function saveStaffDoctor(record: StaffDoctor | null, body: Record<string, unknown>) {
  const path = record ? `/admin/doctors/${record.id}/` : "/admin/doctors/";
  await decode(
    await request(path, {
      method: record ? "PATCH" : "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }),
  );
}

export async function saveStaffService(record: StaffService | null, body: Record<string, unknown>) {
  const path = record ? `/admin/services/${record.id}/` : "/admin/services/";
  await decode(
    await request(path, {
      method: record ? "PATCH" : "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }),
  );
}

export async function saveHospitalCheck(
  bookingId: string,
  check: { status: string; hims_appointment_id: string; hims_patient_id: string; note: string },
) {
  await decode(
    await request(`/admin/bookings/${bookingId}/hims-reconciliation/`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(check),
    }),
  );
}
