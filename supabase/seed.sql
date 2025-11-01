-- Seed data for Resource Hub Database
-- This file populates the database with sample data for testing and demonstration

-- First, ensure we have an admin user in profiles (you may already have this from auth testing)
-- We'll use this admin's ID for created_by fields
DO $$
DECLARE
    admin_id uuid;
BEGIN
    -- Get or create an admin profile (adjust email as needed)
    SELECT id INTO admin_id FROM public.profiles WHERE role = 'admin' LIMIT 1;

    IF admin_id IS NULL THEN
        -- If no admin exists, you'll need to sign up through the auth flow first
        RAISE NOTICE 'No admin user found. Please create an admin user through the signup flow first.';
        RETURN;
    END IF;

    -- Clear existing data for clean seeding (optional - remove if you want to preserve data)
    DELETE FROM public.resource_analytics;
    DELETE FROM public.course_resources;
    DELETE FROM public.courses;
    DELETE FROM public.resource_labels;
    DELETE FROM public.resource_links;
    DELETE FROM public.resource_files;
    DELETE FROM public.resource_categories;
    DELETE FROM public.resources;
    DELETE FROM public.category_label_types;
    DELETE FROM public.labels;
    DELETE FROM public.label_types;
    DELETE FROM public.categories;

    -- ==========================================
    -- CATEGORIES (Hierarchical structure)
    -- ==========================================

    -- Root categories
    INSERT INTO public.categories (name, description, icon, color, display_order, created_by) VALUES
    ('Programming', 'Software development and coding resources', 'code', '#3B82F6', 1, admin_id),
    ('Design', 'UI/UX, graphic design, and creative resources', 'palette', '#EC4899', 2, admin_id),
    ('Business', 'Business strategy, marketing, and management', 'briefcase', '#10B981', 3, admin_id),
    ('Data Science', 'Data analysis, machine learning, and AI', 'chart-bar', '#F59E0B', 4, admin_id),
    ('DevOps', 'Infrastructure, deployment, and operations', 'server', '#8B5CF6', 5, admin_id);

    -- Sub-categories for Programming
    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'Web Development', 'Frontend and backend web technologies', id, 1, admin_id
    FROM public.categories WHERE name = 'Programming';

    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'Mobile Development', 'iOS, Android, and cross-platform mobile', id, 2, admin_id
    FROM public.categories WHERE name = 'Programming';

    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'Languages', 'Programming language specific resources', id, 3, admin_id
    FROM public.categories WHERE name = 'Programming';

    -- Sub-sub-categories for Web Development
    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'React', 'React.js framework and ecosystem', id, 1, admin_id
    FROM public.categories WHERE name = 'Web Development';

    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'Vue', 'Vue.js framework resources', id, 2, admin_id
    FROM public.categories WHERE name = 'Web Development';

    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'Backend APIs', 'REST, GraphQL, and backend services', id, 3, admin_id
    FROM public.categories WHERE name = 'Web Development';

    -- Sub-categories for Design
    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'UI Design', 'User interface design principles and tools', id, 1, admin_id
    FROM public.categories WHERE name = 'Design';

    INSERT INTO public.categories (name, description, parent_fk, display_order, created_by)
    SELECT 'UX Research', 'User experience research and testing', id, 2, admin_id
    FROM public.categories WHERE name = 'Design';

    -- ==========================================
    -- LABEL TYPES AND LABELS
    -- ==========================================

    -- Clear any default label types first
    DELETE FROM public.label_types;

    -- Create label types
    INSERT INTO public.label_types (name, description, allow_multiple, is_required, display_order, created_by) VALUES
    ('Difficulty', 'The difficulty level of the resource', false, true, 1, admin_id),
    ('Format', 'The type of content', true, false, 2, admin_id),
    ('Duration', 'Estimated time to complete', false, false, 3, admin_id),
    ('Topic', 'Specific topics covered', true, false, 4, admin_id),
    ('Tool', 'Software or tools used', true, false, 5, admin_id),
    ('Year', 'Publication or update year', false, false, 6, admin_id);

    -- Create labels for each type
    -- Difficulty labels
    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Beginner', 'beginner', 1, admin_id
    FROM public.label_types WHERE name = 'Difficulty';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Intermediate', 'intermediate', 2, admin_id
    FROM public.label_types WHERE name = 'Difficulty';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Advanced', 'advanced', 3, admin_id
    FROM public.label_types WHERE name = 'Difficulty';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Expert', 'expert', 4, admin_id
    FROM public.label_types WHERE name = 'Difficulty';

    -- Format labels
    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Video Course', 'video-course', 1, admin_id
    FROM public.label_types WHERE name = 'Format';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Tutorial', 'tutorial', 2, admin_id
    FROM public.label_types WHERE name = 'Format';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Documentation', 'documentation', 3, admin_id
    FROM public.label_types WHERE name = 'Format';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Interactive', 'interactive', 4, admin_id
    FROM public.label_types WHERE name = 'Format';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Book/eBook', 'book', 5, admin_id
    FROM public.label_types WHERE name = 'Format';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Cheat Sheet', 'cheat-sheet', 6, admin_id
    FROM public.label_types WHERE name = 'Format';

    -- Duration labels
    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '< 30 minutes', 'under-30min', 1, admin_id
    FROM public.label_types WHERE name = 'Duration';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '30-60 minutes', '30-60min', 2, admin_id
    FROM public.label_types WHERE name = 'Duration';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '1-3 hours', '1-3hours', 3, admin_id
    FROM public.label_types WHERE name = 'Duration';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '3-8 hours', '3-8hours', 4, admin_id
    FROM public.label_types WHERE name = 'Duration';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '1-3 days', '1-3days', 5, admin_id
    FROM public.label_types WHERE name = 'Duration';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '1+ week', 'over-1week', 6, admin_id
    FROM public.label_types WHERE name = 'Duration';

    -- Topic labels (programming specific)
    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Authentication', 'authentication', 1, admin_id
    FROM public.label_types WHERE name = 'Topic';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Database Design', 'database-design', 2, admin_id
    FROM public.label_types WHERE name = 'Topic';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'API Development', 'api-development', 3, admin_id
    FROM public.label_types WHERE name = 'Topic';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'State Management', 'state-management', 4, admin_id
    FROM public.label_types WHERE name = 'Topic';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Testing', 'testing', 5, admin_id
    FROM public.label_types WHERE name = 'Topic';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Security', 'security', 6, admin_id
    FROM public.label_types WHERE name = 'Topic';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Performance', 'performance', 7, admin_id
    FROM public.label_types WHERE name = 'Topic';

    -- Tool labels
    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'VS Code', 'vscode', 1, admin_id
    FROM public.label_types WHERE name = 'Tool';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Figma', 'figma', 2, admin_id
    FROM public.label_types WHERE name = 'Tool';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Git', 'git', 3, admin_id
    FROM public.label_types WHERE name = 'Tool';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Docker', 'docker', 4, admin_id
    FROM public.label_types WHERE name = 'Tool';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, 'Postman', 'postman', 5, admin_id
    FROM public.label_types WHERE name = 'Tool';

    -- Year labels
    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '2025', '2025', 1, admin_id
    FROM public.label_types WHERE name = 'Year';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '2024', '2024', 2, admin_id
    FROM public.label_types WHERE name = 'Year';

    INSERT INTO public.labels (label_type_id, name, value, display_order, created_by)
    SELECT id, '2023', '2023', 3, admin_id
    FROM public.label_types WHERE name = 'Year';

    -- ==========================================
    -- CATEGORY LABEL TYPES (which labels are available for which categories)
    -- ==========================================

    -- Programming categories get all label types
    INSERT INTO public.category_label_types (category_id, label_type_id, is_required, created_by)
    SELECT c.id, lt.id,
           CASE WHEN lt.name = 'Difficulty' THEN true ELSE false END,
           admin_id
    FROM public.categories c
    CROSS JOIN public.label_types lt
    WHERE c.name IN ('Programming', 'Web Development', 'Mobile Development', 'React', 'Vue', 'Backend APIs')
    AND lt.name IN ('Difficulty', 'Format', 'Duration', 'Topic', 'Tool', 'Year');

    -- Design categories get specific label types
    INSERT INTO public.category_label_types (category_id, label_type_id, is_required, created_by)
    SELECT c.id, lt.id,
           CASE WHEN lt.name = 'Difficulty' THEN true ELSE false END,
           admin_id
    FROM public.categories c
    CROSS JOIN public.label_types lt
    WHERE c.name IN ('Design', 'UI Design', 'UX Research')
    AND lt.name IN ('Difficulty', 'Format', 'Duration', 'Tool', 'Year');

    -- Business categories
    INSERT INTO public.category_label_types (category_id, label_type_id, is_required, created_by)
    SELECT c.id, lt.id, false, admin_id
    FROM public.categories c
    CROSS JOIN public.label_types lt
    WHERE c.name = 'Business'
    AND lt.name IN ('Difficulty', 'Format', 'Duration', 'Year');

    -- ==========================================
    -- RESOURCES
    -- ==========================================

    -- Resource 1: React Complete Guide
    INSERT INTO public.resources (title, description, short_description, is_featured, display_order, created_by)
    VALUES (
        'React Complete Guide 2025',
        'Master React.js from the ground up with this comprehensive guide. Learn components, hooks, state management, routing, and advanced patterns. Includes hands-on projects and real-world examples.',
        'Complete React.js course with projects',
        true,
        1,
        admin_id
    );

    -- Resource 2: SvelteKit Authentication
    INSERT INTO public.resources (title, description, short_description, is_featured, created_by)
    VALUES (
        'SvelteKit Authentication with Supabase',
        'Learn how to implement secure authentication in SvelteKit applications using Supabase. Covers user registration, login, password reset, OAuth providers, and role-based access control.',
        'Auth implementation in SvelteKit',
        true,
        admin_id
    );

    -- Resource 3: Database Design Fundamentals
    INSERT INTO public.resources (title, description, short_description, created_by)
    VALUES (
        'Database Design Fundamentals',
        'Essential concepts for designing efficient and scalable databases. Covers normalization, relationships, indexes, and performance optimization with PostgreSQL examples.',
        'Learn database design principles',
        admin_id
    );

    -- Resource 4: Figma for Developers
    INSERT INTO public.resources (title, description, short_description, created_by)
    VALUES (
        'Figma for Developers',
        'Bridge the gap between design and development. Learn how to work with Figma files, extract assets, understand design systems, and implement pixel-perfect UIs.',
        'Developer guide to Figma',
        admin_id
    );

    -- Resource 5: Git Advanced Techniques
    INSERT INTO public.resources (title, description, short_description, created_by)
    VALUES (
        'Git Advanced Techniques',
        'Go beyond basic Git commands. Master branching strategies, rebasing, cherry-picking, bisect, and team collaboration workflows.',
        'Advanced Git workflows',
        admin_id
    );

    -- Resource 6: TypeScript Best Practices
    INSERT INTO public.resources (title, description, short_description, is_featured, created_by)
    VALUES (
        'TypeScript Best Practices 2025',
        'Write better TypeScript code with modern patterns and practices. Covers advanced types, generics, decorators, and integration with popular frameworks.',
        'Modern TypeScript patterns',
        true,
        admin_id
    );

    -- Resource 7: API Design Guidelines
    INSERT INTO public.resources (title, description, short_description, created_by)
    VALUES (
        'RESTful API Design Guidelines',
        'Design scalable and maintainable REST APIs. Learn about endpoints, HTTP methods, status codes, authentication, versioning, and documentation.',
        'REST API best practices',
        admin_id
    );

    -- Resource 8: Docker for Web Developers
    INSERT INTO public.resources (title, description, short_description, created_by)
    VALUES (
        'Docker for Web Developers',
        'Containerize your web applications with Docker. Learn Dockerfile creation, docker-compose, multi-stage builds, and deployment strategies.',
        'Docker containerization guide',
        admin_id
    );

    -- ==========================================
    -- RESOURCE CATEGORIES (assign resources to categories)
    -- ==========================================

    -- React Guide -> React, Web Development
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'React Complete Guide 2025'
    AND c.name = 'React';

    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, false, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'React Complete Guide 2025'
    AND c.name = 'Web Development';

    -- SvelteKit Auth -> Web Development, Backend APIs
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'SvelteKit Authentication with Supabase'
    AND c.name = 'Web Development';

    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, false, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'SvelteKit Authentication with Supabase'
    AND c.name = 'Backend APIs';

    -- Database Design -> Programming, Data Science
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'Database Design Fundamentals'
    AND c.name = 'Programming';

    -- Figma -> Design, UI Design
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'Figma for Developers'
    AND c.name = 'UI Design';

    -- Git -> Programming, DevOps
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'Git Advanced Techniques'
    AND c.name = 'Programming';

    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, false, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'Git Advanced Techniques'
    AND c.name = 'DevOps';

    -- TypeScript -> Programming, Web Development
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'TypeScript Best Practices 2025'
    AND c.name = 'Programming';

    -- API Design -> Backend APIs
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'RESTful API Design Guidelines'
    AND c.name = 'Backend APIs';

    -- Docker -> DevOps
    INSERT INTO public.resource_categories (resource_id, category_id, is_primary, assigned_by)
    SELECT r.id, c.id, true, admin_id
    FROM public.resources r
    CROSS JOIN public.categories c
    WHERE r.title = 'Docker for Web Developers'
    AND c.name = 'DevOps';

    -- ==========================================
    -- RESOURCE LABELS (assign labels to resources)
    -- ==========================================

    -- React Guide: Intermediate, Video Course, 3-8 hours, State Management, 2025
    INSERT INTO public.resource_labels (resource_id, label_id, assigned_by)
    SELECT r.id, l.id, admin_id
    FROM public.resources r
    CROSS JOIN public.labels l
    WHERE r.title = 'React Complete Guide 2025'
    AND (
        (l.value = 'intermediate') OR
        (l.value = 'video-course') OR
        (l.value = '3-8hours') OR
        (l.value = 'state-management') OR
        (l.value = '2025')
    );

    -- SvelteKit Auth: Intermediate, Tutorial, 1-3 hours, Authentication, 2025
    INSERT INTO public.resource_labels (resource_id, label_id, assigned_by)
    SELECT r.id, l.id, admin_id
    FROM public.resources r
    CROSS JOIN public.labels l
    WHERE r.title = 'SvelteKit Authentication with Supabase'
    AND (
        (l.value = 'intermediate') OR
        (l.value = 'tutorial') OR
        (l.value = '1-3hours') OR
        (l.value = 'authentication') OR
        (l.value = '2025')
    );

    -- Database Design: Beginner, Documentation, 30-60min, Database Design, 2024
    INSERT INTO public.resource_labels (resource_id, label_id, assigned_by)
    SELECT r.id, l.id, admin_id
    FROM public.resources r
    CROSS JOIN public.labels l
    WHERE r.title = 'Database Design Fundamentals'
    AND (
        (l.value = 'beginner') OR
        (l.value = 'documentation') OR
        (l.value = '30-60min') OR
        (l.value = 'database-design') OR
        (l.value = '2024')
    );

    -- Figma: Beginner, Interactive, 1-3 hours, Figma, 2024
    INSERT INTO public.resource_labels (resource_id, label_id, assigned_by)
    SELECT r.id, l.id, admin_id
    FROM public.resources r
    CROSS JOIN public.labels l
    WHERE r.title = 'Figma for Developers'
    AND (
        (l.value = 'beginner') OR
        (l.value = 'interactive') OR
        (l.value = '1-3hours') OR
        (l.value = 'figma') OR
        (l.value = '2024')
    );

    -- Git: Advanced, Tutorial, 30-60min, Git, 2024
    INSERT INTO public.resource_labels (resource_id, label_id, assigned_by)
    SELECT r.id, l.id, admin_id
    FROM public.resources r
    CROSS JOIN public.labels l
    WHERE r.title = 'Git Advanced Techniques'
    AND (
        (l.value = 'advanced') OR
        (l.value = 'tutorial') OR
        (l.value = '30-60min') OR
        (l.value = 'git') OR
        (l.value = '2024')
    );

    -- TypeScript: Intermediate, Documentation, Cheat Sheet, under 30min, 2025
    INSERT INTO public.resource_labels (resource_id, label_id, assigned_by)
    SELECT r.id, l.id, admin_id
    FROM public.resources r
    CROSS JOIN public.labels l
    WHERE r.title = 'TypeScript Best Practices 2025'
    AND (
        (l.value = 'intermediate') OR
        (l.value = 'documentation') OR
        (l.value = 'cheat-sheet') OR
        (l.value = 'under-30min') OR
        (l.value = '2025')
    );

    -- ==========================================
    -- RESOURCE FILES (sample file attachments)
    -- ==========================================

    -- React Guide files
    INSERT INTO public.resource_files (resource_id, file_type, file_name, original_name, storage_path, file_size_bytes, is_primary, uploaded_by)
    SELECT r.id, 'pdf', 'react-guide-2025.pdf', 'React Complete Guide 2025.pdf',
           'pdfs/' || r.id || '-react-guide-2025.pdf', 2548576, true, admin_id
    FROM public.resources r
    WHERE r.title = 'React Complete Guide 2025';

    INSERT INTO public.resource_files (resource_id, file_type, file_name, original_name, storage_path, file_size_bytes, uploaded_by)
    SELECT r.id, 'pptx', 'react-slides.pptx', 'React Presentation.pptx',
           'powerpoints/' || r.id || '-react-slides.pptx', 5242880, admin_id
    FROM public.resources r
    WHERE r.title = 'React Complete Guide 2025';

    -- SvelteKit Auth files
    INSERT INTO public.resource_files (resource_id, file_type, file_name, original_name, storage_path, file_size_bytes, is_primary, uploaded_by)
    SELECT r.id, 'docx', 'sveltekit-auth-guide.docx', 'SvelteKit Auth Guide.docx',
           'docs/' || r.id || '-sveltekit-auth-guide.docx', 1048576, true, admin_id
    FROM public.resources r
    WHERE r.title = 'SvelteKit Authentication with Supabase';

    -- Database Design files
    INSERT INTO public.resource_files (resource_id, file_type, file_name, original_name, storage_path, file_size_bytes, is_primary, uploaded_by)
    SELECT r.id, 'pdf', 'database-design.pdf', 'Database Design Fundamentals.pdf',
           'pdfs/' || r.id || '-database-design.pdf', 3145728, true, admin_id
    FROM public.resources r
    WHERE r.title = 'Database Design Fundamentals';

    -- ==========================================
    -- RESOURCE LINKS (external links)
    -- ==========================================

    -- React Guide links
    INSERT INTO public.resource_links (resource_id, link_type, url, title, description, display_order, created_by)
    SELECT r.id, 'video', 'https://www.youtube.com/watch?v=example1',
           'React Hooks Deep Dive', 'Advanced hooks patterns and examples', 1, admin_id
    FROM public.resources r
    WHERE r.title = 'React Complete Guide 2025';

    INSERT INTO public.resource_links (resource_id, link_type, url, title, description, display_order, created_by)
    SELECT r.id, 'documentation', 'https://react.dev/',
           'Official React Documentation', 'Latest React docs and API reference', 2, admin_id
    FROM public.resources r
    WHERE r.title = 'React Complete Guide 2025';

    -- SvelteKit Auth links
    INSERT INTO public.resource_links (resource_id, link_type, url, title, display_order, created_by)
    SELECT r.id, 'documentation', 'https://supabase.com/docs/guides/auth',
           'Supabase Auth Documentation', 1, admin_id
    FROM public.resources r
    WHERE r.title = 'SvelteKit Authentication with Supabase';

    INSERT INTO public.resource_links (resource_id, link_type, url, title, display_order, created_by)
    SELECT r.id, 'source', 'https://github.com/example/sveltekit-auth-demo',
           'Source Code Repository', 2, admin_id
    FROM public.resources r
    WHERE r.title = 'SvelteKit Authentication with Supabase';

    -- Git links
    INSERT INTO public.resource_links (resource_id, link_type, url, title, display_order, created_by)
    SELECT r.id, 'external', 'https://git-scm.com/book',
           'Pro Git Book', 1, admin_id
    FROM public.resources r
    WHERE r.title = 'Git Advanced Techniques';

    -- Docker links
    INSERT INTO public.resource_links (resource_id, link_type, url, title, display_order, created_by)
    SELECT r.id, 'documentation', 'https://docs.docker.com/',
           'Docker Official Docs', 1, admin_id
    FROM public.resources r
    WHERE r.title = 'Docker for Web Developers';

    -- ==========================================
    -- COURSES
    -- ==========================================

    -- Course 1: Full Stack Web Development
    INSERT INTO public.courses (title, description, short_description, estimated_hours, difficulty_level,
                                prerequisites, learning_outcomes, is_published, is_featured, created_by)
    VALUES (
        'Full Stack Web Development Path',
        'Complete learning path for becoming a full-stack web developer. Covers frontend, backend, databases, and deployment.',
        'Comprehensive web development course',
        40.5,
        'intermediate',
        'Basic HTML, CSS, and JavaScript knowledge',
        ARRAY[
            'Build complete web applications from scratch',
            'Implement secure authentication systems',
            'Design and optimize databases',
            'Deploy applications to production'
        ],
        true,
        true,
        admin_id
    );

    -- Course 2: Modern DevOps Practices
    INSERT INTO public.courses (title, description, short_description, estimated_hours, difficulty_level,
                                prerequisites, learning_outcomes, is_published, created_by)
    VALUES (
        'Modern DevOps Practices',
        'Learn essential DevOps tools and practices including Git, Docker, CI/CD, and cloud deployment.',
        'DevOps tools and workflows',
        25.0,
        'intermediate',
        'Command line basics, understanding of web applications',
        ARRAY[
            'Master Git workflows for team collaboration',
            'Containerize applications with Docker',
            'Set up CI/CD pipelines',
            'Deploy to cloud platforms'
        ],
        true,
        admin_id
    );

    -- ==========================================
    -- COURSE RESOURCES (add resources to courses)
    -- ==========================================

    -- Full Stack Course Resources
    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 1, 1, 'Frontend Foundations',
           'Start here to master React fundamentals', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Full Stack Web Development Path'
    AND r.title = 'React Complete Guide 2025';

    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 2, 1, 'Frontend Foundations',
           'Learn TypeScript for better code quality', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Full Stack Web Development Path'
    AND r.title = 'TypeScript Best Practices 2025';

    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 3, 2, 'Backend Development',
           'Design robust APIs', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Full Stack Web Development Path'
    AND r.title = 'RESTful API Design Guidelines';

    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 4, 2, 'Backend Development',
           'Database design principles', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Full Stack Web Development Path'
    AND r.title = 'Database Design Fundamentals';

    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 5, 3, 'Authentication & Security',
           'Implement secure authentication', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Full Stack Web Development Path'
    AND r.title = 'SvelteKit Authentication with Supabase';

    -- DevOps Course Resources
    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 1, 1, 'Version Control Mastery',
           'Advanced Git techniques for teams', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Modern DevOps Practices'
    AND r.title = 'Git Advanced Techniques';

    INSERT INTO public.course_resources (course_id, resource_id, position, section_number, section_title, notes, added_by)
    SELECT c.id, r.id, 2, 2, 'Containerization',
           'Docker fundamentals and best practices', admin_id
    FROM public.courses c
    CROSS JOIN public.resources r
    WHERE c.title = 'Modern DevOps Practices'
    AND r.title = 'Docker for Web Developers';

    -- ==========================================
    -- SAMPLE ANALYTICS DATA (optional - for testing)
    -- ==========================================

    -- Add some sample view data for popular resources
    INSERT INTO public.resource_analytics (
        resource_id,
        session_id,
        interaction_type,
        duration_seconds,
        created_at
    )
    SELECT
        r.id,
        gen_random_uuid(),
        'view',
        (random() * 1800 + 60)::integer, -- Random duration between 1-30 minutes
        NOW() - (random() * interval '30 days') -- Random time in last 30 days
    FROM public.resources r
    CROSS JOIN generate_series(1, 10 + (random() * 20)::integer) -- 10-30 views per resource
    WHERE r.is_featured = true;

    -- Add some download analytics
    INSERT INTO public.resource_analytics (
        resource_id,
        session_id,
        interaction_type,
        file_type_accessed,
        created_at
    )
    SELECT
        r.id,
        gen_random_uuid(),
        'download',
        'pdf',
        NOW() - (random() * interval '30 days')
    FROM public.resources r
    CROSS JOIN generate_series(1, 2 + (random() * 5)::integer) -- 2-7 downloads
    WHERE EXISTS (
        SELECT 1 FROM public.resource_files rf
        WHERE rf.resource_id = r.id
        AND rf.file_type = 'pdf'
    );

    RAISE NOTICE 'Seed data created successfully!';
