// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_summary.dart';

part 'attempt_summary_page.g.dart';

@JsonSerializable()
class AttemptSummaryPage {
  const AttemptSummaryPage({required this.items, required this.nextCursor});

  factory AttemptSummaryPage.fromJson(Map<String, Object?> json) => _$AttemptSummaryPageFromJson(json);

  final List<AttemptSummary> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;

  Map<String, Object?> toJson() => _$AttemptSummaryPageToJson(this);
}
