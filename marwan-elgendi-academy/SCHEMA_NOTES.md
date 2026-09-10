# Schema Notes — Marwan Elgendi Academy

## How to apply
Paste `schema.sql` into the Supabase SQL editor and run it once against a
fresh project (or add it as a migration file via the Supabase CLI).

## Creating the one teacher account
The `handle_new_auth_user` trigger creates every new signup as `role =
'student'` by default. After Marwan's own account signs up once (or is
created via the Supabase Auth admin API), promote it manually:

```sql
update public.profiles set role = 'teacher' where email = 'marwan@...';
```

The unique partial index `one_teacher_only` will reject a second promotion,
so this is safe to run once and forget.

## Key enforcement points to know about
- **Deadlines**: `enforce_submission_rules` and `enforce_exam_attempt_rules`
  compare against Postgres `now()`, not any client-supplied timestamp. A
  student manipulating their device clock has no effect.
- **Grades**: both trigger functions silently reset `grade`/`score` and
  related fields back to their previous value on any student-originated
  write — a student physically cannot set their own grade through the API,
  even if the Flutter UI had a bug that tried.
- **Exam answers**: `exam_questions.correct_answer` has *no* student SELECT
  policy at all. Students must read questions via the
  `get_exam_questions_for_student(exam_id)` RPC, which projects only safe
  columns. Querying `exam_questions` directly as a student returns zero rows.
- **Privacy**: `profiles_select_groupmates_limited` technically exposes full
  rows (including `parent_phone`) to co-members at the RLS layer, since
  column-level security isn't native to RLS. Two mitigations are provided —
  read the comment above that policy in `schema.sql`. **Use the
  `get_group_member_profiles(group_id)` RPC in the Flutter app** for any
  "other members of my group" UI (chat sender lists, group member lists,
  leaderboard) so sensitive columns are never fetched client-side.
- **Leaderboard**: `get_leaderboard(group_id)` returns nothing if the
  teacher hasn't enabled it for that group, and never returns phone numbers.
- **Pinning**: only `is_teacher()` can flip `group_messages.pinned`.
- **Storage**: buckets are private except `avatars`. Paths must follow the
  conventions documented inline in `schema.sql` (§20) — the Flutter upload
  code needs to construct paths like
  `assignment-submissions/{assignment_id}/{student_id}/{filename}` exactly,
  or the storage RLS policies will reject the upload.

## What's NOT in this file
- Push notification dispatch (Edge Function using the service-role key —
  bypasses RLS by design, since only trusted server code should fan out
  FCM/APNs sends).
- Presigned URL generation for private buckets (also an Edge Function).
- Seed/demo data — none included, per the spec's "no fake data" rule.

## Next step
Say the word and I'll scaffold Phase 1 (Flutter project structure, Supabase
client config, auth flow, and the repository layer that talks to this
schema).
