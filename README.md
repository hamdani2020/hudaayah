# Hudaayah

[![Deploy backend to EC2](https://github.com/hamdani2020/hudaayah/actions/workflows/deploy.yml/badge.svg?branch=main)](https://github.com/hamdani2020/hudaayah/actions/workflows/deploy.yml)
[![Backend: Django 5.1 + DRF](https://img.shields.io/badge/backend-Django%205.1%20%2B%20DRF-092E20?logo=django&logoColor=white)](backend/)
[![Mobile: Flutter 3.41](https://img.shields.io/badge/mobile-Flutter%203.41-02569B?logo=flutter&logoColor=white)](mobile/)
[![Database: PostgreSQL 16](https://img.shields.io/badge/db-PostgreSQL%2016-4169E1?logo=postgresql&logoColor=white)](docker-compose.yml)
[![Infra: Terraform](https://img.shields.io/badge/infra-Terraform-7B42BC?logo=terraform&logoColor=white)](infra/terraform/)
[![License: Proprietary](https://img.shields.io/badge/license-proprietary-lightgrey)](#license)

A Duolingo-style, **Quran-only** learning app that helps Muslims build a consistent
daily habit of engaging with the Quran through short, interactive lessons.

> **Core principle:** Quran Foundation provides the Quran content; Hudaayah provides
> the learning experience. Hudaayah never owns, mirrors, or alters Quran text.

The MVP covers one surah — **Al-Fatihah** — end to end: sign in, work through
interactive lessons, get server-side grading, and build an XP + streak habit loop.

## Contents

- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Repository layout](#repository-layout)
- [Quick start (backend)](#quick-start-backend)
- [Quick start (mobile)](#quick-start-mobile)
- [Configuration](#configuration)
- [Testing](#testing)
- [Deployment](#deployment)
- [Quran content & compliance](#quran-content--compliance)
- [Documentation](#documentation)
- [License](#license)

## Architecture

Hudaayah is a **modular monolith**: one Django deployment with app-boundaried modules,
a Flutter mobile client, and all Quran content fetched at runtime through a single
Quran Foundation (QF) adapter on the backend. No microservices or Kubernetes for MVP.

```
┌──────────────┐        HTTPS /api/v1/        ┌───────────────────────────┐
│   Flutter    │  ───────────────────────▶    │   Django + DRF (modular    │
│   mobile     │   session token (secure      │   monolith)                │
│   (iOS/And.) │   storage), Dio client       │                            │
└──────────────┘                              │  accounts · lessons ·      │
                                              │  exercises · progress ·    │
                                              │  review · gamification     │
                                              └──────────┬─────────────────┘
                                         QuranFoundationClient │  (backend-only
                                         OAuth2 client_creds   │   client_secret)
                                                               ▼
                                              ┌───────────────────────────┐
                                              │  Quran Foundation          │
                                              │  Content API (pre-live)    │
                                              └───────────────────────────┘
       PostgreSQL 16  ◀── source of truth for grading, XP, streaks, progress
```

The server is the source of truth for grading, XP, streaks, and completion. The mobile
app is presentational — no scoring or progression logic lives in widgets.

## Tech stack

| Layer     | Choice                                                               |
| --------- | -------------------------------------------------------------------- |
| Mobile    | Flutter 3.41 / Dart 3.11 · Riverpod · GoRouter · Dio · just_audio    |
| Backend   | Django 5.1 · Django REST Framework · Gunicorn · WhiteNoise           |
| Database  | PostgreSQL 16                                                        |
| Auth      | Google Sign-In + Apple Sign-In, verified server-side (Django session)|
| Quran data| Quran Foundation Content API (OAuth2 `client_credentials`, backend)  |
| Dev runtime| Docker Compose v2 (`web` + `db`)                                    |
| Infra     | Terraform → AWS EC2, deployed via GitHub Actions + SSM               |

## Repository layout

```
hudaayah/
├── backend/        Django modular monolith (apps/, config/, requirements/)
├── mobile/         Flutter feature-first app (lib/features/*)
├── infra/          Terraform (AWS EC2), nginx, deploy scripts
├── design/         Google Stitch exports + UI spec
├── docs/           Setup & admin guides
├── docker-compose.yml
└── .github/workflows/deploy.yml
```

## Quick start (backend)

The backend runs in **Docker** — no host virtualenv required. Containers are the
source of truth for the dev environment.

```bash
# 1. Create your env file and fill in the blanks
cp .env.example .env

# 2. Build and start web (Django/DRF) + db (PostgreSQL 16)
docker compose up --build

# 3. In another terminal, run migrations and create an admin user
docker compose exec web python manage.py migrate
docker compose exec web python manage.py createsuperuser

# 4. Seed the Al-Fatihah MVP content
docker compose exec web python manage.py seed_al_fatihah
```

The API is served at `http://localhost:8000/api/v1/` and the Django admin at
`http://localhost:8000/admin/`.

> Inside Compose the database host is the service name `db`, not `localhost`.
> Postgres data persists in the named volume `pgdata`.

## Quick start (mobile)

```bash
cd mobile
flutter pub get
flutter run
```

Point the app at your backend via its API base URL config (see `mobile/lib/core/`).
On the Android emulator the host backend is reachable at `http://10.0.2.2:8000`.

## Configuration

All secrets come from a **gitignored** `.env` injected via Compose `env_file` — never
baked into the image or committed. Copy `.env.example` and fill in:

| Group        | Keys                                                               |
| ------------ | ------------------------------------------------------------------ |
| Django       | `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`         |
| PostgreSQL   | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`|
| Quran Found. | `QF_ENV`, `QF_CLIENT_ID`, `QF_CLIENT_SECRET` (backend-only)         |
| Social auth  | `GOOGLE_CLIENT_IDS`, `APPLE_CLIENT_IDS`                             |

> The QF `client_secret` is **backend-only** and must never ship in the Flutter bundle.
> Pre-live hosts and credentials are used for MVP; never mix pre-live and production.

## Testing

```bash
# Backend (inside the container)
docker compose exec web python manage.py test

# Mobile
cd mobile && flutter test
```

## Deployment

Pushing backend changes to `main` triggers the **Deploy backend to EC2** GitHub Actions
workflow (`.github/workflows/deploy.yml`). It assumes an AWS role via OIDC and rolls out
to the EC2 instance through SSM (no SSH keys). Infrastructure is managed with Terraform
under `infra/terraform/` (see `infra/terraform/README.md`).

## Quran content & compliance

Quran text, translations, word-by-word, and audio are fetched from the Quran Foundation
Content API at runtime and are **never** hardcoded, altered, or redistributed as data.
Key guardrails:

- QF content is cached **at most 1 week**; durable offline requires Content Sync APIs.
- The Quran Arabic text is immutable — rendered RTL with correct diacritics, never
  auto-translated, never rearranged in a way that alters meaning.
- Translation and original educational content are kept clearly separate from the Quran.
- Quran Foundation is credited accessibly in the app.
- QF content is never used to train or fine-tune ML models.

See [`.kiro/steering/quran-content-rules.md`](.kiro/steering/) for the full rules.

## Documentation

- [Backend admin guide](docs/backend-admin.md)
- [Google auth setup](docs/google-auth-setup.md)
- [Infrastructure (Terraform)](infra/terraform/README.md)

## License

Proprietary. Quran content is provided by the Quran Foundation under its Developer Terms
and is not owned or redistributed by this project.
