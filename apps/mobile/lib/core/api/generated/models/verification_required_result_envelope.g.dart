// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_required_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationRequiredResultEnvelope _$VerificationRequiredResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => VerificationRequiredResultEnvelope(
  success: json['success'] as bool,
  data: VerificationRequiredResult.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
  error: json['error'],
);

Map<String, dynamic> _$VerificationRequiredResultEnvelopeToJson(
  VerificationRequiredResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
