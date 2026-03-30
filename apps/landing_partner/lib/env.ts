/**
 * Validate that all required build-time env vars for landing_partner are present.
 *
 * Call from `next.config.ts` so missing variables fail the build early.
 */
export function validateBuildEnv(): void {
  // Fix #447: lazy require to avoid module resolution failure on Vercel
  // where the monorepo root is outside the build directory
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const manifest = require("../../../env-manifest.json");
  const section = manifest.nextjs.landing_partner;
  const required = Object.keys(section.required);
  const missing = required.filter((k) => !process.env[k]);

  if (missing.length > 0) {
    throw new Error(
      `[env-manifest] landing_partner missing required env vars: ${missing.join(", ")}\n` +
        "Set them in Vercel Environment Variables or a local .env file.",
    );
  }
}
