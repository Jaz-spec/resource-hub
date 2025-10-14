<script lang="ts">
    import { getContext } from "svelte";

    // TODO typecheck
    let getState: any = getContext("state");
    let state = $derived(getState());
    import AuthForm from "$lib/authForm.svelte";
</script>

<AuthForm action="?/login" />
