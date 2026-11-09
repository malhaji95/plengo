// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_deck.g.dart';

@JsonSerializable()
class UserDeck {
  const UserDeck({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.color,
    required this.sortOrder,
    required this.cardCount,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });
  
  factory UserDeck.fromJson(Map<String, Object?> json) => _$UserDeckFromJson(json);
  
  final String id;
  final String name;
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? color;
  final int sortOrder;
  final int cardCount;
  final String createdAt;
  final String updatedAt;
  @JsonKey(includeIfNull: true)
  final String? deletedAt;

  Map<String, Object?> toJson() => _$UserDeckToJson(this);
}
