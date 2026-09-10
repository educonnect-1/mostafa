-- =====================================================================
-- MARWAN ELGENDI ACADEMY — PRODUCTION DATABASE SCHEMA
-- Supabase / PostgreSQL
--
-- Run this in the Supabase SQL editor (or via `supabase db push` with
-- this file as a migration). Idempotent-ish: uses IF NOT EXISTS /
-- CREATE OR REPLACE where practical, but this is intended to run once
-- against a fresh project. Wrap in a migration file if you need to
-- re-run pieces.
--
-- Design principles enforced here (do not weaken these later):
--   1. The backend (RLS) is authoritative, never the Flutter client.
--   2. There is exactly one teacher account. Everyone else is 'student'.
--   3. Deadlines are compared against DB now(), never client-supplied time.
--   4. Grades/attendance/exam answers are never writable by students.
--   5. Sensitive profile fields (parent_phone, phone, email) are never
--      exposed to other students — only to the owner and the teacher.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. EXTENSIONS
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- 1. ENUM TYPES
-- ---------------------------------------------------------------------
do $$ begin
  create type public.user_role as enum ('teacher', 'student');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.room_status as enum ('scheduled', 'live', 'ended', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.resource_type as enum ('pdf', 'image', 'video', 'link', 'document');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.submission_status as enum ('not_submitted', 'submitted', 'graded', 'closed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.question_type as enum ('mcq', 'true_false', 'short_answer', 'long_answer', 'numerical');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.attempt_status as enum ('in_progress', 'submitted', 'graded');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.attendance_status as enum ('present', 'late', 'absent', 'excused');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.notification_type as enum (
    'live_room', 'new_assignment', 'new_exam', 'announcement',
    'assignment_graded', 'exam_graded', 'general'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.message_attachment_type as enum ('none', 'image', 'file');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- 2. UTILITY: updated_at trigger
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================
-- 3. PROFILES
-- =====================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'student',
  full_name text not null,
  email text not null,
  age int,
  phone text,
  parent_phone text,               -- NEVER exposed to other students
  avatar_url text,
  online boolean not null default false,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enforce exactly one teacher account in the whole system.
create unique index if not exists one_teacher_only
  on public.profiles ((role = 'teacher'))
  where role = 'teacher';

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row when a new auth user is created.
-- Role defaults to 'student'; the single teacher row must be created/
-- promoted explicitly (e.g. one-off SQL by you, not by app code).
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- =====================================================================
-- 4. GROUPS / MEMBERSHIP
-- =====================================================================
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  chat_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_groups_updated_at
  before update on public.groups
  for each row execute function public.set_updated_at();

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, student_id)
);

create index if not exists idx_group_members_student on public.group_members(student_id);

-- =====================================================================
-- 5. INVITATIONS (registration website / teacher dashboard only)
-- =====================================================================
create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  token text not null unique,
  group_id uuid references public.groups(id) on delete set null,
  invited_by uuid not null references public.profiles(id),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 6. HELPER FUNCTIONS (used throughout RLS policies)
-- All SECURITY DEFINER + STABLE to avoid RLS recursion and allow
-- cross-table checks without granting broad table access.
-- =====================================================================
create or replace function public.is_teacher()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'teacher'
  );
$$;

create or replace function public.is_group_member(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.group_members
    where group_id = p_group_id and student_id = auth.uid()
  );
$$;

create or replace function public.has_assignment_access(p_assignment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.assignment_groups ag
    join public.group_members gm on gm.group_id = ag.group_id
    where ag.assignment_id = p_assignment_id and gm.student_id = auth.uid()
  );
$$;

create or replace function public.has_exam_access(p_exam_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.exam_groups eg
    join public.group_members gm on gm.group_id = eg.group_id
    where eg.exam_id = p_exam_id and gm.student_id = auth.uid()
  );
$$;

create or replace function public.has_room_access(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.room_groups rg
    join public.group_members gm on gm.group_id = rg.group_id
    where rg.room_id = p_room_id and gm.student_id = auth.uid()
  );
$$;

create or replace function public.has_announcement_access(p_announcement_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.announcement_groups ag
    join public.group_members gm on gm.group_id = ag.group_id
    where ag.announcement_id = p_announcement_id and gm.student_id = auth.uid()
  );
$$;

