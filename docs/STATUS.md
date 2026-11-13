# Project status

Living record of Mallika Hospitals. Update this file in the same change as a big feature. Small fixes, copy tweaks, and refactors do not need an entry.

Last updated: 13 November 2026.

## Now

The home opens with the consultation banner, then six service cards, two per row: Book Consultation, 4D Echo, CT Calcium, CT Angio, Lab Tests, and Ambulance. Each card is drawn in the app with an icon, the name, and a short caption. The generated artwork is no longer shown. The logo header and notification button are not on this home. Profile sits at the right of the greeting. Campus opens the hospital Google Maps link. Patient login uses a navy wave header with the logo on a white plate, and the verification screen uses six code boxes under a navy badge. The number 9999999999 with code 123456 signs in on the phone when the server cannot be reached. Any other number still uses the live API. A patient can sign in, set up a profile, add family members, and request a consultation or a published service. Consultation uses the one published doctor, a date, and a time. The patient does not pick a department or a doctor, and the app takes no payment. Staff review requests, record a hospital-system check, publish the catalogue, search patients, read booking counts, and read the audit log. Status changes appear in Updates without a push or SMS provider. The patient app can be installed as a demo APK once it is pointed at a reachable API. PostgreSQL is still required for a normal local server. Tests use SQLite.

## Areas

| Area | State | What exists |
| --- | --- | --- |
| Backend | Sign-in through updates | OTP session, staff password sign-in, family profiles, catalogue, bookings, staff review, HIMS reconciliation, in-app updates, device tokens, and banners. Push and SMS are not sent |
| Mobile | Sign-in through updates | Splash through profile and family, consultation and published services, bookings, cancellation, and the Updates tab |
| Admin | Desk through reports | A reception desk with a side menu. Staff sign-in, the appointment list with counts, the hospital-system check, catalogue editing, patient search, booking counts, and the audit log |
| Infra | Live on one server | The live API still runs on Fargate with a load balancer and RDS, on plain HTTP. `infra/` holds a one-server setup for `app.mallikahospitals.in`: PostgreSQL, the API, and Caddy with HTTPS on one EC2 server, and nightly backups to S3. The server `mallika-app` (`18.60.7.170`), its firewall, role, and the backup bucket exist, with Docker installed. The three containers run there with an empty database, the health check answers, and the nightly backup is scheduled. HTTPS works on `https://app.mallikahospitals.in`. The old load balancer, Fargate service and cluster, image store, and RDS database were deleted on 13 November 2026. A final snapshot of the old database, `mallika-db-final-2026-11-13`, is kept |
| Data | Accounts through audit | User, OTP challenge, refresh session, patient profile, family link, catalogue, booking, cancellation, HIMS reconciliation, device token, notification, notification attempt, banner, and audit log. No prices. No image files |

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
| 21 Oct 2026 | Patient search | Staff search by name, patient number, or mobile number, open the profile, and correct the details a patient can already change. The mobile number stays fixed. Each search, open, and correction writes an audit row without the query or the new value. |
| 21 Oct 2026 | Reports and audit search | Staff see booking counts by status for a requested-date range, and can read the audit log. Reading the log does not write another row. |
| 22 Oct 2026 | Reference service-card home | Stitch screen `Home (Reference Service Cards Layout)`. Heart-screening card, six service cards, emergency strip, and campus map. |
| 22 Oct 2026 | Reference login | Stitch screen `Mobile Login (App Banner & Reference Style)`. Phone number, CONTINUE, and the same OTP step. |
| 26 Oct 2026 | Photo service home | Header, greeting, priority card, six service cards, emergency strip, and campus card. Service names are Consultation, 4D Echo, CT Calcium, CT Angio, Lab Tests, and Ambulance. |
| 27 Oct 2026 | Live API container | The API image runs Django with PostgreSQL. Sign-in codes go out through the WhatsApp Cloud API template `mallika_otp`. |
| 28 Oct 2026 | Artwork service grid | Six square service cards, two equal cards on every row, on every phone width. Book Consultation opens the consultation request. Ambulance calls 108. The other four open published services. |
| 28 Oct 2026 | Consultation banner home | The consultation artwork is the home banner. The logo header and notification button are removed. Profile is at the right of the name. Campus opens `https://maps.app.goo.gl/UGKJ3hgTcLZqGY4V9`. |
| 28 Oct 2026 | Booking tabs | Bookings has Upcoming, Completed, and Missed. An empty tab shows a centered icon and “You have not booked any appointment yet.” |
| 28 Oct 2026 | Profile and footer | Profile uses the navy header, mobile number, and logout. Home, Bookings, Updates, and Profile keep the same bottom bar. The map card says Mallika Hospitals. |
| 28 Oct 2026 | Patient login screens | Login, registration, and the verification code use the hospital logo. A release APK points at the live API. |
| 29 Oct 2026 | Login and verification layout | Login matches the wave header. Verification matches the six boxes, timer, and Verify button. The number 9999999999 with code 123456 opens the app without the server. |
| 12 Nov 2026 | Brand-colour sign-in and service cards | Login, verification, and the shared sign-in button and fields use the logo navy, the theme blue, and the amber accent. The six home cards are drawn in the app instead of using artwork images. This restyle was asked for directly and is not from a Stitch screen. |
| 12 Nov 2026 | One look across the patient app | Every patient screen uses the same navy header, white outlined cards, and buttons. Bookings show a coloured status label and a readable date. The request form has a 14-day date strip, time buttons, a fixed Send request button, and a Request sent message. Updates show the time. Profile shows the patient number and moves Logout to the bottom. The splash shows the logo and no longer shows the accreditation and encryption lines. Back from the verification screen returns to registration when the patient came from there. |
| 13 Nov 2026 | One-server deployment files | `infra/` has the compose file, Caddy configuration, desk image, example settings, server setup script, backup script, and the steps to move from the current AWS setup. Nothing was created or deleted on AWS. |
| 13 Nov 2026 | Reception desk rework | The desk has a side menu in plain words: Appointments, Patients, Doctors & services, Reports, Activity log. Appointments open on New requests, with a count on every tab and coloured status labels. A request shows the patient's mobile number and patient number, one Confirm appointment button that fills in the time the patient asked for, and a question before rejecting or cancelling. The hospital-system check is five plain choices. Reports and the activity log load when opened. The staff booking API now returns the patient number and mobile number. The patient booking API does not. |

