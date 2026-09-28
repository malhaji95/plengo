// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_cards_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeckCardsEnvelope _$DeckCardsEnvelopeFromJson(Map<String, dynamic> json) => DeckCardsEnvelope(
  success: json['success'] as bool,
  data: DeckCards.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$DeckCardsEnvelopeToJson(DeckCardsEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