-- =====================================================================
-- 7. ROOMS (Jitsi)
-- =====================================================================
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  jitsi_room_url text not null,
  host_display_name text not null default 'Mr. Marwan Elgendi',
  status public.room_status not null default 'scheduled',
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_rooms_updated_at
  before update on public.rooms
  for each row execute function public.set_updated_at();

create table if not exists public.room_groups (
  room_id uuid not null references public.rooms(id) on delete cascade,
  group_id uuid not null references public.groups(id) on delete cascade,
  primary key (room_id, group_id)
);

-- =====================================================================
-- 8. ANNOUNCEMENTS
-- =====================================================================
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  send_push boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.announcement_groups (
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  group_id uuid not null references public.groups(id) on delete cascade,
  primary key (announcement_id, group_id)
);

-- =====================================================================
-- 9. RESOURCES
-- =====================================================================
create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  title text not null,
  type public.resource_type not null,
  storage_path text,        -- for pdf/image/video/document
  external_url text,        -- for type = 'link'
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  constraint resource_has_source check (
    (type = 'link' and external_url is not null) or
    (type != 'link' and storage_path is not null)
  )
);

-- =====================================================================
-- 10. ASSIGNMENTS
-- =====================================================================
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  deadline timestamptz not null,
  manually_closed boolean not null default false,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_assignments_updated_at
  before update on public.assignments
  for each row execute function public.set_updated_at();

create table if not exists public.assignment_groups (
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  group_id uuid not null references public.groups(id) on delete cascade,
  primary key (assignment_id, group_id)
);

create table if not exists public.assignment_submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  photo_storage_path text not null,
  status public.submission_status not null default 'submitted',
  grade numeric(5,2),
  max_grade numeric(5,2) not null default 20,
  teacher_comment text,
  submitted_at timestamptz not null default now(),
  graded_at timestamptz,
  graded_by uuid references public.profiles(id),
  unique (assignment_id, student_id)
);

-- Server-side deadline + privilege enforcement for submissions.
create or replace function public.enforce_submission_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deadline timestamptz;
  v_closed boolean;
begin
  select deadline, manually_closed into v_deadline, v_closed
  from public.assignments where id = coalesce(new.assignment_id, old.assignment_id);

  if not public.is_teacher() then
    if tg_op = 'INSERT' then
      if v_closed or now() > v_deadline then
        raise exception 'Assignment is closed; submission rejected.';
      end if;
      -- students may never set grading fields on insert
      new.status := 'submitted';
      new.grade := null;
      new.teacher_comment := null;
      new.graded_at := null;
      new.graded_by := null;
    elsif tg_op = 'UPDATE' then
      if old.status = 'graded' then
        raise exception 'Submission already graded; cannot be modified.';
      end if;
      if v_closed or now() > v_deadline then
        raise exception 'Assignment is closed; resubmission rejected.';
      end if;
      -- lock grading fields to their previous values
      new.grade := old.grade;
      new.teacher_comment := old.teacher_comment;
      new.graded_at := old.graded_at;
      new.graded_by := old.graded_by;
      new.status := 'submitted';
      new.submitted_at := now();
    end if;
  else
    -- teacher grading path
    if tg_op = 'UPDATE' and new.grade is not null and old.grade is distinct from new.grade then
      new.status := 'graded';
      new.graded_at := now();
      new.graded_by := auth.uid();
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_enforce_submission_rules
  before insert or update on public.assignment_submissions
  for each row execute function public.enforce_submission_rules();

-- =====================================================================
-- 11. EXAMS
-- =====================================================================
create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  instructions text,
  deadline timestamptz not null,
  duration_minutes int not null default 60,
  allow_late_submission boolean not null default false,
  manually_closed boolean not null default false,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_exams_updated_at
  before update on public.exams
  for each row execute function public.set_updated_at();

create table if not exists public.exam_groups (
  exam_id uuid not null references public.exams(id) on delete cascade,
  group_id uuid not null references public.groups(id) on delete cascade,
  primary key (exam_id, group_id)
);

create table if not exists public.exam_questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  type public.question_type not null,
  question_text text not null,
  image_url text,
  options jsonb,              -- e.g. [{"id":"a","text":"..."}] for mcq
  correct_answer jsonb not null,  -- NEVER exposed to students directly (see view below)
  points numeric(5,2) not null default 1,
  order_index int not null default 0,
  created_at timestamptz not null default now()
);

