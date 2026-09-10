# Marwan Elgendi Academy — Student Mobile App

Flutter + Supabase student application. See `../schema.sql` (from the
earlier deliverable) for the database this app is built against.

## ✅ Build status: all 6 phases implemented — read this before your first build

Every feature in the spec (§1–§31) is implemented against the real
Supabase schema (`../schema.sql`), with no stub screens, no mock data,
and no "Coming Soon" placeholders anywhere in the app. That said,
**"implemented" here means "written and internally consistent," not
"verified by a real Flutter build"** — this sandbox has no Flutter SDK
and no network access to pub.dev, Firebase, or the Jitsi SDK registry,
so `flutter pub get` / `flutter analyze` / `flutter test` / `flutter
build` have never actually run against this code. See "First build
checklist" below for exactly what to verify locally before shipping.

**What's implemented:**
- Full project architecture (`lib/core`, `lib/features`, `lib/repositories`, `lib/models`, `lib/services`)
- Supabase client config via `.env` (anon key only — see `.env.example`)
- Auth: login, logout, password reset, session persistence, auth-gated
  routing, typed error handling (`AppException`) so no raw exception
  ever reaches a screen
- Presence tracking, wired up and running from `AppShell`
- Privacy-safe group-member lookups (RPC-only, never fetches
  phone/parent_phone for anyone but the signed-in user)
- Groups, realtime group chat (paginated history, live tail merge,
  validated/compressed image attachments, pinned-message banner,
  chat-enabled toggle respected)
- Assignments: photo capture → preview → retake/confirm → upload →
  submit, grade/comment display, server-enforced deadline closure
- Exams: all 5 question types, autosaved answers, local countdown (UI
  convenience only — the DB re-validates on submit), grade/feedback
- Announcements, Jitsi live rooms (live/upcoming/past + join flow)
- Push notifications: FCM token lifecycle, foreground display,
  tap-to-deep-link covering every type in spec §12, realtime
  notification center with read/unread state
- Attendance (grouped by month), Resources (type-aware open/download),
  Student Progress (completion + averages + attendance %), Leaderboard
  (respects the teacher's per-group toggle, never leaks contact info),
  Calendar (month view), Search (5 categories, all RLS-scoped)
- Profile view/edit (name/age/phone/avatar only — role, grades, and
  membership are not editable from this screen, and the DB would
  silently discard such a change even if the UI tried)
- Offline banner (spec §34) — writes simply fail safely offline rather
  than queuing for risky later replay
- `codemagic.yaml` CI pipeline (analyze → test → build, both platforms)
- `SECURITY_AUDIT.md` — a self-audit against spec §35/§29, with the
  underlying grep commands included so you can re-verify the claims
- Unit tests: auth state machine, upload validation, deep-link mapping,
  assignment/exam deadline logic, progress aggregation math

**What genuinely could not be done in this environment** (not a phase
gap — a tooling gap; see "First build checklist"):
- Never compiled. Dart-level typos, import errors, or API mismatches
  against the exact pinned package versions are possible and expected
  to need at least minor fixes.
- `android/` and `ios/` native folders are not included (see below) —
  generating them without the Flutter tool risks a zip that looks
  complete but silently fails to build.
- Firebase and Jitsi wiring is written against each SDK's documented
  API but unverified against a real build (see the dedicated sections
  below for both).
- Widget/integration tests are not included — only pure-logic unit
  tests, since widget tests need the Flutter test harness running for
  real, which this sandbox can't do.

## First build checklist

Run these yourself, in order, before considering this "done":

1. `flutter create . --platforms=android,ios --project-name=marwan_elgendi_academy --org=com.marwanelgendi` (see below)
2. `flutter pub get` — resolve any version conflicts the pinned versions in `pubspec.yaml` might have picked up since this was written
3. Firebase setup (below), then Jitsi setup (below)
4. `flutter analyze` — fix anything it flags
5. `flutter test` — all included unit tests should pass unmodified
6. `flutter run` — walk through: login → view a group → send a chat
   message → submit an assignment photo → take an exam → check a
   push notification deep-link → edit your profile
7. Push to Codemagic using the included `codemagic.yaml`


## Firebase setup (required before push notifications work)

This sandbox has no network access to Firebase, so it could not run
`flutterfire configure` for you. One-time steps before your first
build:

1. Create a Firebase project (or use an existing one) and add Android +
   iOS apps to it.
2. Download `google-services.json` into `android/app/`.
3. Download `GoogleService-Info.plist` into `ios/Runner/`.
4. Run `flutterfire configure` locally (requires the FlutterFire CLI)
   to generate `lib/firebase_options.dart`, then pass
   `options: DefaultFirebaseOptions.currentPlatform` to
   `Firebase.initializeApp()` in `lib/main.dart`.
5. In Codemagic, store `google-services.json` /
   `GoogleService-Info.plist` as encrypted secure files and add a
   script step to copy them into place before `flutter build` (see
   Codemagic's docs on secure files — not included in `codemagic.yaml`
   since the exact file references depend on your Codemagic project
   setup).

## Jitsi setup

`lib/services/jitsi_service.dart` was written against the
`jitsi_meet_flutter_sdk` API as documented in its package README, but
**could not be verified against a real build** in this sandbox (see
below). Double-check the `JitsiMeetConferenceOptions` /
`JitsiMeetUserInfo` constructor shape against the exact version pinned
in `pubspec.yaml` the first time you build.

## One-time local setup before your first Codemagic build

This sandbox has no Flutter SDK, so the Android/iOS native project
folders (`android/`, `ios/`) are **intentionally not included** —
hand-writing Gradle/Xcode project files without the tool that generates
them risks a zip that looks complete but silently fails to build. Run
this once, locally, after unzipping:

```bash
flutter create . --platforms=android,ios --project-name=marwan_elgendi_academy --org=com.marwanelgendi
flutter pub get
```

This fills in only the missing native scaffolding — it will not touch
your existing `lib/`, `pubspec.yaml`, or `test/` files. Commit the
result, then Codemagic can build from the repo as normal using the
included `codemagic.yaml`.

## Local development

```bash
cp .env.example .env   # fill in your Supabase project's URL + anon key
flutter pub get
flutter analyze
flutter test
flutter run
```

## Environment / secrets

- `.env` holds only the public Supabase anon key and non-secret config
  — never the service-role key. See `.env.example`.
- In Codemagic, these values are injected via the `academy_secrets`
  environment group referenced in `codemagic.yaml`, not committed to
  the repo.
