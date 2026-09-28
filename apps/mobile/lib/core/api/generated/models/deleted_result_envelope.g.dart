// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedResultEnvelope _$DeletedResultEnvelopeFromJson(Map<String, dynamic> json) => DeletedResultEnvelope(
  success: json['success'] as bool,
  data: DeletedResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$DeletedResultEnvelopeToJson(DeletedResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
