# 선언적 비동기 처리 위젯 구현 명세서 (Spec)

## 목표
Riverpod의 `AsyncValue`를 처리할 때 반복되는 `when(data:..., loading:..., error:...)` 패턴을 공통화하여 코드 가독성을 높이고 로딩/에러 UI의 일관성을 확보하는 `MinglitAsyncValueWidget`을 구현합니다.

## 상세 요구사항

### 1. 기능 (Features)
- **제네릭 지원**: 다양한 데이터 타입을 처리할 수 있도록 `T` 타입을 지원합니다.
- **표준 로딩 UI**: 별도의 설정이 없으면 `MinglitCircularProgressIndicator`를 표시합니다.
- **표준 에러 UI**: 에러 발생 시 표준 에러 메시지와 재시도 버튼 등을 포함한 UI를 제공합니다.
- **커스텀 가능**: 특정 화면에서 다른 로딩/에러 UI가 필요한 경우 인자로 넘겨받아 처리할 수 있습니다.
- **Shimmer 지원 (선택)**: 로딩 시 단순 인디케이터 대신 스켈레톤(Shimmer)을 보여주는 옵션을 제공합니다.

### 2. 인터페이스 (API Design)
```dart
class MinglitAsyncValueWidget<T> extends StatelessWidget {
  const MinglitAsyncValueWidget({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.showErrorDetails = false,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget Function()? loading;
  final Widget Function(Object, StackTrace)? error;
  final bool showErrorDetails;
}
```

## 구현 위치
- `shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_async_value_widget.dart`

## 통합 (Integration)
- `minglit_ui.dart`에서 익스포트.
- `app_user`, `app_partner`의 기존 `when` 호출부 교체.
