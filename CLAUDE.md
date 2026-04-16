# PEPS — Claude Code Context

## What is PEPS?

PEPS is a **personalized peptide optimization telehealth app** targeting the UAE market. It guides users through a health assessment, generates AI-powered peptide protocols via Anthropic Claude, and provides physician-supervised prescription management under Dubai Health Authority (DHA) guidelines.

Target users: high-net-worth wellness enthusiasts seeking physician-supervised peptide therapy.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.0.0) |
| State management | Provider (ChangeNotifier) |
| Backend | Supabase (PostgreSQL, Auth, REST) |
| AI/ML | Anthropic Claude API (`claude-haiku-4-5-20251001`) |
| Typography | Google Fonts — Sora |
| SVG rendering | flutter_svg |
| UI theme | Material 3, dark glass aesthetic |

**Flutter CLI commands:**
```bash
flutter pub get        # Install dependencies
flutter run            # Run the app
flutter analyze        # Lint
flutter test           # Tests
flutter build ios      # Build for iOS (also: android, web, macos)
```

---

## Project Structure

```
lib/
├── main.dart                  # Entry point — Supabase init, Provider setup, route guard
├── app_router.dart            # Named route generation
├── core/
│   ├── theme/                 # app_theme.dart, color_palette.dart, text_styles.dart
│   ├── navigation/            # app_page_transitions.dart (fade/slide animations)
│   └── widgets/               # Shared UI: PepsGlassCard, PepsAmbientOrbs, PrimaryButton, etc.
├── env/
│   ├── supabase_env.dart      # GITIGNORED — contains Supabase URL, anon key, Anthropic key
│   └── supabase_env_example.dart  # Template to copy from
├── features/
│   ├── onboarding/            # Multi-step assessment: name → goals → biometrics → lifestyle → medical
│   ├── auth/                  # Login, email login, account creation, email verification
│   ├── protocol/              # AI generation loading, immersive carousel, my protocol, peptide details
│   ├── home/                  # Home screen + dashboard (authenticated)
│   ├── checkin/               # Weekly health check-in form
│   ├── profile/               # User profile & onboarding history
│   └── navigation/            # MainNavigation — bottom nav (Home / Protocol / Profile)
├── engine/
│   ├── recommendation_engine.dart   # AI-first strategy with rule-based fallback
│   ├── ai_protocol_engine.dart      # Anthropic Claude API integration
│   └── models/peptide_recommendation.dart
├── providers/
│   ├── onboarding_provider.dart     # Multi-step form state
│   ├── protocol_provider.dart       # Recommendation cache pre-auth
│   └── auth_credentials_provider.dart  # Temp email/pass during verification
└── services/
    ├── supabase_client.dart         # Global Supabase instance
    ├── auth_service.dart            # handlePostLogin — upsert user, save onboarding, route
    ├── onboarding_service.dart      # Save assessment to DB
    └── protocol_service.dart        # Fetch user protocol & profile

database/
├── schema.sql                       # Core tables
├── schema_peptides_extension.sql    # Peptide metadata columns
└── migration_add_first_name.sql     # Schema evolution

assets/branding/peps-logo.png
```

---

## Database Schema (Supabase/PostgreSQL)

| Table | Key Columns |
|---|---|
| `users` | `id`, `auth_uid`, `email`, `first_name`, `created_at` |
| `onboarding_responses` | `user_id`, `first_name`, `goals`, `age`, `height_cm`, `weight_kg`, `activity_level`, `lifestyle_factors[]`, `medical_conditions[]` |
| `peptides` | `id`, `name`, `category`, `description`, `benefits`, `dosage`, `goals_supported`, `medical_flags`, `contraindications` |
| `recommendations` | `user_id`, `peptide_id`, `reasoning`, `created_at` |
| `check_ins` | `user_id`, `energy`, `sleep`, `recovery`, `mood`, `overall`, `side_effects_notes` |

---

## Authentication Flow

```
Welcome → Login (Google OAuth or Email)
              ↓
         Supabase Auth
              ↓
         AuthService.handlePostLogin()
           1. Upsert into users table
           2. Save onboarding data
           3. Save protocol recommendations (if any)
           4. Check onboarding_responses exists?
              YES → /home (MainNavigation)
              NO  → /name (start onboarding)

main.dart route guard:
  currentSession == null → / (Welcome)
  currentSession exists  → /home
```