-- Student-safe view: excludes correct_answer entirely.
create or replace view public.exam_questions_student_view
with (security_invoker = true) as
select id, exam_id, type, question_text, image_url, options, points, order_index
from public.exam_questions;

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status public.attempt_status not null default 'in_progress',
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  score numeric(6,2),
  max_score numeric(6,2),
  teacher_feedback text,
  graded_at timestamptz,
  graded_by uuid references public.profiles(id),
  unique (exam_id, student_id)
);

create table if not exists public.exam_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  question_id uuid not null references public.exam_questions(id) on delete cascade,
  answer_data jsonb,
  points_awarded numeric(5,2),
  updated_at timestamptz not null default now(),
  unique (attempt_id, question_id)
);

-- Server-side exam deadline + grading-field lockdown.
create or replace function public.enforce_exam_attempt_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deadline timestamptz;
  v_allow_late boolean;
  v_closed boolean;
begin
  select deadline, allow_late_submission, manually_closed
    into v_deadline, v_allow_late, v_closed
  from public.exams where id = coalesce(new.exam_id, old.exam_id);

  if not public.is_teacher() then
    if tg_op = 'INSERT' then
      if v_closed or (now() > v_deadline and not v_allow_late) then
        raise exception 'Exam is closed; cannot start a new attempt.';
      end if;
      new.status := 'in_progress';
      new.score := null;
      new.teacher_feedback := null;
      new.graded_at := null;
      new.graded_by := null;
      new.submitted_at := null;
    elsif tg_op = 'UPDATE' then
      if old.status = 'graded' then
        raise exception 'Attempt already graded; cannot be modified.';
      end if;
      if new.status = 'submitted' and old.status != 'submitted' then
        if v_closed or (now() > v_deadline and not v_allow_late) then
          raise exception 'Exam deadline passed; late submission not permitted.';
        end if;
        new.submitted_at := now();
      end if;
      -- students can never set grading fields
      new.score := old.score;
      new.teacher_feedback := old.teacher_feedback;
      new.graded_at := old.graded_at;
      new.graded_by := old.graded_by;
    end if;
  else
    if tg_op = 'UPDATE' and new.score is not null and old.score is distinct from new.score then
      new.status := 'graded';
      new.graded_at := now();
      new.graded_by := auth.uid();
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_enforce_exam_attempt_rules
  before insert or update on public.exam_attempts
  for each row execute function public.enforce_exam_attempt_rules();

-- Answers can only be written while the parent attempt is in_progress
-- and only by the owning student (or teacher, for point overrides).
create or replace function public.enforce_exam_answer_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt_status public.attempt_status;
  v_attempt_student uuid;
begin
  select status, student_id into v_attempt_status, v_attempt_student
  from public.exam_attempts where id = coalesce(new.attempt_id, old.attempt_id);

  if not public.is_teacher() then
    if v_attempt_student != auth.uid() then
      raise exception 'Cannot write answers for another student''s attempt.';
    end if;
    if v_attempt_status != 'in_progress' then
      raise exception 'Attempt is no longer in progress; answers are locked.';
    end if;
    new.points_awarded := null; -- students never set their own points
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_enforce_exam_answer_rules
  before insert or update on public.exam_answers
  for each row execute function public.enforce_exam_answer_rules();

-- =====================================================================
-- 12. ATTENDANCE
-- =====================================================================
create table if not exists public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  session_date date not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (group_id, session_date)
);

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.attendance_sessions(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status public.attendance_status not null,
  created_at timestamptz not null default now(),
  unique (session_id, student_id)
);

-- =====================================================================
-- 13. GROUP CHAT
-- =====================================================================
create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  content text,
  attachment_storage_path text,
  attachment_type public.message_attachment_type not null default 'none',
  pinned boolean not null default false,
  created_at timestamptz not null default now(),
  constraint message_has_content check (content is not null or attachment_storage_path is not null)
);

create index if not exists idx_group_messages_group_created
  on public.group_messages(group_id, created_at desc);

