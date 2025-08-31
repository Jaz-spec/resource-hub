import { type Handle, redirect } from "@sveltejs/kit";
import { sequence } from "@sveltejs/kit/hooks";
import { createServerClient } from "@supabase/ssr";

import dotenv from "dotenv";
dotenv.config();

const supabase: Handle = async ({ event, resolve }) => {
  //The Supabase client gets the Auth token from the request cookies.

  const supabaseUrl = process.env.PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error("Missing Supabase environment variables");
  } else {
    //create client
    event.locals.supabase = createServerClient(supabaseUrl, supabaseKey, {
      //set cookies
      cookies: {
        getAll: () => event.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) => {
            event.cookies.set(name, value, { ...options, path: "/" });
          });
        },
      },
    });

    event.locals.safeGetSession = async () => {
      //gets session
      const {
        data: { session },
      } = await event.locals.supabase.auth.getSession();
      if (!session) {
        return { session: null, user: null };
      }

      //calls get user to vaidate JWT
      const {
        data: { user },
        error,
      } = await event.locals.supabase.auth.getUser();
      if (error) {
        return { session: null, user: null };
      }

      return { session, user };
    };

    return resolve(event, {
      filterSerializedResponseHeaders(name) {
        //Tells sveltekit to send `content-range` and `x-supabase-api-version` headers through.
        return name === "content-range" || name === "x-supabase-api-version";
      },
    });
  }
};

const authGuard: Handle = async ({ event, resolve }) => {
  const { session, user } = await event.locals.safeGetSession();

  event.locals.session = session;
  event.locals.user = user;

  if (!event.locals.session && event.url.pathname.startsWith("/private")) {
    redirect(303, "/auth");
  }

  if (event.locals.session && event.url.pathname === "/auth") {
    redirect(303, "/private");
  }

  return resolve(event);
};

export const handle: Handle = sequence(supabase, authGuard);
