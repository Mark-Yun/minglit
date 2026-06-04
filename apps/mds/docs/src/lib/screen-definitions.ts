import {
  designUrlFor,
  getRoutesByApp,
  screenSourceFor,
  standaloneSpecsFor,
  subComponentsFor,
  widgetNameFor,
} from './flow-data';

export type ScreenSurfaceId = 'user' | 'partner' | 'web_admin';

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
    if (surface.id === 'web_admin') {
      return { surface, screens: WEB_ADMIN_SCREENS };
    }

    return { surface, screens: flutterRouteScreens(surface.id) };
  });
}
