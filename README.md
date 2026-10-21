# Mallika Hospitals

Patient mobile application and hospital administration platform for a single hospital location. Patients request consultations and services. Hospital staff confirm those requests after checking the existing hospital information system by hand. Phase 1 does not take payments or connect to a HIMS API.

## Architecture

The system is a modular monolith sized for fewer than 100 bookings a day.

| Part | Technology |
| --- | --- |
| Patient app | Flutter, Android and iOS |
| API | Python, Django, Django REST Framework |
| Database | PostgreSQL |
| Administration | Responsive web client of the same API. React, TypeScript, and Vite are recommended and not yet created. See `admin/README.md`. |
| Files | Amazon S3 for promotional banners and other approved assets |
| Notifications | SMS and push through provider interfaces |
| Hosting | AWS-ready later. Nothing is deployed in this phase. |

PostgreSQL is the source of truth for app accounts, profiles, booking requests, reconciliation state, and notification attempts. The existing HIMS remains the source of truth for clinical appointments. Staff reconcile the two manually.

## Directory structure

```
backend/     Django project and domain applications
mobile/      Flutter patient application
admin/       Administration frontend notes (no app yet)
docs/        Design documents and project decisions
infra/       Deployment notes (no cloud configuration yet)
```

Backend domains: `accounts`, `patients`, `catalogue`, `bookings`, `reconciliation`, `content`, `notifications`, `reports`, and `audit`.

The mobile library contains `app/`, `core/`, and `features/` for onboarding, authentication, home, profile, catalogue, and bookings.

## Prerequisites

- Python 3.11 or newer
- PostgreSQL, local, for running the API
- Flutter stable (this scaffold was created with Flutter 3.35.7 / Dart 3.9.2)
- Android and iOS toolchains when you want to run the app on a device or emulator

The automated backend tests use SQLite and do not need PostgreSQL.

## Local setup

From the repository root in PowerShell:

```powershell
python -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
pip install -r backend\requirements.txt
Copy-Item backend\.env.example backend\.env
```

On macOS or Linux, create the virtualenv the same way and activate `backend/.venv/bin/activate`.

Edit `backend/.env`. Replace `DJANGO_SECRET_KEY` and `POSTGRES_PASSWORD`. Create the PostgreSQL role and database named in that file, then:

```powershell
cd backend
python manage.py migrate
python manage.py runserver
```

The API listens on `http://127.0.0.1:8000/`. Liveness is `GET /api/v1/health/` and returns `{"status":"ok"}`.

If PostgreSQL is not running, `migrate`, `makemigrations`, and `runserver` stop after `POSTGRES_CONNECT_TIMEOUT` seconds (5 by default) instead of waiting indefinitely. `runserver` checks that migrations can be read from the database before it listens.

`python manage.py` uses local settings. Production processes should set `DJANGO_SETTINGS_MODULE=config.settings.production` and supply a unique `DJANGO_SECRET_KEY` with `DJANGO_DEBUG` left unset or false.

## Environment configuration

`backend/.env.example` lists every variable the settings read. Copy it to `backend/.env`. That file is gitignored. Do not put real passwords, API keys, OTP values, or provider tokens in the repository.

Local settings load `backend/.env`. If `DJANGO_SECRET_KEY` is omitted there, local settings fall back to a known insecure development key. Production settings refuse to start with that key or with debug enabled.

## Flutter

The app opens on the Stitch splash, then welcome, mobile number, and OTP. After the code is verified, a new patient sets up their own profile and reaches the home screen. A returning patient with a profile goes straight home. Home is still "Home (Enhanced Blue Header)". Bookings and updates are still the next screens. The profile tab shows the signed-in patient and can log out. Progress is tracked in `docs/STATUS.md`.

Local OTP delivery prints the code to the API process stderr. That sender is refused by production settings. Do not run it on a shared machine.

```powershell
cd mobile
flutter pub get
flutter run
```

Pass the API origin when you need a non-default backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

The application id `com.mallikahospitals.mallika_hospitals` is provisional. Home colours come from the Stitch screen.

## Tests

```powershell
cd backend
python manage.py test
python manage.py check
python manage.py makemigrations --check --dry-run
```

```powershell
cd mobile
flutter analyze
flutter test
```

## Current implementation status

`docs/STATUS.md` is the current record. Update it when a big feature lands. `AGENTS.md` tells agents how.

## Next development phase

Patient OTP, session, profiles, family members, catalogue reads, booking requests, and staff review are in place. A request stays pending until staff confirm a time. Next is the separate hospital-system check. Do not add prices or confirm bookings automatically.

The original design documents in `docs/` remain the specification.
