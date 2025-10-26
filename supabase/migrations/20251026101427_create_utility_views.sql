-- Migration: Utility views and functions
-- This migration creates helpful views and functions for easier data access

-- Create a comprehensive resource view with all related data
create or replace view public.resources_full as
select
    r.*,
    -- Creator info
    p.name as created_by_name,
    p.email as created_by_email,

    -- Categories as array
    array_agg(distinct c.name) filter (where c.id is not null) as category_names,
    array_agg(distinct c.id) filter (where c.id is not null) as category_ids,

    -- Primary category
    pc.name as primary_category_name,

    -- Labels grouped by type
    jsonb_object_agg(
        lt.name,
        array_agg(distinct l.name)
    ) filter (where l.id is not null) as labels_by_type,

    -- File counts
    count(distinct rf.id) as file_count,
    array_agg(distinct rf.file_type) filter (where rf.id is not null) as available_file_types,

    -- Link count
    count(distinct rl.id) as link_count,

    -- Analytics summary
    coalesce(ras.total_views, 0) as total_views,
    coalesce(ras.total_unique_views, 0) as unique_views,
    ras.last_viewed_at,

    -- Course count
    count(distinct cr.course_id) as course_count

from public.resources r
left join public.profiles p on r.created_by = p.id
left join public.resource_categories rc on r.id = rc.resource_id
left join public.categories c on rc.category_id = c.id
left join public.categories pc on rc.category_id = pc.id and rc.is_primary = true
left join public.resource_labels rl_map on r.id = rl_map.resource_id
left join public.labels l on rl_map.label_id = l.id
left join public.label_types lt on l.label_type_id = lt.id
left join public.resource_files rf on r.id = rf.resource_id
left join public.resource_links rl on r.id = rl.resource_id
left join public.resource_analytics_summary ras on r.id = ras.resource_id
left join public.course_resources cr on r.id = cr.resource_id
where r.deleted_at is null
group by r.id, p.name, p.email, pc.name, ras.total_views, ras.total_unique_views, ras.last_viewed_at;

-- Create a course view with resource count and metadata
create or replace view public.courses_full as
select
    c.*,
    p.name as created_by_name,
    count(distinct cr.resource_id) as resource_count,
    array_agg(
        jsonb_build_object(
            'resource_id', r.id,
            'title', r.title,
            'position', cr.position,
            'section_number', cr.section_number,
            'section_title', cr.section_title,
            'is_optional', cr.is_optional
        ) order by cr.position
    ) filter (where r.id is not null) as resources
from public.courses c
left join public.profiles p on c.created_by = p.id
left join public.course_resources cr on c.id = cr.course_id
left join public.resources r on cr.resource_id = r.id and r.deleted_at is null
where c.deleted_at is null
group by c.id, p.name;

-- Create search function for resources
create or replace function public.search_resources(
    search_query text,
    category_ids bigint[] default null,
    label_ids bigint[] default null,
    file_types text[] default null
)
returns setof public.resources_full as $$
begin
    return query
    select rf.*
    from public.resources_full rf
    where
        -- Text search
        (
            search_query is null
            or rf.title ilike '%' || search_query || '%'
            or rf.description ilike '%' || search_query || '%'
            or rf.short_description ilike '%' || search_query || '%'
        )
        -- Category filter
        and (
            category_ids is null
            or rf.category_ids && category_ids
        )
        -- Label filter
        and (
            label_ids is null
            or exists (
                select 1
                from public.resource_labels rl
                where rl.resource_id = rf.id
                and rl.label_id = any(label_ids)
            )
        )
        -- File type filter
        and (
            file_types is null
            or rf.available_file_types && file_types
        );
end;
$$ language plpgsql stable;

-- Create function to get resource with all details
create or replace function public.get_resource_details(p_resource_id bigint)
returns json as $$
declare
    result json;
begin
    select json_build_object(
        'resource', r,
        'categories', coalesce(
            json_agg(distinct
                jsonb_build_object(
                    'id', c.id,
                    'name', c.name,
                    'is_primary', rc.is_primary
                )
            ) filter (where c.id is not null),
            '[]'::json
        ),
        'labels', coalesce(
            json_agg(distinct
                jsonb_build_object(
                    'id', l.id,
                    'name', l.name,
                    'type', lt.name,
                    'type_id', lt.id
                )
            ) filter (where l.id is not null),
            '[]'::json
        ),
        'files', coalesce(
            json_agg(distinct
                jsonb_build_object(
                    'id', rf.id,
                    'file_type', rf.file_type,
                    'file_name', rf.file_name,
                    'storage_path', rf.storage_path,
                    'is_primary', rf.is_primary
                )
            ) filter (where rf.id is not null),
            '[]'::json
        ),
        'links', coalesce(
            json_agg(distinct
                jsonb_build_object(
                    'id', rl.id,
                    'url', rl.url,
                    'title', rl.title,
                    'link_type', rl.link_type
                )
            ) filter (where rl.id is not null),
            '[]'::json
        ),
        'courses', coalesce(
            json_agg(distinct
                jsonb_build_object(
                    'id', course.id,
                    'title', course.title,
                    'position', cr.position
                )
            ) filter (where course.id is not null),
            '[]'::json
        )
    ) into result
    from public.resources r
    left join public.resource_categories rc on r.id = rc.resource_id
    left join public.categories c on rc.category_id = c.id
    left join public.resource_labels rl_map on r.id = rl_map.resource_id
    left join public.labels l on rl_map.label_id = l.id
    left join public.label_types lt on l.label_type_id = lt.id
    left join public.resource_files rf on r.id = rf.resource_id
    left join public.resource_links rl on r.id = rl.resource_id
    left join public.course_resources cr on r.id = cr.resource_id
    left join public.courses course on cr.course_id = course.id and course.deleted_at is null
    where r.id = p_resource_id
    and r.deleted_at is null
    group by r.id;

    return result;
