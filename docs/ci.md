# CI (pull request checks)

Workflow: `.github/workflows/ci.yml`. Runs on every pull request into `main` or
`develop`, and can be run by hand (Actions → CI → Run workflow).

## Flow

```
feature/fix work on develop
        │  open PR: develop → main
        ▼
CI runs  ──► "CI passed" green?  ── no ──► fix on develop, push (CI re-runs)
        │ yes
        ▼
merge to main ──► deploy.yml (backend, if backend/** changed)
              └─► mobile-release.yml (closed test, if mobile/** changed)
```

## What it checks

| Job | Runs when | Checks |
| --- | --- | --- |
| Backend tests | `backend/**` or `docker-compose.yml` changed | Builds `backend/Dockerfile` (development requirements), a throwaway Postgres 16 with per-run credentials, `makemigrations --check` (no missing migrations), `manage.py check`, `pytest` |
| Mobile checks | `mobile/**` changed | `changelog.json` has an entry for the pubspec version, `flutter analyze`, `flutter test`, Android debug build |
| CI passed | always | Green when every job that ran succeeded (skipped jobs are fine) |

No credentials are stored anywhere, in the repo or in GitHub Secrets. Each run
generates a random Postgres password and Django secret key, masks them in the logs,
passes them to the containers by variable name (never on the command line), and
deletes the database container at the end. QF calls are mocked in tests. A new push
to the same PR cancels the older run.

## Make "CI passed" required (one-time, GitHub settings)

1. Open a PR once so the check exists.
2. GitHub → **Settings → Branches → Add branch ruleset** (or *Add rule*) for `main`:
   - **Require a pull request before merging** (approvals: 0 is fine when working alone).
   - **Require status checks to pass** → add **CI passed**.
   - **Block force pushes**.
   - Optional: **Do not allow bypassing** so even you cannot push to `main` directly.
3. Save. The Merge button now stays disabled until CI passed is green.

## Running the same checks locally

```bash
# backend (from repo root)
docker compose exec web python manage.py makemigrations --check --dry-run
docker compose exec web python -m pytest -q

# mobile
cd mobile && flutter analyze && flutter test
```
