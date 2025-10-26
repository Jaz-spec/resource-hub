-- Migration: Flexible labeling system with types
-- This migration creates the label system with customizable label types

-- Create label types table (categories of labels)
create table public.label_types (
    id bigint generated always as identity primary key,
    name text not null unique,
    description text,
    icon text, -- optional icon identifier
    color text, -- optional hex color for UI
    display_order integer default 0,

    -- Control how labels of this type behave
    allow_multiple boolean default false, -- can a resource have multiple labels of this type?
    is_required boolean default false, -- must resources have at least one label of this type?

    -- Metadata
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    created_by uuid not null references public.profiles(id) on delete restrict
);

-- Create labels table
create table public.labels (
    id bigint generated always as identity primary key,
    label_type_id bigint not null references public.label_types(id) on delete cascade,
    name text not null,
    value text not null, -- internal value
    description text,
    icon text, -- optional icon identifier
    color text, -- optional hex color for UI
    display_order integer default 0,

    -- Metadata
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    created_by uuid not null references public.profiles(id) on delete restrict,

    -- Ensure unique label values within a type
    unique(label_type_id, value)
);

-- Define which label types are available for which categories
create table public.category_label_types (
    id bigint generated always as identity primary key,
    category_id bigint not null references public.categories(id) on delete cascade,
    label_type_id bigint not null references public.label_types(id) on delete cascade,
    is_required boolean default false, -- override label_type's is_required for this category

    -- Metadata
    created_at timestamp with time zone default now(),
    created_by uuid not null references public.profiles(id) on delete restrict,

    -- Ensure unique combination
    unique(category_id, label_type_id)
);

-- Many-to-many table for resource labels
create table public.resource_labels (
    id bigint generated always as identity primary key,
    resource_id bigint not null references public.resources(id) on delete cascade,
    label_id bigint not null references public.labels(id) on delete cascade,

    -- Metadata
    assigned_at timestamp with time zone default now(),
    assigned_by uuid references public.profiles(id) on delete set null,

    -- Ensure unique combination
    unique(resource_id, label_id)
);

-- Create a view to easily see which labels are valid for a resource based on its categories
create or replace view public.valid_resource_labels as
select distinct
    r.id as resource_id,
    l.id as label_id,
    l.name as label_name,
    l.value as label_value,
    lt.id as label_type_id,
    lt.name as label_type_name,
    lt.allow_multiple,
    clt.is_required
from public.resources r
inner join public.resource_categories rc on r.id = rc.resource_id
inner join public.category_label_types clt on rc.category_id = clt.category_id
inner join public.label_types lt on clt.label_type_id = lt.id
inner join public.labels l on lt.id = l.label_type_id;

-- Create function to validate that a resource only has labels approved for its categories
create or replace function public.validate_resource_label()
returns trigger as $$
begin
    -- Check if this label is valid for this resource based on its categories
    if not exists (
        select 1
        from public.valid_resource_labels vrl
        where vrl.resource_id = new.resource_id
        and vrl.label_id = new.label_id
    ) then
        raise exception 'Label % is not valid for resource % based on its categories',
            new.label_id, new.resource_id;
    end if;

    -- Check if multiple labels of this type are allowed
    if not exists (
        select 1
        from public.labels l
        inner join public.label_types lt on l.label_type_id = lt.id
        where l.id = new.label_id
        and lt.allow_multiple = true
    ) then
        -- Check if resource already has a label of this type
        if exists (
            select 1
            from public.resource_labels rl
            inner join public.labels l on rl.label_id = l.id
            inner join public.labels new_label on new_label.id = new.label_id
            where rl.resource_id = new.resource_id
            and l.label_type_id = new_label.label_type_id
            and rl.id != coalesce(new.id, 0)
        ) then
            raise exception 'Resource already has a label of this type and multiple labels are not allowed';
        end if;
    end if;

    return new;
end;
$$ language plpgsql;

-- Add trigger to validate resource labels
create trigger validate_resource_label_assignment
    before insert or update on public.resource_labels
    for each row
    execute function public.validate_resource_label();

