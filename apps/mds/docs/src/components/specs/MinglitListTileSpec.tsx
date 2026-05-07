/**
 * MinglitListTile — generic list row with title, subtitle, leading, trailing.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_list_tile.dart
 *   leading: any widget (icon · CircleAvatar via avatar prop · etc.)
 *   trailing: any widget (chevron · badge · text · empty)
 *   subtitle: optional second line
 *   enabled: muted opacity when false
 *
 * Visual contract — 사용자가 보는 것:
 *   2-줄 행 (title + subtitle) 또는 1-줄 행 (title만)
 *   좌측에 아이콘 / 아바타 / (비움), 우측에 chevron / 뱃지 / 값 / (비움)
 *   탭 시 좌측 둥근 사각형 ripple, 비활성 시 흐려진 회색 톤
 *
 * vs SettingsTile: ListTile은 일반 리스트 (멤버 / 이벤트 등 도메인 데이터)에 사용,
 *   고정 높이가 없고 padding이 더 여유롭다. SettingsTile은 설정 행 전용 48px 고정.
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
function ChevronIcon() {
  return (
    <svg viewBox="0 0 24 24" width={20} height={20} fill="none" stroke="currentColor" strokeWidth={2}>
      <polyline points="9 18 15 12 9 6" />
    </svg>
  );
}

function PersonIcon() {
  return (
    <svg viewBox="0 0 24 24" width={24} height={24} fill="none" stroke="currentColor" strokeWidth={2}>
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}

function MailIcon() {
  return (
    <svg viewBox="0 0 24 24" width={24} height={24} fill="none" stroke="currentColor" strokeWidth={2}>
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22 6 12 13 2 6" />
    </svg>
  );
}

function Avatar({ initials, color }: { initials: string; color: string }) {
  return (
    <span
      style={{
        width: 40,
        height: 40,
        borderRadius: '50%',
        background: color,
        color: 'white',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 14,
        fontWeight: 600,
      }}
    >
      {initials}
    </span>
  );
}

function Badge({ label, color = 'var(--color-text-secondary)' }: { label: string; color?: string }) {
  return (
    <span
      style={{
        fontSize: 11,
        fontWeight: 600,
        padding: '2px 8px',
        borderRadius: 999,
        background: 'rgba(0,0,0,0.06)',
        color,
      }}
    >
      {label}
    </span>
  );
}

function ListTileDemo({
  title,
  subtitle,
  leading,
  trailing,
  enabled = true,
}: {
  title: string;
  subtitle?: string;
  leading?: ReactNode;
  trailing?: ReactNode;
  enabled?: boolean;
}) {
  const opacity = enabled ? 1 : 0.4;
  return (
    <div
      style={{
        padding: '12px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        opacity,
        background: 'white',
        borderRadius: 8,
        cursor: enabled ? 'pointer' : 'default',
      }}
    >
      {leading && (
        <span style={{ display: 'inline-flex', alignItems: 'center', flexShrink: 0, color: 'var(--color-text-secondary)' }}>
          {leading}
        </span>
      )}
      <span style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, gap: 2 }}>
        <span
          style={{
            color: 'var(--color-text-primary)',
            fontSize: 16,
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
              color: 'var(--color-text-secondary)',
              fontSize: 14,
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
      {trailing && (
        <span style={{ display: 'inline-flex', alignItems: 'center', flexShrink: 0 }}>
          {trailing}
        </span>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitListTileSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: 360, background: 'white', borderRadius: 12, overflow: 'hidden' }}>
          <ListTileDemo
            leading={<Avatar initials="홍" color="#a78bfa" />}
            title="홍길동"
            subtitle="파트너 매니저"
            trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
          />
        </div>
      </SpecHero>

      <SpecAnatomy
        subject={
          <div style={{ width: 360, background: 'white', borderRadius: 12, overflow: 'hidden' }}>
            <ListTileDemo
              leading={<Avatar initials="홍" color="#a78bfa" />}
              title="홍길동"
              subtitle="파트너 매니저"
              trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
            />
          </div>
        }
        labels={[
          { text: 'spacing-medium → 좌우 padding (16)', style: { top: 12, right: 8 } },
          { text: 'leading slot — icon / avatar / 비움', style: { top: '50%', left: 0 } },
          { text: 'spacing-medium → leading ↔ title gap (16)', style: { bottom: 12, left: 8 } },
          { text: 'trailing slot — chevron / 뱃지 / 비움', style: { top: '50%', right: 0 } },
        ]}
      />

      <SpecSection title="Leading slot">
        <PreviewTable
          rows={[
            {
              name: 'avatar',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<Avatar initials="홍" color="#a78bfa" />}
                    title="홍길동"
                    subtitle="파트너 매니저"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: '사람 / 파트너 등 entity를 표현하는 행. 원형 아바타 (이미지 또는 이니셜).',
            },
            {
              name: 'icon',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<MailIcon />}
                    title="새 메시지 도착"
                    subtitle="2시간 전"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: '추상 개념 / 시스템 알림 등을 표현하는 행. 24px 아이콘.',
            },
            {
              name: 'none',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    title="공지사항"
                    subtitle="시스템 점검 안내"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: 'leading 슬롯이 비어있는 단순 텍스트 행.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Trailing slot">
        <PreviewTable
          rows={[
            {
              name: 'chevron',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<PersonIcon />}
                    title="프로필 편집"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: '탭 시 다음 화면으로 이동한다는 신호. 가장 흔한 형태.',
            },
            {
              name: 'badge',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<Avatar initials="김" color="#fb7185" />}
                    title="김영희"
                    subtitle="이벤트 매니저"
                    trailing={<Badge label="관리자" color="var(--color-primary)" />}
                  />
                </div>
              ),
              description: '상태 / 역할 라벨을 우측에 표시. 탭은 가능하지만 chevron 없음.',
            },
            {
              name: 'none',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<MailIcon />}
                    title="버전 정보"
                    subtitle="v26.05.42"
                  />
                </div>
              ),
              description: '탭 동작 없는 정보 행.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="Subtitle">
        <PreviewTable
          rows={[
            {
              name: 'with subtitle (2-line)',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<Avatar initials="홍" color="#a78bfa" />}
                    title="홍길동"
                    subtitle="파트너 매니저 · hong@example.com"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: 'title 아래 보조 정보 한 줄. 정렬은 좌우 모두 vertically-center.',
            },
            {
              name: 'title only (1-line)',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<MailIcon />}
                    title="공지사항"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: 'subtitle을 비우면 행 높이가 자동으로 줄어들고 title이 vertical center로 정렬.',
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
                  <ListTileDemo
                    leading={<Avatar initials="홍" color="#a78bfa" />}
                    title="홍길동"
                    subtitle="파트너 매니저"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                  />
                </div>
              ),
              description: '탭 가능한 일반 상태. 탭 시 좌측 둥근 사각형 영역에 잠깐 ripple이 표시됨.',
            },
            {
              name: 'disabled',
              preview: (
                <div style={{ width: 280, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
                  <ListTileDemo
                    leading={<Avatar initials="홍" color="#a78bfa" />}
                    title="홍길동"
                    subtitle="권한 없음"
                    trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
                    enabled={false}
                  />
                </div>
              ),
              description: '전체적으로 흐려지고 탭이 차단됨. 권한 부족 / 잠긴 항목에 사용.',
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
function DoAvatarPersonRow() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <ListTileDemo
        leading={<Avatar initials="홍" color="#a78bfa" />}
        title="홍길동"
        subtitle="파트너 매니저"
        trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
      />
    </div>
  );
}

function DoIconConceptRow() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <ListTileDemo
        leading={<MailIcon />}
        title="새 메시지"
        subtitle="2시간 전"
        trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>}
      />
    </div>
  );
}

function DontUseForSettings() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 8, overflow: 'hidden' }}>
      <ListTileDemo title="언어" subtitle="한국어" trailing={<span style={{ color: 'var(--color-text-secondary)' }}><ChevronIcon /></span>} />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-avatar-person-row': DoAvatarPersonRow,
  'do-icon-concept-row': DoIconConceptRow,
  'dont-use-for-settings': DontUseForSettings,
};
