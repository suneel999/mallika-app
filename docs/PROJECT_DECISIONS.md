# Project decisions

Phase 1 scaffold, 18 October 2026. The specification remains the two design documents in this folder:

- `Mallika_Hospitals_Database_API_Design.docx`
- `Mallika_Hospitals_System_Design_Architecture_v1.docx`

This file records choices made while scaffolding, and conflicts that are not resolved here.

## Decisions applied in the scaffold

1. One Django process is the modular monolith. Domain code lives in `backend/apps/`. There are no microservices, queues, or Kubernetes manifests in this phase.
2. The repository layout is `backend/`, `mobile/`, `admin/`, `docs/`, and `infra/`. The architecture document suggested `infrastructure/`; this phase uses `infra/` as the deployment placeholder.
3. The `reports` application from the architecture module list is included. It has no models yet.
4. The custom user, table `accounts_user`, was the first business model so the first migration does not depend on Django's default user. Sign-in added `accounts_otpchallenge`, `accounts_refreshsession`, and `patients_patientprofile`.
5. `mobile_number` is the unique login identifier. Patient OTP stores Indian numbers as E.164 (`+91` and 10 digits). `create_user` still only trims whitespace, so a caller that already has the normalized value can pass it through.
6. Django's `last_login` field is the document's `last_login_at`. A second timestamp is not stored.
7. `user_kind` (`patient`, `staff`, `admin`) classifies the account. Staff authorization will use Django groups and permissions. `user_kind` is not itself a permission.
8. `is_staff` is Django's operational flag. It does not replace `user_kind`.
9. The password column exists because staff sign in with a password. Patient accounts created by OTP get an unusable password. Staff password sign-in is not built yet.
10. Database checks on the user row restrict `user_kind` and `preferred_language` to the enums in the database design.
11. API routes are mounted at `/api/v1/`. List pagination is limit/offset, default 20, maximum 100.
12. Errors use the database document envelope: `error.code`, `error.message`, optional `error.fields`, and `error.request_id`.
13. Patient requests use a short-lived access token tied to a refresh session. Public views such as health and OTP request set `AllowAny`. Django session middleware is not installed.
14. `GET /api/v1/health/` reports process liveness only. It does not check or describe the database, secrets, or host configuration.
15. Django stores aware datetimes in UTC (`TIME_ZONE = UTC`). Clients present hospital-local time in `Asia/Kolkata`.
16. Automated tests use SQLite. The running API uses PostgreSQL. Constraint tests that depend on PostgreSQL-only behavior belong with the schema phase.
17. Patient colours come from the approved Stitch screens. The crest image is not hotlinked. Address, emergency number, specialist names, and promotional lines stay marked as unconfirmed until the hospital confirms them.
18. The mobile application id `com.mallikahospitals.mallika_hospitals` is provisional.
19. Feature packages exist for onboarding, authentication, home, profile, catalogue, and bookings. Notifications are still planned.
20. Django's built-in admin site is not mounted. Staff use the separate web dashboard.

## Recommended, not built

The architecture document requires a responsive web dashboard and says that dashboard calls the same versioned REST API. It does not name a frontend framework. The recommendation is React with TypeScript, created with Vite, living in `admin/` and talking only to `/api/v1/`. That application is not generated until the recommendation is confirmed. Responsibilities and the setup step are in `admin/README.md`.

AWS deployment remains a later phase. The architecture allows either App Runner or ECS Fargate, RDS for PostgreSQL, S3 for images, a durable queue for notification jobs, and Secrets Manager or SSM for secrets. No service is selected or provisioned here. See `infra/README.md`.

## Locked for implementation

On 19 October 2026 the database and API document became the rule where the two design documents disagree.

- Booking status uses the database list. The app may label `requested` as Pending.
- Reconciliation status uses `not_checked`, `checked_available`, `entered_in_hims`, `mismatch`, and `not_applicable`. It stays independent of booking status.
- Family members are linked patient profiles. The API is `/me/patient-profiles`. The first profile is the signed-in patient, with relationship `self`. Later profiles are new family records linked to that account. A caller cannot attach an existing profile by id.
- Catalogue prices stay out until the hospital approves them.
- Sessions are a short-lived access token plus a rotating refresh token. Logout revokes that refresh session, and the access token stops working with it.
- OTP codes are hashed, expire quickly, and stop after a small number of attempts. The local API prints a code to its own stderr as the SMS stand-in. Production refuses that sender.
- Cancellation and reconciliation routes, when built, follow the database document paths.
- V1 booking is a request only. The patient pays at the hospital. The app shows no price and takes no payment.
- V1 has one consultation doctor. The patient sees that doctor's photo on consultation and chooses a date and a time. The app does not ask the patient to pick a department or a doctor. Department-wise doctors are a later version.
- Other bookable services use the same date-and-time request. A service request does not ask for a doctor.

The table below keeps the original conflict wording.

## Conflicts recorded before the lock

These differences were not silently merged. The lock above is the current rule.

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
| Session | Access token plus rotating refresh token, or a server session. Includes `POST /auth/token/refresh` | Secure session with refresh and revocation. Refresh endpoint not listed | Built as access token plus rotating refresh token. Logout revokes the session. |
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
- OTP delivery is a sender interface called by the API process. There is no queue yet. The console sender is local only. Push is still later.
- Telugu and English are the product languages. Backend messages in this phase are English. Localization arrives with the patient-facing API and Flutter features.
- Official hospital address, emergency phone, logo, and brand colour are not in the design documents, so they are not shown in the app.

## Stitch screens

The patient UI source is the Stitch project `Mallika Hospitals Mobile App` (`projects/7623074882172969862`). Implemented screens: Splash, Welcome & About, Mobile Number Login, OTP Verification, Profile Setup, and Home (Enhanced Blue Header). Copy on those screens comes from that design. Hospital operations still need to confirm the address, phone number, accreditation lines, and doctor roster before release.

## Next schema phase

Family links, catalogue tables, and booking requests are in place. Consultation uses the one active doctor and a date and time. A service request uses that service, a date, and a time. The patient app does not ask for a department or a doctor. Staff review, cancellation, and HIMS reconciliation are next. Do not add a second model for the same concept. Keep booking status and HIMS reconciliation status independent. Do not add prices, and do not confirm a booking automatically.
