"use client";

import { useEffect, useState } from "react";
import { getSupabaseBrowserClient } from "./supabase";

export type AuthGender = "male" | "female";

export type AuthState = {
  status: "loading" | "anonymous" | "ready";
  isVerified: boolean;
  gender: AuthGender | null;
};

const LOADING: AuthState = { status: "loading", isVerified: false, gender: null };
const ANONYMOUS: AuthState = { status: "anonymous", isVerified: false, gender: null };

type ProfileRow = { is_verified: boolean | null; gender: AuthGender | null };

/**
 * Client-only auth snapshot shared by the user web surfaces.
 *
 * - "loading": session probe in flight (render skeleton / disabled controls).
 * - "anonymous": missing env, signed-out, or profile lookup failed.
 * - "ready": signed in AND user_profiles row fetched successfully.
 *
 * `isVerified` mirrors user_profiles.is_verified (same column fetchUserVerified
 * reads); `gender` mirrors user_profiles.gender (null = unset).
 */
export function useAuthState(): AuthState {
  const [state, setState] = useState<AuthState>(LOADING);

  useEffect(() => {
    let active = true;

    async function load() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        if (active) setState(ANONYMOUS);
        return;
      }

      const { data, error } = await supabase.auth.getSession();
      const user = data.session?.user;
      if (error || !user) {
        if (active) setState(ANONYMOUS);
        return;
      }

      try {
        const { data: profile, error: profileError } = await supabase
          .from("user_profiles")
          .select("is_verified,gender")
          .eq("id", user.id)
          .single<ProfileRow>();

        if (profileError) throw profileError;
        if (!active) return;

        setState({
          status: "ready",
          isVerified: profile?.is_verified === true,
          gender: profile?.gender ?? null,
        });
      } catch {
        if (active) setState(ANONYMOUS);
      }
    }

    void load();

    return () => {
      active = false;
    };
  }, []);

  return state;
}
