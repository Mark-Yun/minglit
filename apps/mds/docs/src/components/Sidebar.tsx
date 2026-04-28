'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';

const navItems = [
  { href: '/', label: 'Home' },
  { href: '/tokens', label: 'Tokens' },
  { href: '/icons', label: 'Icons' },
  { href: '/components', label: 'Components' },
  { href: '/flows', label: 'Flows' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  const navList = (
    <ul className="space-y-1">
      {navItems.map(({ href, label }) => {
        const isActive =
          href === '/' ? pathname === '/' : pathname.startsWith(href);
        return (
          <li key={href}>
            <Link
              href={href}
              onClick={() => setMobileOpen(false)}
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
    </ul>
  );

  return (
    <>
      {/* Mobile top bar (< md) */}
      <header className="md:hidden sticky top-0 z-40 flex items-center justify-between bg-white border-b border-[var(--color-divider)] px-4 py-3">
        <Link href="/" className="flex items-baseline gap-2">
          <span className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)]">
            Minglit
          </span>
          <span className="text-sm font-bold text-[var(--color-primary)]">
            Design System
          </span>
        </Link>
        <button
          aria-label="Toggle navigation"
          aria-expanded={mobileOpen}
          onClick={() => setMobileOpen(!mobileOpen)}
          className="px-2 py-1 rounded-md border border-[var(--color-divider)] text-sm text-[var(--color-text-primary)]"
        >
          {mobileOpen ? '✕' : '☰'}
        </button>
      </header>

      {/* Mobile drawer (< md) */}
      {mobileOpen && (
        <div className="md:hidden fixed inset-0 z-30 bg-black/40" onClick={() => setMobileOpen(false)}>
          <div
            className="absolute top-12 left-0 right-0 bg-white border-b border-[var(--color-divider)] p-4"
            onClick={(e) => e.stopPropagation()}
          >
            {navList}
          </div>
        </div>
      )}

      {/* Desktop sidebar (>= md) */}
      <aside className="hidden md:flex fixed top-0 left-0 h-full w-56 bg-white border-r border-[var(--color-divider)] z-40 flex-col">
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
        <nav className="flex-1 px-3 py-4 overflow-y-auto">{navList}</nav>
        <div className="px-6 py-4 border-t border-[var(--color-divider)]">
          <p className="text-xs text-[var(--color-text-secondary)]">Phase 1</p>
          <p className="text-xs text-[var(--color-divider)] mt-0.5">v26.04.1900-dev</p>
        </div>
      </aside>
    </>
  );
}
