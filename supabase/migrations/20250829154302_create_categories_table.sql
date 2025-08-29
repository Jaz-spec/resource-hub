-- Initial schema migration
-- Tables created: categories, resources, cat_res

-- categories table, parent_fk is self referential
create table categories  (
id bigint generated always as identity primary key,
name text not null,
parent_fk bigint references categories(id) on delete set null
);

-- resources table
create table resources (
id bigint generated always as identity primary key,
name text not null
);

-- many-to-many categories_resources table
create table cat_res (
id bigint generated always as identity primary key,
cat_fk bigint not null references categories(id) on delete cascade,
res_fk bigint not null references resources(id) on delete cascade,

-- ensure unique combination
unique(cat_fk, res_fk)
);
