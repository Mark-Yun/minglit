'use client';

import { StatsigProvider } from '@statsig/react-bindings';
import { useMemo } from 'react';

interface Props {
  children: React.ReactNode;
}

function getOrCreateStableId(): string {
  if (typeof window === 'undefined') return 'ssr';
  const key = 'statsig_stable_id';
  const existing = window.localStorage.getItem(key);
  if (existing) return existing;
  const created = window.crypto.randomUUID();
  window.localStorage.setItem(key, created);
  return created;
}

export function StatsigAnalyticsProvider({ children }: Props) {
  const clientKey = process.env.NEXT_PUBLIC_STATSIG_CLIENT_KEY ?? '';
  const stableId = useMemo(() => getOrCreateStableId(), []);

  if (!clientKey || clientKey === 'FILL_THIS') {
    return <>{children}</>;
  }

  return (
    <StatsigProvider
      sdkKey={clientKey}
      user={{ userID: stableId }}
    >
      {children}
    </StatsigProvider>
  );
}
