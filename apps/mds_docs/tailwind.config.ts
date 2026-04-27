import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        "mds-primary": "var(--color-primary)",
        "mds-secondary": "var(--color-secondary)",
        "mds-tertiary": "var(--color-tertiary)",
        "mds-surface": "var(--color-surface)",
        "mds-background": "var(--color-background)",
        "mds-error": "var(--color-error)",
        "mds-text-primary": "var(--color-text-primary)",
        "mds-text-secondary": "var(--color-text-secondary)",
        "mds-success": "var(--color-success)",
        "mds-info": "var(--color-info)",
        "mds-warning": "var(--color-warning)",
        "mds-divider": "var(--color-divider)",
        "mds-partner-primary": "var(--color-partner-primary)",
        "mds-glitch-cyan": "var(--color-glitch-cyan)",
      },
      spacing: {
        "mds-xs": "var(--spacing-xsmall)",
        "mds-sm": "var(--spacing-small)",
        "mds-md": "var(--spacing-medium)",
        "mds-lg": "var(--spacing-large)",
        "mds-xl": "var(--spacing-xlarge)",
        "mds-xxl": "var(--spacing-xxlarge)",
      },
      borderRadius: {
        "mds-sm": "var(--radius-small)",
        "mds-btn": "var(--radius-button)",
        "mds-card": "var(--radius-card)",
        "mds-dialog": "var(--radius-dialog)",
        "mds-chip": "var(--radius-chip)",
      },
    },
  },
  plugins: [],
};

export default config;
