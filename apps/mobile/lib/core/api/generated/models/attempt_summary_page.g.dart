// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_summary_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptSummaryPage _$AttemptSummaryPageFromJson(Map<String, dynamic> json) => AttemptSummaryPage(
  items: (json['items'] as List<dynamic>).map((e) => AttemptSummary.fromJson(e as Map<String, dynamic>)).toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$AttemptSummaryPageToJson(AttemptSummaryPage instance) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
};
