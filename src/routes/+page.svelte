<script lang="ts">
    import { getContext } from "svelte";

    let getState = getContext("state");
    let state = $derived(getState());
</script>

<h1 class:dev={state === "dev"}>Main page</h1>
<a href="/login" class:dev={state === "dev"}>Login</a>
