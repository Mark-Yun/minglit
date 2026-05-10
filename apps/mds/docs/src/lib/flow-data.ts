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
  MyPageRoute -->|"tap profile"| AccountManagementRoute
  MyPageRoute -->|"privacy"| PrivacyRoute
  MyPageRoute -->|"blocked partners"| BlockedPartnersRoute

  %% From MyTicketsPage (v2 — OngoingBanner stack hub).
  %% Empty state CTAs to PurchaseHistory / HomePage; banner footer actions go to 5 sheets (shared with EventNowBar).
  MyTicketsRoute -->|"tap banner body"| EventDetailRoute
  MyTicketsRoute -->|"empty: 구매내역 보기"| PurchaseHistoryRoute
  MyTicketsRoute -->|"empty: 이벤트 둘러보기"| HomeRoute
  MyTicketsRoute -.->|"banner: checkIn / preview"| EventCheckInRoute
  MyTicketsRoute -.->|"banner: checkedIn"| EventCheckedInRoute
  MyTicketsRoute -.->|"banner: matching"| EventMatchingRoute
  MyTicketsRoute -.->|"banner: results"| EventResultsRoute
  MyTicketsRoute -.->|"banner: review"| EventReviewRoute

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
  EventDetailRoute -->|"tap hero (일정)"| EventEditRoute
  EventDetailRoute -->|"tap 참가 현황"| EventApplicationListRoute
  EventApplicationListRoute -->|"tap application card"| EventApplicationDetailRoute
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
    'account_management_page',
    'auth_callback_page',
    'blocked_partners_page',
    'deletion_complete_page',
    'deletion_info_page',
    'deletion_reason_page',
    'deletion_verify_page',
    'event_application_wizard_page',
    'event_check_in_screen',
    'event_checked_in_screen',
    'event_detail_page',
    'event_matching_screen',
    'event_results_screen',
    'event_review_screen',
    'home_page',
    'identity_verification_screen',
    'login_page',
    'my_page',
    'my_tickets_page',
    'notification_list_screen',
    'notification_settings_screen',
    'partner_detail_page',
    'partner_events_page',
    'privacy_page',
    'purchase_history_page',
    'search_page',
    'signup_consent_page',
    'tag_event_list_page',
    'ticket_qr_screen',
  ]),
  partner: new Set([
    'account_management_page',
    'bank_account_page',
    'checkin_placeholder_page',
    'create_verification_page',
    'event_application_detail_page',
    'event_application_list_page',
    'event_application_manage_page',
    'event_create_page',
    'event_edit_page',
    'location_guide_page',
    'more_page',
    'notification_list_screen',
    'notification_settings_screen',
    'partner_application_detail_page',
    'partner_apply_page',
    'partner_apply_status_page',
    'partner_event_detail_page',
    'partner_home_page',
    'partner_login_page',
    'partner_member_list_page',
    'partner_member_permission_page',
    'partner_welcome_page',
    'party_detail_page',
    'party_list_page',
    'recurrence_management_screen',
    'settlement_page',
    'ticket_create_page',
    'ticket_edit_page',
    'verification_manage_page',
    // remaining partner specs are reached via ROUTE_DESIGN_OVERRIDES below.
  ]),
};

