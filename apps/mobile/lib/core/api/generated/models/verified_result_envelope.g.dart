// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verified_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifiedResultEnvelope _$VerifiedResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => VerifiedResultEnvelope(
  success: json['success'] as bool,
  data: VerifiedResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$VerifiedResultEnvelopeToJson(
  VerifiedResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
