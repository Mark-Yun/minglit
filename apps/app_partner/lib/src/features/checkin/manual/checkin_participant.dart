/// 수동 체크인용 참가자 데이터 모델.
class CheckinParticipant {
  const CheckinParticipant({
    required this.id,
    required this.ticketId,
    required this.name,
    required this.phoneLast4,
    required this.status,
    this.checkedInAt,
  });

  factory CheckinParticipant.fromJson(Map<String, dynamic> json) {
    return CheckinParticipant(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      name: json['name'] as String,
      phoneLast4: (json['phone_last4'] as String?) ?? '',
      status: json['status'] as String,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
    );
  }

  final String id;
  final String ticketId;
  final String name;
  final String phoneLast4;

  /// 'ticket_issued' | 'checked_in' | 'no_show'
  final String status;
  final DateTime? checkedInAt;

  bool get isCheckedIn => status == 'checked_in';

  CheckinParticipant copyWith({String? status, DateTime? checkedInAt}) {
    return CheckinParticipant(
      id: id,
      ticketId: ticketId,
      name: name,
      phoneLast4: phoneLast4,
      status: status ?? this.status,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }
}
