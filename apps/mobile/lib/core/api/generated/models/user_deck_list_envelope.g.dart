// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_deck_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDeckListEnvelope _$UserDeckListEnvelopeFromJson(Map<String, dynamic> json) => UserDeckListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>).map((e) => UserDeck.fromJson(e as Map<String, dynamic>)).toList(),
  error: json['error'],
);

Map<String, dynamic> _$UserDeckListEnvelopeToJson(UserDeckListEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
