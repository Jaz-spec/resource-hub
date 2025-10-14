import { redirect } from "@sveltejs/kit";

import type { Actions } from "./$types.js";

export const actions: Actions = {
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
