---
name: django-conventions
description: Django + DRF conventions for the Hudaayah backend — settings split, app boundaries, server-side grading, idempotent rewards, ownership checks, error envelope. Use when adding or modifying backend endpoints, models, or services.
---

# Django Conventions — Hudaayah

## Project shape
- Modular monolith. Settings split: `config/settings/{base,development,production}.py`.
- Apps: accounts, quran_content, lessons, exercises, progress, review, gamification, common.
- API prefix `/api/v1/`. JSON. Standard HTTP status codes.

## Auth
- Verify Google ID tokens and Apple identity tokens server-side (signature, issuer,
  audience, expiry). Use the stable provider subject (`sub`) as the external key, never
  email alone. Model `User` with `(provider, provider_sub)` to support multiple providers.
- Issue short-lived app access token + managed refresh. Logout revokes session.
- Never log any token.

## Authoritative server logic
- Grade answers on the server. Never send the answer key to the client before submission.
- Calculate XP, streak, completion on the server.
- Use DB transactions for completion + reward updates.
- Make reward/completion operations idempotent (idempotency key per attempt).

## Security
- Object-level ownership on every user-owned endpoint. A user cannot read another user's
  attempts/progress.
- Validate all inputs. Paginate large collections. Rate-limit auth + abuse-prone endpoints.
- Least-privilege DB + cloud IAM.

## Error envelope (consistent, machine-readable)
```json
{ "error": { "code": "lesson_not_available", "message": "…", "request_id": "…" } }
```
Never return stack traces, SQL, secrets, or raw provider errors.

## Migrations
All schema changes via migrations. Index frequent lookups: progress by user, attempts by
user/date, reviews due by user/date. Google/Apple subject identifiers are unique.

## Testing
Unit: auth integration, grading, progression, XP, review scheduling. API: permissions,
validation, pagination, errors. Security: cross-user access denial. Integrity:
duplicate-submission + transaction tests. Adapter: mocked QF responses, token expiry,
timeouts, upstream failures.
