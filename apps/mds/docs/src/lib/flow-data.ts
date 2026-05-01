/**
 * Navigation flow charts — shared between /flows (client renderer) and
 * any in-page anchor consumers.
 *
 * Edge style legend:
 *   `-->`   solid = direct route push (router.push / router.go)
 *   `-.->`  dashed = overlay route or embedded widget — same router stack
 *           but presented as modal sheet, dialog, or composed sub-screen
 *           (e.g. EventNowBar tap → bottom-sheet routes).
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

const APP_USER_AUTH_FLOW = `flowchart TB
  Start([App start]) --> HomeRoute
  HomeRoute -->|"tap protected route (not logged in)"| LoginRoute
  LoginRoute -->|"login success"| HomeRoute
  LoginRoute -->|"login success + no required consents"| SignupConsentRoute
  SignupConsentRoute -->|"consents accepted"| HomeRoute
  AuthCallbackRoute -->|"OAuth redirect handled"| HomeRoute
  HomeRoute -->|"tap verify account (/certification)"| CertificationRoute
`;

const APP_USER_MAIN_FLOW = `flowchart TB
  %% Hub widget (not a route — signals overlay sheet group).
  EventNowBar[["EventNowBar widget"]]

  %% From HomePage AppBar / feed / tag bars (verified against home_page.dart).
  HomeRoute -->|"tap search"| SearchRoute
  HomeRoute -->|"tap notifications"| NotificationCenterRoute
  HomeRoute -->|"tap avatar (/my)"| MyPageRoute
  HomeRoute -->|"tap event card"| EventDetailRoute
  HomeRoute -->|"tap tag chip"| TagEventListRoute

  %% From SearchPage (search_coordinator:18).
  SearchRoute -->|"tap result"| EventDetailRoute

  %% From EventDetailPage / EventApplicationWizardPage (event_coordinator).
  EventDetailRoute -->|"tap partner"| PartnerDetailRoute
  EventDetailRoute -->|"tap apply (/events/:eventId/apply)"| EventApplicationRoute
  EventApplicationRoute -->|"submit success → /my/purchases"| PurchaseHistoryRoute

  %% From PartnerDetailPage / PartnerEventsPage (partner_coordinator).
  PartnerDetailRoute -->|"view all events"| PartnerEventsRoute
  PartnerDetailRoute -->|"tap event"| EventDetailRoute
  PartnerEventsRoute -->|"tap event"| EventDetailRoute

  %% From TagEventListPage (event_coordinator.goToEventDetail).
  TagEventListRoute -->|"tap event"| EventDetailRoute

  %% From MyPage (my_page.dart → homeCoordinator).
  MyPageRoute -->|"my tickets"| MyTicketsRoute
  MyPageRoute -->|"purchase history"| PurchaseHistoryRoute
  MyPageRoute -->|"notification settings"| NotificationSettingsRoute
  MyPageRoute -->|"account management"| AccountManagementRoute
  MyPageRoute -->|"privacy"| PrivacyRoute
  MyPageRoute -->|"blocked partners"| BlockedPartnersRoute

  %% From MyTicketsPage (appCoordinator).
  MyTicketsRoute -->|"tap card"| EventDetailRoute
  MyTicketsRoute -->|"view QR"| TicketQRRoute

  %% Account deletion flow (from PrivacyRoute).
  PrivacyRoute -->|"start account deletion"| DeletionReasonRoute
  DeletionReasonRoute -->|"select reason"| DeletionInfoRoute
  DeletionInfoRoute -->|"confirm"| DeletionVerifyRoute
  DeletionVerifyRoute -->|"verified"| DeletionCompleteRoute

  %% EventNowBar overlay hub — 5 phase routed bottom-sheets (Material 3 sheet-route).
  %% Bar widget is embedded in HomePage; tap pushes one of 5 routes presented as sheet.
  HomeRoute -.->|"embeds (bottomSheet slot)"| EventNowBar
  EventNowBar -.->|"checkInReady"| EventCheckInRoute
  EventNowBar -.->|"checkedIn"| EventCheckedInRoute
  EventNowBar -.->|"matching"| EventMatchingRoute
  EventNowBar -.->|"results"| EventResultsRoute
  EventNowBar -.->|"ended"| EventReviewRoute
`;

// ---------------------------------------------------------------------------
// app_partner
// ---------------------------------------------------------------------------

const APP_PARTNER_ONBOARDING_FLOW = `flowchart LR
  Start([App start]) -->|"not logged in → redirect"| LoginRoute
  LoginRoute -->|"login success + needsApplication"| PartnerWelcomeRoute
  PartnerWelcomeRoute -->|"start application (/apply)"| PartnerApplyRoute
  PartnerApplyRoute -->|"submit → pending review (/apply/status)"| PartnerApplyStatusRoute
  PartnerApplyStatusRoute -->|"approved → hasPartner"| HomeRoute
`;

const APP_PARTNER_MAIN_FLOW = `flowchart TB
  Start([Start]) --> HomeRoute
  HomeRoute -->|"view location guide"| LocationGuideRoute
  HomeRoute -->|"bottom nav"| ApplicationListRoute
  ApplicationListRoute -->|"tap event application"| EventApplicationDetailRoute
  ApplicationListRoute -->|"tap partner application"| ApplicationDetailRoute
  HomeRoute -->|"bottom nav"| CheckinRoute
  HomeRoute -->|"bottom nav (SETTLEMENT_VIEW role required)"| SettlementRoute
  SettlementRoute -->|"tap settlement item"| SettlementDetailRoute
  SettlementRoute -->|"manage bank account"| BankAccountRoute
  HomeRoute -->|"bottom nav"| MoreRoute
  MoreRoute -->|"manage parties (/more/parties)"| PartyListRoute
  PartyListRoute -->|"create party"| PartyCreateRoute
  PartyListRoute -->|"tap party"| PartyDetailRoute
  PartyDetailRoute -->|"edit party"| PartyEditRoute
  PartyDetailRoute -->|"create event"| EventCreateRoute
  PartyDetailRoute -->|"tap event"| EventDetailRoute
  EventDetailRoute -->|"create ticket"| TicketCreateRoute
  EventDetailRoute -->|"edit ticket"| TicketEditRoute
  PartyDetailRoute -->|"manage recurrence"| RecurrenceManagementRoute
  MoreRoute -->|"verifications"| VerificationManageRoute
  VerificationManageRoute -->|"create verification"| CreateVerificationRoute
  MoreRoute -->|"member management"| MemberListRoute
  MemberListRoute -->|"set permission"| MemberPermissionRoute
  MoreRoute -->|"account (/more/account)"| PartnerAccountManagementRoute
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
 * Spec files that exist under `/public/specs/`, scoped per app.
 *
 * Routes (e.g. `EventDetailRoute`, `LoginRoute`) repeat across the two apps
 * but map to different widgets — partner's `EventDetailPage` is a partner
 * management screen, not the consumer-facing one. Tracking per-app prevents
 * the partner index from claiming user-only specs.
 *
 * Default mapping rule: RouteName → snake_case basename + `_page` suffix.
 *   `EventDetailRoute` → `event_detail_page.html`
 *   `MyPageRoute`      → `my_page.html` (already ends with `_page`)
 *   `LoginRoute`       → `login_page.html`
 *
 * Special cases (shared specs across apps, non-default basenames) →
 * ROUTE_DESIGN_OVERRIDES.
 */
