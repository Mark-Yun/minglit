import {
  designUrlFor,
  getRoutesByApp,
  screenSourceFor,
  standaloneSpecsFor,
  subComponentsFor,
  widgetNameFor,
} from './flow-data';

export type ScreenSurfaceId = 'user' | 'partner' | 'web_admin' | 'web_user' | 'web_partner';

export type ScreenKind = 'route' | 'sub-component' | 'spec-only' | 'web-route';

export type ScreenStatus = 'specified' | 'missing-spec' | 'planned';

export interface ScreenSurface {
  id: ScreenSurfaceId;
  label: string;
  description: string;
}

export interface ScreenDefinition {
  id: string;
  surface: ScreenSurfaceId;
  kind: ScreenKind;
  status: ScreenStatus;
  screen: string | null;
  route: string;
  specBasename?: string;
  routeSourcePath?: string;
  codeSourcePath?: string;
  codeSourceExists?: boolean;
  parentRoute?: string;
  note?: string;
}

export interface ScreenGroup {
  surface: ScreenSurface;
  screens: ScreenDefinition[];
}

export const SCREEN_SURFACES: ScreenSurface[] = [
  {
    id: 'user',
    label: 'app_user',
    description: 'Consumer Flutter app routes and embedded user-facing screen specs.',
  },
  {
    id: 'partner',
    label: 'app_partner',
    description: 'Partner Flutter app routes, operations screens, and partner admin surfaces.',
  },
  {
    id: 'web_admin',
    label: 'web_admin',
    description: 'Desktop web admin console screens. Defined manually until apps/admin_web exists.',
  },
  {
    id: 'web_user',
    label: 'web_user',
    description:
      'Consumer web screens (landing_user extension). Mobile-web-first; manual registry, web specs authored from /specs/_template_web.html.',
  },
  {
    id: 'web_partner',
    label: 'web_partner',
    description:
      'Partner web screens (landing_partner extension). Desktop-first; manual registry, web specs authored from /specs/_template_web.html.',
  },
];

const WEB_ADMIN_SCREENS: ScreenDefinition[] = [
  {
    id: 'web_admin:admin-console-dashboard',
    surface: 'web_admin',
    kind: 'web-route',
    status: 'planned',
    screen: 'AdminConsoleDashboard',
    route: '/admin',
    specBasename: 'admin_console_dashboard',
    codeSourcePath: 'apps/admin_web/',
    codeSourceExists: false,
    note: 'P0 shell/entry: Supabase Google OAuth login, admin guard, extensible menu frame.',
  },
];

// Web MVP pivot: user/partner web screens are new web specs (mobile app specs
// remain as behavior sources). Register each authored spec here following the
// WEB_ADMIN_SCREENS shape — no route-pages.json / flow-data dependency.
const WEB_USER_SCREENS: ScreenDefinition[] = [
  {
    id: 'web_user:home',
    surface: 'web_user',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebUserHome',
    route: '/',
    specBasename: 'web_user_home',
    codeSourcePath: 'apps/landing_user/',
    codeSourceExists: false,
    note: 'Web MVP pilot (1280 baseline): header + eligibility checkbox + event card grid. Behavior source: home_page, event_card.',
  },
  {
    id: 'web_user:event-detail',
    surface: 'web_user',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebUserEventDetail',
    route: '/events/:id',
    specBasename: 'web_user_event_detail',
    codeSourcePath: 'apps/landing_user/',
    codeSourceExists: false,
    note: '2-col: info + sticky ticket panel. Behavior source: event_detail_page, event_bottom_ticket_bar, ticket_selection_sheet.',
  },
  {
    id: 'web_user:checkout',
    surface: 'web_user',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebUserCheckout',
    route: '/events/:id/checkout',
    specBasename: 'web_user_checkout',
    codeSourcePath: 'apps/landing_user/',
    codeSourceExists: false,
    note: 'Order summary + consent + Portone V2 pay; approval-pending model (pay != confirmed). Behavior source: event_application_wizard_page.',
  },
  {
    id: 'web_user:purchases',
    surface: 'web_user',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebUserPurchases',
    route: '/my/purchases',
    specBasename: 'web_user_purchases',
    codeSourcePath: 'apps/landing_user/',
    codeSourceExists: false,
    note: 'Master-detail purchases + refund request (policy v2). No QR — name-based entry. Behavior source: purchase_history_page/detail.',
  },
];

