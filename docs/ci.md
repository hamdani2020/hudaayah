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
| Backend tests (cont.) | same | `check --deploy --fail-level WARNING` with the **production** settings |
| Mobile checks | `mobile/**` changed | `changelog.json` has an entry for the pubspec version, `flutter analyze`, `flutter test`, Android debug build |
| Secret scan | always | gitleaks over the PR's commits (whole history on manual/scheduled runs); fails on any finding |
| Dependency audit | backend or mobile changed | `pip-audit` (backend requirements, full dependency tree); `osv-scanner` (`pubspec.lock`, `Gemfile.lock`); fails on known vulnerabilities |
| Image scan | backend, `infra/nginx` or `infra/deploy` changed | Builds the **production** backend image and the nginx image; Trivy fails on HIGH/CRITICAL vulnerabilities that have a fix |
| CI passed | always | Green when every job that ran succeeded (skipped jobs are fine) |

Manual runs and the weekly scheduled run (Mondays 06:00 UTC, on `main`) run every
job, so new advisories against unchanged dependencies show up too.

### Scanners
- Scanners run as **containers pinned by digest** (`GITLEAKS_IMAGE`, `OSV_SCANNER_IMAGE`,
  `TRIVY_IMAGE` at the top of `ci.yml`), not through third-party scanner Actions. In
  March 2026 `aquasecurity/trivy-action` tags and some Trivy images were hijacked
  (GHSA-69fq-xp46-6x23); digest-pinned images were not affected. Trivy is 0.76.2 from
  GHCR (post-incident, immutable releases).
- Trivy scans image **tar files**; it never gets the Docker socket.
- Dependabot does not update these three digests (they live in workflow `env`). Check
  for new releases every month or so, resolve the new digest, and update `ci.yml`.

### When a scan fails
| Scanner | Fix | Accept (only if it truly does not apply) |
| --- | --- | --- |
| gitleaks | Remove the secret **and rotate it** (it is in git history). | `.gitleaks.toml` allowlist (paths/regex), with a comment. |
| pip-audit | Bump the package in `backend/requirements/`. | `pip-audit --ignore-vuln <ID>` in `ci.yml`, with a comment. |
| osv-scanner | `flutter pub upgrade <pkg>` / `bundle update <gem>`, commit the lock file. | `osv-scanner.toml` next to the lock file (`[[IgnoredVulns]] id = "…" reason = "…"`). |
| Trivy | Merge the Dependabot base-image update, or bump the Python package. | `.trivyignore`: the ID, a reason and a review date. |

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

## Workflow security rules

Applies to `ci.yml`, `deploy.yml` and `mobile-release.yml`.

- **Token permissions:** `permissions: {}` at the top of every workflow; each job
  lists only what it needs (`contents: read`, plus `pull-requests: read` for the
  change filter and `id-token: write` for the AWS deploy).
- **Checkout:** always `persist-credentials: false`, so the token is not left in
  `.git/config` for later steps.
- **Pinned Actions:** every `uses:` is a full commit SHA with the version in a comment,
  e.g. `actions/checkout@11d5960… # v4.4.0`. Dependabot updates both.
- **Pinned images:** `python`, `nginx`, `postgres` and `certbot` are pinned to digests
  in `backend/Dockerfile`, `infra/nginx/Dockerfile`, both Compose files and `ci.yml`.
- **Locked dependencies:** CI and releases install from `pubspec.lock`
  (`flutter pub get --enforce-lockfile`) and `mobile/android/Gemfile.lock` (frozen by
  `ruby/setup-ruby`). Python requirements pin top-level versions only (full lock with
  hashes is a later step).
- **PR code never sees secrets:** CI uses `pull_request`, never `pull_request_target`.
  Secrets exist only in the deploy/release environments.
- **No untrusted values in scripts:** inputs and event data go through `env:` and are
  validated (e.g. the deploy ref must look like a branch, tag or SHA), never written as
  `${{ … }}` inside `run:`.

### Before adding a new third-party Action
Prefer official (`actions/*`, `docker/*`, vendor-owned) Actions. Check the repo's
owner, activity and permissions it needs, pin it to a commit SHA, and give its job the
smallest `permissions:` block.

### Reviewing Dependabot PRs
Dependabot opens weekly PRs into `develop` (minor/patch grouped). CI runs on them.
Read the changelog before merging majors, Actions updates, and anything that runs
code at install/build time (Gradle plugins, gems, pip packages with build steps).
Postgres majors and `flutter_local_notifications` majors are ignored on purpose (see
`.github/dependabot.yml`).

## GitHub settings checklist (owner, one-time)

1. **Settings → Environments** → for `production`, `play-testing` and
   `play-production`: **Deployment branches and tags → Selected branches → `main`**.
   Without this, a manual run on another branch could deploy or sign unreviewed code.
2. **Settings → Branches → ruleset for `main`:** require a pull request, require the
   **CI passed** check, block force pushes.
3. **Settings → Code security:** enable **Dependabot alerts** and **Dependabot security
   updates**; enable **Secret scanning** and **Push protection** if your plan offers them.
4. **Settings → Actions → General:** "Workflow permissions" = **Read repository
   contents** (default token read-only); leave "Allow GitHub Actions to create and
   approve pull requests" off.
