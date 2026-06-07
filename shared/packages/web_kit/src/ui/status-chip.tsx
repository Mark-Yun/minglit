// StatusChip — 상태 칩 (web_user_purchases spec: pill · padding 3/9 · 11.5/600)
// tone 어휘는 domain/status-vocab.ts 의 StatusTone 과 1:1.
// 색은 MDS 토큰 CSS 변수 (@minglit/mds-tokens tokens.css) — 12% tint bg + 의미색 텍스트.
import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";
import type { StatusChipSpec } from "../domain/status-vocab";
import { cn } from "./cn";

export const statusChipVariants = cva(
  "inline-flex items-center whitespace-nowrap rounded-[var(--radius-chip)] px-[9px] py-[3px] text-[11.5px] font-semibold leading-none",
  {
    variants: {
      tone: {
        success:
          "bg-[color-mix(in_srgb,var(--color-success)_12%,transparent)] text-[var(--color-success)]",
        warning:
          "bg-[color-mix(in_srgb,var(--color-warning)_12%,transparent)] text-[var(--color-warning)]",
        info: "bg-[color-mix(in_srgb,var(--color-info)_12%,transparent)] text-[var(--color-info)]",
        error:
          "bg-[color-mix(in_srgb,var(--color-error)_12%,transparent)] text-[var(--color-error)]",
        neutral:
          "bg-[color-mix(in_srgb,var(--color-text-secondary)_12%,transparent)] text-[var(--color-text-secondary)]",
      },
    },
    defaultVariants: {
      tone: "neutral",
    },
  },
);

export interface StatusChipProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof statusChipVariants> {
  /** status-vocab 의 chip spec — label/tone 한 번에 (예: PURCHASE_STATUS_CHIPS[key]) */
  spec?: StatusChipSpec;
}

export function StatusChip({
  spec,
  tone,
  className,
  children,
  ...props
}: StatusChipProps) {
  return (
    <span
      className={cn(statusChipVariants({ tone: tone ?? spec?.tone }), className)}
      {...props}
    >
      {children ?? spec?.label}
    </span>
  );
}
