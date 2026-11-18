// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_answer_correct_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkAnswerCorrectResultEnvelope _$MarkAnswerCorrectResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => MarkAnswerCorrectResultEnvelope(
  success: json['success'] as bool,
  data: MarkAnswerCorrectResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$MarkAnswerCorrectResultEnvelopeToJson(
  MarkAnswerCorrectResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
