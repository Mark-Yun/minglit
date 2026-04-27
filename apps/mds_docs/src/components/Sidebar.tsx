'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/', label: 'Home' },
  { href: '/tokens', label: 'Tokens' },
  { href: '/screens', label: 'Screens' },
  { href: '/flows', label: 'Flows' },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed top-0 left-0 h-full w-56 bg-white border-r border-[var(--color-divider)] z-40 flex flex-col">
      {/* Logo */}
      <div className="px-6 py-5 border-b border-[var(--color-divider)]">
        <Link href="/" className="block">
          <span className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)]">
            Minglit
          </span>
          <h1 className="text-base font-bold text-[var(--color-primary)] leading-tight mt-0.5">
            Design System
          </h1>
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto">
        <ul className="space-y-1">
          {navItems.map(({ href, label }) => {
            const isActive =
              href === '/' ? pathname === '/' : pathname.startsWith(href);
            return (
              <li key={href}>
                <Link
                  href={href}
                  className={`flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-[var(--color-primary)] text-white'
                      : 'text-[var(--color-text-secondary)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text-primary)]'
                  }`}
                >
                  {label}
                </Link>
              </li>
            );
          })}
          {/* Coming soon placeholder */}
          <li>
            <span className="flex items-center px-3 py-2 rounded-lg text-sm font-medium text-[var(--color-divider)] cursor-not-allowed select-none">
              Components
              <span className="ml-2 text-xs bg-[var(--color-surface)] text-[var(--color-text-secondary)] px-1.5 py-0.5 rounded">
                soon
              </span>
            </span>
          </li>
        </ul>
      </nav>

      {/* Footer */}
      <div className="px-6 py-4 border-t border-[var(--color-divider)]">
        <p className="text-xs text-[var(--color-text-secondary)]">Phase 1</p>
        <p className="text-xs text-[var(--color-divider)] mt-0.5">v26.04.1900-dev</p>
      </div>
    </aside>
  );
}
