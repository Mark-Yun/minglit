import RouteScreenIndex from '@/components/RouteScreenIndex';

export default function ScreensPage() {
  return (
    <div className="max-w-5xl space-y-8">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Screen Registry
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">Screens</h1>
        <p className="text-[var(--color-text-secondary)]">
          Screen definitions grouped by surface: app_user, app_partner, and web_admin.
          Flutter app rows are derived from GoRouter route maps; web_admin starts as a
          manual registry until its app root exists. Click a screen name to open its MDS spec; use{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded">code ↗</code>{' '}
          for implementation source when it exists.
        </p>
      </div>
      <RouteScreenIndex />
    </div>
  );
}
