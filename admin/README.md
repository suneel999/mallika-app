# Administration desk

Staff use this web client for the booking queue. It calls the same `/api/v1/` API as the patient app. It has no database of its own and no connection to the hospital information system.

## Run it locally

From `admin/`, with the API already listening on `http://127.0.0.1:8000`:

```powershell
npm install
npm run dev
```

Open `http://localhost:5173`. Sign in with a staff mobile number and password. The API allows that origin when `DJANGO_CORS_ALLOWED_ORIGINS` includes it. Local settings allow `http://localhost:5173` and `http://127.0.0.1:5173` when the variable is empty.

Set `VITE_API_BASE_URL` when the API is not at `http://127.0.0.1:8000/api/v1`.

## What this desk does

- Staff sign-in, token refresh, and sign-out
- The booking queue, including the saved hospital-system check, the total, and the next page
- Review, confirm a time, reject, complete, mark a missed visit, and decide a cancellation
- Record the hospital-system check without changing the booking status
- Publish, correct, or unpublish departments, doctors, and services. A photo is an address, not a file. No price is stored

Banner uploads, patient search, reports, and audit search are not in this desk. Those screens wait until the API exposes them.
