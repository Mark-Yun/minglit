'use client';

import dynamic from 'next/dynamic';

const MermaidDiagram = dynamic(() => import('@/components/MermaidDiagram'), {
  ssr: false,
  loading: () => (
    <div className="bg-white rounded-xl border border-[var(--color-divider)] p-8 text-center text-sm text-[var(--color-text-secondary)]">
      Loading diagram...
    </div>
  ),
});

// ---------------------------------------------------------------------------
// Diagrams derived from:
//   apps/app_user/lib/src/routing/app_routes.dart
//   apps/app_user/lib/src/routing/app_router.dart
// ---------------------------------------------------------------------------

const APP_USER_AUTH_FLOW = `stateDiagram-v2
  direction TB
  [*] --> HomeRoute : initial "/" (not protected)
  HomeRoute --> LoginRoute : tap protected route (not logged in)
  LoginRoute --> HomeRoute : login success
  LoginRoute --> SignupConsentRoute : login success + no required consents
  SignupConsentRoute --> HomeRoute : consents accepted
  AuthCallbackRoute --> HomeRoute : OAuth redirect handled
  HomeRoute --> CertificationRoute : tap verify account (/certification)
`;

const APP_USER_MAIN_FLOW = `stateDiagram-v2
  direction TB
  HomeRoute --> SearchRoute : tap search
  HomeRoute --> EventDetailRoute : tap event card (/events/:eventId)
  HomeRoute --> PartnerDetailRoute : tap partner card (/partners/:partnerId)
  HomeRoute --> TagEventListRoute : tap tag (/tags/:tagId)
  PartnerDetailRoute --> PartnerEventsRoute : view all events (/partners/:partnerId/events)
  EventDetailRoute --> EventApplicationRoute : tap apply (/events/:eventId/apply)
  HomeRoute --> NotificationCenterRoute : tap notifications (/notifications)
  HomeRoute --> MyPageRoute : tap my page (/my)
  MyPageRoute --> NotificationSettingsRoute : notification settings
  MyPageRoute --> AccountManagementRoute : account management (/my/account)
  MyPageRoute --> PrivacyRoute : privacy (/my/privacy)
  PrivacyRoute --> DeletionReasonRoute : start account deletion
  DeletionReasonRoute --> DeletionInfoRoute : select reason
  DeletionInfoRoute --> DeletionVerifyRoute : confirm
  DeletionVerifyRoute --> DeletionCompleteRoute : verified
  HomeRoute --> MyTicketsRoute : my tickets (/tickets/my)
  MyTicketsRoute --> TicketQRRoute : view QR (/tickets/:ticketId/qr)
  HomeRoute --> PurchaseHistoryRoute : purchase history
  MyPageRoute --> BlockedPartnersRoute : blocked partners
`;

// ---------------------------------------------------------------------------
// Diagrams derived from:
//   apps/app_partner/lib/src/routing/app_routes.dart
//   apps/app_partner/lib/src/routing/app_router.dart
// ---------------------------------------------------------------------------

const APP_PARTNER_ONBOARDING_FLOW = `stateDiagram-v2
  direction LR
  [*] --> LoginRoute : not logged in → redirect
  LoginRoute --> PartnerWelcomeRoute : login success + needsApplication
  PartnerWelcomeRoute --> PartnerApplyRoute : start application (/apply)
  PartnerApplyRoute --> PartnerApplyStatusRoute : submit → pending review (/apply/status)
  PartnerApplyStatusRoute --> HomeRoute : approved → hasPartner
`;

