// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mistake_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MistakeListEnvelope _$MistakeListEnvelopeFromJson(Map<String, dynamic> json) =>
    MistakeListEnvelope(
      success: json['success'] as bool,
      data: MistakeList.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$MistakeListEnvelopeToJson(
  MistakeListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
