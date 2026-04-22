// Fix #1721: Import @next/eslint-plugin-next directly instead of
// eslint-config-next/core-web-vitals. The core-web-vitals entry point loads
// eslint-config-next/dist/parser.js which requires
// next/dist/compiled/babel/eslint-parser — a file removed in next@16+.
// Direct plugin usage bypasses parser.js entirely.
import { defineConfig, globalIgnores } from "eslint/config";
import nextPlugin from "@next/eslint-plugin-next";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  {
    plugins: {
      "@next/next": nextPlugin,
    },
    rules: {
      ...nextPlugin.configs.recommended.rules,
      ...nextPlugin.configs["core-web-vitals"].rules,
    },
  },
  ...nextTs,
  // eslint-plugin-react@7.x uses context.getFilename() which is not available
  // in flat config. Providing version explicitly avoids the detectReactVersion
  // call that triggers the crash. Remove once eslint-plugin-react supports flat config.
  {
    settings: {
      react: { version: "19" },
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
]);

export default eslintConfig;
