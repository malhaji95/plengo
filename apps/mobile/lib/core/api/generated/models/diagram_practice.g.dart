// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_practice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramPractice _$DiagramPracticeFromJson(Map<String, dynamic> json) =>
    DiagramPractice(
      diagrams: (json['diagrams'] as List<dynamic>)
          .map((e) => PracticeDiagram.fromJson(e as Map<String, dynamic>))
          .toList(),
      availableCount: (json['availableCount'] as num).toInt(),
      lockedCount: (json['lockedCount'] as num).toInt(),
      urlsExpireAt: json['urlsExpireAt'] as String,
    );

Map<String, dynamic> _$DiagramPracticeToJson(DiagramPractice instance) =>
    <String, dynamic>{
      'diagrams': instance.diagrams,
      'availableCount': instance.availableCount,
      'lockedCount': instance.lockedCount,
      'urlsExpireAt': instance.urlsExpireAt,
    };
