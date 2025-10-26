-- Migration: Core resource structure with files and links
-- This migration creates the main resource tables and file storage structure

-- Drop existing tables if we're restructuring (remove this section if keeping existing data)
drop table if exists cat_res cascade;
drop table if exists resources cascade;
drop table if exists categories cascade;

-- Recreate categories table with additional metadata
create table public.categories (
    id bigint generated always as identity primary key,
    name text not null,
    description text,
    icon text, -- optional icon identifier
    color text, -- optional hex color for UI
    display_order integer default 0,
    parent_fk bigint references public.categories(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    created_by uuid references public.profiles(id) on delete set null,

    -- Ensure unique names at the same level
    unique(name, parent_fk)
);

-- Create main resources table
create table public.resources (
    id bigint generated always as identity primary key,
    title text not null,
    description text,
    short_description text, -- for cards/previews
    slug text unique, -- URL-friendly identifier
    thumbnail_url text, -- optional thumbnail image
    is_featured boolean default false,
    display_order integer default 0,

    -- Metadata
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    published_at timestamp with time zone default now(),
    created_by uuid not null references public.profiles(id) on delete restrict,
    last_modified_by uuid references public.profiles(id) on delete set null,

    -- For soft deletes if needed in future
    deleted_at timestamp with time zone,

    -- Add index for slug lookups
    constraint valid_slug check (slug ~ '^[a-z0-9-]+$')
);

-- Create resource files table for storing different format files
create table public.resource_files (
    id bigint generated always as identity primary key,
    resource_id bigint not null references public.resources(id) on delete cascade,
    file_type text not null check (file_type in ('pdf', 'pptx', 'ppt', 'docx', 'doc', 'xlsx', 'xls', 'other')),
    file_name text not null,
    original_name text not null, -- preserve original filename
    storage_path text not null, -- path in Supabase storage
    file_size_bytes bigint,
    mime_type text,

    -- Metadata
    display_order integer default 0, -- for ordering multiple files of same type
    is_primary boolean default false, -- mark primary version if multiple
    uploaded_at timestamp with time zone default now(),
    uploaded_by uuid not null references public.profiles(id) on delete restrict
);

-- Ensure one primary file per type per resource
create unique index resource_files_one_primary_per_type_per_resource_idx on public.resource_files(resource_id, file_type) where is_primary = true;

-- Create resource links table for external URLs
create table public.resource_links (
    id bigint generated always as identity primary key,
    resource_id bigint not null references public.resources(id) on delete cascade,
    link_type text not null default 'external', -- external, video, documentation, source, etc.
    url text not null,
    title text,
    description text,
    display_order integer default 0,

    -- Metadata
    created_at timestamp with time zone default now(),
    created_by uuid not null references public.profiles(id) on delete restrict,

    -- Basic URL validation
    constraint valid_url check (url ~ '^https?://')
);

-- Create many-to-many table for resource categories
create table public.resource_categories (
    id bigint generated always as identity primary key,
    resource_id bigint not null references public.resources(id) on delete cascade,
    category_id bigint not null references public.categories(id) on delete cascade,
    is_primary boolean default false, -- mark primary category

    -- Metadata
    assigned_at timestamp with time zone default now(),
    assigned_by uuid references public.profiles(id) on delete set null,

    -- Ensure unique combination and only one primary per resource
    unique(resource_id, category_id)
);

-- Ensure only one primary per resource
create unique index resource_categories_one_primary_per_resource_idx on public.resource_categories(resource_id) where is_primary = true;

-- Create indexes for better query performance
create index idx_resources_created_at on public.resources(created_at desc);
create index idx_resources_published_at on public.resources(published_at desc) where deleted_at is null;
create index idx_resources_created_by on public.resources(created_by);
create index idx_resources_slug on public.resources(slug);
create index idx_resource_files_resource_id on public.resource_files(resource_id);
create index idx_resource_files_file_type on public.resource_files(file_type);
create index idx_resource_links_resource_id on public.resource_links(resource_id);
create index idx_resource_categories_resource_id on public.resource_categories(resource_id);
create index idx_resource_categories_category_id on public.resource_categories(category_id);
create index idx_categories_parent_fk on public.categories(parent_fk);

-- Enable RLS
alter table public.categories enable row level security;
alter table public.resources enable row level security;
alter table public.resource_files enable row level security;
alter table public.resource_links enable row level security;
alter table public.resource_categories enable row level security;

-- RLS Policies for admin-only access (for now)
-- Categories policies
create policy "admins can manage categories"
    on public.categories
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view categories"
    on public.categories
    for select
    to authenticated
    using (true);

-- Resources policies
create policy "admins can manage resources"
    on public.resources
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view published resources"
    on public.resources
    for select
    to authenticated
    using (deleted_at is null);

-- Resource files policies
create policy "admins can manage resource files"
    on public.resource_files
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view resource files"
    on public.resource_files
    for select
    to authenticated
    using (true);

-- Resource links policies
create policy "admins can manage resource links"
    on public.resource_links
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view resource links"
    on public.resource_links
    for select
    to authenticated
    using (true);

-- Resource categories policies
create policy "admins can manage resource categories"
    on public.resource_categories
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view resource categories"
    on public.resource_categories
    for select
    to authenticated
    using (true);

-- Create updated_at trigger function if not exists
create or replace function public.update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Add updated_at triggers
create trigger update_categories_updated_at
    before update on public.categories
    for each row
    execute function public.update_updated_at_column();

create trigger update_resources_updated_at
    before update on public.resources
    for each row
    execute function public.update_updated_at_column();

-- Create function to auto-generate slug from title
create or replace function public.generate_slug_from_title()
returns trigger as $$
begin
    if new.slug is null or new.slug = '' then
        new.slug = lower(
            regexp_replace(
                regexp_replace(
                    regexp_replace(
                        new.title,
                        '[^a-zA-Z0-9\s-]', '', 'g'  -- Remove special characters
                    ),
                    '\s+', '-', 'g'  -- Replace spaces with hyphens
                ),
                '-+', '-', 'g'  -- Replace multiple hyphens with single
            )
        );

        -- Add timestamp if slug already exists
        if exists (select 1 from public.resources where slug = new.slug and id != coalesce(new.id, 0)) then
            new.slug = new.slug || '-' || extract(epoch from now())::integer;
        end if;
    end if;
    return new;
end;
$$ language plpgsql;

-- Add trigger to auto-generate slugs
create trigger generate_resource_slug
    before insert or update on public.resources
    for each row
    execute function public.generate_slug_from_title();

-- Create Supabase storage bucket for resources
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'resources',
    'resources',
    false, -- private bucket, access through RLS
    52428800, -- 50MB limit
    array[
        'application/pdf',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
) on conflict (id) do nothing;

-- Storage policies for the resources bucket
create policy "Admins can upload resource files"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'resources' and
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "Admins can update resource files"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'resources' and
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "Admins can delete resource files"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'resources' and
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "Authenticated users can view resource files"
    on storage.objects
    for select
    to authenticated
    using (bucket_id = 'resources');
