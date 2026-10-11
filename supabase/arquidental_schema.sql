-- EL ARQUI Dental: esquema inicial Supabase
-- Ejecutar en Supabase > SQL Editor SOLO en un proyecto nuevo dedicado a este consultorio.
create extension if not exists pgcrypto;

create table if not exists public.dental_clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.dental_clinic_members (
  clinic_id uuid not null references public.dental_clinics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','dentist','assistant')),
  created_at timestamptz not null default now(),
  primary key (clinic_id,user_id)
);

create table if not exists public.dental_followups (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.dental_clinics(id) on delete cascade,
  patient_code text not null,
  contact_phone text,
  consent_verified boolean not null default false,
  status text not null check (status in ('Pendiente','Contactado','Cita coordinada','Asistió','No contactar')),
  next_step text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (clinic_id, patient_code)
);

create or replace function public.is_dental_clinic_member(target_clinic uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (
  select 1 from public.dental_clinic_members m
  where m.clinic_id = target_clinic and m.user_id = auth.uid()
); $$;

alter table public.dental_clinics enable row level security;
alter table public.dental_clinic_members enable row level security;
alter table public.dental_followups enable row level security;

drop policy if exists "members can view their clinics" on public.dental_clinics;
create policy "members can view their clinics" on public.dental_clinics
for select to authenticated using (public.is_dental_clinic_member(id));

drop policy if exists "members can view clinic membership" on public.dental_clinic_members;
create policy "members can view clinic membership" on public.dental_clinic_members
for select to authenticated using (public.is_dental_clinic_member(clinic_id));

drop policy if exists "members can read followups" on public.dental_followups;
create policy "members can read followups" on public.dental_followups
for select to authenticated using (public.is_dental_clinic_member(clinic_id));

drop policy if exists "members can add followups" on public.dental_followups;
create policy "members can add followups" on public.dental_followups
for insert to authenticated with check (
  public.is_dental_clinic_member(clinic_id) and created_by = auth.uid()
);

drop policy if exists "members can update followups" on public.dental_followups;
create policy "members can update followups" on public.dental_followups
for update to authenticated using (public.is_dental_clinic_member(clinic_id))
with check (public.is_dental_clinic_member(clinic_id));

drop policy if exists "owners can delete followups" on public.dental_followups;
create policy "owners can delete followups" on public.dental_followups
for delete to authenticated using (exists (
  select 1 from public.dental_clinic_members m
  where m.clinic_id = dental_followups.clinic_id and m.user_id = auth.uid() and m.role = 'owner'
));

-- CONFIGURACIÓN MANUAL OBLIGATORIA:
-- 1) Crear cuentas desde Supabase Authentication > Users (no habilitar registro público).
-- 2) Crear clínica y agregar odontóloga como owner usando el UUID de su cuenta:
-- insert into public.dental_clinics (name) values ('Consultorio piloto') returning id;
-- insert into public.dental_clinic_members (clinic_id,user_id,role)
-- values ('UUID_CLINICA','UUID_USUARIA_ODONTOLOGA','owner');
-- 3) Crear/invitar la cuenta individual de la asistente y agregarla:
-- insert into public.dental_clinic_members (clinic_id,user_id,role)
-- values ('UUID_CLINICA','UUID_CUENTA_ASISTENTE','assistant');
-- 4) Antes de uso real, añadir clinic_id en el formulario y en consultas/inserciones.
-- La app no debe usarse con datos reales hasta completar ese cambio y probar separación de datos.
