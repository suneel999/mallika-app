# Administration dashboard

The architecture document calls for a responsive web dashboard used by reception and administrators. It calls the same `/api/v1/` API as the patient app. It does not name a frontend framework, so this directory does not contain an application yet.

## Recommendation

Use React with TypeScript, created with Vite.

That choice matches a separate web client of the versioned REST API, can be hosted beside the API on AWS, and is enough for a booking queue, catalogue forms, and banner management at the expected volume.

Confirm this recommendation before generating the project. The next setup step, from the repository root, is:

```powershell
npm create vite@latest admin -- --template react-ts
```

Then add routing and an API client aimed at `/api/v1/`. Do not give the dashboard a database connection or direct access to the hospital information system.

## Responsibilities

- Pending booking queue, confirmation, rejection, cancellation, and completion
- Manual HIMS reconciliation status and external reference entry
- Departments, doctors, services, and promotional banners
- Patient search limited to fields staff are allowed to see
- Staff accounts, permissions, operational reports, and read-only audit search

Staff actions require server-side permissions. The dashboard must not decide authorization on its own.

## Not in this phase

No package manifest, bundler config, or screens are created until the stack is confirmed. Django's built-in admin is not the operational dashboard.
