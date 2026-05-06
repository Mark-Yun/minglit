/**
 * /foundations/layout — system-level layout reference.
 *
 * Three layers of layout in mds:
 *   1. Foundation — spacing scale, touch target rules, density.  (this page)
 *   2. Scaffolds  — common screen patterns built from layout components
 *                   (MinglitContentLayout, MinglitSection, MinglitBottomCta…).
 *                   Documented here as wireframes + composition recipes.
 *   3. Component  — each component spec's "Placement" section says where
 *                   it lives within a scaffold (see /components).
 */

const SCAFFOLDS: Array<{
  id: string;
  name: string;
  purpose: string;
  composition: Array<{ region: string; component: string; tokenGap?: string }>;
  example: string;
  Wireframe: () => React.ReactElement;
}> = [
  {
    id: 'detail-with-cta',
    name: 'Detail + Bottom CTA',
    purpose: '상세 정보를 스크롤로 보여주고 화면 하단에 고정 액션 버튼을 두는 패턴.',
    composition: [
      { region: 'AppBar',         component: 'MinglitAppBar' },
      { region: 'Scrollable body', component: 'MinglitContentLayout > MinglitSection[]', tokenGap: 'spacing-section-gap (40px)' },
      { region: 'Bottom CTA',     component: 'MinglitBottomCta', tokenGap: 'spacing-screen-edge (16px)' },
    ],
    example: 'Event detail · Party detail · Profile preview',
    Wireframe: DetailCtaWireframe,
  },
  {
    id: 'list-with-filters',
    name: 'List + Filter chips',
    purpose: '필터 칩을 상단에 두고 스크롤되는 카드 리스트로 결과를 보여주는 패턴.',
    composition: [
      { region: 'AppBar',           component: 'MinglitAppBar' },
      { region: 'Filter row',       component: 'MinglitChipGroup', tokenGap: 'spacing-screen-edge (16px)' },
      { region: 'Scrollable list',  component: 'MinglitContentCard[]', tokenGap: 'spacing-card-gap (12px)' },
    ],
    example: 'Event browse · Party search · Member list',
    Wireframe: ListFilterWireframe,
  },
  {
    id: 'settings-groups',
    name: 'Settings groups',
    purpose: '관련 설정을 그룹 단위로 묶고, 그룹 사이 빈 여백으로 구분하는 패턴.',
    composition: [
      { region: 'AppBar',         component: 'MinglitAppBar' },
      { region: 'Group stack',    component: 'MinglitSettingsGroup[] > MinglitSettingsTile[]', tokenGap: 'spacing-large (24px)' },
    ],
    example: 'My page · Notifications · Privacy',
    Wireframe: SettingsWireframe,
  },
  {
    id: 'form-with-cta',
    name: 'Form + Bottom CTA',
    purpose: '입력 필드를 세로로 쌓고 하단에서 제출하는 패턴.',
    composition: [
      { region: 'AppBar',         component: 'MinglitAppBar' },
      { region: 'Field stack',    component: 'MinglitTextField[] / NumberStepperInput', tokenGap: 'spacing-large (24px)' },
      { region: 'Bottom CTA',     component: 'MinglitButton (expand=true)', tokenGap: 'spacing-screen-edge (16px)' },
    ],
    example: 'Profile edit · Party create · Sign-up',
    Wireframe: FormCtaWireframe,
  },
  {
    id: 'dialog',
    name: 'Centered dialog',
    purpose: '결정을 요구하는 시점의 모달. 스크림 위에 작은 카드, 하단에 액션 페어.',
    composition: [
      { region: 'Scrim',          component: 'color-scrim overlay' },
      { region: 'Dialog card',    component: 'MinglitDialog / MinglitAlert', tokenGap: 'radius-dialog (28px)' },
      { region: 'Action row',     component: 'MinglitButton secondary + primary/destructive pair', tokenGap: 'spacing-small (8px)' },
    ],
    example: 'Confirm leave · Confirm delete · Logout',
    Wireframe: DialogWireframe,
  },
  {
    id: 'bottom-sheet',
    name: 'Bottom sheet',
    purpose: '하단에서 올라오는 페이지 내 보조 surface. 단계적 정보 추가나 옵션 선택.',
    composition: [
      { region: 'Scrim',          component: 'color-scrim overlay' },
      { region: 'Sheet',          component: 'MinglitBottomSheet', tokenGap: 'radius-card (16px) — top corners only' },
      { region: 'Handle',         component: 'drag handle' },
      { region: 'Content',        component: 'MinglitListTile[] / MinglitImageSourceSheet 등' },
    ],
    example: 'Image source pick · Filter sort · Member options',
    Wireframe: BottomSheetWireframe,
  },
];

