// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectListEnvelope _$SubjectListEnvelopeFromJson(Map<String, dynamic> json) =>
    SubjectListEnvelope(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$SubjectListEnvelopeToJson(
  SubjectListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
