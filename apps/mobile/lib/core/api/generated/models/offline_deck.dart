// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'offline_deck.g.dart';

@JsonSerializable()
class OfflineDeck {
  const OfflineDeck({
    required this.id,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.description,
    required this.isFree,
    required this.sortOrder,
    required this.cardIds,
  });

  factory OfflineDeck.fromJson(Map<String, Object?> json) => _$OfflineDeckFromJson(json);

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
  final bool isFree;
  final int sortOrder;
  final List<String> cardIds;

  Map<String, Object?> toJson() => _$OfflineDeckToJson(this);
}
