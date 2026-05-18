// MdsRenderEngine — catalog 를 받아 testWidgets 자동 생성 + 캡처.
//
// 각 state 마다 독립 testWidgets (실패 격리). screenshot name 컨벤션:
//   <screen>__<state>
// driver 의 onScreenshot 콜백이 이 name 을 split 해서 출력 경로 결정.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'builder.dart';
import 'catalog.dart';

class MdsRenderEngine {
  /// 카탈로그의 모든 state 를 testWidgets 로 실행 + PNG 캡처.
  static void run<B extends MdsScreenBuilder<dynamic>>(MdsCatalog<B> catalog) {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await initializeDateFormatting('ko_KR');
    });

    for (final state in catalog.states) {
      testWidgets(state.name, (tester) async {
        final builder = state.setup(catalog.builder());
        await tester.pumpWidget(builder.build());
        // Fix #2590: repeat() 애니메이션은 pumpAndSettle이 timeout — 고정 pump 사용.
        if (state.infiniteAnimation) {
          await tester.pump(const Duration(milliseconds: 300));
        } else {
          await tester.pumpAndSettle();
        }

        // Android: Flutter surface → image 변환 후 캡처 필요.
        await binding.convertFlutterSurfaceToImage();
        if (state.infiniteAnimation) {
          await tester.pump(const Duration(milliseconds: 100));
        } else {
          await tester.pumpAndSettle();
        }

        await binding.takeScreenshot('${catalog.screen}__${state.name}');
      });
    }
  }
}