const KNOWN_SPEC_FILES: { user: ReadonlySet<string>; partner: ReadonlySet<string> } = {
  user: new Set([
    'event_detail_page',
    'home_page',
    'login_page',
    'my_page',
  ]),
  partner: new Set([
    // partner currently has no top-level specs that match the default rule;
    // its specs are reached via ROUTE_DESIGN_OVERRIDES below.
  ]),
};

/** Routes that share specs or use non-default basenames. */
const ROUTE_DESIGN_OVERRIDES: Record<string, string> = {
  'partner-PartyCreateRoute':     '/specs/party_create_wizard_page.html',
  'partner-PartyEditRoute':       '/specs/party_create_wizard_page.html', // shares spec
  'partner-SettlementDetailRoute':'/specs/settlement_detail_page.html',
};

/**
 * Sub-component specs that have no route of their own — they're embedded
 * inside a parent screen but get their own spec because they carry significant
 * state/behavior worth documenting separately. The /screens index lists them
 * under their parent route as nested rows.
 */
export interface SubComponentSpec {
  widget: string;          // e.g. 'EventBottomTicketBar'
  parentRoute: string;     // e.g. 'EventDetailRoute' — must exist in route diagrams
  filePath: string;        // dart source (relative to repo root)
  specBasename: string;    // public/specs/ filename without .html
}

