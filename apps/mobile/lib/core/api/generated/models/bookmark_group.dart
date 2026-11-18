// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bookmark_group.g.dart';

@JsonSerializable()
class BookmarkGroup {
  const BookmarkGroup({
    required this.subjectId,
    required this.subjectNameAr,
    required this.unitId,
    required this.unitTitleAr,
    required this.lessonId,
    required this.lessonTitleAr,
    required this.deckId,
    required this.deckTitle,
    required this.ownDeck,
  });
  
  factory BookmarkGroup.fromJson(Map<String, Object?> json) => _$BookmarkGroupFromJson(json);
  
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? subjectNameAr;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? unitTitleAr;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  @JsonKey(includeIfNull: true)
  final String? lessonTitleAr;
  @JsonKey(includeIfNull: true)
  final String? deckId;
  @JsonKey(includeIfNull: true)
  final String? deckTitle;
  final bool ownDeck;

  Map<String, Object?> toJson() => _$BookmarkGroupToJson(this);
}
