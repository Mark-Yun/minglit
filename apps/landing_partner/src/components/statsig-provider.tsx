'use client';

import { StatsigProvider } from '@statsig/react-bindings';

interface Props {
  children: React.ReactNode;
}

export function StatsigAnalyticsProvider({ children }: Props) {
  const clientKey = process.env.NEXT_PUBLIC_STATSIG_CLIENT_KEY ?? '';

  // No-op if key not set
  if (!clientKey || clientKey === 'FILL_THIS') {
    return <>{children}</>;
  }

  return (
    <StatsigProvider
      sdkKey={clientKey}
      user={{ userID: 'anonymous' }}
    >
      {children}
    </StatsigProvider>
  );
}
