// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'today.g.dart';

@JsonSerializable()
class Today {
  const Today({
    required this.dueCards,
    required this.goal,
    required this.done,
    required this.goalMet,
    required this.streak,
  });

  factory Today.fromJson(Map<String, Object?> json) => _$TodayFromJson(json);

  final int dueCards;
  final int goal;
  final int done;
  final bool goalMet;
  final int streak;

  Map<String, Object?> toJson() => _$TodayToJson(this);
}
