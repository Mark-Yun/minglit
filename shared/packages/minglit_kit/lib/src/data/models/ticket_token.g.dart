// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketToken _$TicketTokenFromJson(Map<String, dynamic> json) => _TicketToken(
      ticketId: json['ticketId'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      signature: json['signature'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$TicketTokenToJson(_TicketToken instance) =>
    <String, dynamic>{
      'ticketId': instance.ticketId,
      'eventId': instance.eventId,
      'userId': instance.userId,
      'signature': instance.signature,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