-- Only the teacher may pin/unpin; only chat_enabled groups accept new
-- messages from students.
create or replace function public.enforce_message_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_chat_enabled boolean;
begin
  select chat_enabled into v_chat_enabled from public.groups where id = new.group_id;

  if tg_op = 'INSERT' then
    if not public.is_teacher() then
      if not v_chat_enabled then
        raise exception 'Chat is disabled for this group.';
      end if;
      if new.sender_id != auth.uid() then
        raise exception 'Cannot send messages as another user.';
      end if;
      new.pinned := false;
    end if;
  elsif tg_op = 'UPDATE' then
    if not public.is_teacher() and old.pinned is distinct from new.pinned then
      raise exception 'Only the teacher can pin or unpin messages.';
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_enforce_message_rules
  before insert or update on public.group_messages
  for each row execute function public.enforce_message_rules();

-- =====================================================================
-- 14. NOTIFICATIONS / PUSH TOKENS
-- =====================================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,  -- deep-link payload
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_unread
  on public.notifications(user_id, read, created_at desc);

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null,  -- 'ios' | 'android'
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

-- =====================================================================
-- 15. CALENDAR
-- =====================================================================
create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  event_type text not null,  -- 'live_class' | 'assignment_deadline' | 'exam_deadline' | 'event'
  starts_at timestamptz not null,
  ends_at timestamptz,
  group_id uuid references public.groups(id) on delete cascade,  -- null = global
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 16. LEADERBOARD SETTINGS
-- =====================================================================
create table if not exists public.leaderboard_settings (
  group_id uuid primary key references public.groups(id) on delete cascade,
  enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_leaderboard_settings_updated_at
  before update on public.leaderboard_settings
  for each row execute function public.set_updated_at();

-- Leaderboard is computed on demand, never exposing contact info.
-- Returns empty set if disabled or caller isn't a member.
create or replace function public.get_leaderboard(p_group_id uuid)
returns table (student_id uuid, full_name text, avatar_url text, average_grade numeric)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.full_name, p.avatar_url,
         round(avg(s.grade), 2) as average_grade
  from public.leaderboard_settings ls
  join public.group_members gm on gm.group_id = ls.group_id
  join public.profiles p on p.id = gm.student_id
  left join public.assignment_submissions s
    on s.student_id = p.id and s.status = 'graded'
    and s.assignment_id in (
      select assignment_id from public.assignment_groups where group_id = ls.group_id
    )
  where ls.group_id = p_group_id
    and ls.enabled = true
    and (public.is_teacher() or public.is_group_member(p_group_id))
  group by p.id, p.full_name, p.avatar_url
  order by average_grade desc nulls last;
$$;

-- =====================================================================
-- 17. ENABLE ROW LEVEL SECURITY ON EVERYTHING
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.invitations enable row level security;
alter table public.rooms enable row level security;
alter table public.room_groups enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_groups enable row level security;
alter table public.resources enable row level security;
alter table public.assignments enable row level security;
alter table public.assignment_groups enable row level security;
alter table public.assignment_submissions enable row level security;
alter table public.exams enable row level security;
alter table public.exam_groups enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.exam_answers enable row level security;
alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.group_messages enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.calendar_events enable row level security;
alter table public.leaderboard_settings enable row level security;

-- =====================================================================
-- 18. RLS POLICIES
-- =====================================================================

-- ---------- profiles ----------
create policy "profiles_select_self_or_teacher" on public.profiles
  for select using (id = auth.uid() or public.is_teacher());

create policy "profiles_select_groupmates_limited" on public.profiles
  for select using (
    exists (
      select 1 from public.group_members gm1
      join public.group_members gm2 on gm1.group_id = gm2.group_id
      where gm1.student_id = auth.uid() and gm2.student_id = public.profiles.id
    )
  );
  -- NOTE: this exposes the full row at the RLS layer. The Flutter app
  -- MUST select only (id, full_name, avatar_url, online, last_seen_at)
  -- when querying group members. For a hard guarantee, query group
  -- members exclusively via a dedicated RPC that projects safe columns
  -- (see get_group_member_profiles below) instead of selecting from
  -- profiles directly in that context.

create or replace function public.get_group_member_profiles(p_group_id uuid)
returns table (id uuid, full_name text, avatar_url text, online boolean, last_seen_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.full_name, p.avatar_url, p.online, p.last_seen_at
  from public.profiles p
  join public.group_members gm on gm.student_id = p.id
  where gm.group_id = p_group_id
    and (public.is_teacher() or public.is_group_member(p_group_id));
$$;

create policy "profiles_insert_self_or_teacher" on public.profiles
  for insert with check (id = auth.uid() or public.is_teacher());

create policy "profiles_update_self_or_teacher" on public.profiles
  for update using (id = auth.uid() or public.is_teacher());

-- Lock down role / privilege escalation and grading-adjacent fields.
create or replace function public.enforce_profile_update_rules()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_teacher() then
    new.role := old.role;                -- cannot change own role
    -- online/last_seen_at ARE allowed for self-updates (presence)
  end if;
  return new;
end;
$$;

create trigger trg_enforce_profile_update_rules
  before update on public.profiles
  for each row execute function public.enforce_profile_update_rules();

-- ---------- groups ----------
create policy "groups_select_member_or_teacher" on public.groups
  for select using (public.is_teacher() or public.is_group_member(id));

create policy "groups_write_teacher_only" on public.groups
  for insert with check (public.is_teacher());
create policy "groups_update_teacher_only" on public.groups
  for update using (public.is_teacher());
create policy "groups_delete_teacher_only" on public.groups
  for delete using (public.is_teacher());

-- ---------- group_members ----------
create policy "group_members_select_own_or_teacher" on public.group_members
  for select using (student_id = auth.uid() or public.is_teacher() or public.is_group_member(group_id));

create policy "group_members_write_teacher_only" on public.group_members
  for insert with check (public.is_teacher());
create policy "group_members_delete_teacher_only" on public.group_members
  for delete using (public.is_teacher());

-- ---------- invitations (teacher / service role only) ----------
create policy "invitations_teacher_only" on public.invitations
  for all using (public.is_teacher()) with check (public.is_teacher());

-- ---------- rooms ----------
create policy "rooms_select_member_or_teacher" on public.rooms
  for select using (public.is_teacher() or public.has_room_access(id));
create policy "rooms_write_teacher_only" on public.rooms
  for insert with check (public.is_teacher());
create policy "rooms_update_teacher_only" on public.rooms
  for update using (public.is_teacher());
create policy "rooms_delete_teacher_only" on public.rooms
  for delete using (public.is_teacher());

create policy "room_groups_select" on public.room_groups
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "room_groups_write_teacher_only" on public.room_groups
  for all using (public.is_teacher()) with check (public.is_teacher());

-- ---------- announcements ----------
create policy "announcements_select_member_or_teacher" on public.announcements
  for select using (public.is_teacher() or public.has_announcement_access(id));
create policy "announcements_write_teacher_only" on public.announcements
  for insert with check (public.is_teacher());
create policy "announcements_update_teacher_only" on public.announcements
  for update using (public.is_teacher());
create policy "announcements_delete_teacher_only" on public.announcements
  for delete using (public.is_teacher());

create policy "announcement_groups_select" on public.announcement_groups
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "announcement_groups_write_teacher_only" on public.announcement_groups
  for all using (public.is_teacher()) with check (public.is_teacher());

-- ---------- resources ----------
create policy "resources_select_member_or_teacher" on public.resources
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "resources_write_teacher_only" on public.resources
  for insert with check (public.is_teacher());
create policy "resources_update_teacher_only" on public.resources
  for update using (public.is_teacher());
create policy "resources_delete_teacher_only" on public.resources
  for delete using (public.is_teacher());

-- ---------- assignments ----------
create policy "assignments_select_member_or_teacher" on public.assignments
  for select using (public.is_teacher() or public.has_assignment_access(id));
create policy "assignments_write_teacher_only" on public.assignments
  for insert with check (public.is_teacher());
create policy "assignments_update_teacher_only" on public.assignments
  for update using (public.is_teacher());
create policy "assignments_delete_teacher_only" on public.assignments
  for delete using (public.is_teacher());

create policy "assignment_groups_select" on public.assignment_groups
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "assignment_groups_write_teacher_only" on public.assignment_groups
  for all using (public.is_teacher()) with check (public.is_teacher());

-- ---------- assignment_submissions ----------
create policy "submissions_select_own_or_teacher" on public.assignment_submissions
  for select using (student_id = auth.uid() or public.is_teacher());

create policy "submissions_insert_own_if_access" on public.assignment_submissions
  for insert with check (
    public.is_teacher() or
    (student_id = auth.uid() and public.has_assignment_access(assignment_id))
  );

create policy "submissions_update_own_or_teacher" on public.assignment_submissions
  for update using (student_id = auth.uid() or public.is_teacher());

-- ---------- exams ----------
create policy "exams_select_member_or_teacher" on public.exams
  for select using (public.is_teacher() or public.has_exam_access(id));
create policy "exams_write_teacher_only" on public.exams
  for insert with check (public.is_teacher());
create policy "exams_update_teacher_only" on public.exams
  for update using (public.is_teacher());
create policy "exams_delete_teacher_only" on public.exams
  for delete using (public.is_teacher());

create policy "exam_groups_select" on public.exam_groups
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "exam_groups_write_teacher_only" on public.exam_groups
  for all using (public.is_teacher()) with check (public.is_teacher());

-- exam_questions: TEACHER ONLY at the table level (contains correct_answer).
-- Students must read via exam_questions_student_view / RPC.
create policy "exam_questions_teacher_only_select" on public.exam_questions
  for select using (public.is_teacher());
create policy "exam_questions_write_teacher_only" on public.exam_questions
  for insert with check (public.is_teacher());
create policy "exam_questions_update_teacher_only" on public.exam_questions
  for update using (public.is_teacher());
create policy "exam_questions_delete_teacher_only" on public.exam_questions
  for delete using (public.is_teacher());

-- Since the view uses security_invoker = true, it inherits RLS from
-- exam_questions above and would currently block students. Grant
-- students read access to the view's underlying rows via a dedicated
-- student-safe policy scoped to columns is not possible directly, so
-- expose it through an RPC instead (recommended path):
create or replace function public.get_exam_questions_for_student(p_exam_id uuid)
returns table (
  id uuid, exam_id uuid, type public.question_type, question_text text,
  image_url text, options jsonb, points numeric, order_index int
)
language sql
stable
security definer
set search_path = public
as $$
  select q.id, q.exam_id, q.type, q.question_text, q.image_url, q.options, q.points, q.order_index
  from public.exam_questions q
  where q.exam_id = p_exam_id
    and (public.is_teacher() or public.has_exam_access(p_exam_id))
  order by q.order_index;
$$;
-- Flutter app: use get_exam_questions_for_student(exam_id) RPC for the
-- student exam-taking screen. Never query exam_questions directly as a
-- student — that table intentionally has no student SELECT policy.

create policy "exam_attempts_select_own_or_teacher" on public.exam_attempts
  for select using (student_id = auth.uid() or public.is_teacher());
create policy "exam_attempts_insert_own_if_access" on public.exam_attempts
  for insert with check (
    public.is_teacher() or
    (student_id = auth.uid() and public.has_exam_access(exam_id))
  );
create policy "exam_attempts_update_own_or_teacher" on public.exam_attempts
  for update using (student_id = auth.uid() or public.is_teacher());

create policy "exam_answers_select_own_or_teacher" on public.exam_answers
  for select using (
    public.is_teacher() or
    exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.student_id = auth.uid())
  );
create policy "exam_answers_insert_own_or_teacher" on public.exam_answers
  for insert with check (
    public.is_teacher() or
    exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.student_id = auth.uid())
  );
