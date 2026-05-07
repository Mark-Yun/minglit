/**
 * MinglitBottomCta — fixed bottom action bar.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_bottom_cta.dart
 *   variants: single (단일 버튼) · dual (좌·우 두 버튼) · withPrice (좌 가격 + 우 버튼)
 *   enabled: false면 버튼 비활성
 *   icon: 단일 / withPrice 변형의 주요 버튼 leading 아이콘
 *
 * Visual contract:
 *   화면 하단 고정 — Scaffold.bottomNavigationBar 자리.
 *   상단 0.5px 회색 구분선 / scaffold 배경 / SafeArea 자동 처리.
 *   키보드가 올라오면 사라짐 (입력 폼 가림 방지).
 *   좌우 padding = screenEdge (16) · 위아래 padding = sm (12).
 */

import type { ComponentType, ReactNode } from 'react';
import {
  PreviewTable,
  SpecAnatomy,
  SpecHero,
  SpecRoot,
  SpecSection,
} from './_atoms';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------
function PrimaryBtn({
  label,
  icon,
  enabled = true,
  expand = true,
}: {
  label: string;
  icon?: ReactNode;
  enabled?: boolean;
  expand?: boolean;
}) {
  return (
    <button
      style={{
        height: 48,
        flex: expand ? 1 : 'none',
        background: enabled ? 'var(--color-primary)' : 'var(--color-divider)',
        color: enabled ? 'white' : 'var(--color-text-secondary)',
        border: 'none',
        borderRadius: 12,
        fontSize: 16,
        fontWeight: 600,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        padding: '0 16px',
        cursor: enabled ? 'pointer' : 'default',
        opacity: enabled ? 1 : 0.7,
      }}
    >
      {icon}
      {label}
    </button>
  );
}

function OutlineBtn({ label, enabled = true }: { label: string; enabled?: boolean }) {
  return (
    <button
      style={{
        height: 48,
        flex: 1,
        background: 'white',
        color: enabled ? 'var(--color-text-primary)' : 'var(--color-text-secondary)',
        border: '1px solid var(--color-divider)',
        borderRadius: 12,
        fontSize: 16,
        fontWeight: 500,
        cursor: enabled ? 'pointer' : 'default',
        opacity: enabled ? 1 : 0.6,
      }}
    >
      {label}
    </button>
  );
}

function PlusIcon() {
  return (
    <svg viewBox="0 0 24 24" width={18} height={18} fill="none" stroke="currentColor" strokeWidth={2}>
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function BottomCtaDemo({
  variant = 'single',
  enabled = true,
  withIcon = false,
}: {
  variant?: 'single' | 'dual' | 'withPrice';
  enabled?: boolean;
  withIcon?: boolean;
}) {
  return (
    <div
      style={{
        background: 'var(--color-surface)',
        borderTop: '0.5px solid var(--color-divider)',
        padding: '12px 16px',
      }}
    >
      {variant === 'single' && (
        <PrimaryBtn label="참여하기" enabled={enabled} icon={withIcon ? <PlusIcon /> : undefined} />
      )}
      {variant === 'dual' && (
        <div style={{ display: 'flex', gap: 8 }}>
          <OutlineBtn label="취소" enabled={enabled} />
          <PrimaryBtn label="저장" enabled={enabled} />
        </div>
      )}
      {variant === 'withPrice' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
            <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>최저가</span>
            <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--color-text-primary)' }}>20,000원~</span>
          </div>
          <PrimaryBtn label="참여하기" enabled={enabled} expand={false} />
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitBottomCtaSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 360 }}>
          <BottomCtaDemo variant="single" />
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 360 }}>
            <BottomCtaDemo variant="withPrice" />
          </div>
        }
        labels={[
          { text: '0.5px 상단 구분선 (outlineVariant)', style: { top: 4, left: 8 } },
          { text: 'spacing-screenEdge → 좌우 padding (16)', style: { top: '50%', left: 0 } },
          { text: 'spacing-sm → 위아래 padding (12)', style: { top: '50%', right: 0 } },
          { text: '키보드가 뜨면 자동으로 숨겨짐', style: { bottom: 12, right: 8 } },
        ]}
      />

      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'single',
              preview: <div style={{ width: 280 }}><BottomCtaDemo variant="single" /></div>,
              description: '단일 풀너비 버튼. 가장 단순한 형태 — 한 가지 핵심 액션만 있을 때.',
            },
            {
              name: 'dual',
              preview: <div style={{ width: 280 }}><BottomCtaDemo variant="dual" /></div>,
              description: '좌측 보조 버튼(외곽선) + 우측 주요 버튼(꽉찬). 폼 저장 / 취소 같은 짝 액션.',
            },
            {
              name: 'withPrice',
              preview: <div style={{ width: 280 }}><BottomCtaDemo variant="withPrice" /></div>,
              description: '좌측에 가격 / 부가 정보, 우측에 액션 버튼. 이벤트 결제 등 가격이 액션과 함께 보여야 할 때.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="States">
        <PreviewTable
          rows={[
            {
              name: 'default',
              preview: <div style={{ width: 280 }}><BottomCtaDemo variant="single" /></div>,
              description: '버튼이 활성화된 일반 상태.',
            },
            {
              name: 'disabled',
              preview: <div style={{ width: 280 }}><BottomCtaDemo variant="single" enabled={false} /></div>,
              description: '주요 버튼이 흐려지고 탭 차단. 폼이 미완 / 조건 미충족일 때.',
            },
            {
              name: 'with icon',
              preview: <div style={{ width: 280 }}><BottomCtaDemo variant="single" withIcon /></div>,
              description: '주요 버튼 라벨 앞에 아이콘이 함께 표시 (지원: single · withPrice).',
            },
          ]}
        />
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------
function DoSinglePrimary() {
  return <div style={{ width: 240 }}><BottomCtaDemo variant="single" /></div>;
}

function DoDualSavePair() {
  return <div style={{ width: 240 }}><BottomCtaDemo variant="dual" /></div>;
}

function DoPriceContext() {
  return <div style={{ width: 240 }}><BottomCtaDemo variant="withPrice" /></div>;
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-single-primary': DoSinglePrimary,
  'do-dual-save-pair': DoDualSavePair,
  'do-price-context': DoPriceContext,
};
