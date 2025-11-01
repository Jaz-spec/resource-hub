-- Development Seed: Create Admin User
-- Uses the create_user function for safe user creation
-- WARNING: Use ONLY for local development
-- For production, users should sign up through the proper auth flow

DO $$
DECLARE
    admin_id uuid;
    admin_email text := 'admin@example.com';
    admin_password text := 'AdminPassword123!'; -- Change this!
BEGIN
    -- Check if admin already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = admin_email) THEN
        RAISE NOTICE 'Admin user already exists with email: %', admin_email;
        RETURN;
    END IF;

    -- Create admin user using the helper function
    admin_id := public.create_user(
        p_email := admin_email,
        p_password := admin_password,
        p_name := 'Admin User',
        p_role := 'admin'
    );

    RAISE NOTICE 'Admin user created successfully!';
    RAISE NOTICE 'Email: %', admin_email;
    RAISE NOTICE 'Password: % (CHANGE THIS IN PRODUCTION!)', admin_password;
    RAISE NOTICE 'User ID: %', admin_id;
END $$;
