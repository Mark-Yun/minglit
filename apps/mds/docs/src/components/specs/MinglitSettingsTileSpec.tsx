/**
 * MinglitSettingsTile — compact settings row (minHeight 48px).
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_settings_tile.dart
 *   trailing variants: navigation (chevron) · toggle · value (text) · none
 *   destructive: text + icon → error color (logout · 탈퇴 등)
 *   subtitle: 현재 값 한 줄 표시 (예: "한국어", "켜짐")
 *
 * Visual contract:
 *   minHeight 48px · 위아래 padding 12 고정 · 좌우 padding 16 · leading icon 20px
 *   1줄 (title만): minHeight 48 발동 → 그대로 48px
 *   2줄 (title + subtitle): vertical padding 고정이라 자연스럽게 ~58px로 자람
 *   title (bodyMedium) · optional subtitle (bodySmall · 회색)
 *   trailing 4종 — 사용 맥락에 따라 선택
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
// Atoms — token-driven HTML stand-in.
// ---------------------------------------------------------------------------
function ChevronIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function GlobeIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <circle cx="12" cy="12" r="10" />
      <line x1="2" y1="12" x2="22" y2="12" />
      <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function LogoutIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  );
}

function ToggleSwitch({ on = false }: { on?: boolean }) {
  return (
    <span
      style={{
        width: 36,
        height: 20,
        borderRadius: 999,
        background: on ? 'var(--color-primary)' : 'var(--color-divider)',
        position: 'relative',
        display: 'inline-block',
        flexShrink: 0,
      }}
    >
      <span
        style={{
          position: 'absolute',
          top: 2,
          left: on ? 18 : 2,
          width: 16,
          height: 16,
          borderRadius: '50%',
          background: 'white',
          boxShadow: '0 1px 2px rgba(0,0,0,0.2)',
          transition: 'left 0.15s',
        }}
      />
    </span>
  );
}

function SettingsTileDemo({
  title,
  subtitle,
  leading,
  trailing = 'navigation',
  trailingValue,
  toggleValue = false,
  destructive = false,
  enabled = true,
}: {
  title: string;
  subtitle?: string;
  leading?: ReactNode;
  trailing?: 'navigation' | 'toggle' | 'value' | 'none';
  trailingValue?: string;
  toggleValue?: boolean;
  destructive?: boolean;
  enabled?: boolean;
}) {
  const baseColor = destructive ? 'var(--color-error)' : 'var(--color-text-primary)';
  const secondaryColor = destructive
    ? 'var(--color-error)'
    : 'var(--color-text-secondary)';
  const opacity = enabled ? 1 : 0.4;

  let trailingNode: ReactNode = null;
  if (trailing === 'navigation') {
    trailingNode = (
      <span style={{ color: 'var(--color-text-secondary)', display: 'inline-flex' }}>
        <ChevronIcon />
      </span>
    );
  } else if (trailing === 'toggle') {
    trailingNode = <ToggleSwitch on={toggleValue} />;
  } else if (trailing === 'value' && trailingValue) {
    trailingNode = (
      <span
        style={{
          color: 'var(--color-text-secondary)',
          fontSize: 13,
        }}
      >
        {trailingValue}
      </span>
    );
  }

  return (
    <div
      style={{
        // 1줄일 때는 그대로 48 유지 (minHeight). 2줄일 때는 vertical padding을
        // 고정해 자연스럽게 자라도록 한다.
        minHeight: 48,
        padding: '12px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        opacity,
        background: 'white',
        cursor: enabled && trailing !== 'toggle' ? 'pointer' : 'default',
      }}
    >
      {leading && (
        <span
          style={{
            color: secondaryColor,
            display: 'inline-flex',
            flexShrink: 0,
          }}
        >
          {leading}
        </span>
      )}
      <span style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <span
          style={{
            color: baseColor,
            fontSize: 14,
            fontWeight: 500,
            lineHeight: 1.3,
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
          }}
        >
          {title}
        </span>
        {subtitle && (
          <span
            style={{
              color: secondaryColor,
              fontSize: 12,
              lineHeight: 1.3,
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
            }}
          >
            {subtitle}
          </span>
        )}
      </span>
      {trailingNode && (
        <span style={{ display: 'inline-flex', alignItems: 'center', flexShrink: 0 }}>
          {trailingNode}
        </span>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitSettingsTileSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 320, background: 'white', borderRadius: 12, overflow: 'hidden' }}>
          <SettingsTileDemo
            leading={<GlobeIcon />}
            title="언어"
            subtitle="한국어"
            trailing="navigation"
          />
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 320, background: 'white', borderRadius: 12, overflow: 'hidden' }}>
            <SettingsTileDemo
              leading={<GlobeIcon />}
              title="언어"
              subtitle="한국어"
              trailing="navigation"
            />
          </div>
        }
        labels={[
          { text: 'minHeight 48 · 1줄이면 48 / 2줄이면 자라남', style: { top: 12, left: '50%', transform: 'translateX(-50%)' } },
          { text: 'spacing-sm → 위아래 padding 12 (고정)', style: { bottom: 12, left: 8 } },
          { text: 'spacing-medium → 좌우 padding 16', style: { bottom: 12, right: 8 } },
          { text: 'leading icon 20px', style: { top: '50%', left: 0 } },
          { text: 'spacing-medium → icon ↔ title gap (16)', style: { top: '50%', right: 0 } },
        ]}
      />

      <SpecSection title="Trailing variants">
        <PreviewTable
          rows={[
            {
              name: 'navigation',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="언어" trailing="navigation" />
                </div>
              ),
              description: '탭하면 다음 화면으로 이동. 우측에 ▷ chevron. 가장 흔한 형태.',
            },
            {
              name: 'value',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="언어" trailing="value" trailingValue="한국어" />
                </div>
              ),
              description: '읽기 전용 정보 — 우측에 현재 값 텍스트만 (탭 동작 없음).',
            },
            {
              name: 'toggle',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<BellIcon />} title="알림 받기" trailing="toggle" toggleValue={true} />
                </div>
              ),
              description: '온/오프 즉시 반영 — 우측에 토글 스위치. 행 자체 탭은 비활성, 토글만 반응.',
            },
            {
              name: 'none',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="버전" subtitle="v26.05.42" trailing="none" />
                </div>
              ),
              description: '우측이 비어있는 안내 행. 정보 표시 전용 — 보통 subtitle에 값이 들어감.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Subtitle slot">
        <PreviewTable
          rows={[
            {
              name: 'with subtitle',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="언어" subtitle="한국어" trailing="navigation" />
                </div>
              ),
              description: 'title 아래 작은 회색 텍스트 한 줄로 현재 값 / 보조 설명. 행 높이가 48 → 약 58로 자연스럽게 자라며 위아래 padding은 12로 고정 유지.',
            },
            {
              name: 'without subtitle',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="개인정보 처리방침" trailing="navigation" />
                </div>
              ),
              description: 'title 한 줄만. value를 보여줄 게 없는 단순 진입 행에 사용.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="States">
        <PreviewTable
          rows={[
            {
              name: 'default',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="언어" subtitle="한국어" />
                </div>
              ),
              description: '탭 가능한 일반 상태.',
            },
            {
              name: 'destructive',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<LogoutIcon />} title="로그아웃" trailing="none" destructive />
                </div>
              ),
              description: 'icon + title이 에러 색(빨강)으로 강조 — 로그아웃 / 탈퇴 같은 되돌릴 수 없는 액션.',
            },
            {
              name: 'disabled',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <SettingsTileDemo leading={<GlobeIcon />} title="언어" subtitle="한국어" enabled={false} />
                </div>
              ),
              description: '전체적으로 흐려지고 탭이 차단됨. 권한 부족 / 잠금 상태에 사용.',
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
function DoNavigationRow() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <SettingsTileDemo leading={<GlobeIcon />} title="언어" subtitle="한국어" trailing="navigation" />
    </div>
  );
}

function DoToggleRow() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <SettingsTileDemo leading={<BellIcon />} title="알림 받기" trailing="toggle" toggleValue={true} />
    </div>
  );
}

function DoDestructiveLast() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <SettingsTileDemo leading={<LogoutIcon />} title="로그아웃" trailing="none" destructive />
    </div>
  );
}

function DontMixedTrailing() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <SettingsTileDemo leading={<GlobeIcon />} title="언어" trailing="navigation" />
      <SettingsTileDemo leading={<BellIcon />} title="알림" trailing="toggle" toggleValue={true} />
      <SettingsTileDemo leading={<GlobeIcon />} title="버전" trailing="value" trailingValue="v26.05" />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-navigation-row': DoNavigationRow,
  'do-toggle-row': DoToggleRow,
  'do-destructive-last': DoDestructiveLast,
  'dont-mixed-trailing': DontMixedTrailing,
};
