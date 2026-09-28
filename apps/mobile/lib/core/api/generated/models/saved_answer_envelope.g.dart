// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_answer_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedAnswerEnvelope _$SavedAnswerEnvelopeFromJson(Map<String, dynamic> json) =>
    SavedAnswerEnvelope(
      success: json['success'] as bool,
      data: SavedAnswer.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SavedAnswerEnvelopeToJson(
  SavedAnswerEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