const SUB_COMPONENT_SPECS: { user: SubComponentSpec[]; partner: SubComponentSpec[] } = {
  user: [
    {
      widget: 'EventBottomTicketBar',
      parentRoute: 'EventDetailRoute',
      filePath: 'apps/app_user/lib/src/features/event/detail/event_bottom_ticket_bar.dart',
      specBasename: 'event_bottom_ticket_bar',
    },
    {
      widget: 'EventNowBar',
      parentRoute: 'HomeRoute',
      filePath: 'apps/app_user/lib/src/features/home/widgets/event_now_bar.dart',
      specBasename: 'event_now_bar',
    },
    {
      widget: 'MinglitEventCard',
      parentRoute: 'HomeRoute',
      filePath: 'shared/packages/minglit_kit/lib/src/widgets/event_card/minglit_event_card.dart',
      specBasename: 'event_card',
    },
  ],
  partner: [],
};

/** Sub-component specs for an app. Used by /screens to render nested rows. */
export function subComponentsFor(app: 'user' | 'partner'): SubComponentSpec[] {
  return SUB_COMPONENT_SPECS[app];
}

/** RouteName → snake_case spec basename (without .html). Default rule only. */
function deriveSpecBasename(route: string): string {
  const stripped = route.replace(/Route$/, ''); // 'EventDetail' or 'MyPage'
  const snake = stripped
    .replace(/([A-Z])/g, '_$1')
    .toLowerCase()
    .replace(/^_/, ''); // 'event_detail' or 'my_page'
  return snake.endsWith('_page') ? snake : `${snake}_page`;
}

/** Whether a screen design (wireframe / screenshot) is available for this route. */
export function hasDesignFor(app: 'user' | 'partner', route: string): boolean {
  return designUrlFor(app, route) !== null;
}

/** URL of the wireframe / screenshot for this route (or null). */
export function designUrlFor(app: 'user' | 'partner', route: string): string | null {
  const override = ROUTE_DESIGN_OVERRIDES[`${app}-${route}`];
  if (override) return override;
  const basename = deriveSpecBasename(route);
  return KNOWN_SPEC_FILES[app].has(basename) ? `/specs/${basename}.html` : null;
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
 * Augment a Mermaid flowchart with `Node["Label"]` declarations so each
 * RouteName node renders the corresponding widget class name (e.g. HomePage)
 * while keeping the route ID as the transition key.
 */
export function withWidgetLabels(chart: string, app: 'user' | 'partner'): string {
  const labels: string[] = [];
  for (const route of extractRoutes(chart)) {
    const widget = widgetNameFor(app, route);
    if (widget) labels.push(`  ${route}["${widget}"]`);
  }
  if (labels.length === 0) return chart;
  // Insert labels right after the `flowchart TB|LR` header line.
  const lines = chart.split('\n');
  const insertAt = lines.findIndex((l, i) => i > 0 && l.trim() !== '');
  const target = insertAt === -1 ? lines.length : insertAt;
  lines.splice(target, 0, ...labels);
  return lines.join('\n');
}
