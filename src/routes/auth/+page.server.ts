import { redirect } from "@sveltejs/kit";

import type { Actions } from "./$types.js";

export const actions: Actions = {
  signup: async ({ request, locals: { supabase } }) => {
    console.log("=== Calling signUp ===");
    try {
      const formData = await request.formData();
      const email = formData.get("email") as string;
      const password = formData.get("password") as string;
      console.log("Email:", email, "Password length:", password?.length);

      const name = formData.get("name") as string;
      const { error } = await supabase.auth.signUp({
        email: email,
        password: password,
        options: {
          data: {
            name: name,
          },
        },
      });
      if (error) {
        console.error("Supabase error:", error);
        //redirect(303, "/auth/error");
      } else {
        console.log("Signup successful, no error");
        //redirect(303, "/");
      }
    } catch (err) {
      console.error("Action error:", err);
    }
  },
  login: async ({ request, locals: { supabase } }) => {
    console.log("=== Calling Login ===");
    const formData = await request.formData();
    const email = formData.get("email") as string;
    const password = formData.get("password") as string;

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) {
      console.error(error);
      redirect(303, "/auth/error");
    } else {
      redirect(303, "/private");
    }
  },
  logout: async ({ locals: { supabase } }) => {
    const { error } = await supabase.auth.signOut();

    if (error) {
      console.error(error);
      redirect(303, "/auth/error");
    }
    console.log("Logout successful");
    redirect(303, "/");
  },
};
