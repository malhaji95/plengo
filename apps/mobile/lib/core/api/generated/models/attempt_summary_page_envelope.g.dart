// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_summary_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptSummaryPageEnvelope _$AttemptSummaryPageEnvelopeFromJson(
  Map<String, dynamic> json,
) => AttemptSummaryPageEnvelope(
  success: json['success'] as bool,
  data: AttemptSummaryPage.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$AttemptSummaryPageEnvelopeToJson(
  AttemptSummaryPageEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
