<script lang="ts">
    import { enhance } from "$app/forms";

    const { action } = $props();

    let name = $state("");
    let role = $state("");
    let email = $state("");
    let password = $state("");
    let errors: Errors = {};
    let isSubmitting = $state(false);

    interface Errors {
        name?: string;
        role?: "admin" | "user" | "dev";
        password?: string;
        email?: string;
    }
</script>

<div class="container dev">
    <main class="dev">
        <form method="POST" {action} class="login-form" use:enhance>
            {#if action === "?/signup"}
                <div class="dev">
                    <label for="name">Name:</label>
                    <input
                        id="name"
                        type="text"
                        name="name"
                        bind:value={name}
                        placeholder="Enter your name"
                        disabled={isSubmitting}
                        class="dev"
                    />
                    {#if errors.name}
                        <span class="error-message">{errors.name}</span>
                    {/if}
                </div>

                <div class="dev">
                    <label for="role">Role:</label>
                    <input
                        id="role"
                        type="text"
                        name="role"
                        bind:value={role}
                        placeholder="Enter your role"
                        disabled={isSubmitting}
                        class="dev"
                    />
                    {#if errors.name}
                        <span class="error-message">{errors.name}</span>
                    {/if}
                </div>
            {/if}

            <div class="dev">
                <label for="email">Email:</label>
                <input
                    id="email"
                    type="email"
                    name="email"
                    bind:value={email}
                    placeholder="Enter your name"
                    disabled={isSubmitting}
                    class="dev"
                />
                {#if errors.email}
                    <span class="error-message">{errors.email}</span>
                {/if}
            </div>

            <div class="dev">
                <label for="password">Password:</label>
                <input
                    id="password"
                    type="password"
                    name="password"
                    bind:value={password}
                    placeholder="Enter your password"
                    class:error={errors.password}
                    disabled={isSubmitting}
                    class="dev"
                />
                {#if errors.password}
                    <span class="error-message">{errors.password}</span>
                {/if}
            </div>

            <button class="dev" type="submit" disabled={isSubmitting}>
                {#if action === "?/signup"}
                    {isSubmitting ? "Creating user..." : "Sign Up"}
                {:else}
                    {isSubmitting ? "Logging in..." : "Log in"}
                {/if}
            </button>
        </form>
    </main>
</div>
