-- authentication setup migration
-- creates profiles table and sets up auth integration

-- create profiles table that extends auth.users
create table public.profiles (
    id uuid not null references auth.users on delete cascade,
    email text,
    name text,
    role text check (role in('dev', 'admin', 'user')),

    primary key (id)
);

-- enable row level security on profiles
alter table public.profiles enable row level security;

-- create rls policies for profiles
-- users can view their own profile
create policy "users can view own profile"
    on public.profiles
    for select
    to authenticated
    using ( (select auth.uid()) = id );

-- users can update their own profile
create policy "users can update own profile"
    on public.profiles
    for update
    to authenticated
    using ( (select auth.uid()) = id )
    with check ( (select auth.uid()) = id );

-- users can insert their own profile
create policy "users can insert own profile"
    on public.profiles
    for insert
    to authenticated
    with check ( (select auth.uid()) = id );

-- create function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
    insert into public.profiles (id, email, name, role)
    values (
        new.id,
        new.email,
        new.raw_user_meta_data ->> 'name',
        coalesce(new.raw_user_meta_data ->> 'role', 'user')
    );
    return new;
end;
$$;

-- trigger to automatically create profile when user signs up
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- create function for updated_at trigger
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language 'plpgsql';

-- trigger to update updated_at on profiles
create trigger update_profiles_updated_at
    before update on public.profiles
    for each row
    execute function update_updated_at_column();
