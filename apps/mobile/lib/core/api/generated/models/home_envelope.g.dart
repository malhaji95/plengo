// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeEnvelope _$HomeEnvelopeFromJson(Map<String, dynamic> json) => HomeEnvelope(
  success: json['success'] as bool,
  data: Home.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$HomeEnvelopeToJson(HomeEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
