// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_out_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedOutResultEnvelope _$SignedOutResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => SignedOutResultEnvelope(
  success: json['success'] as bool,
  data: SignedOutResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$SignedOutResultEnvelopeToJson(
  SignedOutResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
