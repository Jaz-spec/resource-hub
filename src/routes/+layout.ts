import type { LayoutLoad } from "./$types.js";
import {
  createBrowserClient,
  createServerClient,
  isBrowser,
} from "@supabase/ssr";
import dotenv from "dotenv";
dotenv.config();

export const load: LayoutLoad = async ({ fetch, data, depends }) => {
  depends("supabase:auth");

  const supabaseUrl = process.env.PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error("missing environmental variables - public supabase keys");
  }
  const supabase = isBrowser()
    ? createBrowserClient(supabaseUrl, supabaseKey, {
        global: {
          fetch,
        },
      })
    : createServerClient(supabaseUrl, supabaseKey, {
        global: {
          fetch,
        },
        cookies: {
          getAll() {
            return data.cookies;
          },
        },
      });
  const {
    data: { session },
  } = await supabase.auth.getSession();

  return { supabase, session };
};
