// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_deck.dart';

part 'plengo_deck_group.g.dart';

@JsonSerializable()
class PlengoDeckGroup {
  const PlengoDeckGroup({
    required this.subjectId,
    required this.subjectNameAr,
    required this.subjectCode,
    required this.subjectCoverUrl,
    required this.subjectSortOrder,
    required this.decks,
  });
  
  factory PlengoDeckGroup.fromJson(Map<String, Object?> json) => _$PlengoDeckGroupFromJson(json);
  
  final String subjectId;
  final String subjectNameAr;
  final String subjectCode;
  @JsonKey(includeIfNull: true)
  final String? subjectCoverUrl;
  final int subjectSortOrder;
  final List<StudentDeck> decks;

  Map<String, Object?> toJson() => _$PlengoDeckGroupToJson(this);
}
