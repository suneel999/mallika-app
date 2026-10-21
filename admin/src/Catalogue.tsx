import { useEffect, useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";

import {
  ApiException,
  listStaffDepartments,
  listStaffDoctors,
  listStaffServices,
  saveStaffDepartment,
  saveStaffDoctor,
  saveStaffService,
  staffLogout,
  type StaffDepartment,
  type StaffDoctor,
  type StaffService,
} from "./api";

type Tab = "doctors" | "services" | "departments";

export function Catalogue() {
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>("doctors");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [doctors, setDoctors] = useState<StaffDoctor[]>([]);
  const [services, setServices] = useState<StaffService[]>([]);
  const [departments, setDepartments] = useState<StaffDepartment[]>([]);

  async function reload() {
    setLoading(true);
    setError("");
    try {
      const [nextDoctors, nextServices, nextDepartments] = await Promise.all([
        listStaffDoctors(),
        listStaffServices(),
        listStaffDepartments(),
      ]);
      setDoctors(nextDoctors);
      setServices(nextServices);
      setDepartments(nextDepartments);
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
    void reload();
    // The catalogue is loaded once when the screen opens.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function signOut() {
    staffLogout();
    navigate("/");
  }

  return (
    <>
      <header className="topbar">
        <div>
          <h1>Catalogue</h1>
          <p>Publish the consultation doctor and the services patients can request.</p>
        </div>
        <div className="actions">
          <Link className="button-link secondary" to="/bookings">
            Booking queue
          </Link>
          <button className="secondary" type="button" onClick={signOut}>
            Sign out
          </button>
        </div>
      </header>
      <main className="page">
        <div className="actions">
          <button className={tab === "doctors" ? "" : "secondary"} type="button" onClick={() => setTab("doctors")}>
            Doctors
          </button>
          <button className={tab === "services" ? "" : "secondary"} type="button" onClick={() => setTab("services")}>
            Services
          </button>
          <button
            className={tab === "departments" ? "" : "secondary"}
            type="button"
            onClick={() => setTab("departments")}
          >
            Departments
          </button>
        </div>
        {error ? <p className="error">{error}</p> : null}
        {loading ? <p>Loading catalogue…</p> : null}
        {!loading && tab === "doctors" ? (
          <DoctorEditor
            doctors={doctors}
            departments={departments}
            onSaved={reload}
            onError={setError}
          />
        ) : null}
        {!loading && tab === "services" ? <ServiceEditor services={services} onSaved={reload} onError={setError} /> : null}
        {!loading && tab === "departments" ? (
          <DepartmentEditor departments={departments} onSaved={reload} onError={setError} />
        ) : null}
      </main>
    </>
  );
}

function DoctorEditor({
  doctors,
  departments,
  onSaved,
  onError,
}: {
  doctors: StaffDoctor[];
  departments: StaffDepartment[];
  onSaved: () => Promise<void>;
  onError: (message: string) => void;
}) {
  const [editing, setEditing] = useState<StaffDoctor | null>(null);
  const [fullName, setFullName] = useState("");
  const [qualification, setQualification] = useState("");
  const [summary, setSummary] = useState("");
  const [photoUrl, setPhotoUrl] = useState("");
  const [order, setOrder] = useState("0");
  const [active, setActive] = useState(true);
  const [linked, setLinked] = useState<string[]>([]);
  const [primaryId, setPrimaryId] = useState("");
  const [busy, setBusy] = useState(false);

  function edit(doctor: StaffDoctor | null) {
    setEditing(doctor);
    setFullName(doctor?.full_name ?? "");
    setQualification(doctor?.qualification ?? "");
    setSummary(doctor?.specialty_summary ?? "");
    setPhotoUrl(doctor?.photo_url ?? "");
    setOrder(String(doctor?.display_order ?? 0));
    setActive(doctor?.is_active ?? true);
    setLinked(doctor?.departments.map((item) => item.id) ?? []);
    setPrimaryId(doctor?.departments.find((item) => item.is_primary)?.id ?? "");
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    onError("");
    try {
      await saveStaffDoctor(editing, {
        full_name: fullName.trim(),
        qualification,
        specialty_summary: summary,
        photo_url: photoUrl,
        display_order: Number(order || 0),
        is_active: active,
        departments: linked.map((id) => ({ id, is_primary: id === primaryId })),
      });
      edit(null);
      await onSaved();
    } catch (caught) {
      onError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid">
      <form className="panel stack" onSubmit={onSubmit}>
        <h2>{editing ? "Edit doctor" : "Add doctor"}</h2>
        <label>
          Full name
          <input value={fullName} onChange={(event) => setFullName(event.target.value)} required />
        </label>
        <label>
          Qualification
          <input value={qualification} onChange={(event) => setQualification(event.target.value)} />
        </label>
        <label>
          Specialty
          <input value={summary} onChange={(event) => setSummary(event.target.value)} />
        </label>
        <label>
          Photo address
          <input value={photoUrl} onChange={(event) => setPhotoUrl(event.target.value)} placeholder="https://" />
        </label>
        <label>
          Display order
          <input value={order} onChange={(event) => setOrder(event.target.value)} inputMode="numeric" />
        </label>
        <label>
          <span>
            <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} /> Published
          </span>
        </label>
        {departments.length > 0 ? (
          <fieldset className="stack">
            <legend>Departments</legend>
            {departments.map((department) => (
              <label key={department.id}>
                <span>
                  <input
                    type="checkbox"
                    checked={linked.includes(department.id)}
                    onChange={(event) => {
                      const next = event.target.checked
                        ? [...linked, department.id]
                        : linked.filter((id) => id !== department.id);
                      setLinked(next);
                      if (!next.includes(primaryId)) {
                        setPrimaryId(next[0] ?? "");
                      }
                    }}
                  />
                  {department.name}
                  <input
                    type="radio"
                    name="primary-department"
                    checked={primaryId === department.id}
                    disabled={!linked.includes(department.id)}
                    onChange={() => setPrimaryId(department.id)}
                  />
                  Primary
                </span>
              </label>
            ))}
          </fieldset>
        ) : null}
        <div className="actions">
          <button type="submit" disabled={busy}>
            {busy ? "Saving…" : "Save doctor"}
          </button>
          {editing ? (
            <button className="secondary" type="button" onClick={() => edit(null)}>
              Cancel
            </button>
          ) : null}
        </div>
      </form>
      <section className="panel stack">
        <h2>Doctors</h2>
        {doctors.length === 0 ? <p>No doctor has been published.</p> : null}
        {doctors.map((doctor) => (
          <button className="secondary" key={doctor.id} type="button" onClick={() => edit(doctor)}>
            {doctor.full_name}
            {doctor.is_active ? "" : " · Unpublished"}
          </button>
        ))}
      </section>
    </div>
  );
}

function ServiceEditor({
  services,
  onSaved,
  onError,
}: {
  services: StaffService[];
  onSaved: () => Promise<void>;
  onError: (message: string) => void;
}) {
  const [editing, setEditing] = useState<StaffService | null>(null);
  const [name, setName] = useState("");
  const [serviceType, setServiceType] = useState("health_checkup");
  const [description, setDescription] = useState("");
  const [preparation, setPreparation] = useState("");
  const [order, setOrder] = useState("0");
  const [active, setActive] = useState(true);
  const [busy, setBusy] = useState(false);

  function edit(service: StaffService | null) {
    setEditing(service);
    setName(service?.name ?? "");
    setServiceType(service?.service_type ?? "health_checkup");
    setDescription(service?.description ?? "");
    setPreparation(service?.preparation_instructions ?? "");
    setOrder(String(service?.display_order ?? 0));
    setActive(service?.is_active ?? true);
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    onError("");
    try {
      await saveStaffService(editing, {
        name: name.trim(),
        service_type: serviceType,
        description,
        preparation_instructions: preparation,
        display_order: Number(order || 0),
        is_active: active,
      });
      edit(null);
      await onSaved();
    } catch (caught) {
      onError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid">
      <form className="panel stack" onSubmit={onSubmit}>
        <h2>{editing ? "Edit service" : "Add service"}</h2>
        <label>
          Name
          <input value={name} onChange={(event) => setName(event.target.value)} required />
        </label>
        <label>
          Type
          <select value={serviceType} onChange={(event) => setServiceType(event.target.value)}>
            <option value="diagnostics">Diagnostics</option>
            <option value="health_checkup">Health checkup</option>
            <option value="procedure">Procedure</option>
            <option value="consultation">Consultation</option>
          </select>
        </label>
        <label>
          Description
          <textarea value={description} onChange={(event) => setDescription(event.target.value)} />
        </label>
        <label>
          Preparation
          <textarea value={preparation} onChange={(event) => setPreparation(event.target.value)} />
        </label>
        <label>
          Display order
          <input value={order} onChange={(event) => setOrder(event.target.value)} inputMode="numeric" />
        </label>
        <label>
          <span>
            <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} /> Published
          </span>
        </label>
        <div className="actions">
          <button type="submit" disabled={busy}>
            {busy ? "Saving…" : "Save service"}
          </button>
          {editing ? (
            <button className="secondary" type="button" onClick={() => edit(null)}>
              Cancel
            </button>
          ) : null}
        </div>
      </form>
      <section className="panel stack">
        <h2>Services</h2>
        {services.length === 0 ? <p>No service has been published.</p> : null}
        {services.map((service) => (
          <button className="secondary" key={service.id} type="button" onClick={() => edit(service)}>
            {service.name}
            {service.is_active ? "" : " · Unpublished"}
          </button>
        ))}
      </section>
    </div>
  );
}

function DepartmentEditor({
  departments,
  onSaved,
  onError,
}: {
  departments: StaffDepartment[];
  onSaved: () => Promise<void>;
  onError: (message: string) => void;
}) {
  const [editing, setEditing] = useState<StaffDepartment | null>(null);
  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [description, setDescription] = useState("");
  const [order, setOrder] = useState("0");
  const [active, setActive] = useState(true);
  const [busy, setBusy] = useState(false);

  function edit(department: StaffDepartment | null) {
    setEditing(department);
    setName(department?.name ?? "");
    setSlug(department?.slug ?? "");
    setDescription(department?.description ?? "");
    setOrder(String(department?.display_order ?? 0));
    setActive(department?.is_active ?? true);
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    onError("");
    try {
      const body: Record<string, unknown> = {
        name: name.trim(),
        description,
        display_order: Number(order || 0),
        is_active: active,
      };
      if (slug.trim() || editing) {
        body.slug = slug.trim();
      }
      await saveStaffDepartment(editing, body);
      edit(null);
      await onSaved();
    } catch (caught) {
      onError(caught instanceof ApiException ? caught.displayMessage() : "The request could not be completed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid">
      <form className="panel stack" onSubmit={onSubmit}>
        <h2>{editing ? "Edit department" : "Add department"}</h2>
        <label>
          Name
          <input value={name} onChange={(event) => setName(event.target.value)} required />
        </label>
        <label>
          Address
          <input value={slug} onChange={(event) => setSlug(event.target.value)} placeholder="Filled from the name" />
        </label>
        <label>
          Description
          <textarea value={description} onChange={(event) => setDescription(event.target.value)} />
        </label>
        <label>
          Display order
          <input value={order} onChange={(event) => setOrder(event.target.value)} inputMode="numeric" />
        </label>
        <label>
          <span>
            <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} /> Published
          </span>
        </label>
        <div className="actions">
          <button type="submit" disabled={busy}>
            {busy ? "Saving…" : "Save department"}
          </button>
          {editing ? (
            <button className="secondary" type="button" onClick={() => edit(null)}>
              Cancel
            </button>
          ) : null}
        </div>
      </form>
      <section className="panel stack">
        <h2>Departments</h2>
        {departments.length === 0 ? <p>No department has been published.</p> : null}
        {departments.map((department) => (
          <button className="secondary" key={department.id} type="button" onClick={() => edit(department)}>
            {department.name}
            {department.is_active ? "" : " · Unpublished"}
          </button>
        ))}
      </section>
    </div>
  );
}
