'use client';

import { useEffect, useRef } from 'react';

interface MermaidDiagramProps {
  chart: string;
  id: string;
}

export default function MermaidDiagram({ chart, id }: MermaidDiagramProps) {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancelled = false;

    async function render() {
      if (!containerRef.current) return;

      const mermaid = (await import('mermaid')).default;

      mermaid.initialize({
        startOnLoad: false,
        theme: 'default',
        themeVariables: {
          primaryColor: '#9900FF',
          primaryTextColor: '#111827',
          primaryBorderColor: '#9900FF',
          lineColor: '#4B5563',
          secondaryColor: '#F9FAFB',
          tertiaryColor: '#F9FAFB',
        },
      });

      if (cancelled) return;

      try {
        const { svg } = await mermaid.render(`mermaid-${id}`, chart);
        if (containerRef.current && !cancelled) {
          containerRef.current.innerHTML = svg;
        }
      } catch (err) {
        if (containerRef.current && !cancelled) {
          containerRef.current.innerHTML = `<pre class="text-red-500 text-xs p-4">${String(err)}</pre>`;
        }
      }
    }

    render();
    return () => {
      cancelled = true;
    };
  }, [chart, id]);

  return (
    <div
      ref={containerRef}
      className="overflow-x-auto bg-white rounded-xl border border-[var(--color-divider)] p-4 min-h-32"
    >
      <p className="text-xs text-[var(--color-text-secondary)]">Loading diagram...</p>
    </div>
  );
}
