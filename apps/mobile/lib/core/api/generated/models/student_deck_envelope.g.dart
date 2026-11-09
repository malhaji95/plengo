// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_deck_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDeckEnvelope _$StudentDeckEnvelopeFromJson(Map<String, dynamic> json) =>
    StudentDeckEnvelope(
      success: json['success'] as bool,
      data: StudentDeck.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$StudentDeckEnvelopeToJson(
  StudentDeckEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
