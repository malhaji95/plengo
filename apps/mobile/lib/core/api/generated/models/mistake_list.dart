// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mistake.dart';

part 'mistake_list.g.dart';

@JsonSerializable()
class MistakeList {
  const MistakeList({
    required this.items,
    required this.activeCount,
    required this.masteredCount,
    required this.masteryStreak,
    required this.nextCursor,
  });

  factory MistakeList.fromJson(Map<String, Object?> json) => _$MistakeListFromJson(json);

  final List<Mistake> items;
  final int activeCount;
  final int masteredCount;
  final int masteryStreak;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;

  Map<String, Object?> toJson() => _$MistakeListToJson(this);
}