/** Routes that share specs or use non-default basenames. */
const ROUTE_DESIGN_OVERRIDES: Record<string, string> = {
  'partner-HomeRoute':            '/specs/partner_home_page/index.html',
  'partner-PartyCreateRoute':     '/specs/party_create_wizard_page/index.html',
  'partner-PartyEditRoute':       '/specs/party_create_wizard_page/index.html', // shares spec
  // PartyTicketEditRoute hosts the same TicketEditPage widget as TicketEditRoute,
  // but with eventId='' (template mode). Default rule for TicketEditRoute already
  // resolves to ticket_edit_page; override the party-scoped variant explicitly.
  'partner-PartyTicketEditRoute': '/specs/ticket_edit_page/index.html',
  'partner-SettlementDetailRoute':'/specs/settlement_detail_page/index.html',
  // Partner EventDetailRoute → partner-side EventDetailPage (운영 관리 + 참가 신청 탭).
  // Default rule yields 'event_detail_page' which would point to the user-side spec —
  // override to the partner-specific spec.
  'partner-EventDetailRoute':     '/specs/partner_event_detail_page/index.html',
  // AccountManagementPage → kit-shared widget. Default rule for user yields
  // 'account_management_page' (already matches), but partner's
  // PartnerAccountManagementRoute would derive 'partner_account_management_page'
  // — override both routes to the shared spec basename.
  'user-AccountManagementRoute':         '/specs/account_management_page/index.html',
  'partner-PartnerAccountManagementRoute':'/specs/account_management_page/index.html',
  // NotificationCenterRoute → kit-shared NotificationListScreen widget. Default rule
  // would derive 'notification_center_page', but the spec basename matches the widget.
  'user-NotificationCenterRoute':    '/specs/notification_list_screen/index.html',
  'partner-NotificationCenterRoute': '/specs/notification_list_screen/index.html',
  // NotificationSettingsRoute → kit-shared NotificationSettingsScreen widget. Default
  // rule yields 'notification_settings_page', but the spec basename matches the widget.
  'user-NotificationSettingsRoute':    '/specs/notification_settings_screen/index.html',
  'partner-NotificationSettingsRoute': '/specs/notification_settings_screen/index.html',
  // ApplicationListRoute → default rule yields 'application_list_page', but the
  // actual widget is EventApplicationManagePage. Override to its real spec.
  'partner-ApplicationListRoute':    '/specs/event_application_manage_page/index.html',
  // EventApplicationRoute → default rule yields 'event_application_page', but
  // the widget is EventApplicationWizardPage. Override to its real spec.
  'user-EventApplicationRoute':      '/specs/event_application_wizard_page/index.html',
  // EventResultsRoute → default rule yields 'event_results_page', but the
  // routed bottom-sheet widget is EventResultsScreen. Override to its real spec.
  'user-EventResultsRoute':          '/specs/event_results_screen/index.html',
  // EventCheckInRoute → default rule yields 'event_check_in_page', but the
  // routed bottom-sheet widget is EventCheckInScreen (kit-shared). Override.
  'user-EventCheckInRoute':          '/specs/event_check_in_screen/index.html',
  // EventCheckedInRoute → default rule yields 'event_checked_in_page', but the
  // routed bottom-sheet widget is EventCheckedInScreen (kit-shared). Override.
  'user-EventCheckedInRoute':        '/specs/event_checked_in_screen/index.html',
  // EventReviewRoute → default rule yields 'event_review_page', but the
  // routed bottom-sheet widget is EventReviewScreen. Override to its real spec.
  'user-EventReviewRoute':           '/specs/event_review_screen/index.html',
  // EventMatchingRoute → default rule yields 'event_matching_page', but the
  // routed bottom-sheet widget is EventMatchingScreen (matching/matchingReady
  // states share the same route). Override to its real spec.
  'user-EventMatchingRoute':         '/specs/event_matching_screen/index.html',
  // CertificationRoute (user) → kit-shared IdentityVerificationScreen. Default
  // rule yields 'certification_page', override to the widget-named spec basename.
  'user-CertificationRoute':         '/specs/identity_verification_screen/index.html',
  // TicketQRRoute → widget is TicketQRScreen. Default rule yields 'ticket_qr_page'.
  'user-TicketQRRoute':              '/specs/ticket_qr_screen/index.html',
  // Partner LoginRoute → PartnerLoginPage (NOT the user app's LoginPage). Default
  // rule yields 'login_page', which would point to the user spec — override to
  // the partner-specific spec.
  'partner-LoginRoute':              '/specs/partner_login_page/index.html',
  // CheckinRoute → CheckinPlaceholderPage. Default rule yields 'checkin_page'.
  'partner-CheckinRoute':            '/specs/checkin_placeholder_page/index.html',
  // ApplicationDetailRoute (partner) → PartnerApplicationDetailPage (admin-side
  // partner application review). Distinct from EventApplicationDetailRoute.
  'partner-ApplicationDetailRoute':  '/specs/partner_application_detail_page/index.html',
  // MemberListRoute → PartnerMemberListPage. Default rule yields 'member_list_page'.
  'partner-MemberListRoute':         '/specs/partner_member_list_page/index.html',
  // MemberPermissionRoute → PartnerMemberPermissionPage. Default would be
  // 'member_permission_page'.
  'partner-MemberPermissionRoute':   '/specs/partner_member_permission_page/index.html',
  // RecurrenceManagementRoute → RecurrenceManagementScreen. Default would be
  // 'recurrence_management_page'.
  'partner-RecurrenceManagementRoute':'/specs/recurrence_management_screen/index.html',
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
