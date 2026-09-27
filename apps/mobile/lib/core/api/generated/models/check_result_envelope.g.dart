// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckResultEnvelope _$CheckResultEnvelopeFromJson(Map<String, dynamic> json) =>
    CheckResultEnvelope(
      success: json['success'] as bool,
      data: CheckResult.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$CheckResultEnvelopeToJson(
  CheckResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
