import type { NextConfig } from "next";
import { validateBuildEnv } from "./lib/env";

// Validate required env vars at build time (skipped during linting)
if (process.env.NODE_ENV === "production") {
  validateBuildEnv();
}

const nextConfig: NextConfig = {
  /* config options here */
};

export default nextConfig;
