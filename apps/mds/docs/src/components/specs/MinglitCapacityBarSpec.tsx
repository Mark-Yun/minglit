/**
 * Inline visual spec for MinglitCapacityBar.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../capacity_bar.dart
 *   total ≤ segmentThreshold(default 30) → segmented (한 칸 = 1명)
 *   total > segmentThreshold              → continuous bar
 *
 * Two exports:
 *   default          — visual playground
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType, CSSProperties } from 'react';
import {
  PreviewTable,
  SpecAnatomy,
  SpecHero,
  SpecRoot,
  SpecSection,
} from './_atoms';

// ---------------------------------------------------------------------------
// Atom — segmented (칸 분리) variant
// ---------------------------------------------------------------------------
function SegmentedBar({
  total,
  filled,
  pending = 0,
  height = 8,
  gap = 2,
  filledColor = 'var(--color-primary)',
  pendingColor = 'rgba(108, 60, 225, 0.3)',
  trackColor = 'var(--color-divider)',
  radius = 2,
}: {
  total: number;
  filled: number;
  pending?: number;
  height?: number;
  gap?: number;
  filledColor?: string;
  pendingColor?: string;
  trackColor?: string;
  radius?: number;
}) {
  const safeFilled = Math.max(0, Math.min(filled, total));
  const safePending = Math.max(0, Math.min(pending, total - safeFilled));
  const empty = total - safeFilled - safePending;

  const segs: Array<'filled' | 'pending' | 'empty'> = [
    ...Array(safeFilled).fill('filled'),
    ...Array(safePending).fill('pending'),
    ...Array(empty).fill('empty'),
  ];

  return (
    <div
      role="progressbar"
      aria-label={`정원 ${total}명 중 확정 ${safeFilled}명 · 대기 ${safePending}명 · 남은 ${empty}명`}
      aria-valuemin={0}
      aria-valuemax={total}
      aria-valuenow={safeFilled}
      style={{
        display: 'flex',
        gap: `${gap}px`,
        width: '100%',
        height: `${height}px`,
      }}
    >
      {segs.map((kind, idx) => (
        <div
          key={idx}
          style={{
            flex: 1,
            height: '100%',
            background:
              kind === 'filled' ? filledColor : kind === 'pending' ? pendingColor : trackColor,
            borderRadius: `${radius}px`,
          }}
        />
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Atom — continuous variant (total > segmentThreshold)
// ---------------------------------------------------------------------------
function ContinuousBar({
  total,
  filled,
  pending = 0,
  height = 6,
  filledColor = 'var(--color-primary)',
  pendingColor = 'rgba(108, 60, 225, 0.3)',
  trackColor = 'var(--color-divider)',
  radius = 3,
}: {
  total: number;
  filled: number;
  pending?: number;
  height?: number;
  filledColor?: string;
  pendingColor?: string;
  trackColor?: string;
  radius?: number;
}) {
  const safeFilled = Math.max(0, Math.min(filled, total));
  const safePending = Math.max(0, Math.min(pending, total - safeFilled));
  const filledPct = (safeFilled / total) * 100;
  const pendingPct = (safePending / total) * 100;

  return (
    <div
      role="progressbar"
      aria-label={`정원 ${total}명 중 확정 ${safeFilled}명 · 대기 ${safePending}명`}
      aria-valuemin={0}
      aria-valuemax={total}
      aria-valuenow={safeFilled}
      style={{
        display: 'flex',
        width: '100%',
        height: `${height}px`,
        background: trackColor,
        borderRadius: `${radius}px`,
        overflow: 'hidden',
      }}
    >
      <div style={{ width: `${filledPct}%`, height: '100%', background: filledColor }} />
      <div style={{ width: `${pendingPct}%`, height: '100%', background: pendingColor }} />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Composite atom — auto-switch based on segmentThreshold
// ---------------------------------------------------------------------------
function MinglitCapacityBarDemo({
  total,
  filled,
  pending = 0,
  segmentThreshold = 30,
}: {
  total: number;
  filled: number;
  pending?: number;
  segmentThreshold?: number;
}) {
  if (total <= segmentThreshold) {
    return <SegmentedBar total={total} filled={filled} pending={pending} />;
  }
  return <ContinuousBar total={total} filled={filled} pending={pending} />;
}

// Wrapper to give each demo a fixed-width context so they look natural in tables.
function DemoWrap({ children, width = 280 }: { children: React.ReactNode; width?: number }) {
  return (
    <div style={{ width, padding: '8px 0' }}>
      {children}
    </div>
  );
}

// Caption helper — small breakdown text below bars (도메인 패턴).
function Caption({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        marginTop: 6,
        fontSize: 12,
        color: 'var(--color-text-secondary)',
        display: 'flex',
        gap: 12,
      }}
    >
      {children}
    </div>
  );
}

const strongStyle: CSSProperties = {
  color: 'var(--color-text-primary)',
  fontWeight: 600,
};

// ---------------------------------------------------------------------------
// Default export — visual playground
// ---------------------------------------------------------------------------
export default function MinglitCapacityBarSpec() {
  return (
    <SpecRoot>
      {/* Hero — segmented 8칸 (운영자가 가장 자주 보는 케이스) */}
      <SpecHero>
        <DemoWrap width={320}>
          <MinglitCapacityBarDemo total={8} filled={4} pending={2} />
          <Caption>
            <span>
              확정 <span style={strongStyle}>4</span>
            </span>
            <span>
              대기 <span style={strongStyle}>2</span>
            </span>
            <span>
              남은 <span style={strongStyle}>2</span>
            </span>
          </Caption>
        </DemoWrap>
      </SpecHero>

      {/* Anatomy — 한 칸 = 1명 단위 표시 */}
      <SpecAnatomy
        subject={
          <DemoWrap width={320}>
            <MinglitCapacityBarDemo total={8} filled={4} pending={2} />
          </DemoWrap>
        }
        subjectClassName="mds-spec__anatomy-capbar"
        labels={[
          {
            text: '확정 (color-primary · 강한 톤)',
            style: { top: -22, left: 0 },
          },
          {
            text: '대기 (color-primary @ 30% · 옅은 톤)',
            style: { top: -22, left: '50%' },
          },
          {
            text: '남은 자리 (color-divider)',
            style: { bottom: -22, right: 0 },
          },
          {
            text: 'segmentGap 2px',
            style: { bottom: -22, left: 0 },
          },
        ]}
      />

      {/* Variants — segmented vs continuous + 채움 패턴 */}
      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'segmented · partial',
              preview: (
                <DemoWrap>
                  <MinglitCapacityBarDemo total={8} filled={4} pending={2} />
                </DemoWrap>
              ),
              description:
                'total ≤ 30 — 칸 분리. 4 강 · 2 옅 · 2 빈 — 한 칸 = 1명. 가장 일반적인 운영 케이스.',
            },
            {
              name: 'segmented · full',
              preview: (
                <DemoWrap>
                  <MinglitCapacityBarDemo total={4} filled={2} pending={2} />
                </DemoWrap>
              ),
              description: '확정 + 대기가 정원에 도달 — 빈 칸 0. 추가 신청 받을 수 없는 직전 상태.',
            },
            {
              name: 'segmented · filled-only',
              preview: (
                <DemoWrap>
                  <MinglitCapacityBarDemo total={6} filled={6} />
                </DemoWrap>
              ),
              description: '대기 0 · 확정만 정원 채움. 모든 신청이 결제까지 완료된 마감 직전 상태.',
            },
            {
              name: 'segmented · empty',
              preview: (
                <DemoWrap>
                  <MinglitCapacityBarDemo total={8} filled={0} />
                </DemoWrap>
              ),
              description: '확정 0 · 대기 0 — 정원만 정의된 신규 그룹.',
            },
            {
              name: 'continuous (total > 30)',
              preview: (
                <DemoWrap>
                  <MinglitCapacityBarDemo total={200} filled={80} pending={30} />
                </DemoWrap>
              ),
              description:
                'total > segmentThreshold → continuous fallback. 0~40% 강 · 40~55% 옅 · 55~100% 빈.',
            },
            {
              name: 'continuous · near full',
              preview: (
                <DemoWrap>
                  <MinglitCapacityBarDemo total={150} filled={130} pending={15} />
                </DemoWrap>
              ),
              description: '큰 이벤트 마감 직전 — 옅은 톤이 얇은 띠로 visible.',
            },
          ]}
        />
      </SpecSection>

      {/* Threshold demo — 깨지는 한계 */}
      <SpecSection title="segmentThreshold 임계값 (default 30)">
        <PreviewTable
          rows={[
            {
              name: 'total = 8',
              preview: (
                <DemoWrap>
                  <SegmentedBar total={8} filled={4} pending={2} />
                </DemoWrap>
              ),
              description: '여유롭게 칸이 보임 — 한 칸 폭 ≈ 30+px.',
            },
            {
              name: 'total = 20',
              preview: (
                <DemoWrap>
                  <SegmentedBar total={20} filled={12} pending={3} />
                </DemoWrap>
              ),
              description: '한 칸 폭 ≈ 12px — 여전히 인지 가능.',
            },
            {
              name: 'total = 30 (임계값)',
              preview: (
                <DemoWrap>
                  <SegmentedBar total={30} filled={18} pending={5} />
                </DemoWrap>
              ),
              description: '한 칸 폭 ≈ 8px — 모바일 360px 폭 기준 가독 한계. 이 이상은 continuous로 자동 fallback.',
            },
            {
              name: 'total = 50 (over threshold → continuous)',
              preview: (
                <DemoWrap>
                  <ContinuousBar total={50} filled={30} pending={10} />
                </DemoWrap>
              ),
              description: 'segmented 시 칸 폭 < 5px로 깨짐 → continuous로 자동 전환.',
            },
          ]}
        />
      </SpecSection>

      {/* Pattern contexts — group card composition */}
      <SpecSection title="In group card (실사용 패턴)">
        <PreviewTable
          rows={[
            {
              name: 'with breakdown',
              preview: (
                <div
                  style={{
                    width: 320,
                    padding: 16,
                    background: 'var(--color-surface)',
                    border: '1px solid var(--color-divider)',
                    borderRadius: 16,
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 8,
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>일반 그룹</div>
                    <div>
                      <span style={{ fontSize: 14, fontWeight: 600 }}>4</span>
                      <span style={{ fontSize: 12, color: 'var(--color-text-secondary)', marginLeft: 2 }}>
                        / 8 확정
                      </span>
                    </div>
                  </div>
                  <SegmentedBar total={8} filled={4} pending={2} />
                  <div style={{ display: 'flex', gap: 16, fontSize: 12, color: 'var(--color-text-secondary)' }}>
                    <span>
                      확정 <strong style={strongStyle}>4</strong>
                    </span>
                    <span>
                      대기 <strong style={strongStyle}>2</strong>
                    </span>
                    <span>
                      거절 <strong style={strongStyle}>0</strong>
                    </span>
                  </div>
                </div>
              ),
              description:
                '`partner_event_detail_page` 입장 그룹 카드 — 그룹 이름 + 분수 + bar + breakdown 한 묶음.',
            },
          ]}
        />
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes — short visual previews keyed to GuidelineEntry.recipeKey
// ---------------------------------------------------------------------------
function DoCapbarDomain() {
  return (
    <DemoWrap width={200}>
      <SegmentedBar total={8} filled={4} pending={2} />
    </DemoWrap>
  );
}

function DoCapbarWithBreakdown() {
  return (
    <div style={{ width: 220 }}>
      <SegmentedBar total={8} filled={4} pending={2} />
      <div style={{ marginTop: 6, display: 'flex', gap: 12, fontSize: 12, color: 'var(--color-text-secondary)' }}>
        <span>
          확정 <strong style={strongStyle}>4</strong>
        </span>
        <span>
          대기 <strong style={strongStyle}>2</strong>
        </span>
        <span>
          거절 <strong style={strongStyle}>0</strong>
        </span>
      </div>
    </div>
  );
}

function DontCapbarShrinkThreshold() {
  // Force segmented for a clearly broken total (e.g. 50) to show why threshold exists.
  return (
    <DemoWrap width={200}>
      <SegmentedBar total={50} filled={30} pending={10} />
    </DemoWrap>
  );
}

function DontCapbarInvert() {
  // Pending more emphasized than filled — wrong hierarchy.
  return (
    <DemoWrap width={200}>
      <SegmentedBar
        total={8}
        filled={4}
        pending={2}
        filledColor="rgba(108, 60, 225, 0.3)"
        pendingColor="var(--color-primary)"
      />
    </DemoWrap>
  );
}

function DontCapbarGeneric() {
  // Simulating a fake "70% upload" use case as if it were CapacityBar.
  return (
    <DemoWrap width={200}>
      <ContinuousBar total={100} filled={70} />
    </DemoWrap>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-capbar-domain': DoCapbarDomain,
  'do-capbar-with-breakdown': DoCapbarWithBreakdown,
  'dont-capbar-shrink-threshold': DontCapbarShrinkThreshold,
  'dont-capbar-invert': DontCapbarInvert,
  'dont-capbar-generic': DontCapbarGeneric,
};
