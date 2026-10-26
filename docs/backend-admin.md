# Backend Admin & Superuser (Hudaayah)

The backend runs in Docker and uses a **custom `User` model** (`apps.accounts.User`).
This changes how you create and log in as an admin — the standard
`createsuperuser --username ... --noinput` command does **not** apply.

## Why the usual command doesn't work

- There is **no `username` field**. The login field (`USERNAME_FIELD`) is **`uid`**,
  a synthetic value derived as `"<provider>:<provider_sub>"`.
- `REQUIRED_FIELDS` is empty and `email` is optional.
- `uid` is recomputed in `User.save()` from `provider`/`provider_sub`, so passing
  `--uid` to `createsuperuser --noinput` would be overwritten.

So create superusers via the model manager (`create_superuser`), which hashes the
password and sets `is_staff` + `is_superuser` correctly.

## Create a superuser

Run inside the `web` container. Pick a readable `provider_sub` so the login username is
memorable — `uid` becomes `admin:root` here:

```bash
docker compose exec -T -e DJANGO_SUPERUSER_PASSWORD="ChangeMe!2026" web \
  python manage.py shell -c "
import os
from apps.accounts.models import User
pw = os.environ['DJANGO_SUPERUSER_PASSWORD']
User.objects.create_superuser(
    provider='admin', provider_sub='root',
    email='admin@example.com', password=pw, display_name='Administrator',
)
print('created admin:root')
"
```

## Log in to Django admin

- URL: `http://localhost:8000/admin/`
- **Username: `admin:root`** (the `uid`, i.e. `provider:provider_sub` — not `admin`)
- Password: whatever you set above

## Change / reset the password

```bash
docker compose exec web python manage.py shell -c "
from apps.accounts.models import User
u = User.objects.get(uid='admin:root')
u.set_password('YOUR_NEW_PASSWORD'); u.save()
"
```

## Verify credentials (optional)

```bash
docker compose exec -T web python manage.py shell -c "
from django.contrib.auth import authenticate
u = authenticate(username='admin:root', password='YOUR_PASSWORD')
print('ok' if u and u.is_staff else 'FAILED')
"
```

## What the admin exposes (R9 content review)

- **Lessons** — with the `draft → in_review → published → archived` lifecycle and the
  **"Mark reviewed & publish"** action that stamps `approved_by` / `approved_at`.
- **Content sources** — QF provenance (provider, resource type, stable ref, attribution).
- **Users** — read-mostly; `provider`/`provider_sub` are read-only.
- **Auth sessions** — token *hashes* only (raw tokens are never stored or shown);
  add disabled.

## Rules / cautions

- Learner (Google/Apple) accounts are **never** staff. Only deliberately created admins
  reach the admin site.
- Never hand-edit a lesson's `approved_by` / `approved_at` — use the publish action so the
  audit trail is accurate.
- QF Arabic/translation are **not** editable in admin; only our own fields and QF
  references-by-ID are.
- Change the placeholder password immediately; in production, admins come from secrets,
  not committed defaults.
