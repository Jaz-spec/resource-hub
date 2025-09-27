<script lang="ts">
    import { getContext } from "svelte";

    // TODO typecheck
    let getState: any = getContext("state");
    let state = $derived(getState());
</script>

<div class="container" class:dev={state === "dev"}>
    <h1>Soon to be Login page</h1>
</div>