end;
$$ language plpgsql stable;

-- Create function to get category tree
create or replace function public.get_category_tree()
returns json as $$
begin
    return (
        with recursive category_tree as (
            -- Start with root categories (no parent)
            select
                c.id,
                c.name,
                c.description,
                c.parent_fk,
                c.display_order,
                0 as level,
                array[c.id] as path
            from public.categories c
            where c.parent_fk is null

            union all

            -- Recursively get children
            select
                c.id,
                c.name,
                c.description,
                c.parent_fk,
                c.display_order,
                ct.level + 1,
                ct.path || c.id
            from public.categories c
            inner join category_tree ct on c.parent_fk = ct.id
        )
        select json_agg(
            jsonb_build_object(
                'id', ct.id,
                'name', ct.name,
                'description', ct.description,
                'level', ct.level,
                'path', ct.path,
                'resource_count', count(distinct rc.resource_id)
            ) order by ct.path
        )
        from category_tree ct
        left join public.resource_categories rc on ct.id = rc.category_id
        group by ct.id, ct.name, ct.description, ct.level, ct.path, ct.display_order
    );
end;
$$ language plpgsql stable;

-- Create function to bulk update resource categories
create or replace function public.update_resource_categories(
    p_resource_id bigint,
    p_category_ids bigint[],
    p_primary_category_id bigint default null
)
returns void as $$
begin
    -- Delete existing categories
    delete from public.resource_categories
    where resource_id = p_resource_id;

    -- Insert new categories
    insert into public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    select
        p_resource_id,
        unnest(p_category_ids),
        case when unnest(p_category_ids) = p_primary_category_id then true else false end,
        auth.uid()
    where array_length(p_category_ids, 1) > 0;
end;
$$ language plpgsql security definer;

-- Create function to bulk update resource labels
create or replace function public.update_resource_labels(
    p_resource_id bigint,
    p_label_ids bigint[]
)
returns void as $$
begin
    -- Delete existing labels
    delete from public.resource_labels
    where resource_id = p_resource_id;

    -- Insert new labels (validation trigger will check if they're valid)
    if array_length(p_label_ids, 1) > 0 then
        insert into public.resource_labels (resource_id, label_id, assigned_by)
        select
            p_resource_id,
            unnest(p_label_ids),
            auth.uid();
    end if;
end;
$$ language plpgsql security definer;

-- Create function to get admin dashboard stats
create or replace function public.get_admin_stats()
returns json as $$
begin
    return json_build_object(
        'total_resources', (select count(*) from public.resources where deleted_at is null),
        'total_categories', (select count(*) from public.categories),
        'total_courses', (select count(*) from public.courses where deleted_at is null),
        'total_views', (select sum(total_views) from public.resource_analytics_summary),
        'unique_viewers', (select count(distinct session_id) from public.resource_analytics),
        'recent_resources', (
            select json_agg(
                jsonb_build_object(
                    'id', r.id,
                    'title', r.title,
                    'created_at', r.created_at
                ) order by r.created_at desc
            )
            from (
                select * from public.resources
                where deleted_at is null
                order by created_at desc
                limit 5
            ) r
        ),
        'popular_resources', (
            select json_agg(
                jsonb_build_object(
                    'id', ras.resource_id,
                    'title', ras.resource_title,
                    'views', ras.total_views
                ) order by ras.total_views desc
            )
            from (
                select * from public.resource_analytics_summary
                order by total_views desc
                limit 5
            ) ras
        )
    );
end;
$$ language plpgsql stable security definer;

-- Grant execute permissions
grant execute on function public.search_resources to authenticated;
grant execute on function public.get_resource_details to authenticated;
grant execute on function public.get_category_tree to authenticated;
grant execute on function public.update_resource_categories to authenticated;
grant execute on function public.update_resource_labels to authenticated;
grant execute on function public.get_admin_stats to authenticated;

-- Create indexes for search performance
create index if not exists idx_resources_title_trgm on public.resources using gin (title gin_trgm_ops);
create index if not exists idx_resources_description_trgm on public.resources using gin (description gin_trgm_ops);

-- Note: The trigram indexes above require the pg_trgm extension
-- Enable it with: create extension if not exists pg_trgm;
