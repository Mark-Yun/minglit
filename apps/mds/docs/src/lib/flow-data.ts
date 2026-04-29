/**
 * Navigation flow charts — shared between /flows (client renderer) and
 * any in-page anchor consumers.
 *
 * When routes change, update both the Mermaid charts here AND regenerate
 * route-pages.json (see scripts/parse-routes.py — eventually).
 */

import routePagesData from './route-pages.json';

interface RoutePageEntry { widget: string | null; file: string | null }
interface RoutePagesMap { user: Record<string, RoutePageEntry>; partner: Record<string, RoutePageEntry> }

const ROUTE_PAGES = routePagesData as RoutePagesMap;

// ---------------------------------------------------------------------------
// app_user
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
// app_partner
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

// ---------------------------------------------------------------------------
// Diagram metadata
// ---------------------------------------------------------------------------

export interface DiagramSpec {
  id: string;
  title: string;
  attribution: string;
  app: 'user' | 'partner';
  chart: string;
}

export const RAW_DIAGRAMS: DiagramSpec[] = [
  {
    id: 'user-auth',
    title: 'app_user — Auth & Consent Flow',
    attribution: 'apps/app_user/lib/src/routing/app_router.dart (redirect logic)',
    app: 'user',
    chart: APP_USER_AUTH_FLOW,
  },
  {
    id: 'user-main',
    title: 'app_user — Main Navigation',
    attribution: 'apps/app_user/lib/src/routing/app_routes.dart',
    app: 'user',
    chart: APP_USER_MAIN_FLOW,
  },
  {
    id: 'partner-onboarding',
    title: 'app_partner — Onboarding Flow',
    attribution: 'apps/app_partner/lib/src/routing/app_router.dart (onboardingStateProvider redirect)',
    app: 'partner',
    chart: APP_PARTNER_ONBOARDING_FLOW,
  },
  {
    id: 'partner-main',
    title: 'app_partner — Main Navigation (StatefulShell)',
    attribution: 'apps/app_partner/lib/src/routing/app_routes.dart',
    app: 'partner',
    chart: APP_PARTNER_MAIN_FLOW,
  },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const ROUTE_REGEX = /\b(\w+Route)\b/g;

/** Extract unique route node names from a Mermaid chart string. */
export function extractRoutes(chart: string): string[] {
  const set = new Set<string>();
  for (const m of chart.matchAll(ROUTE_REGEX)) set.add(m[1]);
  return [...set].sort();
}

/**
 * Mermaid v11 stateDiagram-v2 does NOT support the `click` directive
 * (parse error). Click navigation is wired post-render in
 * MermaidDiagram.tsx by reading `data-app` and matching node labels.
 * Kept as a no-op for API stability.
 */
export function withClicks(chart: string, _app: 'user' | 'partner'): string {
  return chart;
}

/**
 * Group all unique route nodes by app (deduplicating across diagrams of
 * the same app).
 */
export function getRoutesByApp(): { user: string[]; partner: string[] } {
  const groups: { user: Set<string>; partner: Set<string> } = {
    user: new Set(),
    partner: new Set(),
  };
  for (const d of RAW_DIAGRAMS) {
    for (const r of extractRoutes(d.chart)) groups[d.app].add(r);
  }
  return {
    user: [...groups.user].sort(),
    partner: [...groups.partner].sort(),
  };
}

/** Source-of-truth GitHub URL per app's router. */
export function githubUrlFor(app: 'user' | 'partner'): string {
  const path = `apps/app_${app}/lib/src/routing/app_routes.dart`;
  return `https://github.com/Mark-Yun/minglit/blob/dev/${path}`;
}

/** Widget class name for a route (e.g. EventDetailRoute → EventDetailPage). */
export function widgetNameFor(app: 'user' | 'partner', route: string): string | null {
  return ROUTE_PAGES[app]?.[route]?.widget ?? null;
}

/**
 * Map of route → static wireframe HTML path under `/public/specs/`.
 * Add an entry here when a wireframe is authored. The Design column in
 * the flows table lights up automatically.
 */
const ROUTE_DESIGNS: Record<string, string> = {
  'user-MyPageRoute':           '/specs/my_page.html',
  'user-LoginRoute':            '/specs/login_page.html',
  'user-HomeRoute':             '/specs/home_page.html',
  'user-EventDetailRoute':      '/specs/event_detail_page.html',
  'partner-PartyCreateRoute':   '/specs/party_create_wizard_page.html',
  'partner-PartyEditRoute':     '/specs/party_create_wizard_page.html',
  'partner-SettlementDetailRoute': '/specs/settlement_detail_page.html',
};

/** Whether a screen design (wireframe / screenshot) is available for this route. */
export function hasDesignFor(app: 'user' | 'partner', route: string): boolean {
  return `${app}-${route}` in ROUTE_DESIGNS;
}

/** URL of the wireframe / screenshot for this route (or null). */
export function designUrlFor(app: 'user' | 'partner', route: string): string | null {
  return ROUTE_DESIGNS[`${app}-${route}`] ?? null;
}

/**
 * GitHub URL of the actual screen widget file.
 * Falls back to the routes file if the widget file is unknown.
 */
export function screenSourceFor(app: 'user' | 'partner', route: string): {
  url: string; isWidget: boolean; filePath: string;
} {
  const entry = ROUTE_PAGES[app]?.[route];
  if (entry?.file) {
    return {
      url: `https://github.com/Mark-Yun/minglit/blob/dev/${entry.file}`,
      isWidget: true,
      filePath: entry.file,
    };
  }
  const routesPath = `apps/app_${app}/lib/src/routing/app_routes.dart`;
  return {
    url: `https://github.com/Mark-Yun/minglit/blob/dev/${routesPath}`,
    isWidget: false,
    filePath: routesPath,
  };
}

/**
 * Augment a Mermaid stateDiagram with `Node : Label` directives so each
 * RouteName node renders the corresponding widget class name (e.g. HomePage)
 * while keeping the route ID as the transition key.
 */
export function withWidgetLabels(chart: string, app: 'user' | 'partner'): string {
  const labels: string[] = [];
  for (const route of extractRoutes(chart)) {
    const widget = widgetNameFor(app, route);
    if (widget) labels.push(`  ${route} : ${widget}`);
  }
  if (labels.length === 0) return chart;
  // Insert labels after the first stateDiagram line (after `direction TB` or similar)
  const lines = chart.split('\n');
  const firstNonHeader = lines.findIndex((l, i) => i > 0 && !/direction/.test(l) && l.trim() !== '');
  const insertAt = firstNonHeader === -1 ? lines.length : firstNonHeader;
  lines.splice(insertAt, 0, ...labels);
  return lines.join('\n');
}
