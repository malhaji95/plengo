// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registered_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisteredResultEnvelope _$RegisteredResultEnvelopeFromJson(Map<String, dynamic> json) => RegisteredResultEnvelope(
  success: json['success'] as bool,
  data: RegisteredResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$RegisteredResultEnvelopeToJson(RegisteredResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
