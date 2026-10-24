# Structure Steering — Hudaayah

Monorepo layout:

```
hudaayah/
├── backend/                     # Django modular monolith
│   ├── config/
│   │   ├── settings/{base,development,production}.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── apps/
│   │   ├── accounts/            # User (multi-provider), Google/Apple auth, sessions
│   │   ├── quran_content/       # QuranFoundationClient adapter, content proxy, provenance
│   │   ├── lessons/             # Lesson definitions, ordering
│   │   ├── exercises/           # Exercise defs + server-side grading
│   │   ├── progress/            # Attempts, UserProgress, daily activity
│   │   ├── review/              # Spaced repetition (SM-2 trimmed), ReviewItem
│   │   ├── gamification/        # XP, streak, daily goal
│   │   └── common/              # shared utils, error envelope, request IDs
│   ├── seed/                    # Al-Fatihah seed JSON + loader
│   ├── tests/
│   ├── requirements/
│   └── manage.py
├── mobile/                      # Flutter feature-first
│   └── lib/
│       ├── app/                 # setup, router, theme
│       ├── core/                # networking (Dio), config, errors, secure storage
│       ├── features/
│       │   ├── authentication/
│       │   ├── onboarding/
│       │   ├── learning_path/
│       │   ├── lessons/
│       │   ├── exercises/
│       │   ├── quran_reader/
│       │   ├── audio/
│       │   ├── progress/
│       │   └── profile/
│       └── main.dart
├── design/
│   └── stitch/                  # Google Stitch exports (images/HTML/CSS) + UI spec
└── .kiro/                       # specs, steering, skills, agents, settings
```

Rules:
- `backend/apps/*` are Django apps in ONE deployment, not separate services.
- No cross-app imports that bypass the owning app's service layer.
- QF access is funneled through `apps/quran_content` only.
- All schema changes via Django migrations.
