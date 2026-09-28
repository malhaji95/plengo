// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'student_deck.g.dart';

@JsonSerializable()
class StudentDeck {
  const StudentDeck({
    required this.id,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.description,
    required this.coverUrl,
    required this.cardCount,
    required this.isFree,
    required this.locked,
    required this.contentVersion,
    required this.sortOrder,
  });

  factory StudentDeck.fromJson(Map<String, Object?> json) => _$StudentDeckFromJson(json);

  final String id;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final String titleAr;
  @JsonKey(includeIfNull: true)
  final String? description;
  @JsonKey(includeIfNull: true)
  final String? coverUrl;
  final int cardCount;
  final bool isFree;
  final bool locked;
  final int contentVersion;
  final int sortOrder;

  Map<String, Object?> toJson() => _$StudentDeckToJson(this);
}
