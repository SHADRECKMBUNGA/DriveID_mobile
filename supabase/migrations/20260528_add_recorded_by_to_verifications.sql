begin;

alter table if exists public.verifications
  add column if not exists recorded_by text;

create index if not exists verifications_recorded_by_idx
  on public.verifications (recorded_by);

commit;
