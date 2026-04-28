/**
 * Inline visual spec for MinglitButton.
 * Mirrors apps/mds/storybook/lib/main.dart MinglitButton stories.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_button.dart
 *   variants: primary / secondary / text / destructive
 *   sizes:    small (h36, font14) / medium (h48, font15) / large (h56, font16) — large default
 *   icon slot, isLoading, expand
 *
 * Tokens consumed:
 *   color-primary, color-on-primary (literal #ffffff)
 *   color-error, color-on-error (literal #ffffff)
 *   radius-button (12), spacing-small (icon-label gap), spacing-medium (h-padding)
 */

function Annotation({ children }: { children: React.ReactNode }) {
  return <span className="mds-spec__annotation">{children}</span>;
}

export default function MinglitButtonSpec() {
  return (
    <div className="mds-spec">
      {/* Variants */}
      <div className="mds-spec__group">
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--lg">
            <span>참여하기</span>
          </button>
          <Annotation>primary · bg=color-primary · fg=#fff</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--secondary mds-spec-btn--lg">
            <span>취소</span>
          </button>
          <Annotation>secondary · border+fg=color-primary</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--md">
            <span>더보기 →</span>
          </button>
          <Annotation>text · fg=color-primary · default size=md, expand=false</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--destructive mds-spec-btn--lg">
            <span>삭제하기</span>
          </button>
          <Annotation>destructive · bg=color-error · fg=#fff</Annotation>
        </div>
      </div>

      {/* Sizes */}
      <div className="mds-spec__group">
        <p className="mds-spec__label">Sizes</p>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm">
            <span>Small</span>
          </button>
          <Annotation>height=36 · font=14 · icon=16</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--md">
            <span>Medium</span>
          </button>
          <Annotation>height=48 · font=15 · icon=18</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--lg">
            <span>Large (default)</span>
          </button>
          <Annotation>height=56 · font=16 · icon=20</Annotation>
        </div>
      </div>

      {/* States */}
      <div className="mds-spec__group">
        <p className="mds-spec__label">States</p>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--lg">
            <span>기본</span>
          </button>
          <Annotation>default · onPressed != null</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--lg" disabled>
            <span>비활성</span>
          </button>
          <Annotation>disabled · onPressed == null · opacity 0.4</Annotation>
        </div>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--lg mds-spec-btn--loading">
            <span>로딩 중</span>
          </button>
          <Annotation>isLoading=true · spinner replaces tap, label dims</Annotation>
        </div>
      </div>

      {/* Icon slot */}
      <div className="mds-spec__group">
        <p className="mds-spec__label">Icon slot</p>
        <div className="mds-spec__row">
          <button className="mds-spec-btn mds-spec-btn--destructive mds-spec-btn--lg">
            <span aria-hidden style={{ fontSize: '1.1em' }}>🗑</span>
            <span>삭제하기</span>
          </button>
          <Annotation>icon: IconData · gap=spacing-small (8px)</Annotation>
        </div>
      </div>

      {/* Expand */}
      <div className="mds-spec__group">
        <p className="mds-spec__label">expand (full-width)</p>
        <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--lg mds-spec__expand-demo">
          <span>참여하기</span>
        </button>
        <Annotation>
          expand=true (default for primary/secondary/destructive) · false for text
        </Annotation>
      </div>
    </div>
  );
}
