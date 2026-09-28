// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_deck_cards_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDeckCardsEnvelope _$UserDeckCardsEnvelopeFromJson(Map<String, dynamic> json) => UserDeckCardsEnvelope(
  success: json['success'] as bool,
  data: UserDeckCards.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$UserDeckCardsEnvelopeToJson(UserDeckCardsEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
