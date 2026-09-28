// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_card_kind.dart';

part 'user_card_write.g.dart';

@JsonSerializable()
class UserCardWrite {
  const UserCardWrite({
    required this.id,
    required this.deckId,
    required this.kind,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.frontText,
    this.backText,
    this.frontMediaId,
    this.backMediaId,
    this.officialFlashcardId,
    this.deletedAt,
  });
  
  factory UserCardWrite.fromJson(Map<String, Object?> json) => _$UserCardWriteFromJson(json);
  
  final String id;
  final String deckId;
  final UserCardKind kind;
  @JsonKey(includeIfNull: false)
  final String? frontText;
  @JsonKey(includeIfNull: false)
  final String? backText;
  @JsonKey(includeIfNull: false)
  final String? frontMediaId;
  @JsonKey(includeIfNull: false)
  final String? backMediaId;
  @JsonKey(includeIfNull: false)
  final String? officialFlashcardId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(includeIfNull: false)
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => _$UserCardWriteToJson(this);
}
