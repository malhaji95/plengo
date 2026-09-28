// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_cards_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DueCardsEnvelope _$DueCardsEnvelopeFromJson(Map<String, dynamic> json) => DueCardsEnvelope(
  success: json['success'] as bool,
  data: DueCards.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$DueCardsEnvelopeToJson(DueCardsEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
