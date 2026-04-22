// Fix #1721: eslint-config-next/dist/index.js loads ./parser which requires
// next/dist/compiled/babel/eslint-parser — a file removed in Next.js 16+.
// We replicate the full eslint-config-next base config inline, replacing the
// broken babel parser with @typescript-eslint/parser (already used by the
// 'next/typescript' overlay for .ts/.tsx). All plugins, rules, globs, globals,
// and import-resolver settings from eslint-config-next v16.2.3 are preserved.
import { defineConfig, globalIgnores } from "eslint/config";
import nextPlugin from "@next/eslint-plugin-next";
import nextTs from "eslint-config-next/typescript";
import reactPlugin from "eslint-plugin-react";
import reactHooksPlugin from "eslint-plugin-react-hooks";
import jsxA11y from "eslint-plugin-jsx-a11y";
import * as importPlugin from "eslint-plugin-import";
import globals from "globals";

const eslintConfig = defineConfig([
  // Mirrors eslint-config-next/dist/index.js "next" config block,
  // with @typescript-eslint/parser replacing the missing babel parser.
  {
    name: "next",
    files: ["**/*.{js,jsx,mjs,ts,tsx,mts,cts}"],
    plugins: {
      "@next/next": nextPlugin,
      react: reactPlugin,
      "react-hooks": reactHooksPlugin,
      "jsx-a11y": jsxA11y,
      import: importPlugin,
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    settings: {
      // eslint-plugin-react@7.x uses context.getFilename() in flat config;
      // pinning version avoids the detectReactVersion crash.
      react: { version: "19" },
      "import/parsers": {
        "@typescript-eslint/parser": [".ts", ".mts", ".cts", ".tsx", ".d.ts"],
      },
      "import/resolver": {
        node: { extensions: [".js", ".jsx", ".ts", ".tsx"] },
        typescript: { alwaysTryTypes: true },
      },
    },
    rules: {
      ...reactPlugin.configs["jsx-runtime"].rules,
      ...reactHooksPlugin.configs.recommended.rules,
      ...nextPlugin.configs.recommended.rules,
      ...nextPlugin.configs["core-web-vitals"].rules,
      "import/no-anonymous-default-export": "warn",
      "jsx-a11y/alt-text": [
        "warn",
        { elements: ["img"], img: ["Image"] },
      ],
      "jsx-a11y/aria-props": "warn",
      "jsx-a11y/aria-proptypes": "warn",
      "jsx-a11y/aria-unsupported-elements": "warn",
      "jsx-a11y/role-has-required-aria-props": "warn",
      "jsx-a11y/role-supports-aria-props": "warn",
      "react/jsx-no-target-blank": "off",
      "react/no-unknown-property": "off",
      "react/react-in-jsx-scope": "off",
      "react/prop-types": "off",
    },
  },
  // TypeScript overlay: @typescript-eslint/parser + recommended rules for .ts/.tsx
  ...nextTs,
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
]);

export default eslintConfig;
