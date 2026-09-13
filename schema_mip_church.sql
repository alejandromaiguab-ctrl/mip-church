-- ============================================================
-- MIP Church — Schema inicial do sistema de gestão
-- Estrutura inferida a partir do código front-end do app,
-- já adaptada + módulo novo de GPS Precursores.
-- Rode este script no SQL Editor do NOVO projeto Supabase do MIP Church.
-- ============================================================

-- Extensão para gen_random_uuid()
create extension if not exists pgcrypto;

-- ============================================================
-- PERFIS (usuários do sistema — ligado ao auth.users)
-- ============================================================
create table if not exists perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  email text,
  role text not null default 'recepcao', -- admin | coordenador | lideranca | recepcao | bistro | midia | financeiro
  foto_url text,
  created_at timestamptz default now()
);

-- ============================================================
-- CULTOS
-- ============================================================
create table if not exists cultos (
  id uuid primary key default gen_random_uuid(),
  data date not null,
  tema text,
  pregador text,
  created_at timestamptz default now()
);

-- ============================================================
-- VOLUNTÁRIOS
-- ============================================================
create table if not exists voluntarios (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  telefone text,
  email text,
  instagram text,
  departamento text,
  funcao text,
  data_nascimento date,
  data_entrada date,
  observacoes text,
  foto_url text,
  ativo boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- ESCALAS (voluntário ou convidado escalado em um culto)
-- ============================================================
create table if not exists escalas (
  id uuid primary key default gen_random_uuid(),
  culto_id uuid references cultos(id) on delete cascade,
  voluntario_id uuid references voluntarios(id) on delete set null,
  convidado_nome text,
  departamento text,
  funcao text,
  slot_numero int,
  compareceu boolean,
  created_at timestamptz default now()
);

-- ============================================================
-- VISITANTES
-- ============================================================
create table if not exists visitantes (
  id uuid primary key default gen_random_uuid(),
  culto_id uuid references cultos(id) on delete set null,
  nome text not null,
  telefone text,
  data_nascimento date,
  endereco text,
  instagram text,
  como_conheceu text,
  segunda_visita boolean default false,
  observacoes text,
  foto_url text,
  created_at timestamptz default now()
);

-- ============================================================
-- MEMBROS (visitante promovido a membro)
-- ============================================================
create table if not exists membros (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  telefone text,
  email text,
  instagram text,
  endereco text,
  data_nascimento date,
  data_membro date,
  observacoes text,
  foto_url text,
  visitante_id uuid references visitantes(id) on delete set null,
  voluntario_id uuid references voluntarios(id) on delete set null,
  status text default 'ativo', -- ativo | inativo
  created_at timestamptz default now()
);

-- ============================================================
-- DECISÕES (salvação / reconciliação / batismo, ligadas a um culto)
-- ============================================================
create table if not exists decisoes (
  id uuid primary key default gen_random_uuid(),
  culto_id uuid references cultos(id) on delete set null,
  nome text,
  telefone text,
  tipo text, -- salvacao | reconciliacao | batismo
  data date,
  observacoes text,
  created_at timestamptz default now()
);

-- ============================================================
-- RELATÓRIOS (por culto, um registro por departamento: recepcao,
-- bistro, financeiro, lideranca, midia, ordem_culto)
-- ============================================================
create table if not exists relatorios (
  id uuid primary key default gen_random_uuid(),
  culto_id uuid references cultos(id) on delete cascade,
  tipo text not null,
  dados jsonb not null default '{}',
  created_at timestamptz default now()
);

-- ============================================================
-- FINANCEIRO
-- ============================================================
create table if not exists financeiro (
  id uuid primary key default gen_random_uuid(),
  mes_ref text, -- 'YYYY-MM'
  data date not null,
  descricao text,
  tipo text not null, -- entrada | saida
  categoria text,
  valor numeric(12,2) not null,
  observacoes text,
  created_by uuid references perfis(id) on delete set null,
  created_at timestamptz default now()
);

-- ============================================================
-- EVENTOS (vigílias, retiros, eventos especiais)
-- ============================================================
create table if not exists eventos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  tipo text,
  data_inicio date,
  local text,
  responsavel text,
  descricao text,
  created_at timestamptz default now()
);

-- ============================================================
-- AVISOS (mural/dashboard)
-- ============================================================
create table if not exists avisos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  mensagem text,
  autor_id uuid references perfis(id) on delete set null,
  autor_nome text,
  ativo boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- MÓDULO NOVO — GPS PRECURSORES (MIP Church)
-- Ciclo de 16 semanas: Conversão do Amigo -> Consolidação -> Discipulado
-- Papéis por grupo: Líder, Anfitrião, Professor de Crianças
-- Nomenclatura: Felipes (batizados servindo), Etíopes (em progresso),
-- Amigos (ainda não estão no grupo)
-- ============================================================
create table if not exists gps_grupos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  lider_id uuid references voluntarios(id) on delete set null,
  anfitriao_id uuid references voluntarios(id) on delete set null,
  professor_criancas_id uuid references voluntarios(id) on delete set null,
  endereco text,
  dia_semana text,
  horario text,
  data_inicio_ciclo date,
  semana_atual int default 1, -- 1 a 16
  ativo boolean default true,
  created_at timestamptz default now()
);

