// VENDORED — synced from shared/packages/mds/icons/react/src/generated/index.tsx
// Update by running: npm run icons:sync (inside apps/mds/docs/)
// Do NOT edit manually — re-sync from source when icons change.

import * as React from 'react';

export interface MdsIconProps extends React.SVGProps<SVGSVGElement> {
  size?: number | string;
}

/** add icon. Inherits color via currentColor. */
export const Add: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="M5 12h14M12 5v14"/>
  </svg>
);

/** check icon. Inherits color via currentColor. */
export const Check: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="M20 6 9 17l-5-5"/>
  </svg>
);

/** chevron_right icon. Inherits color via currentColor. */
export const ChevronRight: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="m9 18 6-6-6-6"/>
  </svg>
);

/** close icon. Inherits color via currentColor. */
export const Close: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="M18 6 6 18M6 6l12 12"/>
  </svg>
);

/** more_vert icon. Inherits color via currentColor. */
export const MoreVert: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/>
  </svg>
);

/** notifications icon. Inherits color via currentColor. */
export const Notifications: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="M10.268 21a2 2 0 0 0 3.464 0M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>
  </svg>
);

/** person icon. Inherits color via currentColor. */
export const Person: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
  </svg>
);

/** search icon. Inherits color via currentColor. */
export const Search: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={2}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...props}
  >
    <path d="m21 21-4.34-4.34"/><circle cx="11" cy="11" r="8"/>
  </svg>
);

/** Registry of all icons keyed by snake_case name. */
export const MdsIcons = {
  'add': Add,
  'check': Check,
  'chevron_right': ChevronRight,
  'close': Close,
  'more_vert': MoreVert,
  'notifications': Notifications,
  'person': Person,
  'search': Search,
} as const;

export type MdsIconName = keyof typeof MdsIcons;
