# EduConnect Production Specification

## Release target
A real production educational platform, not a visual prototype.

## Required functional areas
1. Authentication: email/password, registration, password reset, session persistence, role-aware access.
2. Student: home, explore, course details, enrollment, modules, lessons, video playback, progress, sequential unlocks, quizzes, notifications, private chat, groups, profile, settings.
3. Teacher: dashboard, course CRUD, modules, lessons, recorded lesson uploads, quizzes/questions, publishing, student management, groups, messaging, notifications, profile/settings.
4. Backend: Supabase Auth/Postgres/Realtime/RLS.
5. Video: Cloudflare R2 private objects + server-generated short-lived signed URLs.
6. Security: no service-role/R2 secrets in the client; least-privilege RLS; server-side authorization for signed URLs.
7. UX: light mode, professional restrained interface, loading/error/empty states, validation, responsive layouts.
8. Quality: tests for critical flows, release builds, logging/error handling without leaking secrets.

## Important release gate
This repository is intentionally honest about the production boundary: the Edge Functions included here are explicit signing placeholders. Before public release, implement and test R2 presigned URL generation and complete the remaining RLS policies for modules, lessons, quizzes, conversations, messages, groups, and group membership. Do not bypass those gates by making storage public or putting R2 secrets in Flutter.

## Storage architecture
- Supabase: relational application data.
- R2: large recorded lesson objects.
- Supabase stores object keys and metadata.
- Flutter receives only short-lived signed URLs.
