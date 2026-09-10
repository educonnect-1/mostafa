# Security Audit — Marwan Elgendi Academy Student App

Self-audit against the spec's security requirements (§35) and privacy
requirements (§29). Every item below was checked by reading the actual
code and schema, not assumed.

## §35 — Never do these

| Requirement | Status | Where verified |
|---|---|---|
| Service-role key in Flutter | ✅ Absent | `grep -r "SERVICE_ROLE" lib/ .env.example` returns nothing. Only `SUPABASE_ANON_KEY` exists client-side (`lib/core/config/env_config.dart`). |
| Resend API key in Flutter | ✅ Absent | Same grep sweep — no email-provider secret anywhere in `lib/`. |
| Hardcoded teacher/student credentials | ✅ Absent | No credentials in source; login is always a live Supabase Auth call (`lib/repositories/auth_repository.dart`). |
| Trusting client-provided role information | ✅ Enforced server-side | `enforce_profile_update_rules` trigger (schema.sql §18) silently resets any `role` change from a non-teacher back to its previous value, regardless of what the client sends. |
| Trusting client-provided deadlines | ✅ Enforced server-side | `enforce_submission_rules` and `enforce_exam_attempt_rules` triggers compare against Postgres `now()`, not any timestamp the app sends. The local countdown in `exam_taking_controller.dart` is explicitly commented as "UI convenience only." |
| Trusting client-provided grades | ✅ Enforced server-side | Both triggers above unconditionally overwrite `grade`/`score`/`teacher_comment`/`graded_at`/`graded_by` back to their prior value on any non-teacher write — there is no code path, buggy UI or otherwise, that can set your own grade. |
| Exposing private Storage buckets | ✅ Private by default | Only `avatars` is `public: true` (schema.sql §20). `chat-attachments`, `assignment-submissions`, `resources` are private; the app always reads them through `StorageService.getSignedUrl`, never a raw public URL. |
| Disabling RLS | ✅ Enabled everywhere | Every table in schema.sql §17 has `ENABLE ROW LEVEL SECURITY`; §18 has no `USING (true)` catch-all policies. |

## §29 — Privacy

| Requirement | Status | Where verified |
|---|---|---|
| Other students' parent phone / phone | ✅ Never fetched | `ProfileRepository.getGroupMemberProfiles` and `GroupRepository.getGroupMembers` call the `get_group_member_profiles` RPC, whose SQL definition (schema.sql §16) only ever `SELECT`s `id, full_name, avatar_url, online, last_seen_at` — `phone`/`parent_phone`/`email` are not in that function's column list, so they never leave the database for this query path. |
| Other students' grades/submissions/exam answers | ✅ RLS-enforced | `submissions_select_own_or_teacher` and the `exam_attempts`/`exam_answers` policies all filter on `student_id = auth.uid()`. |
| Exam answer key | ✅ Never exposed | `exam_questions` has no student `SELECT` policy at all (schema.sql §18) — the only student-facing path is `get_exam_questions_for_student`, which projects columns explicitly and excludes `correct_answer`. |
| Leaderboard contact info | ✅ Excluded at the SQL level | `get_leaderboard` (schema.sql §16) only returns `student_id, full_name, avatar_url, average_grade` — there is no phone/parent_phone column in that function's result set to accidentally serialize. |

## Known residual risks / out of scope for this repo

- **The teacher web dashboard is a separate codebase** not included here. This audit only covers the student mobile app; a compromised or misconfigured dashboard is outside what client-side RLS review can catch.
- **Push notification payloads are trusted as-is** by `deepLinkPathForNotificationData` — a malicious or malformed FCM payload can only navigate the student to a route their own RLS-scoped queries will still filter correctly (e.g. `/assignments/<not-mine>` just 404s via `NotFoundAppException`), so this isn't a data-exposure risk, but it's worth knowing the client doesn't validate payload provenance beyond what FCM itself guarantees.
- **Rate limiting / brute-force protection on login** is whatever Supabase Auth provides by default — this app doesn't add its own lockout logic.
- **Anon key exposure**: the anon key is, by design, public (it's shipped in every client build). Its safety depends entirely on the RLS policies in `schema.sql` being correct, which is why this audit exists.
- **This audit was performed by reading code, not by running a penetration test or `flutter test` against a live Supabase project** — see `README.md` for why a live build/test run wasn't possible in this environment. Re-run RLS policy tests against a real staging project before shipping.
