# Project status

Living record of Mallika Hospitals. Update this file in the same change as a big feature. Small fixes, copy tweaks, and refactors do not need an entry.

Last updated: 21 October 2026.

## Now

A patient can sign in, set up a profile, add family members, and request a consultation or a published service. Consultation uses the one published doctor, a date, and a time. The patient does not pick a department or a doctor, and the app takes no payment. Staff can review a request and a patient can ask to cancel. PostgreSQL is still required for a normal local server. Tests use SQLite.

## Areas

| Area | State | What exists |
| --- | --- | --- |
| Backend | Sign-in, profiles, catalogue, booking requests, and staff review | OTP session, staff password sign-in, family profiles, read-only catalogue, booking requests, staff status changes, and patient cancellation requests |
| Mobile | Sign-in through booking requests | Splash through profile and family, consultation date and time, published services by id, the bookings list, and a cancellation request |
| Admin | Not started | Stack recommendation only, in `admin/README.md` |
| Infra | Not started | AWS notes only, in `infra/README.md` |
| Data | Accounts, profiles, catalogue, and bookings | User, OTP challenge, refresh session, patient profile, family link, department, doctor, service, booking, and booking event. No prices. Reconciliation is not stored yet |

## Big features

| Date | Feature | Notes |
| --- | --- | --- |
| 18 Oct 2026 | Phase 1 scaffold | Backend, Flutter shell, docs, admin and infra placeholders. 17 backend tests passing at that time. |
| 19 Oct 2026 | Patient home UI | Stitch project `Mallika Hospitals Mobile App` (`projects/7623074882172969862`). Screen: Home (Enhanced Blue Header). |
| 19 Oct 2026 | Patient sign-in and profile | OTP session, the patient's own profile, and the Stitch splash, welcome, login, OTP, and profile screens. |
| 21 Oct 2026 | Family profiles | A patient adds a family member as a new linked profile, can correct the mobile number, and can remove a member added by mistake. Another account cannot attach or edit that record. |
| 21 Oct 2026 | Service catalogue | Read-only departments, doctors, and services. Doctors can belong to more than one department. No prices, and no invented hospital names are seeded. |
| 21 Oct 2026 | Booking request | A signed-in patient requests one published service, or a consultation with the one published doctor, for themselves or a linked family member. The patient chooses a date and a listed time. The request stays `requested` (shown as Pending). A repeated Idempotency-Key returns the same booking. |
| 21 Oct 2026 | Staff review | Staff sign in with a password, move a request through review, and confirm a time. A patient can ask to cancel. The agreed time stays until that cancellation is accepted. Confirming a booking does not record a hospital-system check. |

## Stitch screens

| Screen | In the app |
| --- | --- |
| Splash | Yes. Shown while the app checks for a saved session. |
| Welcome & About | Yes. |
| Mobile Number Login | Yes. |
| OTP Verification | Yes. The phone keyboard is used instead of the drawn keypad. |
| Profile Setup | Yes. Creates the signed-in patient's own profile. |
| Home (Enhanced Blue Header) | Yes. This is the current home. |
| Home, Home (Enlarged Cards & Text) | Earlier variants. Not used. |

Address, emergency number `108`, specialist names, accreditation lines, and Telugu marketing lines are copied from those Stitch designs. Hospital operations still need to confirm them.

## Not built

HIMS reconciliation, notifications, the admin dashboard, and AWS deployment. Catalogue rows, including the one consultation doctor and bookable services, are created when the hospital approves the names.

## Checks

21 Oct 2026: `python manage.py test` — 48 tests passed. `flutter analyze` reported no issues. `flutter test` — 12 tests passed, including linked family members on the request form, a service opened by published id, and a cancellation request from the Bookings tab.
