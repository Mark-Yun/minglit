// Fix #1721: Import @next/eslint-plugin-next directly instead of
// eslint-config-next/core-web-vitals. The core-web-vitals entry point loads
// eslint-config-next/dist/parser.js which requires
// next/dist/compiled/babel/eslint-parser — a file removed in next@16+.
// Direct plugin usage bypasses parser.js entirely. React/react-hooks/jsx-a11y
// plugins are wired explicitly to preserve the lint coverage that
// eslint-config-next/core-web-vitals would have provided via its base config.
import { defineConfig, globalIgnores } from "eslint/config";
import nextPlugin from "@next/eslint-plugin-next";
import nextTs from "eslint-config-next/typescript";
import reactPlugin from "eslint-plugin-react";
import reactHooksPlugin from "eslint-plugin-react-hooks";
import jsxA11y from "eslint-plugin-jsx-a11y";

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
  // eslint-plugin-react@7.x uses context.getFilename() which is not available
  // in flat config. Providing version explicitly avoids the detectReactVersion
  // call that triggers the crash. Remove once eslint-plugin-react supports flat config.
  {
    plugins: {
      react: reactPlugin,
      "react-hooks": reactHooksPlugin,
      "jsx-a11y": jsxA11y,
    },
    rules: {
      ...reactPlugin.configs["jsx-runtime"].rules,
      ...reactHooksPlugin.configs.recommended.rules,
      ...jsxA11y.configs.recommended.rules,
    },
    settings: {
      react: { version: "19" },
    },
  },
  ...nextTs,
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
