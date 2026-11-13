# Administration desk

Reception staff use this web client for appointment requests. It calls the same `/api/v1/` API as the patient app. It has no database of its own and no connection to the hospital information system.

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
- The appointment list, opening on new requests, with a count on each tab, the saved hospital-system check, and the next page
- The patient's mobile number and patient number on a request, so reception can call
- One Confirm appointment button on a new request. It moves the request to review and then confirms it, so the patient gets both updates
- Review, confirm a time, reject, complete, mark a missed visit, and decide a cancellation
- Record the hospital-system check without changing the booking status
- Publish, correct, or unpublish departments, doctors, and services. A photo is an address, not a file. No price is stored
- Search a patient by name, patient number, or mobile number, and correct the profile. The mobile number stays fixed. The search is audited
- Booking counts by status for a requested-date range
- The audit log. Opening it does not write another row

Banner image uploads are not in this desk. Those wait until file storage exists.
