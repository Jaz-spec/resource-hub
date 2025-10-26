-- Migration: Courses and Analytics
-- This migration creates the course system and anonymous analytics tracking

-- Create courses table
create table public.courses (
    id bigint generated always as identity primary key,
    title text not null,
    slug text unique,
    description text,
    short_description text,
    thumbnail_url text,

    -- Course metadata (expandable in future)
    estimated_hours decimal(5,2),
    difficulty_level text,
    prerequisites text,
    learning_outcomes text[], -- array of learning outcomes

    -- Status and visibility
    is_published boolean default false,
    is_featured boolean default false,
    display_order integer default 0,

    -- Metadata
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    published_at timestamp with time zone,
    created_by uuid not null references public.profiles(id) on delete restrict,
    last_modified_by uuid references public.profiles(id) on delete set null,

    -- For soft deletes if needed
    deleted_at timestamp with time zone,

    -- Slug validation
    constraint valid_course_slug check (slug ~ '^[a-z0-9-]+$')
);

-- Create course resources junction table with ordering
create table public.course_resources (
    id bigint generated always as identity primary key,
    course_id bigint not null references public.courses(id) on delete cascade,
    resource_id bigint not null references public.resources(id) on delete cascade,
    position integer not null, -- ordering within the course

    -- Optional section grouping
    section_number integer default 1,
    section_title text,

    -- Optional per-resource notes for this course
    notes text,
    is_optional boolean default false,

    -- Metadata
    added_at timestamp with time zone default now(),
    added_by uuid not null references public.profiles(id) on delete restrict,

    -- Ensure unique combination and position
    unique(course_id, resource_id),
    unique(course_id, position)
);

-- Create anonymous resource analytics table
create table public.resource_analytics (
    id bigint generated always as identity primary key,
    resource_id bigint not null references public.resources(id) on delete cascade,

    -- Session tracking (anonymous)
    session_id uuid not null default gen_random_uuid(), -- anonymous session identifier
    ip_hash text, -- hashed IP for unique visitor counting (optional)
    user_agent text, -- for device type analysis
    referrer text, -- where the user came from

    -- View tracking
    view_started_at timestamp with time zone default now(),
    view_ended_at timestamp with time zone,
    duration_seconds integer, -- calculated from start/end or javascript timer

    -- Interaction tracking
    interaction_type text default 'view', -- view, download, link_click, etc.
    file_type_accessed text, -- which file type was accessed (pdf, pptx, etc.)
    completion_percentage integer, -- if trackable (0-100)

    -- Context
    accessed_from_course_id bigint references public.courses(id) on delete set null,
    device_type text, -- mobile, tablet, desktop (derived from user_agent)
    browser text, -- derived from user_agent

    -- Geographic (optional, requires IP lookup)
    country_code text,
    region text,

    -- Index for queries
    created_at timestamp with time zone default now()
);

-- Create aggregated analytics view for easy reporting
create or replace view public.resource_analytics_summary as
select
    r.id as resource_id,
    r.title as resource_title,
    count(distinct ra.session_id) as total_unique_views,
    count(*) as total_views,
    avg(ra.duration_seconds)::integer as avg_duration_seconds,
    sum(ra.duration_seconds) as total_duration_seconds,
    max(ra.created_at) as last_viewed_at,
    count(distinct date(ra.created_at)) as days_with_views,
    count(case when ra.interaction_type = 'download' then 1 end) as total_downloads,
    count(distinct ra.accessed_from_course_id) as accessed_from_courses_count
from public.resources r
left join public.resource_analytics ra on r.id = ra.resource_id
group by r.id, r.title;

-- Create function to track resource view
create or replace function public.track_resource_view(
    p_resource_id bigint,
    p_session_id uuid default null,
    p_interaction_type text default 'view',
    p_file_type text default null,
    p_course_id bigint default null,
    p_user_agent text default null,
    p_referrer text default null
)
returns uuid as $$
declare
    v_session_id uuid;
    v_analytics_id bigint;
begin
    -- Use provided session_id or generate new one
    v_session_id := coalesce(p_session_id, gen_random_uuid());

    -- Insert analytics record
    insert into public.resource_analytics (
        resource_id,
        session_id,
        interaction_type,
        file_type_accessed,
        accessed_from_course_id,
        user_agent,
        referrer
    ) values (
        p_resource_id,
        v_session_id,
        p_interaction_type,
        p_file_type,
        p_course_id,
        p_user_agent,
        p_referrer
    ) returning id into v_analytics_id;

    return v_session_id;
end;
$$ language plpgsql security definer;

-- Create function to update view duration
create or replace function public.update_view_duration(
    p_session_id uuid,
    p_resource_id bigint,
    p_duration_seconds integer default null,
    p_completion_percentage integer default null
)
returns void as $$
begin
    update public.resource_analytics
    set
        view_ended_at = now(),
        duration_seconds = coalesce(p_duration_seconds, extract(epoch from (now() - view_started_at))::integer),
        completion_percentage = p_completion_percentage
    where session_id = p_session_id
    and resource_id = p_resource_id
    and view_ended_at is null
    order by view_started_at desc
    limit 1;
