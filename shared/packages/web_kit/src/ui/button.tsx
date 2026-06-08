// Button — MDS 토큰 스킨 기본 버튼 (radius-button 12px · primary/surface 토큰)
// radix-ui 프리미티브 copy-in 컴포넌트는 후속 — 구조만 시작 (web-client.md §4).
import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";
import { cn } from "./cn";

export const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 rounded-[var(--radius-button)] font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        primary:
          "bg-[var(--color-primary)] text-white hover:bg-[var(--color-primary-dark)]",
        secondary:
          "border border-[var(--color-divider)] bg-[var(--color-background)] text-[var(--color-text-primary)] hover:bg-[var(--color-surface)]",
        ghost:
          "bg-transparent text-[var(--color-text-primary)] hover:bg-[var(--color-surface)]",
        destructive:
          "bg-[var(--color-error)] text-white hover:opacity-90",
      },
      size: {
        sm: "h-9 px-3 text-[13px]",
        md: "h-11 px-4 text-[14px]",
        lg: "h-[52px] px-5 text-[15px]",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  },
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function Button({
  className,
  variant,
  size,
  type = "button",
  ...props
}: ButtonProps) {
  return (
    <button
      type={type}
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  );
}
