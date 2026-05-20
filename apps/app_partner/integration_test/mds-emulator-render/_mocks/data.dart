// Mock 데이터 팩토리. builder fluent 메서드들이 사용.
//
// 시간 의존 데이터는 고정값 사용 — PNG 캡처 시 결정적 결과 보장.

import 'package:minglit_kit/minglit_kit.dart';

/// 결정적 캡처를 위한 기준 시간.
final DateTime mockBaseTime = DateTime.utc(2026, 5, 17, 19);

/// MDS render 용 mock Partner.
Partner mockPartner({
  String id = 'mock-partner-1',
  String name = '밍글릿 파트너',
}) => Partner(id: id, name: name);

/// MDS render 용 mock Event 목록.
List<Event> mockEvents({int count = 2, DateTime? now}) {
  final base = now ?? mockBaseTime;
  return List.generate(
    count,
    (i) => Event(
      id: 'mock-event-$i',
      partyId: 'mock-party-1',
      startTime: base.add(Duration(minutes: 30 + i * 60)),
      endTime: base.add(Duration(hours: 2 + i)),
      createdAt: base,
      updatedAt: base,
      title: 'Mock 이벤트 ${i + 1}',
      currentParticipants: (i + 1) * 5,
    ),
  );
}

/// MDS render 용 mock Verification (partner custom 인증).
Verification mockVerification({
  String id = 'mock-verification-1',
  String displayName = '골프 핸디캡 인증',
  String internalName = 'golf_handicap',
  VerificationCategory category = VerificationCategory.etc,
  bool isActive = true,
}) => Verification(
  id: id,
  displayName: displayName,
  internalName: internalName,
  category: category,
  partnerId: 'mock-partner-1',
  description: '골프 핸디캡을 인증하는 용도입니다.',
  isActive: isActive,
  formSchema: [
    const VerificationFormField(
      type: 'text',
      label: '핸디캡 수치',
      key: 'handicap_value',
    ),
    const VerificationFormField(
      type: 'file',
      label: '증빙 파일',
      key: 'proof_file',
      required: false,
    ),
  ],
);

/// MDS render 용 mock bank account data.
Map<String, dynamic> mockBankAccount({
  String bankName = '국민은행',
  String accountHolder = '밍글릿 파트너',
  String accountNumber = '12345678901234',
}) => {
  'bank_name': bankName,
  'account_holder': accountHolder,
  'account_number': accountNumber,
};

/// MDS render 용 mock RecurrenceRule (활성 상태, 매주 월요일).
RecurrenceRule mockRecurrenceRule({
  String id = 'mock-rule-1',
  String partyId = 'mock-party-1',
  RecurrencePattern pattern = RecurrencePattern.weekly,
  RecurrenceStatus status = RecurrenceStatus.active,
  List<int> daysOfWeek = const [1],
}) => RecurrenceRule(
  id: id,
  partyId: partyId,
  pattern: pattern,
  startTime: '20:00',
  endTime: '22:00',
  createdAt: mockBaseTime,
  updatedAt: mockBaseTime,
  daysOfWeek: daysOfWeek,
  status: status,
);
