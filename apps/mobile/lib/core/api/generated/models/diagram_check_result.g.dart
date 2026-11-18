// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_check_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramCheckResult _$DiagramCheckResultFromJson(Map<String, dynamic> json) =>
    DiagramCheckResult(
      diagramId: json['diagramId'] as String,
      correctCount: (json['correctCount'] as num).toInt(),
      totalCount: (json['totalCount'] as num).toInt(),
      labels: (json['labels'] as List<dynamic>)
          .map((e) => DiagramLabelResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DiagramCheckResultToJson(DiagramCheckResult instance) =>
    <String, dynamic>{
      'diagramId': instance.diagramId,
      'correctCount': instance.correctCount,
      'totalCount': instance.totalCount,
      'labels': instance.labels,
    };