const WEB_PARTNER_SCREENS: ScreenDefinition[] = [
  {
    id: 'web_partner:home',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerHome',
    route: '/dashboard',
    specBasename: 'web_partner_home',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Web MVP pilot (1280 baseline): sidebar console + today-first dashboard. Behavior source: partner_home_page.',
  },
  {
    id: 'web_partner:login',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerLogin',
    route: '/login',
    specBasename: 'web_partner_login',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Centered OAuth card; no signup (manual onboarding). Behavior source: partner_login_page.',
  },
  {
    id: 'web_partner:party-events',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerPartyEvents',
    route: '/events',
    specBasename: 'web_partner_party_events',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Party-grouped event hub: recurrence badge, occurrence table, cancel w/ refund notice. Behavior source: party_list_page, party_detail_page.',
  },
  {
    id: 'web_partner:party-create',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerPartyCreate',
    route: '/parties/new',
    specBasename: 'web_partner_party_create',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Create/edit party: ticket templates (gender/age as ticket attrs) + recurrence. Behavior source: party_create_wizard_page, ticket_create_page.',
  },
  {
    id: 'web_partner:event-edit',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerEventEdit',
    route: '/events/new',
    specBasename: 'web_partner_event_edit',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Single occurrence create/edit; tickets read-only (party-owned); cancel = full auto refund. Behavior source: event_create_page, event_edit_page.',
  },
  {
    id: 'web_partner:applications',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerApplications',
    route: '/applications',
    specBasename: 'web_partner_applications',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Approve/reject + roster (printable, name-based entry). Reject = auto full refund. Behavior source: event_application_manage_page.',
  },
  {
    id: 'web_partner:settlements',
    surface: 'web_partner',
    kind: 'web-route',
    status: 'planned',
    screen: 'WebPartnerSettlements',
    route: '/settlements',
    specBasename: 'web_partner_settlements',
    codeSourcePath: 'apps/landing_partner/',
    codeSourceExists: false,
    note: 'Read-only settlements (14d hold, fee breakdown) + bank account. Behavior source: settlement_page, bank_account_page.',
  },
];

const STATIC_WEB_SCREENS: Record<
  Exclude<ScreenSurfaceId, 'user' | 'partner'>,
  ScreenDefinition[]
> = {
  web_admin: WEB_ADMIN_SCREENS,
  web_user: WEB_USER_SCREENS,
  web_partner: WEB_PARTNER_SCREENS,
};

function appPathSegment(app: 'user' | 'partner'): 'app_user' | 'app_partner' {
  return app === 'user' ? 'app_user' : 'app_partner';
}

function specBasenameFromUrl(url: string | null): string | undefined {
  const match = url?.match(/^\/specs\/([^/]+)\/index\.html$/);
  return match?.[1];
}

function flutterRouteScreens(app: 'user' | 'partner'): ScreenDefinition[] {
  const routes = getRoutesByApp()[app];
  const routeSourcePath = `apps/${appPathSegment(app)}/lib/src/routing/app_routes.dart`;
  const rows: ScreenDefinition[] = [];

  for (const route of routes) {
    const designUrl = designUrlFor(app, route);
    const screenSource = screenSourceFor(app, route);
    const specBasename = specBasenameFromUrl(designUrl);

    rows.push({
      id: `${app}:${route}`,
      surface: app,
      kind: 'route',
      status: specBasename ? 'specified' : 'missing-spec',
      screen: widgetNameFor(app, route),
      route,
      specBasename,
      routeSourcePath,
      codeSourcePath: screenSource.isWidget ? screenSource.filePath : undefined,
      codeSourceExists: screenSource.isWidget,
    });

    for (const sub of subComponentsFor(app).filter((s) => s.parentRoute === route)) {
      rows.push({
        id: `${app}:${route}:sub:${sub.widget}`,
        surface: app,
        kind: 'sub-component',
        status: 'specified',
        screen: sub.widget,
        route: `(sub of ${route})`,
        specBasename: sub.specBasename,
        codeSourcePath: sub.filePath,
        codeSourceExists: true,
        parentRoute: route,
      });
    }
  }

  for (const spec of standaloneSpecsFor(app)) {
    rows.push({
      id: `${app}:standalone:${spec.specBasename}`,
      surface: app,
      kind: 'spec-only',
      status: 'specified',
      screen: spec.widget,
      route: 'spec-only',
      specBasename: spec.specBasename,
      note: spec.note,
    });
  }

  return rows;
}

export function getScreenGroups(): ScreenGroup[] {
  return SCREEN_SURFACES.map((surface) => {
    if (surface.id === 'user' || surface.id === 'partner') {
      return { surface, screens: flutterRouteScreens(surface.id) };
    }

    return { surface, screens: STATIC_WEB_SCREENS[surface.id] };
  });
}
