-- Development Seed: Create Admin User
-- WARNING: This directly manipulates auth tables - use ONLY for local development
-- For production, users should sign up through the proper auth flow

DO $$
DECLARE
    admin_id uuid := gen_random_uuid();
    admin_email text := 'admin@example.com';
    admin_password text := 'AdminPassword123!'; -- Change this!
BEGIN
    -- Check if admin already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
        RAISE NOTICE 'Admin user already exists';
        RETURN;
    END IF;

    -- Create user in auth.users (Supabase Auth table)
    -- Note: Password is hashed using crypt function
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role
    ) VALUES (
        admin_id,
        '00000000-0000-0000-0000-000000000000',
        admin_email,
        crypt(admin_password, gen_salt('bf')),
        now(),
        now(),
        now(),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        jsonb_build_object('name', 'Admin User', 'role', 'admin'),
        false,
        'authenticated'
    );

    -- Create identity for the user
    INSERT INTO auth.identities (
        id,
        user_id,
        provider_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        admin_id,
        admin_id::text,
        jsonb_build_object('sub', admin_id::text, 'email', admin_email),
        'email',
        now(),
        now(),
        now()
    );

    -- The profile will be created automatically by your trigger
    -- But we can ensure it's an admin
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (admin_id, admin_email, 'Admin User', 'admin')
    ON CONFLICT (id) DO UPDATE
    SET role = 'admin';

    RAISE NOTICE 'Admin user created successfully with email: %', admin_email;
    RAISE NOTICE 'Password: % (CHANGE THIS IN PRODUCTION!)', admin_password;
END $$;
