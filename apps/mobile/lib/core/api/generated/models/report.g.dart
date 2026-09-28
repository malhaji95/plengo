// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: json['id'] as String,
  itemType: $enumDecode(_$ReportItemTypeEnumMap, json['itemType']),
  itemId: json['itemId'] as String,
  reason: $enumDecode(_$ReportReasonEnumMap, json['reason']),
  note: json['note'] as String?,
  status: $enumDecode(_$ReportStatusEnumMap, json['status']),
  createdAt: json['createdAt'] as String,
  resolvedAt: json['resolvedAt'] as String?,
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'itemType': instance.itemType,
  'itemId': instance.itemId,
  'reason': instance.reason,
  'note': instance.note,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'resolvedAt': instance.resolvedAt,
};

const _$ReportItemTypeEnumMap = {ReportItemType.question: 'question', ReportItemType.flashcard: 'flashcard'};

const _$ReportReasonEnumMap = {
  ReportReason.wrongAnswer: 'wrong_answer',
  ReportReason.typo: 'typo',
  ReportReason.unclear: 'unclear',
  ReportReason.imageProblem: 'image_problem',
  ReportReason.other: 'other',
};

const _$ReportStatusEnumMap = {
  ReportStatus.open: 'open',
  ReportStatus.resolved: 'resolved',
  ReportStatus.dismissed: 'dismissed',
};