const APP_PARTNER_MAIN_FLOW = `stateDiagram-v2
  direction TB
  HomeRoute : Home (/)
  ApplicationListRoute : Applications (/applications)
  CheckinRoute : Check-in (/checkin)
  SettlementRoute : Settlement (/settlement)
  MoreRoute : More (/more)

  [*] --> HomeRoute
  HomeRoute --> LocationGuideRoute : view location guide
  HomeRoute --> ApplicationListRoute : bottom nav
  ApplicationListRoute --> EventApplicationDetailRoute : tap event application
  ApplicationListRoute --> ApplicationDetailRoute : tap partner application
  HomeRoute --> CheckinRoute : bottom nav
  HomeRoute --> SettlementRoute : bottom nav (SETTLEMENT_VIEW role required)
  SettlementRoute --> SettlementDetailRoute : tap settlement item
  SettlementRoute --> BankAccountRoute : manage bank account
  HomeRoute --> MoreRoute : bottom nav
  MoreRoute --> PartyListRoute : manage parties (/more/parties)
  PartyListRoute --> PartyCreateRoute : create party
  PartyListRoute --> PartyDetailRoute : tap party
  PartyDetailRoute --> PartyEditRoute : edit party
  PartyDetailRoute --> EventCreateRoute : create event
  PartyDetailRoute --> EventDetailRoute : tap event
  EventDetailRoute --> TicketCreateRoute : create ticket
  EventDetailRoute --> TicketEditRoute : edit ticket
  PartyDetailRoute --> RecurrenceManagementRoute : manage recurrence
  MoreRoute --> VerificationManageRoute : verifications
  VerificationManageRoute --> CreateVerificationRoute : create verification
  MoreRoute --> MemberListRoute : member management
  MemberListRoute --> MemberPermissionRoute : set permission
  MoreRoute --> PartnerAccountManagementRoute : account (/more/account)
`;

const diagrams = [
  {
    id: 'user-auth',
    title: 'app_user — Auth & Consent Flow',
    attribution: 'apps/app_user/lib/src/routing/app_router.dart (redirect logic)',
    chart: APP_USER_AUTH_FLOW,
  },
  {
    id: 'user-main',
    title: 'app_user — Main Navigation',
    attribution: 'apps/app_user/lib/src/routing/app_routes.dart',
    chart: APP_USER_MAIN_FLOW,
  },
  {
    id: 'partner-onboarding',
    title: 'app_partner — Onboarding Flow',
    attribution: 'apps/app_partner/lib/src/routing/app_router.dart (onboardingStateProvider redirect)',
    chart: APP_PARTNER_ONBOARDING_FLOW,
  },
  {
    id: 'partner-main',
    title: 'app_partner — Main Navigation (StatefulShell)',
    attribution: 'apps/app_partner/lib/src/routing/app_routes.dart',
    chart: APP_PARTNER_MAIN_FLOW,
  },
];

export default function FlowsPage() {
  return (
    <div className="max-w-5xl space-y-10">
      {/* Header */}
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Navigation Flows
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">Flows</h1>
        <p className="text-[var(--color-text-secondary)]">
          Navigation graphs for <strong>app_user</strong> and <strong>app_partner</strong>,
          derived directly from GoRouter route definitions. Route names match the
          Dart class names (e.g.{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            EventDetailRoute
          </code>
          ).
        </p>
        <div className="mt-3 p-3 bg-[var(--color-surface)] rounded-lg border border-[var(--color-divider)] text-sm text-[var(--color-text-secondary)]">
          <strong className="text-[var(--color-warning)]">Manual update required:</strong> These
          diagrams are hand-authored from the routing source. When routes change, update this
          file:{' '}
          <code className="text-xs bg-white px-1 rounded">
            apps/mds/docs/src/app/flows/page.tsx
          </code>
          . Automated generation is planned for a future phase.
        </div>
      </div>

      {/* Diagrams */}
      {diagrams.map((d) => (
        <section key={d.id} className="space-y-3">
          <div>
            <h2 className="text-lg font-bold text-[var(--color-text-primary)]">{d.title}</h2>
            <p className="text-xs text-[var(--color-text-secondary)] mt-0.5">
              Generated from{' '}
              <code className="bg-[var(--color-surface)] px-1 rounded">{d.attribution}</code>
            </p>
          </div>
          <MermaidDiagram chart={d.chart} id={d.id} />
        </section>
      ))}
    </div>
  );
}
