# Agent guide

Mallika Hospitals is a Flutter patient app and a Django REST modular monolith. Read `docs/STATUS.md` and `docs/PROJECT_DECISIONS.md` before a large change. The two Word files in `docs/` remain the specification.

## Update status after a big feature

A big feature is a new patient flow, a new API area, a new set of models, an admin workflow, or a completed Stitch screen. In that same change:

1. Add a row to the big-features table in `docs/STATUS.md`.
2. Move the area table and the "Now" summary to match the code.
3. Record the checks you actually ran, with the date. Do not mark a check passed unless it ran.
4. Leave `docs/PROJECT_DECISIONS.md` for conflicts and choices. Do not paste a second copy of the status there.

Skip the status update for a bugfix, a rename, or a comment.

## Working rules

- Keep one Django process. Domain code belongs in `backend/apps/`.
- Patient screens follow the Stitch project `Mallika Hospitals Mobile App`. Do not invent a parallel layout.
- Hospital address, phone numbers, logos, and doctor details come from an approved Stitch screen or from hospital operations.
- Do not commit `.cursor/mcp.json`, `.env`, or provider tokens.
- API errors stay in the `error.code` / `error.message` / `error.fields` / `error.request_id` shape.
- Booking status and HIMS reconciliation status stay independent. Do not add those models until the open conflicts in `docs/PROJECT_DECISIONS.md` are settled.

## Checks

```powershell
cd backend
python manage.py test
cd ..\mobile
flutter analyze
flutter test
```
