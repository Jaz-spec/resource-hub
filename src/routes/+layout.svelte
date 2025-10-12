<script lang="ts">
    import { setContext, onMount } from "svelte";
    import { invalidate } from "$app/navigation";

    let { data, children } = $props();
    let { session, supabase } = $derived(data);
    let state = $state("dev");

    setContext("state", () => state);

    onMount(() => {
        const { data } = supabase.auth.onAuthStateChange((_, newSession) => {
            if (newSession?.expires_at !== session?.expires_at) {
                invalidate("supabase:auth");
            }
        });
        return () => data.subscription.unsubscribe();
    });
</script>

<header class="nav">
    <a href="/" class:dev={state === "dev"}>Home</a>
    <a href="/auth" class:dev={state === "dev"}>Sign Up</a>
    <a href="/login" class:dev={state === "dev"}>Login</a>
    <form method="POST" action="?/logout">
        <button type="submit" class:dev={state === "dev"}>Logout</button>
    </form>

    <div>
        <button
            class:dev={state === "dev"}
            onclick={() => {
                bind: state = "dev";
            }}>DEV</button
        >
        <button
            class:dev={state === "dev"}
            onclick={() => {
                bind: state = "admin";
            }}>ADMIN</button
        >
        <button
            class:dev={state === "dev"}
            onclick={() => {
                bind: state = "user";
            }}>USER</button
        >
    </div>
</header>
<main class:dev={state === "dev"}>
    {@render children()}
</main>
<footer class:dev={state === "dev"}>
    <p>Footer</p>
</footer>
