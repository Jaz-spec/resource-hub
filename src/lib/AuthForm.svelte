<script lang="ts">
    import { getContext } from "svelte";
    import { enhance } from "$app/forms";

    // TODO: typecheck
    let getState: any = getContext("state");
    let state = $derived(getState());

    let name = $state("");
    let email = $state("");
    let password = $state("");
    let errors: Errors = {};
    let isSubmitting = $state(false);

    interface Errors {
        name?: string;
        password?: string;
        email?: string;
    }
    const { action } = $props();
</script>

<div class="container" class:dev={state === "dev"}>
    <main class:dev={state === "dev"}>
        <form method="POST" {action} class="login-form" use:enhance>
            <div class:dev={state === "dev"}>
                <label for="name">Name:</label>
                <input
                    id="name"
                    type="text"
                    name="name"
                    bind:value={name}
                    placeholder="Enter your name"
                    disabled={isSubmitting}
                    class:dev={state === "dev"}
                />
                {#if errors.name}
                    <span class="error-message">{errors.name}</span>
                {/if}
            </div>

            <div class:dev={state === "dev"}>
                <label for="email">Email:</label>
                <input
                    id="email"
                    type="email"
                    name="email"
                    bind:value={email}
                    placeholder="Enter your name"
                    disabled={isSubmitting}
                    class:dev={state === "dev"}
                />
                {#if errors.email}
                    <span class="error-message">{errors.email}</span>
                {/if}
            </div>

            <div class:dev={state === "dev"}>
                <label for="password">Password:</label>
                <input
                    id="password"
                    type="password"
                    name="password"
                    bind:value={password}
                    placeholder="Enter your password"
                    class:error={errors.password}
                    disabled={isSubmitting}
                    class:dev={state === "dev"}
                />
                {#if errors.password}
                    <span class="error-message">{errors.password}</span>
                {/if}
            </div>

            <button
                class:dev={state === "dev"}
                type="submit"
                disabled={isSubmitting}
            >
                {isSubmitting ? "Creating user..." : "Sign Up"}
            </button>
        </form>
    </main>
</div>