END $$;

-- ==========================================
-- VERIFICATION QUERIES (Run these to check the data)
-- ==========================================

-- Check resource count by category
SELECT c.name as category, COUNT(rc.resource_id) as resource_count
FROM categories c
LEFT JOIN resource_categories rc ON c.id = rc.category_id
GROUP BY c.name
ORDER BY resource_count DESC;

-- Check resources with their labels
SELECT
    r.title,
    array_agg(DISTINCT c.name) as categories,
    json_agg(DISTINCT jsonb_build_object('type', lt.name, 'label', l.name)) FILTER (WHERE l.name IS NOT NULL) as labels
FROM resources r
LEFT JOIN resource_categories rc ON r.id = rc.resource_id
LEFT JOIN categories c ON rc.category_id = c.id
LEFT JOIN resource_labels rl ON r.id = rl.resource_id
LEFT JOIN labels l ON rl.label_id = l.id
LEFT JOIN label_types lt ON l.label_type_id = lt.id
GROUP BY r.id, r.title;

-- Check course contents
SELECT
    c.title as course,
    COUNT(cr.resource_id) as resource_count,
    c.estimated_hours as hours
FROM courses c
LEFT JOIN course_resources cr ON c.id = cr.course_id
GROUP BY c.id, c.title, c.estimated_hours;

-- Check analytics summary
SELECT
    r.title,
    COUNT(DISTINCT ra.session_id) as unique_views,
    COUNT(*) as total_interactions,
    COUNT(CASE WHEN ra.interaction_type = 'download' THEN 1 END) as downloads
FROM resources r
LEFT JOIN resource_analytics ra ON r.id = ra.resource_id
GROUP BY r.id, r.title
ORDER BY unique_views DESC;
