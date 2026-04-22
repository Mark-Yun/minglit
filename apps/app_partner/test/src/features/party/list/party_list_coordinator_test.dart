import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('PartyListCoordinator', () {
    late _MockGoRouter mockRouter;
    late PartyListCoordinator coordinator;

    setUp(() {
      mockRouter = _MockGoRouter();
      coordinator = PartyListCoordinator(mockRouter);
      when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    });

    test('goToCreate pushes /more/parties/create', () {
      coordinator.goToCreate();
      verify(() => mockRouter.push('/more/parties/create')).called(1);
    });

    test('goToDetail pushes /more/parties/<partyId>', () {
      coordinator.goToDetail('party-123');
      verify(() => mockRouter.push('/more/parties/party-123')).called(1);
    });
  });
}