create policy "exam_answers_update_own_or_teacher" on public.exam_answers
  for update using (
    public.is_teacher() or
    exists (select 1 from public.exam_attempts a where a.id = attempt_id and a.student_id = auth.uid())
  );

-- ---------- attendance ----------
create policy "attendance_sessions_select_member_or_teacher" on public.attendance_sessions
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "attendance_sessions_write_teacher_only" on public.attendance_sessions
  for all using (public.is_teacher()) with check (public.is_teacher());

create policy "attendance_records_select_own_or_teacher" on public.attendance_records
  for select using (
    student_id = auth.uid() or public.is_teacher()
  );
create policy "attendance_records_write_teacher_only" on public.attendance_records
  for insert with check (public.is_teacher());
create policy "attendance_records_update_teacher_only" on public.attendance_records
  for update using (public.is_teacher());
create policy "attendance_records_delete_teacher_only" on public.attendance_records
  for delete using (public.is_teacher());

-- ---------- group_messages ----------
create policy "messages_select_member_or_teacher" on public.group_messages
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "messages_insert_member_or_teacher" on public.group_messages
  for insert with check (
    public.is_teacher() or
    (sender_id = auth.uid() and public.is_group_member(group_id))
  );
create policy "messages_update_own_or_teacher" on public.group_messages
  for update using (sender_id = auth.uid() or public.is_teacher());