end;
$$ language plpgsql security definer;

-- Create daily analytics summary table for performance
create table public.resource_analytics_daily (
    id bigint generated always as identity primary key,
    resource_id bigint not null references public.resources(id) on delete cascade,
    date date not null,
    unique_views integer default 0,
    total_views integer default 0,
    total_duration_seconds integer default 0,
    downloads integer default 0,

    -- Ensure unique combination
    unique(resource_id, date)
);

-- Create function to aggregate daily analytics
create or replace function public.aggregate_daily_analytics(p_date date default current_date - interval '1 day')
returns void as $$
begin
    insert into public.resource_analytics_daily (
        resource_id,
        date,
        unique_views,
        total_views,
        total_duration_seconds,
        downloads
    )
    select
        resource_id,
        p_date,
        count(distinct session_id),
        count(*),
        coalesce(sum(duration_seconds), 0),
        count(case when interaction_type = 'download' then 1 end)
    from public.resource_analytics
    where date(created_at) = p_date
    group by resource_id
    on conflict (resource_id, date) do update
    set
        unique_views = excluded.unique_views,
        total_views = excluded.total_views,
        total_duration_seconds = excluded.total_duration_seconds,
        downloads = excluded.downloads;
end;
$$ language plpgsql;

-- Create indexes for better query performance
create index idx_courses_slug on public.courses(slug);
create index idx_courses_published on public.courses(is_published, published_at desc) where deleted_at is null;
create index idx_courses_created_by on public.courses(created_by);
create index idx_course_resources_course_id on public.course_resources(course_id);
create index idx_course_resources_resource_id on public.course_resources(resource_id);
create index idx_course_resources_position on public.course_resources(course_id, position);
create index idx_resource_analytics_resource_id on public.resource_analytics(resource_id);
create index idx_resource_analytics_session_id on public.resource_analytics(session_id);
create index idx_resource_analytics_created_at on public.resource_analytics(created_at desc);
create index idx_resource_analytics_interaction_type on public.resource_analytics(interaction_type);
create index idx_resource_analytics_course on public.resource_analytics(accessed_from_course_id) where accessed_from_course_id is not null;
create index idx_resource_analytics_daily_date on public.resource_analytics_daily(date desc);
create index idx_resource_analytics_daily_resource on public.resource_analytics_daily(resource_id, date desc);

-- Enable RLS
alter table public.courses enable row level security;
alter table public.course_resources enable row level security;
alter table public.resource_analytics enable row level security;
alter table public.resource_analytics_daily enable row level security;

-- RLS Policies
-- Courses policies
create policy "admins can manage courses"
    on public.courses
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view published courses"
    on public.courses
    for select
    to authenticated
    using (is_published = true and deleted_at is null);

-- Course resources policies
create policy "admins can manage course resources"
    on public.course_resources
    for all
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "anyone can view course resources"
    on public.course_resources
    for select
    to authenticated
    using (
        exists (
            select 1 from public.courses c
            where c.id = course_id
            and c.is_published = true
            and c.deleted_at is null
        )
    );

-- Analytics policies - only admins can view
create policy "admins can view analytics"
    on public.resource_analytics
    for select
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

-- Allow anonymous inserts for tracking (through function)
create policy "allow analytics tracking"
    on public.resource_analytics
    for insert
    to authenticated
    with check (true);

create policy "admins can view daily analytics"
    on public.resource_analytics_daily
    for select
    to authenticated
    using (
        exists (
            select 1 from public.profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

-- Add updated_at triggers
create trigger update_courses_updated_at
    before update on public.courses
    for each row
    execute function public.update_updated_at_column();

-- Create trigger to auto-generate course slugs
create trigger generate_course_slug
    before insert or update on public.courses
    for each row
    execute function public.generate_slug_from_title();

-- Create function to reorder course resources
create or replace function public.reorder_course_resources(
    p_course_id bigint,
    p_resource_ids bigint[]
)
returns void as $$
declare
    i integer;
begin
    -- Update positions based on array order
    for i in 1..array_length(p_resource_ids, 1) loop
        update public.course_resources
        set position = i
        where course_id = p_course_id
        and resource_id = p_resource_ids[i];
    end loop;
end;
$$ language plpgsql security definer;

-- Grant execute permissions on tracking functions
grant execute on function public.track_resource_view to authenticated;
grant execute on function public.update_view_duration to authenticated;
grant execute on function public.reorder_course_resources to authenticated;

-- Create a scheduled job to aggregate daily analytics (optional - requires pg_cron extension)
-- This would typically be set up separately in Supabase dashboard
-- select cron.schedule('aggregate-daily-analytics', '0 1 * * *', 'select public.aggregate_daily_analytics();');
