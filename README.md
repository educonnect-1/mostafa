# EduConnect | Production-Ready Base

A production-oriented Flutter + Supabase learning platform.

## Architecture
Flutter owns UI/state. Repositories own Supabase access. Server-side functions own privileged operations such as signed R2 URLs.

## Required environment
Copy `.env.example` to `.env` in the project root and fill in your project's values:
- SUPABASE_URL
- SUPABASE_ANON_KEY

`.env` is gitignored and is bundled into the app at build time via `flutter_dotenv`, so it must exist before you run `flutter pub get` / `flutter run` / `flutter build`.

CI builds (see `codemagic.yaml`) instead write `.env` from secret environment variables at build time, so no secrets are ever committed. Compile-time `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` values are still honored as a fallback if `.env` isn't present.

Never put a Supabase service-role key, Cloudflare R2 secret, or other private credential in the Flutter app.

## Storage
Recorded lessons are represented by an object key in `lessons.video_object_key`.
The intended production flow is:
1. Authenticated teacher requests an upload URL from the server function.
2. Server validates role/course ownership and signs an R2 upload.
3. Flutter uploads directly to R2.
4. Supabase stores the object key and lesson metadata.
5. Authenticated students request a short-lived playback URL.
6. Server verifies enrollment/preview access and signs the R2 download.

## Database
Run `supabase/schema.sql` in a fresh Supabase project, or apply the migration file.

## Production checklist
Before release:
- Configure Supabase Auth email settings.
- Configure redirect URLs.
- Deploy Edge Functions.
- Configure R2 bucket and secrets on the server side.
- Replace placeholder branding/assets.
- Run flutter test.
- Build release APK/AAB.
- Review RLS policies against the exact business rules.
