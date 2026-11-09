// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_deck_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDeckListEnvelope _$StudentDeckListEnvelopeFromJson(
  Map<String, dynamic> json,
) => StudentDeckListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => StudentDeck.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$StudentDeckListEnvelopeToJson(
  StudentDeckListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
