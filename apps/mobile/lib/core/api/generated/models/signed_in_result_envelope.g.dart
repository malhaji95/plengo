// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_in_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedInResultEnvelope _$SignedInResultEnvelopeFromJson(Map<String, dynamic> json) => SignedInResultEnvelope(
  success: json['success'] as bool,
  data: SignedInResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$SignedInResultEnvelopeToJson(SignedInResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
