# Project status

Living record of Mallika Hospitals. Update this file in the same change as a big feature. Small fixes, copy tweaks, and refactors do not need an entry.

Last updated: 19 October 2026.

## Now

A patient can request an OTP, verify it, set up their own profile, and open the home screen. Family profiles, the service catalogue, and booking requests are not built. PostgreSQL is still required for a normal local server. Tests use SQLite.

## Areas

| Area | State | What exists |
| --- | --- | --- |
| Backend | Sign-in and own profile | `/api/v1/health/`, OTP request and verify, refresh, logout, `/me/`, and the signed-in patient's profile |
| Mobile | Sign-in through home | Splash, welcome, mobile number, OTP, profile setup, home, and a profile page with logout |
| Admin | Not started | Stack recommendation only, in `admin/README.md` |
| Infra | Not started | AWS notes only, in `infra/README.md` |
| Data | Accounts and own profile | User, OTP challenge, refresh session, patient profile. No family, catalogue, or booking tables |

## Big features

| Date | Feature | Notes |
| --- | --- | --- |
| 18 Oct 2026 | Phase 1 scaffold | Backend, Flutter shell, docs, admin and infra placeholders. 17 backend tests passing at that time. |
| 19 Oct 2026 | Patient home UI | Stitch project `Mallika Hospitals Mobile App` (`projects/7623074882172969862`). Screen: Home (Enhanced Blue Header). |
| 19 Oct 2026 | Patient sign-in and profile | OTP session, the patient's own profile, and the Stitch splash, welcome, login, OTP, and profile screens. |

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

Family profiles, catalogue APIs, bookings, HIMS reconciliation, notifications, the admin dashboard, and AWS deployment.

## Checks

Backend tests cover health, the error envelope, OTP limits, session rotation, and the patient's own profile. Flutter tests cover the home screen, the path from welcome to the mobile-number check, and profile name validation.
