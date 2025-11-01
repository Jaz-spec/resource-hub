<script lang="ts">
    import { onMount } from "svelte";
    import { invalidate } from "$app/navigation";

    import NavBar from "$lib/NavBar.svelte";

    let { data, children } = $props();
    let { session, supabase } = $derived(data);

    onMount(() => {
        const { data } = supabase.auth.onAuthStateChange((_, newSession) => {
            if (newSession?.expires_at !== session?.expires_at) {
                invalidate("supabase:auth");
            }
        });
        return () => data.subscription.unsubscribe();
    });
</script>

<NavBar {data} />
<main class="dev">
    {@render children()}
</main>
<footer class="dev">
    <p>Footer</p>
</footer>
