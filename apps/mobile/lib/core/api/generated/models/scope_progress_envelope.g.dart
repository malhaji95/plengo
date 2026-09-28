// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scope_progress_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScopeProgressEnvelope _$ScopeProgressEnvelopeFromJson(
  Map<String, dynamic> json,
) => ScopeProgressEnvelope(
  success: json['success'] as bool,
  data: ScopeProgress.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$ScopeProgressEnvelopeToJson(
  ScopeProgressEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