-- Create function to check required labels when a resource is published
create or replace function public.check_required_labels()
returns trigger as $$
begin
    -- Only check when resource is being published (has categories)
    if exists (select 1 from public.resource_categories where resource_id = new.id) then
        -- Check if all required label types have at least one label assigned
        if exists (
            select 1
            from public.resource_categories rc
            inner join public.category_label_types clt on rc.category_id = clt.category_id
            inner join public.label_types lt on clt.label_type_id = lt.id
            where rc.resource_id = new.id
            and (clt.is_required = true or lt.is_required = true)
            and not exists (
                select 1
                from public.resource_labels rl
                inner join public.labels l on rl.label_id = l.id
                where rl.resource_id = new.id
                and l.label_type_id = lt.id
            )
        ) then
            raise exception 'Resource is missing required labels';
        end if;
    end if;

    return new;
end;
$$ language plpgsql;

-- Add trigger to check required labels (optional - you may want to enforce this only in application logic)
-- create trigger check_resource_required_labels
--     before update on public.resources
--     for each row
--     when (new.published_at is not null)
--     execute function public.check_required_labels();

-- Create indexes for better query performance
create index idx_labels_label_type_id on public.labels(label_type_id);
create index idx_category_label_types_category_id on public.category_label_types(category_id);
create index idx_category_label_types_label_type_id on public.category_label_types(label_type_id);
create index idx_resource_labels_resource_id on public.resource_labels(resource_id);
create index idx_resource_labels_label_id on public.resource_labels(label_id);

-- Enable RLS
alter table public.label_types enable row level security;
alter table public.labels enable row level security;
alter table public.category_label_types enable row level security;
alter table public.resource_labels enable row level security;

-- RLS Policies
-- Label types policies
create policy "admins can manage label types"
    on public.label_types
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view label types"
    on public.label_types
    for select
    to authenticated
    using (true);

-- Labels policies
create policy "admins can manage labels"
    on public.labels
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view labels"
    on public.labels
    for select
    to authenticated
    using (true);

-- Category label types policies
create policy "admins can manage category label types"
    on public.category_label_types
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view category label types"
    on public.category_label_types
    for select
    to authenticated
    using (true);

-- Resource labels policies
create policy "admins can manage resource labels"
    on public.resource_labels
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view resource labels"
    on public.resource_labels
    for select
    to authenticated
    using (true);

-- Add updated_at triggers
create trigger update_label_types_updated_at
    before update on public.label_types
    for each row
    execute function public.update_updated_at_column();

create trigger update_labels_updated_at
    before update on public.labels
    for each row
    execute function public.update_updated_at_column();

-- Insert some example label types and labels (can be removed in production)
-- These are just examples - admins can create their own
insert into public.label_types (name, description, allow_multiple, display_order, created_by)
select
    'Difficulty Level',
    'The difficulty level of the resource',
    false,
    1,
    (select id from public.profiles where role = 'admin' limit 1)
where exists (select 1 from public.profiles where role = 'admin');

insert into public.label_types (name, description, allow_multiple, display_order, created_by)
select
    'Resource Format',
    'The format or medium of the resource',
    true,
    2,
    (select id from public.profiles where role = 'admin' limit 1)
where exists (select 1 from public.profiles where role = 'admin');

insert into public.label_types (name, description, allow_multiple, display_order, created_by)
select
    'Duration',
    'Estimated time to complete',
    false,
    3,
    (select id from public.profiles where role = 'admin' limit 1)
where exists (select 1 from public.profiles where role = 'admin');

-- Add example labels (only if label types were created)
insert into public.labels (label_type_id, name, value, display_order, created_by)
select
    lt.id,
    'Beginner',
    'beginner',
    1,
    (select id from public.profiles where role = 'admin' limit 1)
from public.label_types lt
where lt.name = 'Difficulty Level'
and exists (select 1 from public.profiles where role = 'admin');

insert into public.labels (label_type_id, name, value, display_order, created_by)
select
    lt.id,
    'Intermediate',
    'intermediate',
    2,
    (select id from public.profiles where role = 'admin' limit 1)
from public.label_types lt
where lt.name = 'Difficulty Level'
and exists (select 1 from public.profiles where role = 'admin');

insert into public.labels (label_type_id, name, value, display_order, created_by)
select
    lt.id,
    'Advanced',
    'advanced',
    3,
    (select id from public.profiles where role = 'admin' limit 1)
from public.label_types lt
where lt.name = 'Difficulty Level'
and exists (select 1 from public.profiles where role = 'admin');
