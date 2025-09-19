<script lang="ts">
    let name = "";
    let password = "";
    let errors: Errors = {};
    let isSubmitting = false;

    interface Errors {
        name?: string;
        password?: string;
    }

    function validateForm() {
        if (!name.trim()) {
            errors.name = "Name is required";
        } else if (name.trim().length < 2) {
            errors.name = "Name must be at least 2 characters";
        }

        if (!password) {
            errors.password = "Password is required";
        } else if (password.length < 6) {
            errors.password = "Password must be at least 6 characters";
        }

        return Object.keys(errors).length === 0;
    }

    async function handleSubmit() {
        if (!validateForm()) return;

        isSubmitting = true;

        try {
            console.log("Login attempt:", { name, password });
            //request to server
            console.log("Login successful!");
        } catch (error) {
            console.error(error);
        } finally {
            isSubmitting = false;
        }
    }
</script>

<div class="container dev">
    <nav>
        <a href="/" class="dev">Home</a>
    </nav>

    <main class="dev">
        <form on:submit|preventDefault={handleSubmit} class="login-form">
            <div class="dev">
                <label for="name">Name:</label>
                <input
                    id="name"
                    type="text"
                    bind:value={name}
                    placeholder="Enter your name"
                    disabled={isSubmitting}
                    class="dev"
                />
                {#if errors.name}
                    <span class="error-message">{errors.name}</span>
                {/if}
            </div>

            <div class="dev">
                <label for="password">Password:</label>
                <input
                    id="password"
                    type="password"
                    bind:value={password}
                    placeholder="Enter your password"
                    class:error={errors.password}
                    disabled={isSubmitting}
                    class="dev"
                />
                {#if errors.password}
                    <span class="error-message">{errors.password}</span>
                {/if}
            </div>

            <button class="dev" type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Logging in..." : "Login"}
            </button>
        </form>
    </main>
</div>
