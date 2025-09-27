<script lang="ts">
    import { getContext } from "svelte";

    // TODO: typecheck
    let getState: any = getContext("state");
    let state = $derived(getState());
</script>

<h1 class:dev={state === "dev"}>Main page</h1>
