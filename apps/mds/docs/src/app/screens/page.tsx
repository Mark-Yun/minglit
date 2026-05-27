import RouteScreenIndex from '@/components/RouteScreenIndex';

export default function ScreensPage() {
  return (
    <div className="max-w-5xl space-y-8">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Route → Screen Index
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">Screens</h1>
        <p className="text-[var(--color-text-secondary)]">
          Every GoRouter route mapped to its screen widget, route declaration, and Dart source.
          Click a page name to open its MDS spec; use{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded">code ↗</code>{' '}
          for the widget source.
        </p>
      </div>
      <RouteScreenIndex />
    </div>
  );
}