---

## Navigation

**Named routes (app_router.dart):**
- `/` — Welcome
- `/name`, `/goals`, `/biometrics`, `/lifestyle`, `/medical` — Onboarding steps
- `/protocol-building` — AI generation loading state
- `/protocol` — Immersive carousel (post-generation review)
- `/login`, `/create-account-email`, `/email-verification-pending` — Auth
- `/home` — MainNavigation (authenticated shell)
- `/check-in` — Weekly check-in form

**Bottom navigation (MainNavigation):**
- Tab 0: HomeScreen → HomeDashboardScreen
- Tab 1: MyProtocolScreen
- Tab 2: ProfileScreen

---

## Key Screens

| Screen | Purpose |
|---|---|
| Welcome | Entry hero — dark glass, animated orbs |
| Onboarding (5 steps) | Name → Goals (multi-select) → Biometrics (age/height/weight/activity) → Lifestyle (stress/sleep) → Medical conditions |
| Protocol Building | AI generation loading (animated pulse, ~5s) |
| Protocol | Swipeable carousel of 5 peptide recommendations with draggable detail panel |
| Home Dashboard | Authenticated overview with protocol summary from Supabase |
| My Protocol | Saved peptide stack (fetched from `recommendations` table) |
| Check-In | Weekly sliders: energy, sleep, recovery, mood, overall + free-text side effects |
| Profile | Email, account creation date, onboarding history |

---

## AI Recommendation Engine

- **Strategy:** AI-first, rule-based fallback
- `recommendation_engine.dart` calls `ai_protocol_engine.dart` first
- If Claude API fails → falls back to scoring engine in `features/protocol/engine/protocol_engine.dart`
- Protocol size constant: `kProtocolSize = 5` (max 5 peptides)
- Model: `claude-haiku-4-5-20251001`
- DHA safety guardrails baked into the Claude prompt

---

## Environment Setup

`lib/env/supabase_env.dart` is gitignored. Copy from the example and fill in credentials:

```bash
cp lib/env/supabase_env_example.dart lib/env/supabase_env.dart
# Then fill in: supabaseUrl, supabaseAnonKey, anthropicApiKey
# Or use: bash tool/setup_supabase_env.sh
```

---

## Design System

- **Palette:** Deep blue background `#08101E`, teal accent `#3ECFA0`, gold highlights
- **Cards:** Glassmorphic (`PepsGlassCard`) with blur + frosted glass effect
- **Motion:** Ambient animated orbs (`PepsAmbientOrbs`), fade-through transitions between onboarding steps, staggered list animations
- **Typography:** Sora (Google Fonts) throughout
- **Theme:** Material 3 dark theme

---

## State Management Pattern

All state is Provider (ChangeNotifier). Three providers registered at the root:
1. `OnboardingProvider` — holds the multi-step assessment model
2. `ProtocolProvider` — caches AI recommendations before account creation
3. `AuthCredentialsProvider` — temporary email/password during email verification flow

---

## Testing & Linting

- `flutter analyze` — runs Dart linter (`flutter_lints`)
- `flutter test` — minimal smoke test only (`test/widget_test.dart`)
- No CI/CD pipeline is configured yet

---

## Development Workflow

### Branch Structure

```
main          ← production-ready, stable
  └── development  ← integration branch; all feature work bases off here
        └── worktree/[feature-name]  ← active work happens here
```

### Standard Flow

1. **Start work** — create a worktree from `development`, named after the feature being built:
   ```bash
   git worktree add .claude/worktrees/[feature-name] -b [feature-name] development
   ```
2. **Do all work** inside that worktree — never commit directly to `development` or `main`
3. **When complete** — open a PR from `[feature-name]` → `main` (skip development as the merge target)
4. **After merge** — delete the worktree and branch

### Worktree Naming

Name worktrees and branches after the feature or task, e.g.:
- `check-in-redesign`
- `protocol-pdf-export`
- `auth-google-deeplink-fix`

### Rules

- Always work in a worktree — never on `main` or `development` directly
- PRs always target `main`
- Worktree branch always starts from `development`
- Worktree name = feature name (descriptive, kebab-case)
