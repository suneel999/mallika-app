const storageKey = "mallika.staff.session";

export type StaffSession = {
  access: string;
  refresh: string;
};

export function readSession(): StaffSession | null {
  const raw = sessionStorage.getItem(storageKey);
  if (!raw) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw) as Partial<StaffSession>;
    if (!parsed.access || !parsed.refresh) {
      return null;
    }
    return { access: parsed.access, refresh: parsed.refresh };
  } catch {
    return null;
  }
}

export function writeSession(session: StaffSession) {
  sessionStorage.setItem(storageKey, JSON.stringify(session));
}

export function clearSession() {
  sessionStorage.removeItem(storageKey);
}
