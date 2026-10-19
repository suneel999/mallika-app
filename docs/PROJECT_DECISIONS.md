# Project decisions

Phase 1 scaffold, 18 October 2026. The specification remains the two design documents in this folder:

- `Mallika_Hospitals_Database_API_Design.docx`
- `Mallika_Hospitals_System_Design_Architecture_v1.docx`

This file records choices made while scaffolding, and conflicts that are not resolved here.

## Decisions applied in the scaffold

1. One Django process is the modular monolith. Domain code lives in `backend/apps/`. There are no microservices, queues, or Kubernetes manifests in this phase.
2. The repository layout is `backend/`, `mobile/`, `admin/`, `docs/`, and `infra/`. The architecture document suggested `infrastructure/`; this phase uses `infra/` as the deployment placeholder.
3. The `reports` application from the architecture module list is included. It has no models yet.
4. The only business model created now is the custom user, table `accounts_user`, so the first migration does not depend on Django's default user. Other tables wait until the conflicts below are agreed.
5. `mobile_number` is the unique login identifier, stored as supplied after trimming whitespace. E.164 normalization belongs with OTP verification, not this scaffold.
6. Django's `last_login` field is the document's `last_login_at`. A second timestamp is not stored.
7. `user_kind` (`patient`, `staff`, `admin`) classifies the account. Staff authorization will use Django groups and permissions. `user_kind` is not itself a permission.
8. `is_staff` is Django's operational flag. It does not replace `user_kind`.
9. The password column exists because staff sign in with a password. Patient accounts created without a password get an unusable password. OTP login is not implemented.
10. Database checks on the user row restrict `user_kind` and `preferred_language` to the enums in the database design.
11. API routes are mounted at `/api/v1/`. List pagination is limit/offset, default 20, maximum 100.
12. Errors use the database document envelope: `error.code`, `error.message`, optional `error.fields`, and `error.request_id`.
13. Authentication classes are empty until the OTP and staff-session phase. Session middleware is not installed yet.
14. `GET /api/v1/health/` reports process liveness only. It does not check or describe the database, secrets, or host configuration.
15. Django stores aware datetimes in UTC (`TIME_ZONE = UTC`). Clients present hospital-local time in `Asia/Kolkata`.
16. Automated tests use SQLite. The running API uses PostgreSQL. Constraint tests that depend on PostgreSQL-only behavior belong with the schema phase.
17. The Flutter placeholder uses a provisional blue (`#0B4F8A`) and white surface. Official logos, colours, addresses, phone numbers, and doctor details are not invented. Approved Stitch screens replace the placeholder.
18. The mobile application id `com.mallikahospitals.mallika_hospitals` is provisional.
19. Feature packages are created when a screen exists. `features/home/` is the only one so far. Planned packages are onboarding, authentication, doctors, services, bookings, notifications, profile, and shared widgets.
20. Django's built-in admin site is not mounted. Staff use the separate web dashboard.

## Recommended, not built

The architecture document requires a responsive web dashboard and says that dashboard calls the same versioned REST API. It does not name a frontend framework. The recommendation is React with TypeScript, created with Vite, living in `admin/` and talking only to `/api/v1/`. That application is not generated until the recommendation is confirmed. Responsibilities and the setup step are in `admin/README.md`.

AWS deployment remains a later phase. The architecture allows either App Runner or ECS Fargate, RDS for PostgreSQL, S3 for images, a durable queue for notification jobs, and Secrets Manager or SSM for secrets. No service is selected or provisioned here. See `infra/README.md`.

## Conflicts to resolve before schema work

These differences are recorded, not silently merged into models.

| Topic | Database and API document | Architecture document | Scaffold stance |
| --- | --- | --- | --- |
| Booking status | `requested`, `under_review`, `confirmed`, `rejected`, `cancellation_requested`, `cancelled`, `completed`, `no_show` | Pending, Confirmed, Rejected, Cancellation requested, Cancelled, Completed, No-show | Do not create the booking model until the hospital confirms whether `under_review` is a distinct state. A patient-facing "Pending" label can map to `requested`. |
| Reconciliation status | `not_checked`, `checked_available`, `entered_in_hims`, `mismatch`, `not_applicable` | Not checked, Availability verified, Entered in HIMS, Reconciled, Exception | Do not create reconciliation models until one state list is chosen. |
| Family data | `patients_patientprofile` plus `patients_familyrelationship`. API: `/me/patient-profiles` | `FamilyMember` entity. API: `/family-members` and `GET/PATCH /me` | The database document is the more detailed contract. The resource shape still needs an operations decision before models are added. |
| Doctor departments and price | Many-to-many departments. Price deferred unless approved | A department on the doctor, plus a fee | Follow the database document when catalogue models are added. Do not add price columns unless the hospital approves them. |
| Booking concurrency | Idempotency key and append-only events | Version or equivalent locking | Add one locking approach with the booking model. The mechanism is not chosen. |
| Banner image | `image_url` | Storage key | Store the S3 key and derive a URL when content is implemented. |
| Notifications | Device token, notification, and attempt tables | One `NotificationDelivery` entity | Follow the three-table database design when notifications are implemented. |
| Staff identity | Same `accounts_user` row, unique mobile number, `user_kind` | `StaffUser` with a username | The scaffold user is mobile-number based. A separate username is not added unless operations require it. |
| Session | Access token plus rotating refresh token, or a server session. Includes `POST /auth/token/refresh` | Secure session with refresh and revocation. Refresh endpoint not listed | Provider and token strategy stay open. No token code is included. |
| Cancellation route | `POST /bookings/{id}/cancellation-requests` | `POST /bookings/{id}/cancellation-request` | Use the database document path when the endpoint is built. |
| Reconciliation route | `PATCH /admin/bookings/{id}/hims-reconciliation` | `POST /admin/bookings/{id}/reconcile` | Use the database document path when the endpoint is built. |
| Reconciliation table ownership | Tables named `bookings_himsreconciliation` and `bookings_reconciliationevent` | Separate `reconciliation` module | The Django app is `reconciliation`. Physical table names are chosen with the models. |
| Banner table name | `contentops_banner` | `content` module | The Django app is `content`. The physical table name is chosen with the model. |

Where an endpoint exists only in the database document (dashboard metrics, device registration, notification list, catalogue writes, audit search, staff management), that document is the API catalogue to implement later. The architecture document remains the source for module boundaries, patient experience, and the manual HIMS rule.

## Assumptions

- Phase 1 is one hospital, under 100 bookings a day, payment at the hospital, and no HIMS API.
- Staff accounts also have a unique mobile number because that is the user model's identifier.
- Patients and staff share one user table, distinguished by `user_kind` and permissions.
- Banner binaries and other approved assets go to S3. The database stores metadata only.
- SMS and push are sent by a worker later. The API process does not call providers in this scaffold.
- Telugu and English are the product languages. Backend messages in this phase are English. Localization arrives with the patient-facing API and Flutter features.
- Official hospital address, emergency phone, logo, and brand colour are not in the design documents, so they are not shown in the app.

## Stitch screens

The patient UI source is the Stitch project `Mallika Hospitals Mobile App` (`projects/7623074882172969862`). The first implemented screen is `Home (Enhanced Blue Header)`. Copy, colours, Telugu lines, specialist names, and the campus line on that screen come from that design. Hospital operations still need to confirm the address, phone number, and doctor roster before release. Other Stitch screens (splash, welcome, login, OTP, profile) are not built yet.

## Next schema phase

Implement the agreed tables once the status lists, family resource, and staff identifier are confirmed. Do not add a second model for the same concept. Keep booking status and HIMS reconciliation status independent.
