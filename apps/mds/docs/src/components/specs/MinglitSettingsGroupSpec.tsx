/**
 * MinglitSettingsGroup — settings tiles grouped into a card.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_settings_group.dart
 *   children: List<MinglitSettingsTile>
 *   header: optional uppercase section label above the card
 *
 * Visual contract:
 *   - 카드 좌우 horizontal padding (medium = 16) — scaffold edge에서 떨어진 모양
 *   - radius-card (16) · surfaceContainerLowest 배경 (라이트모드 흰색)
 *   - 카드 위에 헤더 라벨 (uppercase · letter-spacing 0.5 · 회색)
 *   - 카드 안의 행 사이에 0.5px 얇은 선 (좌측 indent 52 = 16 padding + 20 icon + 16 gap)
 *   - 카드의 둥근 모서리 안쪽으로 콘텐츠가 깔끔히 잘림
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
// Tile demo — simplified row used inside the group preview only.
// (Full tile spec lives in MinglitSettingsTileSpec.tsx.)
// ---------------------------------------------------------------------------
function ChevronIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function PlaceholderIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <circle cx="12" cy="12" r="9" />
    </svg>
  );
}

function Tile({
  title,
  subtitle,
  destructive = false,
}: {
  title: string;
  subtitle?: string;
  destructive?: boolean;
}) {
  const baseColor = destructive ? 'var(--color-error)' : 'var(--color-text-primary)';
  const secondaryColor = destructive
    ? 'var(--color-error)'
    : 'var(--color-text-secondary)';
  return (
    <div
      style={{
        height: 48,
        padding: '0 16px',
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        background: 'white',
      }}
    >
      <span style={{ color: secondaryColor, display: 'inline-flex', flexShrink: 0 }}>
        <PlaceholderIcon />
      </span>
      <span style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <span style={{ color: baseColor, fontSize: 14, fontWeight: 500, lineHeight: 1.3 }}>{title}</span>
        {subtitle && (
          <span style={{ color: secondaryColor, fontSize: 12, lineHeight: 1.3 }}>{subtitle}</span>
        )}
      </span>
      <span style={{ color: 'var(--color-text-secondary)', display: 'inline-flex', flexShrink: 0 }}>
        <ChevronIcon />
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Group atom
// ---------------------------------------------------------------------------
function SettingsGroupDemo({
  header,
  children,
}: {
  header?: string;
  children: ReactNode[];
}) {
  return (
    <div
      style={{
        padding: '0 16px',
        display: 'flex',
        flexDirection: 'column',
        gap: 8,
      }}
    >
      {header && (
        <span
          style={{
            paddingLeft: 4,
            color: 'var(--color-text-secondary)',
            fontSize: 12,
            fontWeight: 500,
            letterSpacing: '0.5px',
            textTransform: 'uppercase',
          }}
        >
          {header}
        </span>
      )}
      <div
        style={{
          background: 'white',
          borderRadius: 16,
          overflow: 'hidden',
        }}
      >
        {children.map((child, i) => (
          <div key={i}>
            {child}
            {i < children.length - 1 && (
              <div
                style={{
                  height: 0.5,
                  marginLeft: 52,
                  background: 'var(--color-divider)',
                }}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitSettingsGroupSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div
          style={{
            width: 360,
            background: 'var(--color-surface)',
            padding: '24px 0',
            borderRadius: 12,
          }}
        >
          <SettingsGroupDemo header="계정">
            {[
              <Tile key="1" title="이메일" subtitle="user@example.com" />,
              <Tile key="2" title="비밀번호" subtitle="마지막 변경 6개월 전" />,
              <Tile key="3" title="로그아웃" destructive />,
            ]}
          </SettingsGroupDemo>
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 360, background: 'var(--color-surface)', padding: '24px 0', borderRadius: 12 }}>
            <SettingsGroupDemo header="계정">
              {[
                <Tile key="1" title="이메일" subtitle="user@example.com" />,
                <Tile key="2" title="비밀번호" />,
              ]}
            </SettingsGroupDemo>
          </div>
        }
        labels={[
          { text: 'spacing-medium → 카드 좌우 padding (16)', style: { top: 12, left: '50%', transform: 'translateX(-50%)' } },
          { text: 'header (uppercase · 회색 · letter-spacing 0.5)', style: { top: 60, right: 8 } },
          { text: 'radius-card (16) · 카드 모서리', style: { bottom: 80, right: 8 } },
          { text: 'divider 0.5px · indent 52 (icon 폭만큼 들여쓰기)', style: { bottom: 12, left: 8 } },
        ]}
      />

      <SpecSection title="With / without header">
        <PreviewTable
          rows={[
            {
              name: 'with header',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: 12, borderRadius: 12 }}>
                  <SettingsGroupDemo header="알림">
                    {[
                      <Tile key="1" title="푸시 알림" />,
                      <Tile key="2" title="이메일 알림" />,
                    ]}
                  </SettingsGroupDemo>
                </div>
              ),
              description:
                '카드 위에 회색 대문자 라벨을 두어 그룹의 의미를 명시. 같은 화면에 그룹이 여러 개일 때 사용.',
            },
            {
              name: 'without header',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: 12, borderRadius: 12 }}>
                  <SettingsGroupDemo>
                    {[
                      <Tile key="1" title="앱 정보" />,
                      <Tile key="2" title="개인정보 처리방침" />,
                    ]}
                  </SettingsGroupDemo>
                </div>
              ),
              description:
                '단일 그룹이거나 그룹의 의미가 자명할 때 — 헤더 없이 카드만.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Composition">
        <PreviewTable
          rows={[
            {
              name: 'single tile',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: 12, borderRadius: 12 }}>
                  <SettingsGroupDemo>{[<Tile key="1" title="앱 정보" />]}</SettingsGroupDemo>
                </div>
              ),
              description: '행 1개여도 카드로 감싸 다른 그룹과 시각적 일관성 유지.',
            },
            {
              name: 'multiple tiles',
              preview: (
                <div style={{ width: 280, background: 'var(--color-surface)', padding: 12, borderRadius: 12 }}>
                  <SettingsGroupDemo>
                    {[
                      <Tile key="1" title="이메일" subtitle="user@example.com" />,
                      <Tile key="2" title="비밀번호" />,
                      <Tile key="3" title="2단계 인증" />,
                      <Tile key="4" title="로그아웃" destructive />,
                    ]}
                  </SettingsGroupDemo>
                </div>
              ),
              description: '여러 행 — 행 사이에 0.5px 얇은 선이 그어지고 destructive 행을 마지막에 둠.',
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
function DoMultipleGroupsWithHeaders() {
  return (
    <div style={{ width: 280, background: 'var(--color-surface)', padding: 12, borderRadius: 12, display: 'flex', flexDirection: 'column', gap: 16 }}>
      <SettingsGroupDemo header="계정">
        {[
          <Tile key="1" title="이메일" />,
          <Tile key="2" title="비밀번호" />,
        ]}
      </SettingsGroupDemo>
      <SettingsGroupDemo header="알림">
        {[<Tile key="1" title="푸시" />]}
      </SettingsGroupDemo>
    </div>
  );
}

function DontGiantSingleGroup() {
  return (
    <div style={{ width: 280, background: 'var(--color-surface)', padding: 12, borderRadius: 12 }}>
      <SettingsGroupDemo>
        {[
          <Tile key="1" title="이메일" />,
          <Tile key="2" title="비밀번호" />,
          <Tile key="3" title="푸시 알림" />,
          <Tile key="4" title="앱 정보" />,
          <Tile key="5" title="로그아웃" destructive />,
        ]}
      </SettingsGroupDemo>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-multiple-groups-with-headers': DoMultipleGroupsWithHeaders,
  'dont-giant-single-group': DontGiantSingleGroup,
};
