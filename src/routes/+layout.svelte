<script lang="ts">
    import { setContext } from "svelte";

    let { children } = $props();

    let state = $state("dev");
    setContext("state", () => state);
</script>

<header>
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
</header>
<main class:dev={state === "dev"}>
    {@render children()}
</main>
<footer class:dev={state === "dev"}>
    <p>Footer</p>
</footer>