## Stitch screens

| Screen | In the app |
| --- | --- |
| Splash | Yes. Shown while the app checks for a saved session. |
| Welcome & About | Yes. |
| Mobile Number Login | Earlier login. Not used. |
| Mobile Login (App Banner & Reference Style) | Earlier login. Not used. |
| Patient login and verification | Yes. This is the current login. Wave header, registration, and the six-box verification screen. |
| OTP Verification | Yes. The phone keyboard is used instead of the drawn keypad. |
| Profile Setup | Yes. Creates the signed-in patient's own profile. |
| Home (Enhanced Blue Header) | Earlier home. Not used. |
| Home, Home (Enlarged Cards & Text) | Earlier variants. Not used. |
| Mallika Hospitals - Calm Visual Home | Earlier home. Not used. |
| Home (Reference Service Cards Layout) | Earlier home. Not used. |
| Patient home, service photos | Earlier photo cards. Not used. |
| Artwork service grid | The two-per-row square grid is kept. The artwork images are replaced by cards drawn in the app. |
| Consultation banner home | Yes. This is the current home. Banner, Services heading, six cards, emergency call, and Google Maps. |

Address, emergency number `108`, specialist names, accreditation lines, and Telugu marketing lines are copied from those Stitch designs. Hospital operations still need to confirm them.

## Not built

A staff login and the published doctor and services on the new, empty database. A patient APK built for the new address. Real push, SMS, and banner image files wait until a provider and storage are chosen. Catalogue rows, including the one consultation doctor and bookable services, are created when the hospital approves the names. The first staff password is still created outside the desk.

## Checks

21 Oct 2026: `python manage.py test` — 53 tests passed. `flutter analyze` reported no issues. `flutter test` — 13 tests passed, including linked family members on the request form, a service opened by published id, a cancellation request from the Bookings tab, and a stored update on the Updates tab. The hospital-system check and in-app updates were covered by the backend suite. `npm run build` in `admin/` completed. The desk sign-in, queue, and booking screens opened in the browser. The queue shows the total and loads the next page. Keeping a cancellation shows the confirmed-time field when no time was agreed, and leaves that field off when a time is already stored. A live review against PostgreSQL could not be completed because the database was not running. Later the same day: `python manage.py test` — 60 tests passed. The catalogue screen opened in the browser, and saving a doctor sent no price. Patient search, booking counts, and the audit list are covered by the backend suite. The desk type check completed with no errors. The reports screen showed counts for the chosen dates, and the audit screen listed a search row, both against a stand-in API because PostgreSQL was not running. `flutter analyze` reported no issues. `flutter test` — 13 tests passed.

22 Oct 2026: `flutter test` — 13 tests passed after the reference service-card home and the reference login replaced the earlier screens.

