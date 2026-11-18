// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uncategorized.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Uncategorized _$UncategorizedFromJson(Map<String, dynamic> json) =>
    Uncategorized(
      questionCount: (json['questionCount'] as num).toInt(),
      accessibleCount: (json['accessibleCount'] as num).toInt(),
    );

Map<String, dynamic> _$UncategorizedToJson(Uncategorized instance) =>
    <String, dynamic>{
      'questionCount': instance.questionCount,
      'accessibleCount': instance.accessibleCount,
    };
