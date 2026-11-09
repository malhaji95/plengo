// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_report_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReportRequest _$CreateReportRequestFromJson(Map<String, dynamic> json) =>
    CreateReportRequest(
      itemType: $enumDecode(_$ReportItemTypeEnumMap, json['itemType']),
      itemId: json['itemId'] as String,
      reason: $enumDecode(_$ReportReasonEnumMap, json['reason']),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CreateReportRequestToJson(
  CreateReportRequest instance,
) => <String, dynamic>{
  'itemType': instance.itemType,
  'itemId': instance.itemId,
  'reason': instance.reason,
  'note': ?instance.note,
};

const _$ReportItemTypeEnumMap = {
  ReportItemType.question: 'question',
  ReportItemType.flashcard: 'flashcard',
};

const _$ReportReasonEnumMap = {
  ReportReason.wrongAnswer: 'wrong_answer',
  ReportReason.typo: 'typo',
  ReportReason.unclear: 'unclear',
  ReportReason.imageProblem: 'image_problem',
  ReportReason.other: 'other',
};
