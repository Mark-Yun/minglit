import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import '../../utils/mocks.dart';

User createFakeUser({String id = 'test-user-id-001', String email = 'test@minglit.com', String name = '김민글'}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email);
  when(() => user.phone).thenReturn(null);
  when(() => user.userMetadata).thenReturn({'full_name': name, 'name': name, 'avatar_url': null});
  return user;
}

UserProfile createFakeProfile({String id = 'test-user-id-001', String name = '김민글'}) {
  return UserProfile(id: id, name: name, username: 'mingl_test', isVerified: true, gender: 'male', birthYear: 1995, createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1));
}

List<Event> createFakeEvents({int count = 3}) {
  final now = DateTime.now();
  final titles = ['강남 소셜 파티', '홍대 직장인 모임', '이태원 글로벌 파티'];
  return List.generate(count, (i) => Event(id: 'test-event-$i', partyId: 'test-party-$i', title: titles[i % titles.length], startTime: now.add(Duration(days: i + 1)), endTime: now.add(Duration(days: i + 1, hours: 3)), createdAt: now, updatedAt: now, tickets: [Ticket(id: 'test-ticket-$i', name: '일반 티켓', price: i == 0 ? 0 : 15000, createdAt: now, updatedAt: now)]));
}

List<Map<String, dynamic>> createFakeNotifications({int count = 3}) {
  final now = DateTime.now().toIso8601String();
  return List.generate(count, (i) => {'id': 'notif-$i', 'user_id': 'test-user-id-001', 'title': '알림 제목 $i', 'body': '알림 내용입니다.', 'type': 'general', 'is_read': i == 0, 'created_at': now, 'data': <String, dynamic>{}});
}