create table if not exists gps_participantes (
  id uuid primary key default gen_random_uuid(),
  grupo_id uuid references gps_grupos(id) on delete cascade,
  nome text not null,
  telefone text,
  categoria text default 'amigo', -- amigo | etiope | felipe
  data_entrada date,
  observacoes text,
  created_at timestamptz default now()
);

create table if not exists gps_relatorios_semanais (
  id uuid primary key default gen_random_uuid(),
  grupo_id uuid references gps_grupos(id) on delete cascade,
  semana int not null, -- 1 a 16
  data date,
  presentes int default 0,
  ausentes int default 0,
  visitantes int default 0,
  motivo_ausencias text, -- pastoral care, não cobrança
  observacoes text,
  created_by uuid references perfis(id) on delete set null,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- Padrão: autenticados podem ler tudo; escrita controlada por role
-- em perfis (ajuste fino via app).
-- ============================================================
alter table perfis enable row level security;
alter table cultos enable row level security;
alter table voluntarios enable row level security;
alter table escalas enable row level security;
alter table visitantes enable row level security;
alter table membros enable row level security;
alter table decisoes enable row level security;
alter table relatorios enable row level security;
alter table financeiro enable row level security;
alter table eventos enable row level security;
alter table avisos enable row level security;
alter table gps_grupos enable row level security;
alter table gps_participantes enable row level security;
alter table gps_relatorios_semanais enable row level security;

-- Leitura liberada para qualquer usuário autenticado (ajustar por tabela se precisar restringir mais)
drop policy if exists "read_auth" on perfis;
create policy "read_auth" on perfis for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on cultos;
create policy "read_auth" on cultos for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on voluntarios;
create policy "read_auth" on voluntarios for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on escalas;
create policy "read_auth" on escalas for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on visitantes;
create policy "read_auth" on visitantes for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on membros;
create policy "read_auth" on membros for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on decisoes;
create policy "read_auth" on decisoes for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on relatorios;
create policy "read_auth" on relatorios for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on financeiro;
create policy "read_auth" on financeiro for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on eventos;
create policy "read_auth" on eventos for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on avisos;
create policy "read_auth" on avisos for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on gps_grupos;
create policy "read_auth" on gps_grupos for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on gps_participantes;
create policy "read_auth" on gps_participantes for select using (auth.role() = 'authenticated');

drop policy if exists "read_auth" on gps_relatorios_semanais;
create policy "read_auth" on gps_relatorios_semanais for select using (auth.role() = 'authenticated');

-- Escrita liberada para qualquer autenticado nesta v1 (o app já controla por role na UI;
-- pode ser refinado depois com checagem de perfis.role por tabela)
drop policy if exists "write_auth" on cultos;
create policy "write_auth" on cultos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on voluntarios;
create policy "write_auth" on voluntarios for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on escalas;
create policy "write_auth" on escalas for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on visitantes;
create policy "write_auth" on visitantes for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on membros;
create policy "write_auth" on membros for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on decisoes;
create policy "write_auth" on decisoes for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on relatorios;
create policy "write_auth" on relatorios for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on financeiro;
create policy "write_auth" on financeiro for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on eventos;
create policy "write_auth" on eventos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on avisos;
create policy "write_auth" on avisos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on gps_grupos;
create policy "write_auth" on gps_grupos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on gps_participantes;
create policy "write_auth" on gps_participantes for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "write_auth" on gps_relatorios_semanais;
create policy "write_auth" on gps_relatorios_semanais for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- perfis: cada um só edita o próprio (foto etc.); admin edita geral via app com service checks futuros
drop policy if exists "update_own_perfil" on perfis;
create policy "update_own_perfil" on perfis for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "insert_own_perfil" on perfis;
create policy "insert_own_perfil" on perfis for insert with check (auth.uid() = id);

-- ============================================================
-- STORAGE — bucket de fotos (perfis, voluntários, visitantes)
-- ============================================================
insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do nothing;

drop policy if exists "fotos_select_public" on storage.objects;
create policy "fotos_select_public" on storage.objects for select using (bucket_id = 'fotos');

drop policy if exists "fotos_insert_auth" on storage.objects;
create policy "fotos_insert_auth" on storage.objects for insert with check (bucket_id = 'fotos' and auth.role() = 'authenticated');

drop policy if exists "fotos_update_auth" on storage.objects;
create policy "fotos_update_auth" on storage.objects for update using (bucket_id = 'fotos' and auth.role() = 'authenticated');

drop policy if exists "fotos_delete_auth" on storage.objects;
create policy "fotos_delete_auth" on storage.objects for delete using (bucket_id = 'fotos' and auth.role() = 'authenticated');

-- ============================================================
-- Fim do schema inicial
-- ============================================================
