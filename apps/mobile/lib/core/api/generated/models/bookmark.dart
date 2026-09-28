// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark_item_type.dart';
import 'student_card.dart';
import 'student_deck.dart';
import 'student_question.dart';

part 'bookmark.g.dart';

@JsonSerializable()
class Bookmark {
  const Bookmark({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.createdAt,
    required this.locked,
    required this.available,
    required this.titleAr,
    required this.subjectId,
    required this.subjectNameAr,
    required this.question,
    required this.deck,
    required this.card,
  });

  factory Bookmark.fromJson(Map<String, Object?> json) => _$BookmarkFromJson(json);

  final String id;
  final BookmarkItemType itemType;
  final String itemId;
  final String createdAt;
  final bool locked;
  final bool available;
  @JsonKey(includeIfNull: true)
  final String? titleAr;
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? subjectNameAr;
  @JsonKey(includeIfNull: true)
  final StudentQuestion? question;
  @JsonKey(includeIfNull: true)
  final StudentDeck? deck;
  @JsonKey(includeIfNull: true)
  final StudentCard? card;

  Map<String, Object?> toJson() => _$BookmarkToJson(this);
}
