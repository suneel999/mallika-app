# Project status

Living record of Mallika Hospitals. Update this file in the same change as a big feature. Small fixes, copy tweaks, and refactors do not need an entry.

Last updated: 19 October 2026.

## Now

The API scaffold and the patient home screen exist. Patients cannot log in or submit a booking yet. PostgreSQL was not running in the local environment, so the API has been started with test settings when a live server was needed.

## Areas

| Area | State | What exists |
| --- | --- | --- |
| Backend | Scaffold | Django REST project, `/api/v1/health/`, error envelope, custom `accounts_user`, empty domain apps |
| Mobile | Home only | Flutter app. Home matches the Stitch screen "Home (Enhanced Blue Header)" |
| Admin | Not started | Stack recommendation only, in `admin/README.md` |
| Infra | Not started | AWS notes only, in `infra/README.md` |
| Data | User table only | Other tables wait on the open decisions in `docs/PROJECT_DECISIONS.md` |

## Big features

| Date | Feature | Notes |
| --- | --- | --- |
| 18 Oct 2026 | Phase 1 scaffold | Backend, Flutter shell, docs, admin and infra placeholders. 17 backend tests passing at that time. |
| 19 Oct 2026 | Patient home UI | Stitch project `Mallika Hospitals Mobile App` (`projects/7623074882172969862`). Screen: Home (Enhanced Blue Header). Flutter analyze clean; home widget test passing. |

## Stitch screens

| Screen | In the app |
| --- | --- |
| Home (Enhanced Blue Header) | Yes. This is the current home. |
| Home, Home (Enlarged Cards & Text) | Earlier variants. Not used. |
| Splash, Welcome & About, Mobile Number Login, OTP Verification, Profile Setup | Designed. Not built. |

Address, emergency number `108`, specialist names, and Telugu lines on the home screen are copied from that Stitch design. Hospital operations still need to confirm them.

## Not built

OTP login, patient and family profiles, catalogue APIs, bookings, HIMS reconciliation, notifications, the admin dashboard, and AWS deployment.

## Checks last recorded

- `python manage.py test`: 17 passed (18 Oct 2026, scaffold).
- `flutter analyze` and `flutter test`: passed after the home screen (19 Oct 2026).

Re-record a check here only when a big feature runs it.
