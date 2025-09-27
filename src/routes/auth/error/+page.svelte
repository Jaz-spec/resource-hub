<script lang="ts">
    import { getContext } from "svelte";

    //TODO typecheck
    let state: any = getContext("state");
</script>

<p class:dev={state === "dev"}>
    You have been redirected to the Error page: Login Error
</p>
