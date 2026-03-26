import manifest from "../../../env-manifest.json";

/**
 * Validate that all required build-time env vars for landing_user are present.
 *
 * Call from `next.config.ts` so missing variables fail the build early.
 */
export function validateBuildEnv(): void {
  const section = manifest.nextjs.landing_user;
  const required = Object.keys(section.required);
  const missing = required.filter((k) => !process.env[k]);

  if (missing.length > 0) {
    throw new Error(
      `[env-manifest] landing_user missing required env vars: ${missing.join(", ")}\n` +
        "Set them in Vercel Environment Variables or a local .env file.",
    );
  }
}
