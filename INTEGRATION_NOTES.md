# Flutter ↔ Django Integration Notes

This file documents the integration work and how to run/debug the mobile ↔ backend stack. Copy the `reference/` directory anywhere and the API contract below will keep working.

## What changed (high level)
- Added dedicated Django API layers for events, event detail, forum, profiles, registrations, and notifications (`* /api_urls.py` + `* /api_views.py`) plus shared serializers (`reference/core/api_helpers.py`).
- Normalized JSON payloads to the Flutter models (e.g., event categories now expose `name`/`distance_km`, forum threads include `id/event/author`, registrations embed event details, notifications include `read_at`).
- Updated Flutter screens to use real APIs instead of dummy fixtures; dummy data can still be enabled via `--dart-define USE_DUMMY_DATA=true`.
- ApiService now auto-picks a base URL (`10.0.2.2` for Android emu, `localhost` otherwise) and exposes a shared singleton backed by `SharedPreferences`.

## API endpoints (mobile contract)
- Auth: `POST /api/auth/login/` (DRF Token), `POST /api/auth/logout/`
- Events: `GET /api/events/` (filters: `search`, `status`, `city`, `distance`, `page`), `GET /api/events/<id>/`, `GET /api/events/<id>/detail/`
- Profile: `GET|PUT /api/profile/`, `GET|POST /api/profile/achievements/`, `DELETE /api/profile/achievements/<id>/`
- Forum: `GET|POST /api/forum/threads/`, `GET /api/forum/threads/<id>/posts/`, `POST /api/forum/posts/`, `POST /api/forum/posts/<id>/like/`
- Registrations: `GET|POST /api/registrations/` (alias `/api/register/` kept for legacy), `GET /api/registrations/<reference>/`
- Notifications: `GET /api/notifications/` (`page`, `unread=true`), `POST /api/notifications/<id>/read/`, `POST /api/notifications/mark-all-read/`

## Running the backend (reference/)
1. Install deps: `python -m pip install -r requirements.txt` (needed: `Django`, `djangorestframework`, `djangorestframework-authtoken`).
2. Apply migrations: `python manage.py migrate`
3. Create a user (for API token login): `python manage.py createsuperuser`
4. Run: `python manage.py runserver 0.0.0.0:8000`

### Debug log (check)
```text
python manage.py check
ModuleNotFoundError: No module named 'rest_framework'
```
Install requirements (step 1) to resolve.

## Running Flutter (mobile/)
- Fetch deps: `flutter pub get`
- Run with backend host overrides (examples):
  - Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
  - Device/desktop/web: `flutter run --dart-define=API_BASE_URL=http://localhost:8000`
- Toggle fixtures (optional): `--dart-define=USE_DUMMY_DATA=true`

## Debugging tips
- Verify auth token flow: `curl -X POST http://<base>/api/auth/login/ -d '{"username":"<u>","password":"<p>"}' -H "Content-Type: application/json"`
- Events JSON shape check: `curl http://<base>/api/events/ | jq '.results[0].categories[0]'` (should show `id/name/distance_km/display_name`)
- Registration POST sample:
  ```bash
  curl -X POST http://<base>/api/registrations/ \
    -H "Authorization: Token <token>" -H "Content-Type: application/json" \
    -d '{"event":1,"category":2,"phone_number":"0800","emergency_contact_name":"ICE","emergency_contact_phone":"0801"}'
  ```
- Forum like toggle: `POST /api/forum/posts/<id>/like/` returns `{liked, like_count}`.

## Known considerations
- Create initial data (events, categories, threads) before hitting the mobile UI; empty datasets will render skeleton states.
- The admin alias for registrations exists at both `/api/register/` and `/api/registrations/` to keep compatibility with older links.
- If you fork/move the backend folder, the API URLs remain the same; just update `API_BASE_URL` in your run command.

