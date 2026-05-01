import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    resolveAlias: {
      "@upsetjs/venn.js": "./src/lib/empty-stub.ts",
    },
  },
};

export default nextConfig;