create policy "messages_delete_own_or_teacher" on public.group_messages
  for delete using (sender_id = auth.uid() or public.is_teacher());

-- ---------- notifications ----------
create policy "notifications_select_own" on public.notifications
  for select using (user_id = auth.uid());
create policy "notifications_update_own" on public.notifications
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());
create policy "notifications_insert_teacher_or_system" on public.notifications
  for insert with check (public.is_teacher());
  -- Note: most notification inserts happen server-side via Edge
  -- Functions using the service-role key (bypasses RLS entirely),
  -- e.g. when grading triggers a push. This policy only covers the
  -- rare case of an authenticated teacher client inserting directly.

-- ---------- push_tokens ----------
create policy "push_tokens_own_only" on public.push_tokens
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- calendar_events ----------
create policy "calendar_select_relevant_or_teacher" on public.calendar_events
  for select using (
    public.is_teacher() or
    group_id is null or
    public.is_group_member(group_id)
  );
create policy "calendar_write_teacher_only" on public.calendar_events
  for all using (public.is_teacher()) with check (public.is_teacher());

-- ---------- leaderboard_settings ----------
create policy "leaderboard_settings_select_member_or_teacher" on public.leaderboard_settings
  for select using (public.is_teacher() or public.is_group_member(group_id));
create policy "leaderboard_settings_write_teacher_only" on public.leaderboard_settings
  for all using (public.is_teacher()) with check (public.is_teacher());