26 Oct 2026: `flutter test` — 13 tests passed after the photo service home.

27 Oct 2026: `python manage.py test tests.test_whatsapp_sender` — 2 tests passed.

28 Oct 2026: `flutter analyze` reported no issues. `flutter test` — 14 tests passed, including two equal service cards on each row at phone widths 320, 360, 390, 430, and 600. Later the same day, after the consultation banner: `flutter analyze` reported no issues. `flutter test` — 14 tests passed, including the banner opening consultation, the profile icon opening the profile, and the same two-card rows. After the booking tabs: `flutter analyze` reported no issues. `flutter test` — 14 tests passed, including an upcoming request, empty Completed and Missed tabs, and a cancellation request. After the profile screen and shared footer: `flutter analyze` reported no issues. `flutter test` — 14 tests passed, including the profile from home and the footer on Bookings and Updates. After the login screens: `flutter analyze` reported no issues. `flutter test` — 14 tests passed. `flutter build apk --release` completed, pointed at the live API, with no demo code.

29 Oct 2026: `flutter analyze` reported no issues. `flutter test` — 15 tests passed, including sign-in with 9999999999 and 123456 while the API throws a network error. `flutter build apk --release` completed, pointed at the live API, with no demo code. The test number is built into that APK.

12 Nov 2026: `flutter analyze` reported no issues. `flutter test` — 15 tests passed after the brand-colour login, verification screen, and drawn service cards. The three screens were rendered from the widget tree to images and looked at. They were not run on a phone. Later the same day, after the one look across the app: `flutter analyze` reported no issues. `flutter test` — 15 tests passed. Splash, registration, profile setup, bookings, the request form, updates, profile, and the family form were rendered to images with stand-in data and looked at. They were not run on a phone.
 `flutter build apk --release` completed with the new design, pointed at the live API, with no demo code. The first attempt ran out of Gradle memory at 1 GB and the second ran with 2 GB for that run only. The APK was not installed on a phone.
 After the richer home (navy greeting band, coloured service cards, and a Your appointments shortcut): `flutter analyze` reported no issues and `flutter test` — 15 tests passed. The live API answered `GET /api/v1/health/` with 200, and every read path the app uses answered 401 without a sign-in. Sign-in and signed-in requests were not tried against the live API.

13 Nov 2026: `python manage.py test` — 63 tests passed, including the patient number and mobile number on the staff booking list and their absence from the patient's own list. `npm run build` in `admin/` completed. The desk was opened in the browser against a local API on a throwaway SQLite database with stand-in patients: sign-in, the appointment list and its counts, confirming a new request in one step, reports, doctors and services, patient search, and the activity log all worked. It was not tried against the live API or PostgreSQL. The AWS account was read, not changed: the current setup costs about 67 US dollars a month before credits. `docker compose config` accepted `infra/docker-compose.yml`, and both shell scripts parse. The images were not built and the setup was not run, because Docker was not running on this computer. `app.mallikahospitals.in` has no DNS record yet. Later the same day the server, fixed address, firewall group, server role, and backup bucket were created in `ap-south-2`, and Docker was installed through Session Manager. Both EC2 status checks pass. The app was not started there. The app was then started on the new server: the tables were created, the three containers stayed up, the health check answered `{"status":"ok"}` from inside the server, and plain HTTP from outside is sent to HTTPS. One backup was written to the bucket and the nightly schedule was added. HTTPS was not checked because `app.mallikahospitals.in` has no DNS record. Sign-in on the new server was not tried. After the DNS record was added, `https://app.mallikahospitals.in/api/v1/health/` answered 200, the desk page loaded, and a signed-out booking call answered 401. The old load balancer, Fargate service and cluster, and image store were then deleted, and the old database was deleted with a final snapshot. The patient APK from 12 November still points at the deleted load balancer. Checks on the live server the same day: `python manage.py test` inside the live API image — 63 tests passed on a separate test database. No migration is waiting. The live database is empty: no staff login, patient, booking, doctor, or service. The health check answered 200 over HTTPS, the desk page, its script, and the logo loaded, every signed-out API path answered 401, a made-up staff sign-in answered 401, and an invalid mobile number answered 400. Meta rejected the stored WhatsApp token (the session was logged out), so sign-in codes cannot be sent. Locally: 63 backend tests and 15 Flutter tests passed, `flutter analyze` reported no issues, and the desk build completed. `flutter build apk --release` completed for `https://app.mallikahospitals.in/api/v1`; the old address is not in that APK. The APK was not installed on a phone, and no sign-in, booking, or desk action was made on the live server.
