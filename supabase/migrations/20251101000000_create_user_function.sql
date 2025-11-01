-- Create helper function for seeding auth users
-- This function safely creates users with proper password hashing and all required fields

CREATE OR REPLACE FUNCTION public.create_user(
    p_email text,
    p_password text,
    p_name text DEFAULT NULL,
    p_role text DEFAULT 'user'
) RETURNS uuid AS $$
DECLARE
    user_id uuid;
    encrypted_pw text;
BEGIN
    -- Generate UUID for the new user
    user_id := gen_random_uuid();

    -- Hash the password using bcrypt
    encrypted_pw := crypt(p_password, gen_salt('bf'));

    -- Insert into auth.users with all required fields
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
        role,
        aud,
        confirmation_token,
        last_sign_in_at,
        email_change,
        phone_change,
        email_change_token_current,
        phone_change_token,
        reauthentication_token,
        email_change_token_new,
        recovery_token
    ) VALUES (
        user_id,
        '00000000-0000-0000-0000-000000000000',
        p_email,
        encrypted_pw,
        now(),
        now(),
        now(),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        jsonb_build_object('name', COALESCE(p_name, p_email), 'role', p_role),
        false,
        'authenticated',
        'authenticated',
        '',
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        ''
    );

    -- Insert into auth.identities with proper provider_id
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
        user_id,
        user_id::text,
        jsonb_build_object('sub', user_id::text, 'email', p_email),
        'email',
        now(),
        now(),
        now()
    );

    -- The profile will be created automatically by the handle_new_user trigger
    -- But we can ensure it has the correct role
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (user_id, p_email, COALESCE(p_name, p_email), p_role)
    ON CONFLICT (id) DO UPDATE
    SET role = EXCLUDED.role, name = COALESCE(EXCLUDED.name, public.profiles.name);

    RETURN user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_user IS 'Helper function to create auth users for seeding. Only use in development!';
