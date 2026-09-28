// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'university_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UniversityListEnvelope _$UniversityListEnvelopeFromJson(
  Map<String, dynamic> json,
) => UniversityListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => University.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$UniversityListEnvelopeToJson(
  UniversityListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