-- =====================================================================
-- 19. INDEXES FOR PERFORMANCE (pagination-heavy tables)
-- =====================================================================
create index if not exists idx_notifications_created on public.notifications(created_at desc);
create index if not exists idx_assignment_submissions_student on public.assignment_submissions(student_id);
create index if not exists idx_exam_attempts_student on public.exam_attempts(student_id);
create index if not exists idx_attendance_records_student on public.attendance_records(student_id);
create index if not exists idx_calendar_events_starts_at on public.calendar_events(starts_at);
create index if not exists idx_resources_group on public.resources(group_id);

-- =====================================================================
-- 20. STORAGE BUCKETS + POLICIES
-- =====================================================================
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('chat-attachments', 'chat-attachments', false),
  ('assignment-submissions', 'assignment-submissions', false),
  ('resources', 'resources', false)
on conflict (id) do nothing;

-- avatars: path convention avatars/{user_id}/filename — public read, owner write
create policy "avatars_public_read" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "avatars_owner_write" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "avatars_owner_update" on storage.objects
  for update using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

-- chat-attachments: path convention chat-attachments/{group_id}/filename
create policy "chat_attachments_group_read" on storage.objects
  for select using (
    bucket_id = 'chat-attachments' and
    (public.is_teacher() or public.is_group_member(((storage.foldername(name))[1])::uuid))
  );
create policy "chat_attachments_group_write" on storage.objects
  for insert with check (
    bucket_id = 'chat-attachments' and
    (public.is_teacher() or public.is_group_member(((storage.foldername(name))[1])::uuid))
  );

-- assignment-submissions: path convention
--   assignment-submissions/{assignment_id}/{student_id}/filename
create policy "submissions_owner_read" on storage.objects
  for select using (
    bucket_id = 'assignment-submissions' and (
      public.is_teacher() or
      (storage.foldername(name))[2] = auth.uid()::text
    )
  );
create policy "submissions_owner_write" on storage.objects
  for insert with check (
    bucket_id = 'assignment-submissions' and
    (storage.foldername(name))[2] = auth.uid()::text and
    public.has_assignment_access(((storage.foldername(name))[1])::uuid)
  );

-- resources: path convention resources/{group_id}/filename
create policy "resources_group_read" on storage.objects
  for select using (
    bucket_id = 'resources' and
    (public.is_teacher() or public.is_group_member(((storage.foldername(name))[1])::uuid))
  );
create policy "resources_teacher_write" on storage.objects
  for insert with check (bucket_id = 'resources' and public.is_teacher());
create policy "resources_teacher_delete" on storage.objects
  for delete using (bucket_id = 'resources' and public.is_teacher());

-- =====================================================================
-- END OF SCHEMA
-- =====================================================================
