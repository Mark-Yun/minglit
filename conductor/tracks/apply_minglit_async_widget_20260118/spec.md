# MinglitAsyncValueWidget 전체 적용 명세서 (Spec)

## 목표
프로젝트 전반에 걸쳐 파편화된 비동기 상태 처리 로직(`AsyncValue.when`)을 표준화된 `MinglitAsyncValueWidget`으로 교체하여 UI 일관성을 확보하고 유지보수성을 높입니다.

## 작업 범위
- `apps/app_user` 및 `apps/app_partner` 내의 모든 UI 위젯.
- `shared/packages/minglit_kit` 내의 UI 위젯.

## 교체 규칙
**변경 전:**
```dart
asyncValue.when(
  data: (data) => _buildData(data),
  loading: () => const Center(child: CircularProgressIndicator()), // 또는 MinglitCircular...
  error: (e, s) => Center(child: Text('Error: $e')),
)
```

**변경 후:**
```dart
MinglitAsyncValueWidget(
  value: asyncValue,
  data: (data) => _buildData(data),
)
```

## 예외 사항
- **SkipLoadingOnRefresh**: `when(skipLoadingOnRefresh: false)` 등의 옵션을 명시적으로 사용해야 하는 경우.
- **Custom UI**: 표준 로딩/에러 UI가 아닌 완전히 다른 커스텀 UI가 필수적인 경우 (이 경우 `MinglitAsyncValueWidget`의 `loading`/`error` 파라미터로 처리 가능한지 우선 검토).
