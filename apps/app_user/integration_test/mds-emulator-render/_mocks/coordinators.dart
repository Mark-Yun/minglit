// 화면 builder 들이 공통으로 쓰는 Coordinator mock 풀.

import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeCoordinator extends Mock implements HomeCoordinator {}

// 추가될 mock 들 (필요 시):
// class MockEventCoordinator extends Mock implements EventCoordinator {}
// class MockAuthCoordinator extends Mock implements AuthCoordinator {}
// class MockPartnerCoordinator extends Mock implements PartnerCoordinator {}
