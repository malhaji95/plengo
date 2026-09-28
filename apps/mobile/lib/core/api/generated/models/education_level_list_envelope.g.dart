// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'education_level_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EducationLevelListEnvelope _$EducationLevelListEnvelopeFromJson(Map<String, dynamic> json) =>
    EducationLevelListEnvelope(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>).map((e) => EducationLevel.fromJson(e as Map<String, dynamic>)).toList(),
      error: json['error'],
    );

Map<String, dynamic> _$EducationLevelListEnvelopeToJson(EducationLevelListEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
