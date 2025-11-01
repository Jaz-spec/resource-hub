<script lang="ts">
    let { data } = $props();
</script>

<header class="nav">
    <a href="/" class="dev">Home</a>
    {#if data.session}
        <a href="/auth" class="dev">Create new admin</a>
        <form method="POST" action="?/logout">
            <button type="submit" class="dev">Logout</button>
        </form>
    {:else}
        <a href="/login" class="dev">Admin</a>
    {/if}
</header>
