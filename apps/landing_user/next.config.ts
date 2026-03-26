import type { NextConfig } from "next";
import { validateBuildEnv } from "./lib/env";

// Validate required env vars at build time (skipped in CI where secrets are not available)
if (process.env.NODE_ENV === "production" && !process.env.CI) {
  validateBuildEnv();
}

const nextConfig: NextConfig = {
  /* config options here */
};

export default nextConfig;
