// 화면 builder 들이 공통으로 쓰는 Coordinator mock 풀.

import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/logic/auth_coordinator.dart';
import 'package:app_user/src/logic/event_coordinator.dart';
import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeCoordinator extends Mock implements HomeCoordinator {}

class MockAuthCoordinator extends Mock implements AuthCoordinator {}

class MockSearchCoordinator extends Mock implements SearchCoordinator {}

class MockEventCoordinator extends Mock implements EventCoordinator {}

class MockPartnerCoordinator extends Mock implements PartnerCoordinator {}

class MockAppCoordinator extends Mock implements AppCoordinator {}
