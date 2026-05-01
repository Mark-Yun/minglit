/**
 * /components/template — visible authoring guide for new component specs.
 *
 * Shows on the dev server (no GitHub round-trip):
 *   1. Live preview of `_template.tsx`'s default export — what the
 *      placeholder spec actually looks like rendered.
 *   2. README contents (markdown rendered as styled HTML — no extra deps).
 *   3. Source code blocks for `_template.tsx` and `_atoms.tsx`.
 *
 * Server Component — reads files via `fs` at request time so edits to
 * the template / atoms / README show up on reload without a rebuild.
 */

import fs from 'node:fs';
import path from 'node:path';
import TemplateSpec from '@/components/specs/_template';

const SPECS_DIR = path.join(process.cwd(), 'src', 'components', 'specs');

function readSpecFile(name: string): string {
  try {
    return fs.readFileSync(path.join(SPECS_DIR, name), 'utf8');
  } catch {
    return `// failed to read ${name}`;
  }
}

// ---------------------------------------------------------------------------
// Tiny markdown renderer — handles only the subset README.md uses
// (headings, paragraphs, ordered + unordered lists, inline code, blockquotes,
// tables). No heavy deps.
// ---------------------------------------------------------------------------
function renderMarkdown(md: string): React.ReactNode {
  const lines = md.split('\n');
  const blocks: React.ReactNode[] = [];
  let i = 0;

  const inline = (text: string): React.ReactNode => {
    // Split on backticks, code spans get <code>.
    const parts = text.split(/(`[^`]+`)/g);
    return parts.map((p, idx) => {
      if (p.startsWith('`') && p.endsWith('`')) {
        return (
          <code
            key={idx}
            style={{
              fontFamily: 'ui-monospace, monospace',
              background: 'rgba(0,0,0,0.06)',
              padding: '1px 4px',
              borderRadius: 4,
              fontSize: '0.9em',
            }}
          >
            {p.slice(1, -1)}
          </code>
        );
      }
      // also handle **strong**
      const strongParts = p.split(/(\*\*[^*]+\*\*)/g);
      return strongParts.map((sp, sidx) => {
        if (sp.startsWith('**') && sp.endsWith('**')) {
          return <strong key={`${idx}-${sidx}`}>{sp.slice(2, -2)}</strong>;
        }
        return <span key={`${idx}-${sidx}`}>{sp}</span>;
      });
    });
  };

  while (i < lines.length) {
    const line = lines[i];

    // Heading
    const heading = /^(#{1,6})\s+(.*)$/.exec(line);
    if (heading) {
      const level = heading[1].length;
      const text = heading[2];
      const Tag = `h${Math.min(level + 1, 6)}` as 'h2' | 'h3' | 'h4' | 'h5' | 'h6';
      blocks.push(
        <Tag
          key={`h-${i}`}
          style={{
            marginTop: level === 1 ? 0 : 'var(--spacing-large)',
            marginBottom: 'var(--spacing-small)',
            fontWeight: 600,
            fontSize:
              level === 1
                ? '1.5rem'
                : level === 2
                ? '1.2rem'
                : '1rem',
          }}
        >
          {inline(text)}
        </Tag>,
      );
      i += 1;
      continue;
    }

    // Blockquote
    if (line.startsWith('> ')) {
      const buf: string[] = [];
      while (i < lines.length && lines[i].startsWith('> ')) {
        buf.push(lines[i].slice(2));
        i += 1;
      }
      blocks.push(
        <blockquote
          key={`bq-${blocks.length}`}
          style={{
            margin: 'var(--spacing-medium) 0',
            paddingLeft: 'var(--spacing-medium)',
            borderLeft: '3px solid var(--color-divider)',
            color: 'var(--color-text-secondary)',
          }}
        >
          {inline(buf.join(' '))}
        </blockquote>,
      );
      continue;
    }

    // Table — `| a | b |` start
    if (line.startsWith('|') && i + 1 < lines.length && /^\|\s*[-:]+/.test(lines[i + 1])) {
      const headerCells = line.split('|').slice(1, -1).map((c) => c.trim());
      i += 2; // skip header + separator
      const rows: string[][] = [];
      while (i < lines.length && lines[i].startsWith('|')) {
        const cells = lines[i].split('|').slice(1, -1).map((c) => c.trim());
        rows.push(cells);
        i += 1;
      }
      blocks.push(
        <table
          key={`tbl-${blocks.length}`}
          style={{
            width: '100%',
            borderCollapse: 'collapse',
            margin: 'var(--spacing-medium) 0',
          }}
        >
          <thead>
            <tr>
              {headerCells.map((h, hi) => (
                <th
                  key={hi}
                  style={{
                    textAlign: 'left',
                    padding: 'var(--spacing-small) var(--spacing-medium)',
                    borderBottom: '1px solid var(--color-divider)',
                    color: 'var(--color-text-secondary)',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                  }}
                >
                  {inline(h)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((r, ri) => (
              <tr key={ri}>
                {r.map((c, ci) => (
                  <td
                    key={ci}
                    style={{
                      padding: 'var(--spacing-small) var(--spacing-medium)',
                      borderTop: '1px solid var(--color-divider)',
                      verticalAlign: 'top',
                    }}
                  >
                    {inline(c)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>,
      );
      continue;
    }

    // Ordered list
    if (/^\d+\.\s+/.test(line)) {
      const items: string[] = [];
      while (i < lines.length && /^(\d+\.\s+|\s+)/.test(lines[i]) && lines[i].trim()) {
        if (/^\d+\.\s+/.test(lines[i])) {
          items.push(lines[i].replace(/^\d+\.\s+/, ''));
        } else {
          items[items.length - 1] += ' ' + lines[i].trim();
        }
        i += 1;
      }
      blocks.push(
        <ol
          key={`ol-${blocks.length}`}
          style={{
            paddingLeft: 'var(--spacing-large)',
            margin: 'var(--spacing-small) 0',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--spacing-xsmall)',
          }}
        >
          {items.map((it, ii) => (
            <li key={ii}>{inline(it)}</li>
          ))}
        </ol>,
      );
      continue;
    }

    // Unordered list
    if (/^-\s+/.test(line)) {
      const items: string[] = [];
      while (i < lines.length && (/^-\s+/.test(lines[i]) || (lines[i].startsWith('  ') && lines[i].trim()))) {
        if (/^-\s+/.test(lines[i])) {
          items.push(lines[i].replace(/^-\s+/, ''));
        } else {
          items[items.length - 1] += ' ' + lines[i].trim();
        }
        i += 1;
      }
      blocks.push(
        <ul
          key={`ul-${blocks.length}`}
          style={{
            paddingLeft: 'var(--spacing-large)',
            margin: 'var(--spacing-small) 0',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--spacing-xsmall)',
            listStyle: 'disc',
          }}
        >
          {items.map((it, ii) => (
            <li key={ii}>{inline(it)}</li>
          ))}
        </ul>,
      );
      continue;
    }

    // Empty line
    if (!line.trim()) {
      i += 1;
      continue;
    }

    // Paragraph — collect until blank line
    const buf: string[] = [line];
    i += 1;
    while (i < lines.length && lines[i].trim() && !/^(#{1,6}\s|>\s|\d+\.\s|-\s|\|)/.test(lines[i])) {
      buf.push(lines[i]);
      i += 1;
    }
    blocks.push(
      <p
        key={`p-${blocks.length}`}
        style={{
          margin: 'var(--spacing-small) 0',
          color: 'var(--color-text-primary)',
          lineHeight: 1.6,
        }}
      >
        {inline(buf.join(' '))}
      </p>,
    );
  }

  return blocks;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
export default function ComponentTemplatePage() {
  const readme = readSpecFile('README.md');
  const templateSrc = readSpecFile('_template.tsx');
  const atomsSrc = readSpecFile('_atoms.tsx');

  return (
    <div
      className="max-w-5xl flex flex-col"
      style={{ gap: 'var(--spacing-xlarge)' }}
    >
      <div className="flex flex-col" style={{ gap: 'var(--spacing-sm)' }}>
        <p
          className="mds-text-caption font-bold uppercase"
          style={{ letterSpacing: '1px', color: 'var(--color-text-secondary)' }}
        >
          Authoring guide
        </p>
        <h1
          className="mds-text-page-title"
          style={{ color: 'var(--color-text-primary)' }}
        >
          Component spec template
        </h1>
        <p
          className="mds-text-body"
          style={{ color: 'var(--color-text-secondary)' }}
        >
          신규 컴포넌트 spec을 작성하려면 아래 템플릿을 복사해 시작하세요. 이
          페이지는 dev server에서 직접 서빙되어 GitHub 왕복 없이 미리보기 / 가이드 / 소스를 확인할 수 있습니다.
          <br />
          <a
            href="/components"
            style={{ color: 'var(--color-primary)' }}
            className="hover:underline"
          >
            ← /components로 돌아가기
          </a>
        </p>
      </div>

      {/* Live preview */}
      <section
        style={{
          border: '1px solid var(--color-divider)',
          borderRadius: 'var(--radius-card)',
          padding: 'var(--spacing-xlarge)',
          background: 'white',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--spacing-medium)',
        }}
      >
        <p
          className="mds-text-caption-tiny font-bold uppercase"
          style={{
            letterSpacing: '0.5px',
            color: 'var(--color-text-secondary)',
            margin: 0,
          }}
        >
          Live preview · `_template.tsx` default export
        </p>
        <TemplateSpec />
      </section>

      {/* README */}
      <section
        style={{
          border: '1px solid var(--color-divider)',
          borderRadius: 'var(--radius-card)',
          padding: 'var(--spacing-xlarge)',
          background: 'white',
        }}
      >
        <p
          className="mds-text-caption-tiny font-bold uppercase"
          style={{
            letterSpacing: '0.5px',
            color: 'var(--color-text-secondary)',
            marginBottom: 'var(--spacing-medium)',
          }}
        >
          README · `src/components/specs/README.md`
        </p>
        <div>{renderMarkdown(readme)}</div>
      </section>

      {/* Source code */}
      <section
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--spacing-medium)',
        }}
      >
        <p
          className="mds-text-caption-tiny font-bold uppercase"
          style={{
            letterSpacing: '0.5px',
            color: 'var(--color-text-secondary)',
            margin: 0,
          }}
        >
          Source
        </p>
        <details
          style={{
            border: '1px solid var(--color-divider)',
            borderRadius: 'var(--radius-card)',
            padding: 'var(--spacing-medium)',
            background: 'white',
          }}
        >
          <summary
            style={{
              cursor: 'pointer',
              fontFamily: 'ui-monospace, monospace',
              color: 'var(--color-text-primary)',
            }}
          >
            src/components/specs/_template.tsx
          </summary>
          <pre
            style={{
              marginTop: 'var(--spacing-medium)',
              padding: 'var(--spacing-medium)',
              background: '#1f2937',
              color: '#e5e7eb',
              borderRadius: 'var(--radius-card)',
              overflow: 'auto',
              fontSize: '0.85rem',
              lineHeight: 1.5,
            }}
          >
            <code>{templateSrc}</code>
          </pre>
        </details>
        <details
          style={{
            border: '1px solid var(--color-divider)',
            borderRadius: 'var(--radius-card)',
            padding: 'var(--spacing-medium)',
            background: 'white',
          }}
        >
          <summary
            style={{
              cursor: 'pointer',
              fontFamily: 'ui-monospace, monospace',
              color: 'var(--color-text-primary)',
            }}
          >
            src/components/specs/_atoms.tsx
          </summary>
          <pre
            style={{
              marginTop: 'var(--spacing-medium)',
              padding: 'var(--spacing-medium)',
              background: '#1f2937',
              color: '#e5e7eb',
              borderRadius: 'var(--radius-card)',
              overflow: 'auto',
              fontSize: '0.85rem',
              lineHeight: 1.5,
            }}
          >
            <code>{atomsSrc}</code>
          </pre>
        </details>
      </section>
    </div>
  );
}
