# Project status

Living record of Mallika Hospitals. Update this file in the same change as a big feature. Small fixes, copy tweaks, and refactors do not need an entry.

Last updated: 21 October 2026.

## Now

A patient can sign in, set up a profile, add family members, and request a consultation or a published service. Consultation uses the one published doctor, a date, and a time. The patient does not pick a department or a doctor, and the app takes no payment. Staff review requests, record a hospital-system check, and publish the doctor and services from the desk. Status changes appear in Updates without a push or SMS provider. PostgreSQL is still required for a normal local server. Tests use SQLite.

## Areas

| Area | State | What exists |
| --- | --- | --- |
| Backend | Sign-in through updates | OTP session, staff password sign-in, family profiles, catalogue, bookings, staff review, HIMS reconciliation, in-app updates, device tokens, and banners. Push and SMS are not sent |
| Mobile | Sign-in through updates | Splash through profile and family, consultation and published services, bookings, cancellation, and the Updates tab |
| Admin | Booking desk and catalogue | Staff sign-in, the booking queue, status review, the hospital-system check, and catalogue editing for departments, doctors, and services. No prices, reports, or audit search |
| Infra | Not started | AWS notes only, in `infra/README.md` |
| Data | Accounts through updates | User, OTP challenge, refresh session, patient profile, family link, catalogue, booking, cancellation, HIMS reconciliation, device token, notification, notification attempt, and banner. No prices. No image files |

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
| 21 Oct 2026 | Hospital-system check | Staff record `not_checked`, `checked_available`, `entered_in_hims`, `mismatch`, or `not_applicable` on a booking and can read that check on the booking. That status stays independent of the booking status. There is no live hospital-system connection. |
| 21 Oct 2026 | Updates | A booking status change is stored for that patient and shown on the Updates tab. Device tokens can be registered. Banners are listed only while published. No push, SMS, or image file is sent. |
| 21 Oct 2026 | Staff desk | A web desk for staff sign-in, the booking queue, confirming a time, and recording the hospital-system check. It uses the API only. |
| 21 Oct 2026 | Catalogue editing | Staff publish, correct, or unpublish a department, doctor, or service. Patients still see only published rows. There is no price and no file upload. |

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

Patient search, reports, audit search, and AWS deployment. Real push, SMS, and banner image files wait until a provider and storage are chosen. Catalogue rows, including the one consultation doctor and bookable services, are created when the hospital approves the names.

## Checks

21 Oct 2026: `python manage.py test` — 53 tests passed. `flutter analyze` reported no issues. `flutter test` — 13 tests passed, including linked family members on the request form, a service opened by published id, a cancellation request from the Bookings tab, and a stored update on the Updates tab. The hospital-system check and in-app updates were covered by the backend suite. `npm run build` in `admin/` completed. The desk sign-in, queue, and booking screens opened in the browser. The queue shows the total and loads the next page. Keeping a cancellation shows the confirmed-time field when no time was agreed, and leaves that field off when a time is already stored. A live review against PostgreSQL could not be completed because the database was not running. Later the same day: `python manage.py test` — 56 tests passed. The catalogue screen opened in the browser, and saving a doctor sent no price.