export default function LayoutPage() {
  return (
    <div className="max-w-5xl flex flex-col" style={{ gap: 'var(--spacing-xlarge)' }}>
      {/* Header */}
      <div className="flex flex-col" style={{ gap: 'var(--spacing-sm)' }}>
        <p
          className="mds-text-caption font-bold uppercase"
          style={{ letterSpacing: '1px', color: 'var(--color-text-secondary)' }}
        >
          Foundations
        </p>
        <h1 className="mds-text-page-title" style={{ color: 'var(--color-text-primary)' }}>
          Layout
        </h1>
        <p className="mds-text-body" style={{ color: 'var(--color-text-secondary)' }}>
          mds 레이아웃은 세 레이어로 분리됩니다 — <strong>foundation</strong>(spacing 스케일·터치 타깃),
          <strong> scaffold</strong>(흔한 화면 패턴), <strong>component placement</strong>
          (각 컴포넌트가 스캐폴드 안에서 어디에 위치하는지). 이 페이지는 앞 두 레이어를 정의합니다.
          컴포넌트별 배치 가이드는{' '}
          <a href="/components" style={{ color: 'var(--color-primary)' }}>
            /components
          </a>
          {' '}각 카드의 Placement 섹션 참조.
        </p>
      </div>

      {/* Section: Touch targets */}
      <Section title="Touch targets">
        <div className="mds-spec__panel">
          <p className="mds-text-body" style={{ color: 'var(--color-text-primary)', marginBottom: 12 }}>
            모든 인터랙티브 요소는 <strong>최소 44pt</strong> 터치 타깃을 보장해야 합니다 (Apple HIG 기준).
            mds 컴포넌트의 사이즈 토큰이 이 규칙을 따라 설정되어 있음.
          </p>
          <ul
            className="mds-text-body list-disc pl-5"
            style={{ color: 'var(--color-text-secondary)' }}
          >
            <li>MinglitButton sm h36 — 단독 CTA로 쓰면 안 됨, 칩 옆 보조용. md/lg는 기본 충족.</li>
            <li>MinglitChip / MinglitTag — 시각 사이즈는 작아도 hit area는 44pt 이상으로 확장.</li>
            <li>MinglitListTile / MinglitSettingsTile — vertical padding 포함 hit zone 56pt 이상.</li>
          </ul>
        </div>
      </Section>

      {/* Section: Spacing rhythm */}
      <Section title="Spacing rhythm">
        <div className="mds-spec__panel">
          <p className="mds-text-body" style={{ color: 'var(--color-text-primary)', marginBottom: 12 }}>
            화면을 구성할 때 사용하는 6가지 핵심 spacing 토큰. 모두{' '}
            <a href="/tokens" style={{ color: 'var(--color-primary)' }}>
              /tokens
            </a>
            {' '}Spacing 탭에 정의됨.
          </p>
          <table className="mds-spec__tokens-table">
            <thead>
              <tr>
                <th style={{ width: 220 }}>Token</th>
                <th style={{ width: 80 }}>px</th>
                <th>Layout role</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><code>spacing-screen-edge</code></td><td>16</td>
                <td>화면 좌우 가장자리에서 콘텐츠까지 마진.</td>
              </tr>
              <tr>
                <td><code>spacing-card-gap</code></td><td>12</td>
                <td>리스트에서 카드와 카드 사이 세로 간격.</td>
              </tr>
              <tr>
                <td><code>spacing-card-content-v</code></td><td>16</td>
                <td>카드 내부 상하 패딩.</td>
              </tr>
              <tr>
                <td><code>spacing-large</code></td><td>24</td>
                <td>섹션 안 그룹 사이 간격 — 폼 필드 사이, 설정 그룹 사이.</td>
              </tr>
              <tr>
                <td><code>spacing-section-gap</code></td><td>40</td>
                <td>화면 내 큰 섹션 사이 간격 — 한 페이지 안 다른 토픽으로 넘어갈 때.</td>
              </tr>
              <tr>
                <td><code>spacing-medium / sm / small / xsmall</code></td><td>16/12/8/4</td>
                <td>컴포넌트 내부 패딩, 아이콘-라벨 갭, 칩 사이 등 마이크로 간격.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </Section>

      {/* Section: Screen scaffolds */}
      <Section title="Screen scaffolds">
        <p
          className="mds-text-body"
          style={{
            color: 'var(--color-text-secondary)',
            marginTop: 'calc(-1 * var(--spacing-small))',
            marginBottom: 'var(--spacing-medium)',
          }}
        >
          밍글릿 화면은 대부분 아래 6가지 스캐폴드 중 하나를 따릅니다. 새 화면 작성 시 가장 가까운 패턴을 골라 시작하세요.
        </p>
        <div className="flex flex-col" style={{ gap: 'var(--spacing-large)' }}>
          {SCAFFOLDS.map((s) => (
            <ScaffoldCard key={s.id} scaffold={s} />
          ))}
        </div>
      </Section>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Section primitive (mirrors /components page)
// ---------------------------------------------------------------------------
function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <p
        className="mds-text-caption-tiny font-bold uppercase"
        style={{
          letterSpacing: '0.5px',
          color: 'var(--color-text-secondary)',
          marginBottom: 'var(--spacing-small)',
        }}
      >
        {title}
      </p>
      {children}
    </section>
  );
}

// ---------------------------------------------------------------------------
// Scaffold card
// ---------------------------------------------------------------------------
function ScaffoldCard({
  scaffold,
}: {
  scaffold: (typeof SCAFFOLDS)[number];
}) {
  const { name, purpose, composition, example, Wireframe } = scaffold;
  return (
    <article
      id={scaffold.id}
      className="bg-white scroll-mt-20"
      style={{
        borderRadius: 'var(--radius-card)',
        border: '1px solid var(--color-divider)',
        padding: 'var(--spacing-large)',
        display: 'grid',
        gridTemplateColumns: '180px 1fr',
        gap: 'var(--spacing-large)',
      }}
    >
      <div className="mds-spec__panel" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Wireframe />
      </div>
      <div className="flex flex-col" style={{ gap: 'var(--spacing-sm)' }}>
        <h2 className="mds-text-section-title" style={{ color: 'var(--color-text-primary)' }}>
          {name}
        </h2>
        <p className="mds-text-body" style={{ color: 'var(--color-text-secondary)' }}>
          {purpose}
        </p>
        <table className="mds-spec__tokens-table" style={{ marginTop: 'var(--spacing-xsmall)' }}>
          <thead>
            <tr>
              <th style={{ width: 140 }}>Region</th>
              <th>Components / spacing</th>
            </tr>
          </thead>
          <tbody>
            {composition.map((c) => (
              <tr key={c.region}>
                <td><code>{c.region}</code></td>
                <td style={{ color: 'var(--color-text-secondary)' }}>
                  {c.component}
                  {c.tokenGap && (
                    <>
                      {' · '}
                      <code style={{ color: 'var(--color-text-secondary)' }}>{c.tokenGap}</code>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <p
          className="mds-text-caption"
          style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--spacing-xsmall)' }}
        >
          예시 화면: {example}
        </p>
      </div>
    </article>
  );
}

// ---------------------------------------------------------------------------
// Wireframes — schematic CSS-only phone outlines.
// 160 × 280 viewport (~iPhone proportions). All blocks reference the
// mds_tokens for radius / surface bg.
// ---------------------------------------------------------------------------
const PHONE: React.CSSProperties = {
  width: 140,
  height: 248,
  borderRadius: 18,
  border: '1px solid var(--color-divider)',
  background: 'white',
  position: 'relative',
  overflow: 'hidden',
  display: 'flex',
  flexDirection: 'column',
};

const REGION_BASE: React.CSSProperties = {
  background: 'var(--color-surface)',
  borderRadius: 4,
  margin: 4,
};

function AppBar() {
  return <div style={{ ...REGION_BASE, height: 24, marginBottom: 0 }} />;
}

function ScrollFiller({ children, flex = 1 }: { children?: React.ReactNode; flex?: number }) {
  return (
    <div
      style={{
        flex,
        margin: 4,
        marginTop: 4,
        padding: 4,
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
      }}
    >
      {children}
    </div>
  );
}

function Block({ height = 16, primary = false }: { height?: number; primary?: boolean }) {
  return (
    <div
      style={{
        height,
        borderRadius: 4,
        background: primary ? 'var(--color-primary)' : 'var(--color-surface)',
        opacity: primary ? 0.8 : 1,
      }}
    />
  );
}

function DetailCtaWireframe() {
  return (
    <div style={PHONE}>
      <AppBar />
      <ScrollFiller>
        <Block height={50} />
        <Block height={20} />
        <Block height={20} />
        <Block height={40} />
        <Block height={20} />
      </ScrollFiller>
      <div style={{ ...REGION_BASE, height: 32, background: 'var(--color-primary)', margin: 8, marginTop: 4 }} />
    </div>
  );
}

function ListFilterWireframe() {
  return (
    <div style={PHONE}>
      <AppBar />
      <div style={{ display: 'flex', gap: 4, padding: 4, paddingTop: 4 }}>
        <div style={{ height: 16, flex: 1, background: 'var(--color-primary)', opacity: 0.7, borderRadius: 999 }} />
        <div style={{ height: 16, flex: 1, background: 'var(--color-surface)', borderRadius: 999 }} />
        <div style={{ height: 16, flex: 1, background: 'var(--color-surface)', borderRadius: 999 }} />
      </div>
      <ScrollFiller>
        <Block height={36} />
        <Block height={36} />
        <Block height={36} />
        <Block height={36} />
        <Block height={36} />
      </ScrollFiller>
    </div>
  );
}

function SettingsWireframe() {
  return (
    <div style={PHONE}>
      <AppBar />
      <ScrollFiller>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <Block height={14} />
          <Block height={14} />
          <Block height={14} />
        </div>
        <div style={{ height: 12 }} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <Block height={14} />
          <Block height={14} />
        </div>
        <div style={{ height: 12 }} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <Block height={14} />
          <Block height={14} />
          <Block height={14} />
          <Block height={14} />
        </div>
      </ScrollFiller>
    </div>
  );
}

function FormCtaWireframe() {
  return (
    <div style={PHONE}>
      <AppBar />
      <ScrollFiller>
        <Block height={28} />
        <div style={{ height: 8 }} />
        <Block height={28} />
        <div style={{ height: 8 }} />
        <Block height={28} />
      </ScrollFiller>
      <div style={{ ...REGION_BASE, height: 32, background: 'var(--color-primary)', margin: 8, marginTop: 4 }} />
    </div>
  );
}

function DialogWireframe() {
  return (
    <div style={{ ...PHONE, background: 'rgba(0,0,0,0.45)', position: 'relative' }}>
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 110,
          background: 'white',
          borderRadius: 14,
          padding: 10,
          display: 'flex',
          flexDirection: 'column',
          gap: 6,
          boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
        }}
      >
        <div style={{ height: 12, background: 'var(--color-surface)', borderRadius: 3 }} />
        <div style={{ height: 8, background: 'var(--color-surface)', borderRadius: 3 }} />
        <div style={{ height: 8, background: 'var(--color-surface)', borderRadius: 3, width: '70%' }} />
        <div style={{ display: 'flex', gap: 4, marginTop: 4 }}>
          <div style={{ flex: 1, height: 18, background: 'var(--color-surface)', borderRadius: 4 }} />
          <div style={{ flex: 1, height: 18, background: 'var(--color-primary)', borderRadius: 4, opacity: 0.85 }} />
        </div>
      </div>
    </div>
  );
}

function BottomSheetWireframe() {
  return (
    <div style={{ ...PHONE, background: 'rgba(0,0,0,0.45)', position: 'relative' }}>
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: '60%',
          background: 'white',
          borderTopLeftRadius: 14,
          borderTopRightRadius: 14,
          padding: 8,
          display: 'flex',
          flexDirection: 'column',
          gap: 6,
        }}
      >
        <div style={{ width: 28, height: 3, background: 'var(--color-divider)', borderRadius: 999, alignSelf: 'center' }} />
        <div style={{ height: 10, background: 'var(--color-surface)', borderRadius: 3 }} />
        <div style={{ height: 18, background: 'var(--color-surface)', borderRadius: 4 }} />
        <div style={{ height: 18, background: 'var(--color-surface)', borderRadius: 4 }} />
        <div style={{ height: 18, background: 'var(--color-surface)', borderRadius: 4 }} />
      </div>
    </div>
  );
}
